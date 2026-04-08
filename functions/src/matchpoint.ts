/**
 * Cloud Functions para o feature Matchpoint.
 *
 * Funcionalidades:
 * - submitMatchpointAction: Processa ações de like/dislike
 * - Criação de match e reserva do conversationId do chat
 * - onInteractionCreated: Atualiza estatísticas
 * - getRemainingLikes: Retorna quota diária
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";

const db = admin.firestore();

const DAILY_SWIPE_LIMIT = 50;
const INTERACTION_EXPIRY_DAYS = 30;
const MATCH_NOTIFICATION_TYPE = "system";
const MATCH_NOTIFICATION_ROUTE_PREFIX = "/conversation/";
const MATCHPOINT_COMMANDS_COLLECTION = "matchpointCommands";

type MatchpointSwipeAction = "like" | "dislike";
type MatchpointCommandStatus = "pending" | "processing" | "completed" | "failed";

/**
 * Estrutura do request para submitMatchpointAction.
 */
interface MatchpointActionRequest {
  targetUserId: string;
  action: MatchpointSwipeAction;
}

/**
 * Estrutura da resposta de submitMatchpointAction.
 */
interface MatchpointActionResponse {
  success: boolean;
  isMatch?: boolean;
  matchId?: string;
  conversationId?: string;
  remainingLikes?: number;
  message?: string;
}

interface MatchpointCommandRequest {
  userId: string;
  targetUserId: string;
  action: MatchpointSwipeAction;
  idempotencyKey: string;
}

interface MatchpointCommandError {
  code: string;
  message: string;
}

interface RemainingLikesResponse {
  remaining: number;
  limit: number;
  resetTime: string;
}

interface RankingAuditRequest {
  poolTotal: number;
  returnedTotal: number;
  poolProximity: number;
  poolHashtag: number;
  poolGenre: number;
  poolFallback: number;
  poolLocalTotal: number;
  poolLocalHashtag: number;
  poolLocalGenre: number;
  returnedProximity: number;
  returnedHashtag: number;
  returnedGenre: number;
  returnedFallback: number;
  returnedLocalTotal: number;
  returnedLocalHashtag: number;
  returnedLocalGenre: number;
  queryGenres: number;
  queryHashtags: number;
  usedGeohash: boolean;
}

interface RankingAuditResponse {
  success: boolean;
  bucketId: string;
}

interface NotificationInput {
  userId: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  senderId?: string;
  conversationId?: string;
  route?: string;
  data?: Record<string, string>;
}

interface MatchNotificationInput {
  senderUserId: string;
  recipientUserId: string;
  conversationId: string;
}

/**
 * Valida e normaliza o payload do callable de swipe.
 *
 * Evita TypeError em payload nulo/inesperado e garante mensagens explícitas
 * para o cliente.
 *
 * @param {unknown} rawData - Payload bruto recebido do callable.
 * @return {MatchpointActionRequest} Payload validado e normalizado.
 */
function readMatchpointActionRequest(
  rawData: unknown
): MatchpointActionRequest {
  const payload = asRecord(rawData);
  const targetUserId = firstNonEmptyString([payload.targetUserId]);
  const rawAction = readMatchpointSwipeAction(payload.action);

  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "targetUserId é obrigatório");
  }

  return {
    targetUserId,
    action: rawAction,
  };
}

export function readMatchpointSwipeAction(
  value: unknown
): MatchpointSwipeAction {
  const rawAction = firstNonEmptyString([value]).toLowerCase();
  if (rawAction !== "like" && rawAction !== "dislike") {
    throw new HttpsError(
      "invalid-argument",
      "action deve ser 'like' ou 'dislike'"
    );
  }

  return rawAction;
}

export function readMatchpointCommandRequest(
  rawData: unknown,
  commandId: string
): MatchpointCommandRequest {
  const payload = asRecord(rawData);
  const userId = firstNonEmptyString([payload.user_id, payload.userId]);
  const targetUserId = firstNonEmptyString([
    payload.target_user_id,
    payload.targetUserId,
  ]);
  const idempotencyKey = firstNonEmptyString([
    payload.idempotency_key,
    payload.idempotencyKey,
  ], commandId);

  if (!userId) {
    throw new HttpsError("invalid-argument", "user_id é obrigatório");
  }

  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "target_user_id é obrigatório");
  }

  if (userId === targetUserId) {
    throw new HttpsError(
      "invalid-argument",
      "Não pode interagir consigo mesmo"
    );
  }

  return {
    userId,
    targetUserId,
    action: readMatchpointSwipeAction(payload.action),
    idempotencyKey,
  };
}

