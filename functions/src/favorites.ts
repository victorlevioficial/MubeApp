import {
  onDocumentCreated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();

/**
 * Converts an unknown value into a non-negative integer.
 *
 * @param {unknown} value - Raw value.
 * @return {number} Non-negative integer.
 */
function toNonNegativeInt(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return 0;
  }

  return Math.max(0, Math.floor(value));
}

/**
 * Applies +1/-1 to received-like counters of target user.
 *
 * Counters kept in sync:
 * - likeCount
 * - favorites_count
 *
 * @param {string} targetUserId - User receiving or losing a like.
 * @param {1|-1} delta - Counter delta (+1 create, -1 delete).
 * @return {Promise<void>} Completes when transaction ends.
 */
async function applyReceivedFavoriteDelta(
  targetUserId: string,
  delta: 1 | -1
): Promise<void> {
  const targetUserRef = db.collection("users").doc(targetUserId);

  await db.runTransaction(async (transaction) => {
    const targetUserDoc = await transaction.get(targetUserRef);
    if (!targetUserDoc.exists) {
      console.warn(
        `onFavoriteTrigger: target user ${targetUserId} does not exist`
      );
      return;
    }

    const data = targetUserDoc.data() || {};
    // Canonical counter for runtime updates is `likeCount`.
    // `favorites_count` is mirrored for legacy compatibility only.
    const currentBase = toNonNegativeInt(data.likeCount);
    const nextCount = Math.max(0, currentBase + delta);

    transaction.update(targetUserRef, {
      likeCount: nextCount,
      favorites_count: nextCount,
      updated_at: Timestamp.now(),
    });
  });
}

/**
 * Triggered when user A favorites user B.
 * Path: users/{userId}/favorites/{favoriteId}
 */
export const onFavoriteCreated = onDocumentCreated(
  {
    document: "users/{userId}/favorites/{favoriteId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const actorUserId = event.params.userId as string;
    const targetUserId = event.params.favoriteId as string;

    if (!targetUserId || actorUserId === targetUserId) {
      return;
    }

    try {
      await applyReceivedFavoriteDelta(targetUserId, 1);
    } catch (error) {
      console.error("Erro ao processar onFavoriteCreated:", error);
    }
  }
);

/**
 * Triggered when user A removes favorite from user B.
 * Path: users/{userId}/favorites/{favoriteId}
 */
export const onFavoriteDeleted = onDocumentDeleted(
  {
    document: "users/{userId}/favorites/{favoriteId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const actorUserId = event.params.userId as string;
    const targetUserId = event.params.favoriteId as string;

    if (!targetUserId || actorUserId === targetUserId) {
      return;
    }

    try {
      await applyReceivedFavoriteDelta(targetUserId, -1);
    } catch (error) {
      console.error("Erro ao processar onFavoriteDeleted:", error);
    }
  }
);
