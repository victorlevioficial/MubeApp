import {
  onDocumentCreated,
  onDocumentDeleted,
} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();

interface FavoriteNotificationInput {
  userId: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  senderId: string;
  route: string;
}

/**
 * Returns the display name for a user document.
 *
 * Checks `profissional.nomeArtistico` first, then `name`, then fallback.
 *
 * @param {Record<string, unknown>} data - User document data.
 * @param {string} fallback - Fallback text.
 * @return {string} Display name.
 */
function getDisplayName(
  data: Record<string, unknown>,
  fallback = "Alguém"
): string {
  const profissional = data.profissional as Record<string, unknown> | undefined;
  const artistName = profissional?.nomeArtistico;
  if (typeof artistName === "string" && artistName.trim().length > 0) {
    return artistName.trim();
  }
  const name = data.name;
  if (typeof name === "string" && name.trim().length > 0) {
    return name.trim();
  }
  return fallback;
}

/**
 * Persists a notification in the target user's subcollection and sends a push.
 *
 * @param {FavoriteNotificationInput} input - Notification data.
 * @return {Promise<void>}
 */
async function notifyFavoriteReceived(
  input: FavoriteNotificationInput
): Promise<void> {
  // Persist notification in Firestore
  await db
    .collection("users")
    .doc(input.userId)
    .collection("notifications")
    .doc(input.notificationId)
    .set({
      type: input.type,
      title: input.title,
      body: input.body,
      senderId: input.senderId,
      route: input.route,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

  // Send push notification (best-effort)
  const userDoc = await db.collection("users").doc(input.userId).get();
  const userData = userDoc.data() || {};
  const fcmToken = userData.fcm_token;

  if (typeof fcmToken !== "string" || fcmToken.trim().length === 0) {
    return;
  }

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: input.title,
        body: input.body,
      },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        type: input.type,
        route: input.route,
        sender_id: input.senderId,
      },
      android: {
        notification: {
          channelId: "high_importance_channel",
          tag: input.notificationId,
        },
        collapseKey: input.notificationId,
      },
      apns: {
        headers: {
          "apns-collapse-id": input.notificationId,
        },
      },
    });
  } catch (error) {
    console.error(`Erro ao enviar push para ${input.userId}:`, error);
  }
}

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

      // Send notification to the target user
      const actorDoc = await db.collection("users").doc(actorUserId).get();
      const actorData = actorDoc.data() || {};
      const actorName = getDisplayName(
        actorData as Record<string, unknown>,
        "Alguém"
      );

      await notifyFavoriteReceived({
        userId: targetUserId,
        notificationId: `like_${actorUserId}`,
        type: "like",
        title: actorName,
        body: "curtiu seu perfil",
        senderId: actorUserId,
        route: `/user/${actorUserId}`,
      });
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
