import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

// Export geohash and interactions migration functions
export {migrategeohashes, updateusergeohash} from "./geohash_migration";
export {migrateinteractions} from "./interaction_migration";

// Export Matchpoint functions
export {
  submitMatchpointAction,
  getRemainingLikes,
  onInteractionCreated,
} from "./matchpoint";

// Export Bands functions
export {
  manageBandInvite,
  getPendingInvites,
  leaveBand,
} from "./bands";

// Export Chat functions
export {
  initiateContact,
} from "./chat";

// Export Moderation functions
export {
  onReportCreated,
  liftSuspensions,
} from "./moderation";

// Export Scheduled functions
export {
  pruneOldInteractions,
  cleanupOrphanedData,
  updateMatchpointStats,
} from "./scheduled";

// Export Hashtag functions
export {
  onHashtagUsed,
  recalculateHashtagRanking,
  getTrendingHashtags,
  searchHashtags,
} from "./hashtags";

// Export Support functions
export {
  onTicketCreated,
} from "./support";

// Export Favorites functions
export {
  onFavoriteCreated,
  onFavoriteDeleted,
} from "./favorites";

/**
 * Push notification throttle cooldown in milliseconds.
 * Messages within this window from the same sender won't trigger
 * a new push notification — following WhatsApp/Telegram market pattern.
 */
const PUSH_COOLDOWN_MS = 30_000; // 30 seconds

/**
 * Trigger: When a new message is created in a conversation.
 * Path: conversations/{conversationId}/messages/{messageId}
 *
 * Actions:
 * 1. Update conversation metadata (lastMessageText, lastMessageAt, updatedAt).
 * 2. Send Push Notification to the recipient (with anti-flood throttle).
 *
 * Anti-flood strategy (market standard):
 * - 30s cooldown per sender→recipient pair prevents notification spam
 * - Notifications upserted by conversationId (one entry per conversation)
 * - Message count tracked for grouped display on client
 */
export const onMessageCreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log("No data associated with the event");
      return;
    }

    const conversationId = event.params.conversationId;
    const messageData = snapshot.data();
    const senderId = messageData.senderId;
    const text = messageData.text;
    const displayMessage = text || "📷 Enviou uma imagem";

    const db = admin.firestore();
    const conversationRef = db.collection("conversations").doc(conversationId);

    try {
      // 1. Update conversation metadata
      const conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) {
        console.error(`Conversation ${conversationId} does not exist.`);
        return;
      }

      const conversationData = conversationDoc.data();
      const participants: string[] = conversationData?.participants || [];

      const recipientId = participants.find((uid) => uid !== senderId);

      if (!recipientId) {
        console.log("No recipient found for this message.");
        return;
      }

      await db.runTransaction(async (transaction) => {
        transaction.update(conversationRef, {
          lastMessageText: displayMessage,
          lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
          lastSenderId: senderId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(`✅ Conversation updated for message ${snapshot.id}`);

      // 2. Upsert notification in Firestore
      // (one per conversation, not per message)
      const notificationRef = db
        .collection("users")
        .doc(recipientId)
        .collection("notifications")
        .doc(`chat_${conversationId}`);

      const existingNotification = await notificationRef.get();
      const senderName = messageData.sender_name || "Nova mensagem";

      if (existingNotification.exists) {
        const existingData = existingNotification.data() || {};
        const currentCount = (existingData.messageCount as number) || 1;
        const newCount = currentCount + 1;

        await notificationRef.update({
          body: `${newCount} novas mensagens`,
          messageCount: newCount,
          lastMessageText: displayMessage,
          isRead: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(
          `📝 Notification updated for ${recipientId} (${newCount} msgs)`
        );
      } else {
        await notificationRef.set({
          type: "chat_message",
          title: senderName,
          body: displayMessage,
          lastMessageText: displayMessage,
          conversationId: conversationId,
          senderId: senderId,
          messageCount: 1,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`📝 Notification created for ${recipientId}`);
      }

      // 3. Throttle check — only send push if cooldown expired
      const cooldownRef = db
        .collection("notifications_cooldown")
        .doc(`${recipientId}_${senderId}`);

      const cooldownDoc = await cooldownRef.get();
      const now = Date.now();

      if (cooldownDoc.exists) {
        const lastPushAt = cooldownDoc.data()?.lastPushAt?.toMillis() || 0;
        if (now - lastPushAt < PUSH_COOLDOWN_MS) {
          console.log(
            `⏳ Push throttled for ${recipientId} ` +
            "(" +
            Math.round(
              (PUSH_COOLDOWN_MS - (now - lastPushAt)) / 1000
            ) +
            "s remaining)"
          );
          return;
        }
      }

      // 4. Send push notification
      const userDoc = await db.collection("users").doc(recipientId).get();
      const userData = userDoc.data();
      const fcmToken = userData?.fcm_token;

      if (!fcmToken) {
        console.log(`User ${recipientId} has no FCM token. Skipping push.`);
        return;
      }

      // Get accumulated message count for this conversation
      const latestNotification = await notificationRef.get();
      const messageCount =
        (latestNotification.data()?.messageCount as number) || 1;
      const pushBody = messageCount > 1 ?
        `${messageCount} novas mensagens` :
        displayMessage;

      const payload = {
        token: fcmToken,
        notification: {
          title: senderName,
          body: pushBody,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          conversation_id: conversationId,
          sender_id: senderId,
          type: "chat_message",
          message_count: String(messageCount),
        },
        android: {
          notification: {
            tag: `chat_${conversationId}`,
            channelId: "high_importance_channel",
          },
          collapseKey: `chat_${conversationId}`,
        },
        apns: {
          headers: {
            "apns-collapse-id": `chat_${conversationId}`,
          },
          payload: {
            aps: {
              "thread-id": conversationId,
            },
          },
        },
      };

      await admin.messaging().send(payload);
      console.log(`🚀 Push sent to ${recipientId} (${messageCount} msgs)`);

      // 5. Update cooldown timestamp + reset message count
      await cooldownRef.set({
        lastPushAt: admin.firestore.Timestamp.now(),
      });

      // Reset message count after push is sent
      await notificationRef.update({messageCount: 1});
    } catch (error) {
      console.error("Error processing onMessageCreated:", error);
    }
  }
);
