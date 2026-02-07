/**
 * Cloud Functions para Moderação.
 *
 * Funcionalidades:
 * - onReportCreated: Processa denúncias e aplica suspensões
 * - liftSuspensions: Remove suspensões expiradas
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import {FieldValue, Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();

const REPORT_THRESHOLD_SUSPENSION = 3;
const SUSPENSION_DURATION_DAYS = 7;
const SUSPENSION_ESCALATION_MULTIPLIER = 2;

type ReportData = Record<string, unknown>;

/**
 * Trigger: onReportCreated.
 */
export const onReportCreated = onDocumentCreated(
  {
    document: "reports/{reportId}",
    region: "southamerica-east1",
    memory: "256MiB",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const reportData = snapshot.data() as ReportData;
    const reportId = event.params.reportId as string;
    const reportedItemType = getStringField(reportData, "reported_item_type");
    const reportedItemId = getStringField(reportData, "reported_item_id");

    console.log("Processando denúncia", {
      type: reportedItemType,
      targetId: reportedItemId,
    });

    try {
      if (!isValidReport(reportData)) {
        console.log(`Denúncia ${reportId} inválida, ignorando`);
        await snapshot.ref.update({
          status: "invalid",
          processed_at: Timestamp.now(),
        });
        return;
      }

      await snapshot.ref.update({
        status: "processing",
        processing_started_at: Timestamp.now(),
      });

      switch (reportedItemType) {
      case "user":
        await handleUserReport(reportData, reportId);
        break;
      case "message":
        await handleMessageReport(reportData);
        break;
      case "post":
        await handlePostReport(reportData);
        break;
      case "band":
        await handleBandReport(reportData);
        break;
      default:
        console.log(
          `Tipo de denúncia desconhecido: ${reportedItemType || ""}`
        );
      }

      await snapshot.ref.update({
        status: "processed",
        processed_at: Timestamp.now(),
      });
    } catch (error) {
      console.error(`Erro ao processar denúncia ${reportId}:`, error);

      await snapshot.ref.update({
        status: "error",
        error_message: error instanceof Error ?
          error.message :
          "Erro desconhecido",
        processed_at: Timestamp.now(),
      });
    }
  }
);

/**
 * Valida se a denúncia tem dados mínimos necessários.
 *
 * @param {Object} data - Documento da denúncia
 * @return {boolean} resultado da validação
 */
function isValidReport(data: ReportData): boolean {
  const reportedItemId = getStringField(data, "reported_item_id");
  const reportedItemType = getStringField(data, "reported_item_type");
  const reporterUserId = getStringField(data, "reporter_user_id");
  const reason = getStringField(data, "reason");

  if (!reportedItemId || !reportedItemType || !reporterUserId || !reason) {
    return false;
  }

  return reportedItemId !== reporterUserId;
}

/**
 * Processa denúncia de usuário.
 *
 * @param {Object} reportData - Documento da denúncia
 * @param {string} reportId - ID da denúncia
 * @return {Promise<void>} conclusão
 */
async function handleUserReport(
  reportData: ReportData,
  reportId: string
): Promise<void> {
  const reportedUserId = getStringField(reportData, "reported_item_id");
  if (!reportedUserId) return;

  const now = Timestamp.now();

  await db.runTransaction(async (transaction) => {
    const userRef = db.collection("users").doc(reportedUserId);
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) return;

    const moderationRef = db.collection("userModerations").doc(reportedUserId);
    const moderationDoc = await transaction.get(moderationRef);

    let reportCount = 1;
    let suspensionCount = 0;

    if (moderationDoc.exists) {
      const moderationData = moderationDoc.data() || {};
      reportCount = (moderationData.report_count || 0) + 1;
      suspensionCount = moderationData.suspension_count || 0;
    }

    transaction.update(userRef, {
      report_count: FieldValue.increment(1),
      updated_at: now,
    });

    const shouldSuspend = reportCount >=
      REPORT_THRESHOLD_SUSPENSION * (suspensionCount + 1);

    if (shouldSuspend) {
      const durationDays = SUSPENSION_DURATION_DAYS *
        Math.pow(SUSPENSION_ESCALATION_MULTIPLIER, suspensionCount);
      const suspendedUntil = Timestamp.fromDate(
        new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000)
      );

      const suspensionRef = db.collection("suspensions").doc();
      transaction.set(suspensionRef, {
        user_id: reportedUserId,
        reason: getStringField(reportData, "reason") || "indefinido",
        report_ids: [reportId],
        created_at: now,
        suspended_until: suspendedUntil,
        lifted_at: null,
        lifted_by: null,
        status: "active",
      });

      transaction.update(userRef, {
        status: "suspended",
        suspended_until: suspendedUntil,
        updated_at: now,
      });

      transaction.set(
        moderationRef,
        {
          user_id: reportedUserId,
          report_count: reportCount,
          suspension_count: suspensionCount + 1,
          last_report_at: now,
          last_suspension_at: now,
          updated_at: now,
        },
        {merge: true}
      );

      console.log(
        `Usuário ${reportedUserId} suspenso por ${durationDays} dias`
      );
      return;
    }

    transaction.set(
      moderationRef,
      {
        user_id: reportedUserId,
        report_count: reportCount,
        suspension_count: suspensionCount,
        last_report_at: now,
        updated_at: now,
      },
      {merge: true}
    );
  });
}