export function buildMatchpointCommandResult(
  request: MatchpointCommandRequest,
  response: MatchpointActionResponse
): Record<string, unknown> {
  return {
    targetUserId: request.targetUserId,
    action: request.action,
    isMatch: response.isMatch === true,
    matchId: response.matchId ?? null,
    conversationId: response.conversationId ?? null,
    remainingLikes: response.remainingLikes ?? null,
    message: response.message ?? null,
  };
}

function buildMatchpointCommandError(error: unknown): MatchpointCommandError {
  if (error instanceof HttpsError) {
    return {
      code: error.code,
      message: error.message || "Erro ao processar comando do MatchPoint.",
    };
  }

  return {
    code: "internal",
    message: "Erro interno ao processar comando do MatchPoint.",
  };
}

/**
 * Retorna o primeiro texto não vazio de uma lista.
 *
 * @param {unknown[]} values - Valores candidatos.
 * @param {string=} fallback - Valor padrão quando nada é válido.
 * @return {string} Primeiro texto válido encontrado.
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
 * Converte um valor arbitrário em objeto indexável.
 *
 * @param {unknown} value - Valor recebido do Firestore.
 * @return {Record<string, unknown>} Objeto seguro para leitura.
 */
function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
      typeof value === "object" &&
      !Array.isArray(value) ? value as Record<string, unknown> : {};
}

/**
 * Resolve nome de exibição para notificações de match.
 *
 * @param {Record<string, unknown>} userData - Documento do usuário.
 * @return {string} Nome amigável para título da notificação.
 */
function resolveMatchSenderName(userData: Record<string, unknown>): string {
  const professionalProfile = asRecord(userData.profissional);
  const bandProfile = asRecord(userData.banda);
  const studioProfile = asRecord(userData.estudio);
  const contractorProfile = asRecord(userData.contratante);

  return firstNonEmptyString([
    professionalProfile.nomeArtistico,
    bandProfile.nomeBanda,
    bandProfile.nomeArtistico,
    studioProfile.nomeEstudio,
    studioProfile.nomeArtistico,
    contractorProfile.nomeExibicao,
    userData.nome_artistico,
    userData.nome,
  ], "Novo match");
}

/**
 * Normaliza o tipo salvo em um documento de interação.
 *
 * @param {DocumentData|undefined} data - Dados brutos do documento.
 * @return {string} Tipo normalizado ou string vazia.
 */
function readInteractionType(data: DocumentData | undefined): string {
  return typeof data?.type === "string" ? data.type : "";
}

/**
 * Resolve o conversationId persistido em documentos de match legados/atuais.
 *
 * @param {DocumentData|undefined} matchData - Dados do match.
 * @param {string} fallback - conversationId determinístico padrão.
 * @return {string} conversationId utilizável.
 */
function resolveMatchConversationId(
  matchData: DocumentData | undefined,
  fallback: string
): string {
  return firstNonEmptyString([
    matchData?.conversation_id,
    matchData?.conversationId,
  ], fallback);
}

/**
 * Cria/atualiza uma notificação no Firestore do usuário.
 *
 * @param {NotificationInput} input - Dados da notificação.
 * @return {Promise<void>} Promise concluída após persistência.
 */
