import fs from "node:fs";
import path from "node:path";
import {after, before, describe, test} from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {deleteObject, getBytes, ref, uploadBytes} from "firebase/storage";

const projectId = "mube-rules-test";
const repoRoot = path.resolve(import.meta.dirname, "../..");
let env;

function storage(uid) {
  return env.authenticatedContext(uid).storage();
}

async function seed(filePath, contentType = "image/jpeg") {
  await env.withSecurityRulesDisabled(async (context) => {
    await uploadBytes(ref(context.storage(), filePath), new Uint8Array([1, 2, 3]), {
      contentType,
    });
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    storage: {
      rules: fs.readFileSync(path.join(repoRoot, "storage.rules"), "utf8"),
    },
  });
});

after(async () => env.cleanup());

describe("Storage", () => {
  test("proprietário envia imagem válida; outro usuário e MIME inválido falham", async () => {
    const alice = storage("alice");
    const bytes = new Uint8Array([1, 2, 3]);
    await assertSucceeds(uploadBytes(
      ref(alice, "profile_photos/alice/avatar.webp"),
      bytes,
      {contentType: "image/webp"},
    ));
    await assertFails(uploadBytes(
      ref(storage("bob"), "profile_photos/alice/hijack.webp"),
      bytes,
      {contentType: "image/webp"},
    ));
    await assertFails(uploadBytes(
      ref(alice, "profile_photos/alice/payload.exe"),
      bytes,
      {contentType: "application/octet-stream"},
    ));
  });

  test("mídia pública é legível e fonte privada de story exige o dono", async () => {
    await seed("gallery_photos/alice/photo.jpg");
    await seed("stories_videos_source/alice/source.mp4", "video/mp4");
    const guest = env.unauthenticatedContext().storage();

    await assertSucceeds(getBytes(ref(guest, "gallery_photos/alice/photo.jpg")));
    await assertFails(getBytes(ref(guest, "stories_videos_source/alice/source.mp4")));
    await assertFails(getBytes(ref(storage("bob"), "stories_videos_source/alice/source.mp4")));
    await assertSucceeds(getBytes(ref(storage("alice"), "stories_videos_source/alice/source.mp4")));
  });

  test("saídas processadas são backend-only e fallback nega caminhos desconhecidos", async () => {
    const alice = storage("alice");
    const bytes = new Uint8Array([1, 2, 3]);
    await assertFails(uploadBytes(
      ref(alice, "gallery_videos_transcoded/alice/out.mp4"),
      bytes,
      {contentType: "video/mp4"},
    ));
    await assertFails(uploadBytes(
      ref(alice, "unknown/alice/file.jpg"),
      bytes,
      {contentType: "image/jpeg"},
    ));

    await seed("gallery_videos_transcoded/alice/out.mp4", "video/mp4");
    await assertSucceeds(deleteObject(ref(alice, "gallery_videos_transcoded/alice/out.mp4")));
    await seed("gallery_videos_transcoded/alice/out2.mp4", "video/mp4");
    await assertFails(deleteObject(ref(storage("bob"), "gallery_videos_transcoded/alice/out2.mp4")));
  });
});
