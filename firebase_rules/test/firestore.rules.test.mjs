import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import {after, before, beforeEach, describe, test} from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  setDoc,
  Timestamp,
  updateDoc,
  where,
} from "firebase/firestore";

const projectId = "mube-rules-test";
const repoRoot = path.resolve(import.meta.dirname, "../..");
let env;

function auth(uid, extra = {}) {
  return env.authenticatedContext(uid, {
    email: `${uid}@example.com`,
    email_verified: true,
    ...extra,
  }).firestore();
}

async function seed(entries) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await Promise.all(
      entries.map(([documentPath, data]) => setDoc(doc(db, documentPath), data)),
    );
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.join(repoRoot, "firestore.rules"), "utf8"),
    },
  });
});

beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

describe("bootstrap e perfis", () => {
  test("expõe apenas a configuração pública antes do login", async () => {
    await seed([
      ["config/app_data", {minVersion: "1.0.0"}],
      ["config/private", {secret: true}],
    ]);
    const guest = env.unauthenticatedContext().firestore();

    await assertSucceeds(getDoc(doc(guest, "config/app_data")));
    await assertFails(getDoc(doc(guest, "config/private")));
  });

  test("permite criar o próprio perfil, mas bloqueia campos administrativos e exclusão", async () => {
    const alice = auth("alice");
    const userRef = doc(alice, "users/alice");

    await assertSucceeds(setDoc(userRef, {
      uid: "alice",
      email: "alice@example.com",
      cadastro_status: "tipo_pendente",
      nome: "Alice",
    }));
    await assertFails(updateDoc(userRef, {report_count: 99}));
    await assertFails(deleteDoc(userRef));

    const bob = auth("bob");
    await assertFails(setDoc(doc(bob, "users/alice"), {
      uid: "alice",
      cadastro_status: "tipo_pendente",
    }));
  });

  test("perfil privado exige login e contratante público permanece compartilhável", async () => {
    await seed([
      ["users/private", {uid: "private", tipo_perfil: "musico"}],
      ["users/public", {
        uid: "public",
        tipo_perfil: "contratante",
        contratante: {isPublic: true},
      }],
    ]);
    const guest = env.unauthenticatedContext().firestore();

    await assertFails(getDoc(doc(guest, "users/private")));
    await assertSucceeds(getDoc(doc(guest, "users/public")));
    await assertSucceeds(getDoc(doc(auth("alice"), "users/private")));
  });
});

describe("dados privados e backend-only", () => {
  test("subcoleções privadas são isoladas por proprietário", async () => {
    const alice = auth("alice");
    const bob = auth("bob");
    const favorite = doc(alice, "users/alice/favorites/bob");
    const blocked = doc(alice, "users/alice/blocked/bob");
    const notification = doc(alice, "users/alice/notifications/n1");

    await assertSucceeds(setDoc(favorite, {target_user_id: "bob"}));
    await assertSucceeds(setDoc(blocked, {blockedUserId: "bob"}));
    await assertSucceeds(setDoc(notification, {senderId: "bob"}));
    await assertFails(setDoc(doc(bob, favorite.path), {target_user_id: "bob"}));
    await assertFails(getDoc(doc(bob, notification.path)));
  });

  test("coleções calculadas não aceitam gravação do cliente", async () => {
    const alice = auth("alice");
    for (const documentPath of [
      "interactions/i1",
      "matches/m1",
      "matchpointFeeds/alice",
      "publicUsernames/alice",
      "suspensions/s1",
      "userModerations/m1",
      "matchpointStats/alice",
    ]) {
      await assertFails(setDoc(doc(alice, documentPath), {user_id: "alice"}));
    }
  });
});

