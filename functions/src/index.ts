import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

admin.initializeApp();

// Export geohash migration functions (lowercase for v2 naming convention)
export {migrategeohashes, updateusergeohash} from "./geohash_migration";

/**
 * Trigger: When a new message is created in a conversation.
 * Path: conversations/{conversationId}/messages/{messageId}
 *
 * Actions:
 * 1. Update conversation metadata (last_message, last_message_at, updated_at).
 * 2. Increment unread_count for the recipient.
 * 3. Send Push Notification to the recipient.
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
    const displayMessage = text || "📷 Sent an image";

    const db = admin.firestore();
    const conversationRef = db.collection("conversations").doc(conversationId);

    try {
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
        const freshConvDoc = await transaction.get(conversationRef);
        const freshData = freshConvDoc.data();
        const currentUnread = freshData?.unread_counts?.[recipientId] || 0;

        transaction.update(conversationRef, {
          last_message: displayMessage,
          last_message_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
          [`unread_counts.${recipientId}`]: currentUnread + 1,
        });
      });

      console.log(`✅ Conversation updated for message ${snapshot.id}`);

      const userDoc = await db.collection("users").doc(recipientId).get();
      const userData = userDoc.data();
      const fcmToken = userData?.fcm_token;

      if (!fcmToken) {
        console.log(`User ${recipientId} has no FCM token. Skipping push.`);
        return;
      }

      const payload = {
        token: fcmToken,
        notification: {
          title: messageData.sender_name || "New Message",
          body: displayMessage,
        },
        data: {
          click_action: "FLUTTER_NOTIFICATION_CLICK",
          conversation_id: conversationId,
          type: "chat_message",
        },
      };

      await admin.messaging().send(payload);
      console.log(`🚀 Push sent to ${recipientId}`);

      // Persist notification to Firestore for history
      await db
        .collection("users")
        .doc(recipientId)
        .collection("notifications")
        .add({
          type: "chat_message",
          title: messageData.sender_name || "Nova mensagem",
          body: displayMessage,
          conversationId: conversationId,
          senderId: senderId,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      console.log(`📝 Notification persisted for ${recipientId}`);
    } catch (error) {
      console.error("Error processing onMessageCreated:", error);
    }
  }
);