async function upsertUserNotification(input: NotificationInput): Promise<void> {
  const {
    userId,
    notificationId,
    type,
    title,
    body,
    senderId,
    conversationId,
    route,
    data,
  } = input;

  await db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .doc(notificationId)
    .set({
      type,
      title,
      body,
      senderId: senderId ?? null,
      conversationId: conversationId ?? null,
      route: route ?? null,
      ...data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
}

/**
 * Envia push notification best-effort para o usuário.
 *
 * @param {NotificationInput} input - Dados da notificação.
 * @return {Promise<void>} Promise concluída após tentativa de envio.
 */
async function sendPushNotification(input: NotificationInput): Promise<void> {
  const userDoc = await db.collection("users").doc(input.userId).get();
  const userData = userDoc.data() || {};
  const fcmToken = userData.fcm_token;

  if (typeof fcmToken !== "string" || fcmToken.trim().length === 0) {
    return;
  }

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: input.title,
      body: input.body,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: input.type,
      route: input.route ?? "",
      sender_id: input.senderId ?? "",
      conversation_id: input.conversationId ?? "",
      ...(input.data ?? {}),
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
}

/**
 * Persiste a notificação e tenta enviar push sem derrubar o fluxo principal.
 *
 * @param {NotificationInput} input - Dados da notificação.
 * @return {Promise<void>} Promise concluída após tentativa.
 */
async function notifyUser(input: NotificationInput): Promise<void> {
  try {
    await upsertUserNotification(input);
    await sendPushNotification(input);
  } catch (error) {
    console.error(`Erro ao notificar usuario ${input.userId}:`, error);
  }
}

/**
 * Notifica o usuário que recebeu match de volta no MatchPoint.
 *
 * @param {MatchNotificationInput} input - Dados do match.
 * @return {Promise<void>} Promise concluída após tentativa.
 */
async function notifyMatchCreated(
  input: MatchNotificationInput
): Promise<void> {
  const {
    senderUserId,
    recipientUserId,
    conversationId,
  } = input;

  try {
    const senderDoc = await db.collection("users").doc(senderUserId).get();
    const senderData = senderDoc.data() || {};
    const senderName = resolveMatchSenderName(senderData);
    const route = `${MATCH_NOTIFICATION_ROUTE_PREFIX}${conversationId}`;

    await notifyUser({
      userId: recipientUserId,
      notificationId: `match_${conversationId}`,
      type: MATCH_NOTIFICATION_TYPE,
      title: "Novo match no MatchPoint",
      body: `${senderName} curtiu você também.`,
      senderId: senderUserId,
      conversationId,
      route,
      data: {
        conversation_id: conversationId,
        conversation_type: "matchpoint",
        sender_name: senderName,
      },
    });
  } catch (error) {
    console.error(
      `Erro ao enviar notificacao de match para ${recipientUserId}:`,
      error
    );
  }
}

/**
 * Núcleo compartilhado de processamento de swipe do MatchPoint.
 *
 * Mantém a regra de negócio central em um único lugar para o callable legado
 * e para o novo pipeline assíncrono por documento em `matchpointCommands`.
 *
 * @param {string} currentUserId - UID do usuário que executou a ação.
 * @param {string} targetUserId - UID do perfil alvo do swipe.
 * @param {MatchpointSwipeAction} action - Ação solicitada pelo usuário.
 * @return {Promise<MatchpointActionResponse>} Resultado autoritativo do swipe.
 */
async function processMatchpointAction(
  currentUserId: string,
  targetUserId: string,
  action: MatchpointSwipeAction
): Promise<MatchpointActionResponse> {
  let stage = "load_current_user";

  try {
    const userRef = db.collection("users").doc(currentUserId);
    const interactionsRef = db.collection("interactions");
    const existingInteractionPromise = interactionsRef
      .where("source_user_id", "==", currentUserId)
      .where("target_user_id", "==", targetUserId)
      .where("type", "in", ["like", "dislike"])
      .limit(1)
      .get();
    const mutualLikePromise = action === "like" ?
      interactionsRef
        .where("source_user_id", "==", targetUserId)
        .where("target_user_id", "==", currentUserId)
        .where("type", "==", "like")
        .limit(1)
        .get() :
      Promise.resolve(null);

    const [userDoc, existingInteractionQuery, mutualLikeQuery] =
      await Promise.all([
        userRef.get(),
        existingInteractionPromise,
        mutualLikePromise,
      ]);

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado");
    }

    const userData = userDoc.data() || {};
    const remainingLikesSnapshot = getRemainingLikesSnapshot(userData);

    const existingInteraction = existingInteractionQuery.empty ?
      null :
      existingInteractionQuery.docs[0];
    const existingData = existingInteraction?.data() || {};
    const existingType = existingData.type as string | undefined;

    let remainingQuota = remainingLikesSnapshot.remainingLikes;

    if (!existingInteraction) {
      stage = "check_rate_limit";
      const rateLimitResult = await checkAndUpdateRateLimit(currentUserId);
      if (!rateLimitResult.allowed) {
        throw new HttpsError(
          "resource-exhausted",
          `Limite diário de ${DAILY_SWIPE_LIMIT} swipes atingido. ` +
          "Tente novamente amanhã."
        );
      }
      remainingQuota = rateLimitResult.remainingLikes;
    }

    if (action === "dislike") {
      const now = Timestamp.now();
      const expiresAt = Timestamp.fromDate(
        new Date(Date.now() + INTERACTION_EXPIRY_DAYS * 24 * 60 * 60 * 1000)
      );

      if (existingInteraction) {
        if (existingType !== "dislike") {
          stage = "persist_dislike_existing";
          await existingInteraction.ref.update({
            type: "dislike",
            updated_at: now,
            expires_at: expiresAt,
            resulted_in_match: FieldValue.delete(),
          });
        }
      } else {
        stage = "persist_dislike_new";
        const interactionRef = db.collection("interactions").doc();
        await interactionRef.set({
          source_user_id: currentUserId,
          target_user_id: targetUserId,
          type: "dislike",
          created_at: now,
          updated_at: now,
          expires_at: expiresAt,
        });
      }

      stage = "remove_match";
      const removedMatch = await removeMatch(currentUserId, targetUserId);

      return {
        success: true,
        remainingLikes: remainingQuota,
        message: removedMatch ? "Match desfeito" : "Dislike registrado",
      };
    }

    const now = Timestamp.now();
    let interactionRef = existingInteraction?.ref;

    if (existingInteraction && existingType === "like") {
      return {
        success: true,
        remainingLikes: remainingQuota,
        message: "Interação já registrada",
      };
    }

    if (existingInteraction) {
      stage = "persist_like_existing";
      await existingInteraction.ref.update({
        type: "like",
        updated_at: now,
        expires_at: FieldValue.delete(),
        resulted_in_match: FieldValue.delete(),
      });
      interactionRef = existingInteraction.ref;
    } else {
      stage = "persist_like_new";
      interactionRef = interactionsRef.doc();
      await interactionRef.set({
        source_user_id: currentUserId,
        target_user_id: targetUserId,
        type: "like",
        created_at: now,
        updated_at: now,
      });
    }

    const isMatch = mutualLikeQuery !== null && !mutualLikeQuery.empty;

    if (!isMatch) {
      return {
        success: true,
        isMatch: false,
        remainingLikes: remainingQuota,
        message: "Like registrado",
      };
    }

    stage = "finalize_match";
    const matchResult = await createMatch(
      currentUserId,
      targetUserId,
      interactionRef,
      mutualLikeQuery.docs[0].ref
    );

    if (matchResult === null) {
      return {
        success: true,
        isMatch: false,
        remainingLikes: remainingQuota,
        message: "Like registrado",
      };
    }

    return {
      success: true,
      isMatch: true,
      matchId: matchResult.matchId,
      conversationId: matchResult.conversationId,
      remainingLikes: remainingQuota,
      message: "Match! Vocês podem conversar agora",
    };
  } catch (error) {
    console.error("Erro ao processar ação do MatchPoint:", {
      currentUserId,
      targetUserId,
      action,
      stage,
      error,
    });

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError("internal", "Erro interno ao processar ação");
  }
}

/**
 * Cloud Function: submitMatchpointAction.
 *
 * Compatibilidade do fluxo legado por callable.
 */
export const submitMatchpointAction = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    concurrency: 1,
    maxInstances: 10,
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<MatchpointActionResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const currentUserId = request.auth.uid;
    const {targetUserId, action} = readMatchpointActionRequest(request.data);

    if (currentUserId === targetUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Não pode interagir consigo mesmo"
      );
    }

    return processMatchpointAction(currentUserId, targetUserId, action);
  }
);

