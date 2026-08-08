import * as admin from "firebase-admin";
import {cleanupUserFirestoreData} from "../src/account_deletion";

const describeWithEmulator = process.env.FIRESTORE_EMULATOR_HOST ? describe : describe.skip;

describeWithEmulator("account deletion against Firestore emulator", () => {
  const projectId = "mube-rules-test";
  const uid = "delete-me";
  let db: FirebaseFirestore.Firestore;

  beforeAll(() => {
    if (admin.apps.length === 0) {
      admin.initializeApp({projectId});
    }
    db = admin.firestore();
  });

  afterAll(async () => {
    await Promise.all(admin.apps.map((app) => app?.delete()));
  });

  test("deletes private data and anonymizes shared relationships", async () => {
    const now = admin.firestore.Timestamp.now();
    const docs: Array<[string, FirebaseFirestore.DocumentData]> = [
      ["stories/story-owned", {owner_uid: uid}],
      ["stories/story-owned/views/viewer", {viewer_uid: "other"}],
      ["stories/story-other", {owner_uid: "other"}],
      ["stories/story-other/views/deleted-view", {viewer_uid: uid}],
      ["users/other/favorites/deleted", {target_user_id: uid}],
      ["users/other/blocked/deleted", {blockedUserId: uid}],
      ["users/other/notifications/from-deleted", {senderId: uid}],
      ["users/other/story_seen_authors/deleted", {owner_uid: uid}],
      ["posts/deleted-post", {author_id: uid}],
      ["interactions/deleted-like", {source_user_id: uid, target_user_id: "other"}],
      ["matchpointCommands/deleted-command", {user_id: uid, target_user_id: "other"}],
      ["matchpointFeedRefreshRequests/deleted-refresh", {user_id: uid}],
      ["matches/deleted-match", {user_ids: [uid, "other"]}],
      ["invites/deleted-invite", {sender_uid: uid, target_uid: "other"}],
      ["tickets/deleted-ticket", {userId: uid}],
      ["mediaTranscodeJobs/deleted-job", {userId: uid}],
      ["matchpointFeeds/delete-me", {candidate_ids: ["other"]}],
      ["messageDailyCounters/delete-me", {subject_id: uid}],
      ["notifications_cooldown/delete-me_other", {lastPushAt: now}],
      ["notifications_cooldown/other_delete-me", {lastPushAt: now}],
      ["notifications_cooldown/other_third", {lastPushAt: now}],
      ["conversations/delete-me_other", {
        participants: [uid, "other"],
        lastSenderId: uid,
        requestStatus: "pending",
      }],
      ["conversations/delete-me_other/messages/sent", {
        senderId: uid,
        sender_name: "Personal Name",
        sender_photo: "https://example.com/private.jpg",
        text: "mensagem preservada",
        createdAt: now,
      }],
      ["conversations/delete-me_other/messages/reply", {
        senderId: "other",
        replyToSenderId: uid,
        replyToText: "texto pessoal citado",
        text: "resposta",
        createdAt: now,
      }],
      ["users/other/conversationPreviews/delete-me_other", {
        otherUserId: uid,
        otherUserName: "Personal Name",
        otherUserPhoto: "private.jpg",
        unreadCount: 4,
      }],
      ["gigs/deleted-gig", {creator_id: uid, status: "open"}],
      ["gigs/other-gig/gig_applications/delete-me", {
        applicant_id: uid,
        message: "telefone pessoal",
        status: "pending",
      }],
      ["gig_reviews/by-deleted", {
        reviewer_id: uid,
        reviewed_user_id: "other",
        comment: "comentário pessoal",
      }],
      ["gig_reviews/about-deleted", {
        reviewer_id: "other",
        reviewed_user_id: uid,
        comment: "registro compartilhado",
      }],
      ["reports/by-deleted", {reporter_user_id: uid, reported_item_id: "other"}],
      ["reports/about-deleted", {reporter_user_id: "other", reported_item_id: uid}],
      ["chatSafetyEvents/deleted-event", {user_id: uid, masked_text: "***"}],
      ["matchpointFeeds/other", {candidate_ids: [uid, "third"]}],
      ["users/blocking", {blocked_users: [uid, "third"]}],
      ["users/band", {members: [uid, "other"], status: "ativo"}],
      ["config/featuredProfiles", {uids: [uid, "other"]}],
    ];

    const batch = db.batch();
    for (const [path, data] of docs) batch.set(db.doc(path), data);
    await batch.commit();

    const summary = await cleanupUserFirestoreData(db, uid);

    expect(summary.deletedDocuments).toBeGreaterThanOrEqual(16);
    expect(summary.recursivelyDeletedDocuments).toBe(1);
    expect(summary.anonymizedDocuments).toBeGreaterThanOrEqual(10);
    expect(summary.detachedReferences).toBe(4);

    for (const path of [
      "stories/story-owned",
      "stories/story-owned/views/viewer",
      "stories/story-other/views/deleted-view",
      "users/other/favorites/deleted",
      "users/other/blocked/deleted",
      "users/other/notifications/from-deleted",
      "users/other/story_seen_authors/deleted",
      "posts/deleted-post",
      "interactions/deleted-like",
      "matchpointCommands/deleted-command",
      "matches/deleted-match",
      "tickets/deleted-ticket",
      "mediaTranscodeJobs/deleted-job",
      "matchpointFeeds/delete-me",
      "messageDailyCounters/delete-me",
      "notifications_cooldown/delete-me_other",
      "notifications_cooldown/other_delete-me",
    ]) {
      expect((await db.doc(path).get()).exists).toBe(false);
    }
    expect((await db.doc("notifications_cooldown/other_third").get()).exists).toBe(true);

    const conversation = (await db.doc("conversations/delete-me_other").get()).data();
    expect(conversation).toMatchObject({
      is_closed: true,
      closed_reason: "participant_deleted",
      lastSenderId: "deleted",
    });
    const sentMessage = (
      await db.doc("conversations/delete-me_other/messages/sent").get()
    ).data();
    expect(sentMessage).toMatchObject({
      senderId: "deleted",
      sender_name: "Conta excluída",
      sender_photo: null,
      sender_deleted: true,
    });
    const reply = (
      await db.doc("conversations/delete-me_other/messages/reply").get()
    ).data();
    expect(reply).toMatchObject({
      replyToSenderId: "deleted",
      replyToText: "Mensagem de conta excluída",
    });
    const preview = (
      await db.doc("users/other/conversationPreviews/delete-me_other").get()
    ).data();
    expect(preview).toMatchObject({
      otherUserName: "Conta excluída",
      otherUserPhoto: null,
      otherUserDeleted: true,
      unreadCount: 0,
    });
    expect((await db.doc("gigs/deleted-gig").get()).data()).toMatchObject({
      creator_id: "deleted",
      creator_deleted: true,
      status: "cancelled",
    });
    expect((
      await db.doc("gigs/other-gig/gig_applications/delete-me").get()
    ).data()).toMatchObject({
      applicant_id: "deleted",
      applicant_deleted: true,
      message: "",
      status: "rejected",
    });
    expect((await db.doc("chatSafetyEvents/deleted-event").get()).data()).toMatchObject({
      user_id: "deleted",
      user_deleted: true,
    });
    expect((await db.doc("matchpointFeeds/other").get()).data()?.candidate_ids)
      .toEqual(["third"]);
    expect((await db.doc("users/blocking").get()).data()?.blocked_users)
      .toEqual(["third"]);
    expect((await db.doc("users/band").get()).data()).toMatchObject({
      members: ["other"],
      status: "rascunho",
    });
    expect((await db.doc("config/featuredProfiles").get()).data()?.uids)
      .toEqual(["other"]);
  }, 30_000);
});