describe("chat", () => {
  test("somente participantes leem e usuário verificado envia mensagem", async () => {
    await seed([["conversations/alice_bob", {
      participants: ["alice", "bob"],
      requestStatus: "accepted",
    }]]);
    const alice = auth("alice");
    const outsider = auth("mallory");

    await assertSucceeds(getDoc(doc(alice, "conversations/alice_bob")));
    await assertFails(getDoc(doc(outsider, "conversations/alice_bob")));
    await assertSucceeds(setDoc(
      doc(alice, "conversations/alice_bob/messages/m1"),
      {senderId: "alice", text: "Olá", createdAt: Timestamp.now()},
    ));
    await assertFails(setDoc(
      doc(outsider, "conversations/alice_bob/messages/m2"),
      {senderId: "mallory", text: "intrusão", createdAt: Timestamp.now()},
    ));
  });

  test("bloqueia remetente não verificado e conversa encerrada", async () => {
    await seed([["conversations/alice_bob", {
      participants: ["alice", "bob"],
      requestStatus: "accepted",
      is_closed: true,
    }]]);
    const alice = auth("alice");
    const unverified = auth("bob", {email_verified: false});
    const message = {text: "Olá", createdAt: Timestamp.now()};

    await assertFails(setDoc(
      doc(alice, "conversations/alice_bob/messages/a"),
      {...message, senderId: "alice"},
    ));
    await assertFails(setDoc(
      doc(unverified, "conversations/alice_bob/messages/b"),
      {...message, senderId: "bob"},
    ));
    await assertFails(updateDoc(doc(alice, "conversations/alice_bob"), {
      is_closed: false,
    }));
  });
});

describe("marketplace e denúncias", () => {
  const validGig = {
    creator_id: "alice",
    title: "Banda para evento",
    description: "Precisamos de banda completa para um evento particular.",
    gig_type: "evento_privado",
    date_mode: "to_be_arranged",
    location_type: "presencial",
    compensation_type: "negotiable",
    slots_total: 2,
    slots_filled: 0,
    applicant_count: 0,
    status: "open",
    created_at: Timestamp.now(),
  };

  test("exige perfil concluído e protege contadores de gigs", async () => {
    await seed([
      ["users/alice", {uid: "alice", cadastro_status: "concluido"}],
      ["users/draft", {uid: "draft", cadastro_status: "perfil_pendente"}],
    ]);
    const alice = auth("alice");
    await assertSucceeds(setDoc(doc(alice, "gigs/g1"), validGig));
    await assertFails(updateDoc(doc(alice, "gigs/g1"), {applicant_count: 100}));
    await assertFails(deleteDoc(doc(alice, "gigs/g1")));
    await assertFails(setDoc(doc(alice, "gigs/title-too-long"), {
      ...validGig,
      title: "x".repeat(121),
    }));
    await assertFails(setDoc(doc(alice, "gigs/description-too-long"), {
      ...validGig,
      description: "x".repeat(2001),
    }));

    await assertFails(setDoc(doc(auth("draft"), "gigs/g2"), {
      ...validGig,
      creator_id: "draft",
    }));
  });

  test("candidato aplica em gig alheia e não pode forjar identidade", async () => {
    await seed([
      ["users/alice", {uid: "alice", cadastro_status: "concluido"}],
      ["users/bob", {uid: "bob", cadastro_status: "concluido"}],
      ["gigs/g1", validGig],
    ]);
    const bob = auth("bob");
    const application = {
      applicant_id: "bob",
      message: "Tenho disponibilidade.",
      status: "pending",
      applied_at: Timestamp.now(),
      responded_at: null,
    };
    await assertSucceeds(setDoc(doc(bob, "gigs/g1/gig_applications/bob"), application));
    await assertFails(setDoc(doc(bob, "gigs/g1/gig_applications/mallory"), application));
  });

  test("denúncia válida entra como pending e nunca fica legível ao cliente", async () => {
    await seed([["users/bob", {uid: "bob", cadastro_status: "concluido"}]]);
    const alice = auth("alice");
    const reportRef = doc(alice, "reports/r1");
    await assertSucceeds(setDoc(reportRef, {
      reporter_user_id: "alice",
      reported_item_id: "bob",
      reported_item_type: "user",
      reason: "Perfil falso",
      created_at: Timestamp.now(),
      status: "pending",
    }));
    await assertFails(getDoc(reportRef));
    await assertFails(updateDoc(reportRef, {status: "resolved"}));
  });
});

describe("queries", () => {
  test("consulta de candidaturas só retorna as do usuário", async () => {
    await seed([
      ["gigs/g1", {creator_id: "alice"}],
      ["gigs/g1/gig_applications/bob", {applicant_id: "bob"}],
      ["gigs/g2", {creator_id: "alice"}],
      ["gigs/g2/gig_applications/mallory", {applicant_id: "mallory"}],
    ]);
    const bob = auth("bob");
    const scoped = query(
      collection(bob, "gigs/g1/gig_applications"),
      where("applicant_id", "==", "bob"),
    );
    const snapshot = await assertSucceeds(getDocs(scoped));
    assert.equal(snapshot.size, 1);
  });
});