/**
 * Trigger: processa comandos assíncronos de swipe criados pelo app.
 *
 * Caminho: matchpointCommands/{commandId}
 */
export const onMatchpointCommandCreated = onDocumentCreated(
  {
    document: `${MATCHPOINT_COMMANDS_COLLECTION}/{commandId}`,
    region: "southamerica-east1",
    memory: "256MiB",
    concurrency: 1,
    maxInstances: 10,
    timeoutSeconds: 20,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const commandId = event.params.commandId;
    const commandRef = snapshot.ref;

    try {
      const request = readMatchpointCommandRequest(snapshot.data(), commandId);
      const processingStatus: MatchpointCommandStatus = "processing";
      await commandRef.set({
        status: processingStatus,
        processing_started_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      }, {merge: true});

      const result = await processMatchpointAction(
        request.userId,
        request.targetUserId,
        request.action
      );

      const completedStatus: MatchpointCommandStatus = "completed";
      await commandRef.set({
        status: completedStatus,
        processed_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        result: buildMatchpointCommandResult(request, result),
        error: FieldValue.delete(),
      }, {merge: true});
    } catch (error) {
      const failedStatus: MatchpointCommandStatus = "failed";
      const commandError = buildMatchpointCommandError(error);
      console.error("Erro ao processar matchpoint command:", {
        commandId,
        error,
      });
      await commandRef.set({
        status: failedStatus,
        processed_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        error: commandError,
      }, {merge: true});
    }
  }
);

