import * as admin from "firebase-admin";

type FirestoreDb = FirebaseFirestore.Firestore;
type FirestoreQuery = FirebaseFirestore.Query<FirebaseFirestore.DocumentData>;
type FirestoreDoc = FirebaseFirestore.QueryDocumentSnapshot<
  FirebaseFirestore.DocumentData
>;
type UpdatePayload = FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>;

const BATCH_SIZE = 400;
const DELETED_ACTOR_ID = "deleted";
const DELETED_ACTOR_NAME = "Conta excluída";

export interface AccountDeletionCleanupSummary {
  deletedDocuments: number;
  recursivelyDeletedDocuments: number;
  anonymizedDocuments: number;
  detachedReferences: number;
}

function uniqueDocs(docs: FirestoreDoc[]): FirestoreDoc[] {
  const byPath = new Map<string, FirestoreDoc>();
  for (const doc of docs) byPath.set(doc.ref.path, doc);
  return [...byPath.values()];
}

async function loadQueryDocs(queries: FirestoreQuery[]): Promise<FirestoreDoc[]> {
  const snapshots = await Promise.all(queries.map((query) => query.get()));
  return uniqueDocs(snapshots.flatMap((snapshot) => snapshot.docs));
}

async function commitDeletes(db: FirestoreDb, docs: FirestoreDoc[]): Promise<number> {
  for (let index = 0; index < docs.length; index += BATCH_SIZE) {
    const batch = db.batch();
    for (const doc of docs.slice(index, index + BATCH_SIZE)) {
      batch.delete(doc.ref);
    }
    await batch.commit();
  }
  return docs.length;
}

async function commitUpdates(
  db: FirestoreDb,
  docs: FirestoreDoc[],
  payloadFor: (doc: FirestoreDoc) => UpdatePayload | null
): Promise<number> {
  let updated = 0;
  for (let index = 0; index < docs.length; index += BATCH_SIZE) {
    const batch = db.batch();
    let batchWrites = 0;
    for (const doc of docs.slice(index, index + BATCH_SIZE)) {
      const payload = payloadFor(doc);
      if (payload === null) continue;
      batch.update(doc.ref, payload);
      batchWrites += 1;
      updated += 1;
    }
    if (batchWrites > 0) await batch.commit();
  }
  return updated;
}

function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

/**
 * Removes or anonymizes every Firestore relationship tied to an account.
 *
 * Private and ephemeral documents are deleted. Shared records such as chat
 * transcripts, gigs, applications, reviews and moderation evidence are kept
 * only when another user depends on them, with embedded identity fields
 * removed. The function is deliberately idempotent so an authenticated user
 * can retry after a partial infrastructure failure.
 *
 * @param {FirestoreDb} db Firestore Admin instance.
 * @param {string} uid Auth uid being deleted.
 * @return {Promise<AccountDeletionCleanupSummary>} Cleanup counters for logs.
 */