/**
 * Processa denúncia de mensagem.
 *
 * @param {Object} reportData - Documento da denúncia
 * @return {Promise<void>} conclusão
 */
async function handleMessageReport(reportData: ReportData): Promise<void> {
  const messageId = getStringField(reportData, "reported_item_id");
  const conversationId = getConversationId(reportData);
  if (!messageId || !conversationId) return;

  const messageRef = db
    .collection("conversations")
    .doc(conversationId)
    .collection("messages")
    .doc(messageId);

  await messageRef.update({
    reported: true,
    report_count: FieldValue.increment(1),
    updated_at: Timestamp.now(),
  });

  const messageDoc = await messageRef.get();
  if (!messageDoc.exists) return;

  const msgData = messageDoc.data() || {};
  if ((msgData.report_count || 0) >= REPORT_THRESHOLD_SUSPENSION) {
    await messageRef.update({
      hidden: true,
      hidden_reason: "multiple_reports",
      updated_at: Timestamp.now(),
    });
  }
}

/**
 * Processa denúncia de post.
 *
 * @param {Object} reportData - Documento da denúncia
 * @return {Promise<void>} conclusão
 */
async function handlePostReport(reportData: ReportData): Promise<void> {
  const postId = getStringField(reportData, "reported_item_id");
  if (!postId) return;

  const postRef = db.collection("posts").doc(postId);
  await postRef.update({
    reported: true,
    report_count: FieldValue.increment(1),
    updated_at: Timestamp.now(),
  });

  const postDoc = await postRef.get();
  if (!postDoc.exists) return;

  const postData = postDoc.data() || {};
  if ((postData.report_count || 0) >= REPORT_THRESHOLD_SUSPENSION) {
    await postRef.update({
      status: "hidden",
      hidden_reason: "multiple_reports",
      updated_at: Timestamp.now(),
    });
  }
}

/**
 * Processa denúncia de banda.
 *
 * @param {Object} reportData - Documento da denúncia
 * @return {Promise<void>} conclusão
 */
async function handleBandReport(reportData: ReportData): Promise<void> {
  const bandId = getStringField(reportData, "reported_item_id");
  if (!bandId) return;

  const now = Timestamp.now();

  const bandRef = db.collection("users").doc(bandId);
  const bandDoc = await bandRef.get();

  if (bandDoc.exists) {
    await bandRef.update({
      report_count: FieldValue.increment(1),
      updated_at: now,
    });
    return;
  }

  const legacyBandRef = db.collection("bands").doc(bandId);
  const legacyBandDoc = await legacyBandRef.get();
  if (!legacyBandDoc.exists) return;

  await legacyBandRef.update({
    report_count: FieldValue.increment(1),
    updated_at: now,
  });

  console.log(
    `Banda ${bandId} denunciada, notificação enviada para moderadores`
  );
}

/**
 * Scheduled Function: liftSuspensions.
 */
export const liftSuspensions = onSchedule(
  {
    schedule: "0 0 * * *",
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 300,
  },
  async () => {
    const now = Timestamp.now();
    console.log("Iniciando liftSuspensions:", now.toDate());

    try {
      const expiredSuspensions = await db
        .collection("suspensions")
        .where("status", "==", "active")
        .where("suspended_until", "<=", now)
        .limit(500)
        .get();

      console.log(
        `Encontradas ${expiredSuspensions.size} suspensões expiradas`
      );

      let liftedCount = 0;
      let batch = db.batch();
      let batchSize = 0;

      for (const doc of expiredSuspensions.docs) {
        const suspension = doc.data() || {};
        const userId = suspension.user_id as string;

        batch.update(doc.ref, {
          status: "lifted",
          lifted_at: now,
          lifted_by: "system",
          updated_at: now,
        });

        const userRef = db.collection("users").doc(userId);
        batch.update(userRef, {
          status: "active",
          suspended_until: null,
          updated_at: now,
        });

        batchSize += 2;
        liftedCount++;

        if (batchSize >= 500) {
          await batch.commit();
          console.log(`Processados ${liftedCount} usuários`);
          batch = db.batch();
          batchSize = 0;
        }
      }

      if (batchSize > 0) {
        await batch.commit();
      }

      console.log(
        `liftSuspensions concluído: ${liftedCount} suspensões removidas`
      );
    } catch (error) {
      console.error("Erro em liftSuspensions:", error);
      throw error;
    }
  }
);

/**
 * Extrai campo string do objeto.
 *
 * @param {Object} data - Origem
 * @param {string} key - Nome do campo
 * @return {string|null} Valor do campo
 */
function getStringField(data: ReportData, key: string): string | null {
  const value = data[key];
  return typeof value === "string" ? value : null;
}

/**
 * Obtém conversation_id a partir do contexto da denúncia.
 *
 * @param {Object} reportData - Documento da denúncia
 * @return {string|null} conversationId
 */
function getConversationId(reportData: ReportData): string | null {
  const context = reportData.context;
  if (!context || typeof context !== "object") return null;

  const contextRecord = context as Record<string, unknown>;
  const conversationId = contextRecord.conversation_id;
  return typeof conversationId === "string" ? conversationId : null;
}
