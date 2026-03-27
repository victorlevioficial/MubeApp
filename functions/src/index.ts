import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

import {logChatSafetyEvent} from "./chat_safety";

admin.initializeApp();

// Export geohash and interactions migration functions
export {migrategeohashes, updateusergeohash} from "./geohash_migration";
export {migrateinteractions} from "./interaction_migration";

// Export Matchpoint functions
export {
  submitMatchpointAction,
  recordMatchpointRankingAudit,
  getRemainingLikes,
  onMatchCreated,
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
export {
  logChatPreSendWarning,
} from "./chat_safety";

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
  submitSupportTicket,
  onTicketCreated,
} from "./support";

// Export Admin panel functions
export {
  setAdminClaim,
  setFeaturedProfiles,
  getFeaturedProfiles,
  getDashboardOverview,
  getUserAdminDetail,
  lookupUser,
  searchUsers,
  listUsersAdmin,
  listReports,
  updateReportStatus,
  listSuspensions,
  manageSuspension,
  listTickets,
  updateTicket,
  getDashboardStats,
  getMatchpointRankingAuditDashboard,
  listConversationsAdmin,
  listConversations,
  getConversationMessages,
  getConversationAdminDetail,
  listGigsAdmin,
  getGigAdminDetail,
  getMatchpointAdminOverview,
  getSystemAdminData,
  inspectFirestorePath,
  inspectStoragePrefix,
} from "./admin";

// Export Favorites functions
export {
  onFavoriteCreated,
  onFavoriteDeleted,
} from "./favorites";

// Export Users functions
export {
  deleteAccount,
  setPublicUsername,
  syncContractorDisplayName,
  backfillContractorDisplayNames,
} from "./users";

// Export Gigs functions
export {
  onGigCreated,
  onGigUpdated,
  onGigDeleted,
  onGigApplicationCreated,
  onGigApplicationUpdated,
  onGigApplicationDeleted,
  expireFixedDateGigs,
} from "./gigs";

// Export Video transcode functions
export {
  onGalleryVideoUploaded,
  backfillGalleryVideoTranscodes,
} from "./video_transcode";

/**
 * Push notification throttle cooldown in milliseconds.
 * Messages within this window from the same sender won't trigger
 * a new push notification — following WhatsApp/Telegram market pattern.
 */
const PUSH_COOLDOWN_MS = 30_000; // 30 seconds
const NAME_CONNECTORS = new Set(["de", "da", "do", "dos", "das", "e"]);

/**
 * Returns the first non-empty string from the provided values.
 *
 * @param {unknown[]} values Candidate values.
 * @param {string=} fallback Fallback when no value is valid.
 * @return {string} First valid trimmed string.
 */
function firstNonEmptyString(values: unknown[], fallback = ""): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }
  return fallback;
}

/**
 * Builds a short display name from a full personal name.
 *
 * @param {string} fullName Full name.
 * @return {string} Short display name.
 */
function shortenPersonName(fullName: string): string {
  const normalized = fullName.trim().replace(/\s+/g, " ");
  if (!normalized) return "";

  const parts = normalized.split(" ");
  if (parts.length <= 2) return normalized;

  const secondWord = parts[1].toLowerCase();
  const takeCount = NAME_CONNECTORS.has(secondWord) ? 3 : 2;
  return parts.slice(0, takeCount).join(" ");
}

/**
 * Casts unknown values to safe object maps.
 *
 * @param {unknown} value Raw unknown value.
 * @return {Record<string, unknown>} Safe object map.
 */
function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value) ? value as Record<string, unknown> : {};
}

/**
 * Resolves sender display name for chat notifications.
 *
 * Rule:
 * - Professional: nome artistico
 * - Band: nome da banda
 * - Studio: nome do estudio
 * - Contractor: nome de exibicao curto
 *
 * @param {Record<string, unknown>} userData Sender user document.
 * @return {string} Name used in notification title.
 */
function resolveSenderDisplayName(userData: Record<string, unknown>): string {
  const tipoPerfil = firstNonEmptyString(
    [userData.tipo_perfil, userData.tipoPerfil]
  );
  const profissional = asRecord(userData.profissional);
  const banda = asRecord(userData.banda);
  const estudio = asRecord(userData.estudio);
  const contratante = asRecord(userData.contratante);

  switch (tipoPerfil) {
  case "profissional":
    return firstNonEmptyString([
      profissional.nomeArtistico,
      userData.nome_artistico,
    ], "Nova mensagem");
  case "banda":
    return firstNonEmptyString([
      banda.nomeBanda,
      banda.nomeArtistico,
      banda.nome,
    ], "Banda");
  case "estudio":
    return firstNonEmptyString([
      estudio.nomeEstudio,
      estudio.nomeArtistico,
      estudio.nome,
    ], "Estudio");
  case "contratante":
    return firstNonEmptyString([
      contratante.nomeExibicao,
      shortenPersonName(firstNonEmptyString([userData.nome])),
      userData.nome,
    ], "Contratante");
  default:
    return firstNonEmptyString([
      profissional.nomeArtistico,
      banda.nomeBanda,
      banda.nomeArtistico,
      estudio.nomeEstudio,
      estudio.nomeArtistico,
      userData.nome_artistico,
    ], "Nova mensagem");
  }
}

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
      try {
        await logChatSafetyEvent({
          userId: senderId,
          conversationId,
          messageId: snapshot.id,
          text: typeof text === "string" ? text : "",
          source: "post_send_detected",
          platform: "server",
        });
      } catch (safetyError) {
        console.error("Error logging chat safety event:", safetyError);
      }

      // 1. Update conversation metadata
      const conversationDoc = await conversationRef.get();
      if (!conversationDoc.exists) {
        console.error(`Conversation ${conversationId} does not exist.`);
        return;
      }

      const conversationData = conversationDoc.data();
      const participants: string[] = conversationData?.participants || [];
      const conversationType = typeof conversationData?.type === "string" &&
          conversationData.type.trim().length > 0 ?
        conversationData.type.trim() :
        "direct";

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

      // Busca o nome do remetente diretamente do Firestore
      // para garantir que a notificação sempre exiba o nome correto.
      const senderDoc = await db.collection("users").doc(senderId).get();
      const senderData = senderDoc.data() || {};
      const senderName =
        (typeof messageData.sender_name === "string" &&
          messageData.sender_name.trim().length > 0) ?
          messageData.sender_name.trim() :
          resolveSenderDisplayName(senderData);
      const senderPhoto =
        typeof messageData.sender_photo === "string" &&
          messageData.sender_photo.trim().length > 0 ?
          messageData.sender_photo.trim() :
          (typeof senderData.foto === "string" ? senderData.foto : "");

      if (existingNotification.exists) {
        const existingData = existingNotification.data() || {};
        const currentCount = (existingData.messageCount as number) || 1;
        const newCount = currentCount + 1;

        await notificationRef.update({
          title: senderName,
          body: `${newCount} novas mensagens`,
          messageCount: newCount,
          lastMessageText: displayMessage,
          senderPhoto: senderPhoto || null,
          conversationType,
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
          senderPhoto: senderPhoto || null,
          conversationType,
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
          sender_name: senderName,
          sender_photo: senderPhoto,
          conversation_type: conversationType,
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