/**
 * Verifica e atualiza o rate limit diário (lazy reset).
 *
 * @param {string} userId - UID do usuário
 * @return {Promise<{allowed: boolean, remainingLikes: number}>} Resultado
 */
async function checkAndUpdateRateLimit(
  userId: string
): Promise<{ allowed: boolean; remainingLikes: number }> {
  const userRef = db.collection("users").doc(userId);

  return await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado");
    }

    const userData = userDoc.data() || {};
    const now = Timestamp.now();
    const today = new Date(now.toDate().setHours(0, 0, 0, 0));
    const todayTimestamp = Timestamp.fromDate(today);

    let dailyLikesCount = readDailySwipeCount(userData);
    const lastLikeDate = readLastLikeDate(userData);

    if (!lastLikeDate || lastLikeDate < today) {
      dailyLikesCount = 0;
    }

    if (dailyLikesCount >= DAILY_SWIPE_LIMIT) {
      return {allowed: false, remainingLikes: 0};
    }

    transaction.update(userRef, {
      daily_swipes_count: dailyLikesCount + 1,
      last_swipe_date: todayTimestamp,
      daily_likes_count: dailyLikesCount + 1,
      last_like_date: todayTimestamp,
      updated_at: now,
    });

    return {
      allowed: true,
      remainingLikes: DAILY_SWIPE_LIMIT - dailyLikesCount - 1,
    };
  });
}

/**
 * Calcula a quantidade de swipes restantes sem escrever no banco.
 *
 * @param {DocumentData} userData - Dados do usuário
 * @return {{remainingLikes: number, dailyLikesCount: number}} Snapshot
 */
function getRemainingLikesSnapshot(userData: DocumentData): {
  remainingLikes: number;
  dailyLikesCount: number;
} {
  const now = Timestamp.now();
  const today = new Date(now.toDate().setHours(0, 0, 0, 0));
  const lastLikeDate = readLastLikeDate(userData);
  let dailyLikesCount = readDailySwipeCount(userData);

  if (!lastLikeDate || lastLikeDate < today) {
    dailyLikesCount = 0;
  }

  return {
    remainingLikes: Math.max(0, DAILY_SWIPE_LIMIT - dailyLikesCount),
    dailyLikesCount,
  };
}

/**
 * Lê e normaliza contador diário de swipes.
 *
 * @param {DocumentData} userData - Dados do usuário
 * @return {number} contador diário >= 0
 */
function readDailySwipeCount(userData: DocumentData): number {
  const rawCount = userData.daily_swipes_count ?? userData.daily_likes_count;
  if (typeof rawCount !== "number" || !Number.isFinite(rawCount)) {
    return 0;
  }

  return Math.max(0, Math.floor(rawCount));
}

/**
 * Lê e normaliza a data de último swipe/like.
 *
 * @param {DocumentData} userData - Dados do usuário
 * @return {Date|null} data válida ou null
 */
function readLastLikeDate(userData: DocumentData): Date | null {
  const rawDate = userData.last_swipe_date ?? userData.last_like_date;
  if (rawDate instanceof Timestamp) {
    return rawDate.toDate();
  }

  if (rawDate && typeof rawDate.toDate === "function") {
    try {
      const parsed = rawDate.toDate();
      if (parsed instanceof Date) return parsed;
    } catch (_) {
      return null;
    }
  }

  return null;
}

/**
 * Cria um match e reserva o conversationId do chat associado.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @param {DocumentReference<DocumentData>} sourceInteractionRef - Interação
 *   atual persistida pelo usuário que acabou de curtir.
 * @param {DocumentReference<DocumentData>} reciprocalInteractionRef -
 *   Interação recíproca já encontrada para o potencial match.
 * @return {Promise<{matchId: string, conversationId: string} | null>}
 *   Resultado do match ou null quando a reciprocidade sumiu durante a corrida.
 */
