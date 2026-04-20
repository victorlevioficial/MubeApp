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

import {
  buildUtcDayKey,
  isDailyLimitExceeded,
  REPORT_DAILY_LIMIT,
  startOfUtcDay,
} from "./rate_limits";

const db = admin.firestore();

const REPORT_THRESHOLD_SUSPENSION = 3;
const SUSPENSION_DURATION_DAYS = 7;
const SUSPENSION_ESCALATION_MULTIPLIER = 2;
const VALID_REPORTED_ITEM_TYPES = ["user", "message", "post", "band"];
const DUPLICATE_GUARD_STATUSES = ["pending", "processing", "processed"];

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
    const reporterUserId = getStringField(reportData, "reporter_user_id");
    const now = Timestamp.now();

    console.log("Processando denúncia", {
      type: reportedItemType,
      targetId: reportedItemId,
    });

    try {
      if (!isValidReport(reportData)) {
        console.log(`Denúncia ${reportId} inválida, ignorando`);
        await snapshot.ref.update({
          status: "invalid",
          invalid_reason: "invalid_payload",
          processed_at: now,
        });
        return;
      }

      if (!(await isReportTargetAllowed(reportData))) {
        console.log(`Denúncia ${reportId} sem permissão/alvo válido`);
        await snapshot.ref.update({
          status: "invalid",
          invalid_reason: "target_not_allowed",
          processed_at: now,
        });
        return;
      }

      const duplicateReportId = await findPriorReportId(reportData, reportId);
      if (duplicateReportId != null) {
        console.log(`Denúncia ${reportId} duplicada de ${duplicateReportId}`);
        await snapshot.ref.update({
          status: "duplicate",
          duplicate_of_report_id: duplicateReportId,
          processed_at: now,
        });
        return;
      }

      if (reporterUserId != null) {
        const dailyReportCount = await getReporterDailyReportCount(
          reporterUserId,
          now
        );
        if (shouldRateLimitReportCount(dailyReportCount)) {
          await snapshot.ref.update({
            status: "rate_limited",
            processed_at: now,
            rate_limit_count: dailyReportCount,
            rate_limit_day_key: buildUtcDayKey(now.toDate()),
          });
          return;
        }
      }

      await snapshot.ref.update({
        status: "processing",
        processing_started_at: now,
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
        processed_at: now,
      });
    } catch (error) {
      console.error(`Erro ao processar denúncia ${reportId}:`, error);

      await snapshot.ref.update({
        status: "error",
        error_message: error instanceof Error ?
          error.message :
          "Erro desconhecido",
        processed_at: now,
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
export function isValidReport(data: ReportData): boolean {
  const reportedItemId = getStringField(data, "reported_item_id");
  const reportedItemType = getStringField(data, "reported_item_type");
  const reporterUserId = getStringField(data, "reporter_user_id");
  const reason = getStringField(data, "reason");
  const normalizedReason = typeof reason === "string" ? reason.trim() : "";

  if (!reportedItemId || !reportedItemType || !reporterUserId || !reason) {
    return false;
  }

  if (!VALID_REPORTED_ITEM_TYPES.includes(reportedItemType)) {
    return false;
  }

  if (normalizedReason.length < 3 || normalizedReason.length > 1000) {
    return false;
  }

  if (reportedItemType == "message" && !getConversationId(data)) {
    return false;
  }

  return reportedItemId !== reporterUserId;
}

export function shouldRateLimitReportCount(count: number): boolean {
  return isDailyLimitExceeded(count, REPORT_DAILY_LIMIT);
}

async function isReportTargetAllowed(reportData: ReportData): Promise<boolean> {
  const reportedItemType = getStringField(reportData, "reported_item_type");

  switch (reportedItemType) {
  case "user":
    return canReportUser(reportData);
  case "message":
    return canReportMessage(reportData);
  case "post":
    return canReportPost(reportData);
  case "band":
    return canReportBand(reportData);
  default:
    return false;
  }
}

async function canReportUser(reportData: ReportData): Promise<boolean> {
  const reporterUserId = getStringField(reportData, "reporter_user_id");
  const reportedUserId = getStringField(reportData, "reported_item_id");
  if (!reporterUserId || !reportedUserId || reporterUserId === reportedUserId) {
    return false;
  }

  const reportedUserDoc = await db.collection("users").doc(reportedUserId).get();
  return reportedUserDoc.exists;
}

async function canReportMessage(reportData: ReportData): Promise<boolean> {
  const reporterUserId = getStringField(reportData, "reporter_user_id");
  const messageId = getStringField(reportData, "reported_item_id");
  const conversationId = getConversationId(reportData);
  if (!reporterUserId || !messageId || !conversationId) return false;

  const conversationRef = db.collection("conversations").doc(conversationId);
  const messageRef = conversationRef.collection("messages").doc(messageId);
  const [conversationDoc, messageDoc] = await Promise.all([
    conversationRef.get(),
    messageRef.get(),
  ]);

  if (!conversationDoc.exists || !messageDoc.exists) return false;

  const participants = readStringArray(conversationDoc.data()?.participants);
  if (!participants.includes(reporterUserId)) return false;

  const messageData = messageDoc.data() || {};
  return getStringField(messageData, "senderId") !== reporterUserId;
}

async function canReportPost(reportData: ReportData): Promise<boolean> {
  const reporterUserId = getStringField(reportData, "reporter_user_id");
  const postId = getStringField(reportData, "reported_item_id");
  if (!reporterUserId || !postId) return false;

  const postDoc = await db.collection("posts").doc(postId).get();
  if (!postDoc.exists) return false;

  const postData = postDoc.data() || {};
  return getStringField(postData, "author_id") !== reporterUserId;
}

async function canReportBand(reportData: ReportData): Promise<boolean> {
  const reporterUserId = getStringField(reportData, "reporter_user_id");
  const bandId = getStringField(reportData, "reported_item_id");
  if (!reporterUserId || !bandId || reporterUserId === bandId) return false;

  const [userBandDoc, legacyBandDoc] = await Promise.all([
    db.collection("users").doc(bandId).get(),
    db.collection("bands").doc(bandId).get(),
  ]);

  return userBandDoc.exists || legacyBandDoc.exists;
}

async function findPriorReportId(
  reportData: ReportData,
  reportId: string
): Promise<string | null> {
  const reporterUserId = getStringField(reportData, "reporter_user_id");
  const reportedItemType = getStringField(reportData, "reported_item_type");
  const reportedItemId = getStringField(reportData, "reported_item_id");
  if (!reporterUserId || !reportedItemType || !reportedItemId) return null;

  const currentConversationId = getConversationId(reportData);
  const snapshot = await db
    .collection("reports")
    .where("reporter_user_id", "==", reporterUserId)
    .where("reported_item_type", "==", reportedItemType)
    .where("reported_item_id", "==", reportedItemId)
    .limit(10)
    .get();

  for (const doc of snapshot.docs) {
    if (doc.id === reportId) continue;

    const data = doc.data() as ReportData;
    const status = getStringField(data, "status") || "pending";
    if (!DUPLICATE_GUARD_STATUSES.includes(status)) continue;

    if (
      reportedItemType === "message" &&
      getConversationId(data) !== currentConversationId
    ) {
      continue;
    }

    return doc.id;
  }

  return null;
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
  const reporterUserId = getStringField(reportData, "reporter_user_id");
  if (!messageId || !conversationId) return;

  const messageRef = db
    .collection("conversations")
    .doc(conversationId)
    .collection("messages")
    .doc(messageId);

  await db.runTransaction(async (transaction) => {
    const messageDoc = await transaction.get(messageRef);
    if (!messageDoc.exists) return;

    const msgData = messageDoc.data() || {};
    if (getStringField(msgData, "senderId") === reporterUserId) return;

    const nextReportCount = getNumberField(msgData, "report_count") + 1;
    const updateData: Record<string, unknown> = {
      reported: true,
      report_count: FieldValue.increment(1),
      updated_at: Timestamp.now(),
    };

    if (nextReportCount >= REPORT_THRESHOLD_SUSPENSION) {
      updateData.hidden = true;
      updateData.hidden_reason = "multiple_reports";
    }

    transaction.update(messageRef, updateData);
  });
}

/**
 * Processa denúncia de post.
 *
 * @param {Object} reportData - Documento da denúncia
 * @return {Promise<void>} conclusão
 */
async function handlePostReport(reportData: ReportData): Promise<void> {
  const postId = getStringField(reportData, "reported_item_id");
  const reporterUserId = getStringField(reportData, "reporter_user_id");
  if (!postId) return;

  const postRef = db.collection("posts").doc(postId);
  await db.runTransaction(async (transaction) => {
    const postDoc = await transaction.get(postRef);
    if (!postDoc.exists) return;

    const postData = postDoc.data() || {};
    if (getStringField(postData, "author_id") === reporterUserId) return;

    const nextReportCount = getNumberField(postData, "report_count") + 1;
    const updateData: Record<string, unknown> = {
      reported: true,
      report_count: FieldValue.increment(1),
      updated_at: Timestamp.now(),
    };

    if (nextReportCount >= REPORT_THRESHOLD_SUSPENSION) {
      updateData.status = "hidden";
      updateData.hidden_reason = "multiple_reports";
    }

    transaction.update(postRef, updateData);
  });
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

function getNumberField(data: ReportData, key: string): number {
  const value = data[key];
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function readStringArray(value: unknown): string[] {
  return Array.isArray(value) ?
    value.filter((item): item is string => typeof item === "string") :
    [];
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

async function getReporterDailyReportCount(
  reporterUserId: string,
  now: Timestamp
): Promise<number> {
  const dayStart = Timestamp.fromDate(startOfUtcDay(now.toDate()));
  const countSnapshot = await db
    .collection("reports")
    .where("reporter_user_id", "==", reporterUserId)
    .where("created_at", ">=", dayStart)
    .count()
    .get();

  return countSnapshot.data().count || 0;
}