export async function cleanupUserFirestoreData(
  db: FirestoreDb,
  uid: string
): Promise<AccountDeletionCleanupSummary> {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const expiredAt = admin.firestore.Timestamp.fromMillis(0);
  const summary: AccountDeletionCleanupSummary = {
    deletedDocuments: 0,
    recursivelyDeletedDocuments: 0,
    anonymizedDocuments: 0,
    detachedReferences: 0,
  };

  const ownedStories = await db
    .collection("stories")
    .where("owner_uid", "==", uid)
    .get();
  for (const story of ownedStories.docs) {
    await db.recursiveDelete(story.ref);
    summary.recursivelyDeletedDocuments += 1;
  }

  const privateDocs = await loadQueryDocs([
    db.collectionGroup("views").where("viewer_uid", "==", uid),
    db.collectionGroup("favorites").where("target_user_id", "==", uid),
    db.collectionGroup("blocked").where("blockedUserId", "==", uid),
    db.collectionGroup("notifications").where("senderId", "==", uid),
    db.collectionGroup("story_seen_authors").where("owner_uid", "==", uid),
    db.collection("posts").where("author_id", "==", uid),
    db.collection("interactions").where("source_user_id", "==", uid),
    db.collection("interactions").where("target_user_id", "==", uid),
    db.collection("interactions").where("senderId", "==", uid),
    db.collection("interactions").where("receiverId", "==", uid),
    db.collection("matchpointCommands").where("user_id", "==", uid),
    db.collection("matchpointCommands").where("target_user_id", "==", uid),
    db.collection("matchpointFeedRefreshRequests").where("user_id", "==", uid),
    db.collection("matches").where("user_ids", "array-contains", uid),
    db.collection("invites").where("target_uid", "==", uid),
    db.collection("invites").where("sender_uid", "==", uid),
    db.collection("invites").where("band_id", "==", uid),
    db.collection("bandMemberships").where("user_id", "==", uid),
    db.collection("bandMemberships").where("band_id", "==", uid),
    db.collection("tickets").where("userId", "==", uid),
    db.collection("mediaTranscodeJobs").where("userId", "==", uid),
  ]);
  summary.deletedDocuments += await commitDeletes(db, privateDocs);

  const ownFeedRef = db.collection("matchpointFeeds").doc(uid);
  const directPrivateRefs = [
    ownFeedRef,
    db.collection("messageDailyCounters").doc(uid),
  ];
  for (const ref of directPrivateRefs) {
    await ref.delete();
    summary.deletedDocuments += 1;
  }

  // Legacy push cooldown documents predate queryable owner fields. They are
  // short-lived technical state, so remove the entries whose deterministic id
  // contains the deleted account at either side of the sender/recipient pair.
  const cooldownSnapshot = await db.collection("notifications_cooldown").get();
  const cooldownDocs = cooldownSnapshot.docs.filter(
    (doc) => doc.id.startsWith(`${uid}_`) || doc.id.endsWith(`_${uid}`)
  );
  summary.deletedDocuments += await commitDeletes(db, cooldownDocs);

  const conversations = await db
    .collection("conversations")
    .where("participants", "array-contains", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    conversations.docs,
    (doc) => {
      const data = doc.data();
      const payload: UpdatePayload = {
        is_closed: true,
        closed_reason: "participant_deleted",
        closed_at: now,
        requestStatus: "accepted",
        requestRecipientId: null,
        requestSenderId: null,
        updatedAt: now,
      };
      if (data.lastSenderId === uid) payload.lastSenderId = DELETED_ACTOR_ID;
      return payload;
    }
  );

  const sentMessages = await db
    .collectionGroup("messages")
    .where("senderId", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    sentMessages.docs,
    () => ({
      senderId: DELETED_ACTOR_ID,
      sender_name: DELETED_ACTOR_NAME,
      sender_photo: null,
      sender_deleted: true,
    })
  );

  const repliesToUser = await db
    .collectionGroup("messages")
    .where("replyToSenderId", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    repliesToUser.docs,
    () => ({
      replyToSenderId: DELETED_ACTOR_ID,
      replyToText: "Mensagem de conta excluída",
    })
  );

  const otherUserPreviews = await db
    .collectionGroup("conversationPreviews")
    .where("otherUserId", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    otherUserPreviews.docs,
    () => ({
      otherUserName: DELETED_ACTOR_NAME,
      otherUserPhoto: null,
      otherUserDeleted: true,
      isPending: false,
      unreadCount: 0,
      updatedAt: now,
    })
  );

  const createdGigs = await db
    .collection("gigs")
    .where("creator_id", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    createdGigs.docs,
    (doc) => ({
      creator_id: DELETED_ACTOR_ID,
      creator_deleted: true,
      status: doc.data().status === "open" ? "cancelled" : doc.data().status,
      updated_at: now,
    })
  );

  const applications = await db
    .collectionGroup("gig_applications")
    .where("applicant_id", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    applications.docs,
    (doc) => {
      const isPending = doc.data().status === "pending";
      return {
        applicant_id: DELETED_ACTOR_ID,
        applicant_deleted: true,
        message: "",
        status: isPending ? "rejected" : doc.data().status,
        responded_at: isPending ? now : doc.data().responded_at ?? null,
      };
    }
  );

  const reviewsByUser = await db
    .collection("gig_reviews")
    .where("reviewer_id", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    reviewsByUser.docs,
    () => ({
      reviewer_id: DELETED_ACTOR_ID,
      reviewer_deleted: true,
      comment: null,
    })
  );
  const reviewsAboutUser = await db
    .collection("gig_reviews")
    .where("reviewed_user_id", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    reviewsAboutUser.docs,
    () => ({
      reviewed_user_id: DELETED_ACTOR_ID,
      reviewed_user_deleted: true,
    })
  );

  const filedReports = await db
    .collection("reports")
    .where("reporter_user_id", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    filedReports.docs,
    () => ({
      reporter_user_id: DELETED_ACTOR_ID,
      reporter_deleted: true,
    })
  );

  const safetyEvents = await db
    .collection("chatSafetyEvents")
    .where("user_id", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    safetyEvents.docs,
    () => ({
      user_id: DELETED_ACTOR_ID,
      user_deleted: true,
    })
  );
  const reportsAboutUser = await db
    .collection("reports")
    .where("reported_item_id", "==", uid)
    .get();
  summary.anonymizedDocuments += await commitUpdates(
    db,
    reportsAboutUser.docs,
    () => ({reported_item_deleted: true})
  );

  const feedsContainingUser = await db
    .collection("matchpointFeeds")
    .where("candidate_ids", "array-contains", uid)
    .get();
  summary.detachedReferences += await commitUpdates(
    db,
    feedsContainingUser.docs,
    () => ({
      candidate_ids: admin.firestore.FieldValue.arrayRemove(uid),
      expires_at: expiredAt,
      updated_at: now,
    })
  );

  const blockingUsers = await db
    .collection("users")
    .where("blocked_users", "array-contains", uid)
    .get();
  summary.detachedReferences += await commitUpdates(
    db,
    blockingUsers.docs,
    () => ({
      blocked_users: admin.firestore.FieldValue.arrayRemove(uid),
      updated_at: now,
    })
  );

  const bandsContainingUser = await db
    .collection("users")
    .where("members", "array-contains", uid)
    .get();
  summary.detachedReferences += await commitUpdates(
    db,
    bandsContainingUser.docs,
    (doc) => {
      const remainingMembers = stringList(doc.data().members).filter(
        (memberId) => memberId !== uid
      );
      return {
        members: admin.firestore.FieldValue.arrayRemove(uid),
        status: remainingMembers.length >= 2 ? doc.data().status : "rascunho",
        updated_at: now,
      };
    }
  );

  const featuredRef = db.collection("config").doc("featuredProfiles");
  const featuredDoc = await featuredRef.get();
  if (featuredDoc.exists && stringList(featuredDoc.data()?.uids).includes(uid)) {
    await featuredRef.update({
      uids: admin.firestore.FieldValue.arrayRemove(uid),
      updatedAt: now,
    });
    summary.detachedReferences += 1;
  }

  return summary;
}