async function createMatch(
  userId1: string,
  userId2: string,
  sourceInteractionRef: DocumentReference<DocumentData>,
  reciprocalInteractionRef: DocumentReference<DocumentData>
): Promise<{ matchId: string; conversationId: string } | null> {
  const now = Timestamp.now();

  const pairKey = [userId1, userId2].sort().join("_");
  const matchId = `match_${pairKey}`;
  const matchRef = db.collection("matches").doc(matchId);

  return await db.runTransaction(async (transaction) => {
    const sourceInteractionDoc = await transaction.get(sourceInteractionRef);
    const reciprocalInteractionDoc = await transaction.get(
      reciprocalInteractionRef
    );

    if (!sourceInteractionDoc.exists || !reciprocalInteractionDoc.exists) {
      return null;
    }

    if (
      readInteractionType(sourceInteractionDoc.data()) !== "like" ||
      readInteractionType(reciprocalInteractionDoc.data()) !== "like"
    ) {
      return null;
    }

    const existingMatch = await transaction.get(matchRef);
    const conversationId = resolveMatchConversationId(
      existingMatch.data(),
      pairKey
    );

    transaction.set(sourceInteractionRef, {
      resulted_in_match: true,
      updated_at: now,
    }, {merge: true});
    transaction.set(reciprocalInteractionRef, {
      resulted_in_match: true,
      updated_at: now,
    }, {merge: true});

    if (existingMatch.exists) {
      transaction.set(matchRef, {
        conversation_id: conversationId,
        updated_at: now,
      }, {merge: true});
      return {matchId: existingMatch.id, conversationId};
    }

    transaction.set(matchRef, {
      user_id_1: userId1,
      user_id_2: userId2,
      user_ids: [userId1, userId2],
      pair_key: pairKey,
      conversation_id: conversationId,
      matched_by_user_id: userId1,
      notification_recipient_user_id: userId2,
      created_at: now,
      updated_at: now,
    });

    return {matchId, conversationId};
  });
}

/**
 * Trigger: Quando um match e criado.
 *
 * Move notificacao para fora do callable para reduzir latencia do swipe.
 */
export const onMatchCreated = onDocumentCreated(
  {
    document: "matches/{matchId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data() || {};
    const senderUserId = firstNonEmptyString([data.matched_by_user_id]);
    const userIds = Array.isArray(data.user_ids) ?
      data.user_ids.filter((value): value is string => typeof value === "string") :
      [];
    const recipientUserId = firstNonEmptyString([
      data.notification_recipient_user_id,
      userIds.find((userId) => userId !== senderUserId),
    ]);
    const conversationId = resolveMatchConversationId(
      data,
      snapshot.id.startsWith("match_") ? snapshot.id.slice(6) : snapshot.id
    );

    if (!senderUserId || !recipientUserId || senderUserId === recipientUserId) {
      return;
    }

    await notifyMatchCreated({
      senderUserId,
      recipientUserId,
      conversationId,
    });
  }
);

/**
 * Remove apenas o match entre dois usuários.
 *
 * A conversa é mantida para não quebrar o chat direto fora do MatchPoint.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @return {Promise<boolean>} true quando removeu match
 */
async function removeMatch(userId1: string, userId2: string): Promise<boolean> {
  const pairKey = [userId1, userId2].sort().join("_");
  const matchId = `match_${pairKey}`;

  const matchRef = db.collection("matches").doc(matchId);

  const matchDoc = await matchRef.get();

  if (!matchDoc.exists) return false;

  await matchRef.delete();
  return true;
}

/**
 * Trigger: Quando uma interação é criada.
 */
export const onInteractionCreated = onDocumentCreated(
  {
    document: "interactions/{interactionId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const sourceUserId = data.source_user_id as string;
    const type = data.type as string;

    try {
      const userRef = db.collection("users").doc(sourceUserId);
      let field = "total_dislikes_sent";
      if (type === "like") {
        field = "total_likes_sent";
      }

      await userRef.update({
        [field]: FieldValue.increment(1),
        updated_at: Timestamp.now(),
      });
    } catch (error) {
      console.error("Erro ao atualizar estatísticas:", error);
    }
  }
);

/**
 * Cloud Function: recordMatchpointRankingAudit.
 *
 * Persiste um espelho agregado por hora da auditoria de ranking do MatchPoint
 * para leitura no painel interno/debug do app.
 */
export const recordMatchpointRankingAudit = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<RankingAuditResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const payload = sanitizeRankingAuditRequest(
      request.data as Partial<RankingAuditRequest>
    );
    const now = Timestamp.now();
    const {bucketId, bucketStart} = getRankingAuditBucket(now.toDate());
    const bucketRef = db.collection("matchpointStats").doc(bucketId);

    try {
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(bucketRef);

        if (!snapshot.exists) {
          transaction.set(bucketRef, {
            type: "ranking_audit_hourly",
            bucket_id: bucketId,
            bucket_start: bucketStart,
            total_events: 1,
            pool_total_sum: payload.poolTotal,
            returned_total_sum: payload.returnedTotal,
            pool_proximity_sum: payload.poolProximity,
            pool_hashtag_sum: payload.poolHashtag,
            pool_genre_sum: payload.poolGenre,
            pool_fallback_sum: payload.poolFallback,
            pool_local_total_sum: payload.poolLocalTotal,
            pool_local_hashtag_sum: payload.poolLocalHashtag,
            pool_local_genre_sum: payload.poolLocalGenre,
            returned_proximity_sum: payload.returnedProximity,
            returned_hashtag_sum: payload.returnedHashtag,
            returned_genre_sum: payload.returnedGenre,
            returned_fallback_sum: payload.returnedFallback,
            returned_local_total_sum: payload.returnedLocalTotal,
            returned_local_hashtag_sum: payload.returnedLocalHashtag,
            returned_local_genre_sum: payload.returnedLocalGenre,
            query_genres_sum: payload.queryGenres,
            query_hashtags_sum: payload.queryHashtags,
            geohash_used_count: payload.usedGeohash ? 1 : 0,
            created_at: now,
            updated_at: now,
          });
          return;
        }

        transaction.update(bucketRef, {
          total_events: FieldValue.increment(1),
          pool_total_sum: FieldValue.increment(payload.poolTotal),
          returned_total_sum: FieldValue.increment(payload.returnedTotal),
          pool_proximity_sum: FieldValue.increment(payload.poolProximity),
          pool_hashtag_sum: FieldValue.increment(payload.poolHashtag),
          pool_genre_sum: FieldValue.increment(payload.poolGenre),
          pool_fallback_sum: FieldValue.increment(payload.poolFallback),
          pool_local_total_sum: FieldValue.increment(payload.poolLocalTotal),
          pool_local_hashtag_sum: FieldValue.increment(
            payload.poolLocalHashtag
          ),
          pool_local_genre_sum: FieldValue.increment(payload.poolLocalGenre),
          returned_proximity_sum: FieldValue.increment(
            payload.returnedProximity
          ),
          returned_hashtag_sum: FieldValue.increment(payload.returnedHashtag),
          returned_genre_sum: FieldValue.increment(payload.returnedGenre),
          returned_fallback_sum: FieldValue.increment(payload.returnedFallback),
          returned_local_total_sum: FieldValue.increment(
            payload.returnedLocalTotal
          ),
          returned_local_hashtag_sum: FieldValue.increment(
            payload.returnedLocalHashtag
          ),
          returned_local_genre_sum: FieldValue.increment(
            payload.returnedLocalGenre
          ),
          query_genres_sum: FieldValue.increment(payload.queryGenres),
          query_hashtags_sum: FieldValue.increment(payload.queryHashtags),
          geohash_used_count: FieldValue.increment(payload.usedGeohash ? 1 : 0),
          updated_at: now,
        });
      });

      return {success: true, bucketId};
    } catch (error) {
      console.error("Erro em recordMatchpointRankingAudit:", error);
      throw new HttpsError("internal", "Erro ao registrar auditoria");
    }
  }
);

/**
 * Valida e normaliza payload de auditoria de ranking.
 *
 * @param {Partial<RankingAuditRequest>} payload - Payload bruto recebido.
 * @return {RankingAuditRequest} Payload sanitizado.
 */
function sanitizeRankingAuditRequest(
  payload: Partial<RankingAuditRequest>
): RankingAuditRequest {
  const result: RankingAuditRequest = {
    poolTotal: readAuditInteger(payload.poolTotal, "poolTotal"),
    returnedTotal: readAuditInteger(payload.returnedTotal, "returnedTotal"),
    poolProximity: readAuditInteger(payload.poolProximity, "poolProximity"),
    poolHashtag: readAuditInteger(payload.poolHashtag, "poolHashtag"),
    poolGenre: readAuditInteger(payload.poolGenre, "poolGenre"),
    poolFallback: readAuditInteger(payload.poolFallback, "poolFallback"),
    poolLocalTotal: readAuditInteger(
      payload.poolLocalTotal ?? 0,
      "poolLocalTotal"
    ),
    poolLocalHashtag: readAuditInteger(
      payload.poolLocalHashtag ?? 0,
      "poolLocalHashtag"
    ),
    poolLocalGenre: readAuditInteger(
      payload.poolLocalGenre ?? 0,
      "poolLocalGenre"
    ),
    returnedProximity: readAuditInteger(
      payload.returnedProximity,
      "returnedProximity"
    ),
    returnedHashtag: readAuditInteger(
      payload.returnedHashtag,
      "returnedHashtag"
    ),
    returnedGenre: readAuditInteger(payload.returnedGenre, "returnedGenre"),
    returnedFallback: readAuditInteger(
      payload.returnedFallback,
      "returnedFallback"
    ),
    returnedLocalTotal: readAuditInteger(
      payload.returnedLocalTotal ?? 0,
      "returnedLocalTotal"
    ),
    returnedLocalHashtag: readAuditInteger(
      payload.returnedLocalHashtag ?? 0,
      "returnedLocalHashtag"
    ),
    returnedLocalGenre: readAuditInteger(
      payload.returnedLocalGenre ?? 0,
      "returnedLocalGenre"
    ),
    queryGenres: readAuditInteger(payload.queryGenres, "queryGenres", 20),
    queryHashtags: readAuditInteger(
      payload.queryHashtags,
      "queryHashtags",
      20
    ),
    usedGeohash: payload.usedGeohash === true,
  };

  if (
    result.poolProximity +
      result.poolHashtag +
      result.poolGenre +
      result.poolFallback >
    result.poolTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Soma do pool excede poolTotal."
    );
  }

  if (result.poolLocalTotal > result.poolTotal) {
    throw new HttpsError(
      "invalid-argument",
      "poolLocalTotal excede poolTotal."
    );
  }

  if (
    result.poolLocalHashtag > result.poolLocalTotal ||
    result.poolLocalGenre > result.poolLocalTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Afinidade local do pool excede poolLocalTotal."
    );
  }

  if (
    result.returnedProximity +
      result.returnedHashtag +
      result.returnedGenre +
      result.returnedFallback >
    result.returnedTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Soma do retorno excede returnedTotal."
    );
  }

  if (result.returnedLocalTotal > result.returnedTotal) {
    throw new HttpsError(
      "invalid-argument",
      "returnedLocalTotal excede returnedTotal."
    );
  }

  if (
    result.returnedLocalHashtag > result.returnedLocalTotal ||
    result.returnedLocalGenre > result.returnedLocalTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Afinidade local do retorno excede returnedLocalTotal."
    );
  }

  return result;
}

/**
 * Lê e valida um inteiro não-negativo para auditoria.
 *
 * @param {unknown} value - Valor bruto.
 * @param {string} fieldName - Nome do campo para erro.
 * @param {number=} max - Máximo permitido.
 * @return {number} Valor inteiro validado.
 */
function readAuditInteger(
  value: unknown,
  fieldName: string,
  max = 1000
): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `${fieldName} inválido.`);
  }

  const normalized = Math.floor(value);
  if (normalized < 0 || normalized > max) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} fora do intervalo.`
    );
  }

  return normalized;
}

/**
 * Gera identificador/bucket horário para agregação de auditoria.
 *
 * @param {Date} now - Data/hora de referência.
 * @return {{bucketId: string, bucketStart: Timestamp}} Bucket normalizado.
 */
function getRankingAuditBucket(now: Date): {
  bucketId: string;
  bucketStart: Timestamp;
} {
  const bucketDate = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate(),
      now.getUTCHours()
    )
  );

  const bucketId = [
    "ranking_audit_hourly",
    bucketDate.getUTCFullYear(),
    String(bucketDate.getUTCMonth() + 1).padStart(2, "0"),
    String(bucketDate.getUTCDate()).padStart(2, "0"),
    String(bucketDate.getUTCHours()).padStart(2, "0"),
  ].join("_");

  return {
    bucketId,
    bucketStart: Timestamp.fromDate(bucketDate),
  };
}

/**
 * Cloud Function: getRemainingLikes.
 */
export const getRemainingLikes = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 5,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<RemainingLikesResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const userId = request.auth.uid;

    try {
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Usuário não encontrado");
      }

      const userData = userDoc.data() || {};
      const now = Timestamp.now();
      const today = new Date(now.toDate().setHours(0, 0, 0, 0));
      const dailyLikesSnapshot = getRemainingLikesSnapshot(userData);

      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      return {
        remaining: dailyLikesSnapshot.remainingLikes,
        limit: DAILY_SWIPE_LIMIT,
        resetTime: tomorrow.toISOString(),
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("Erro em getRemainingLikes:", error);
      throw new HttpsError("internal", "Erro ao consultar swipes");
    }
  }
);
