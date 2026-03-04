/**
 * Cloud Functions para o feature Matchpoint.
 *
 * Funcionalidades:
 * - submitMatchpointAction: Processa ações de like/dislike
 * - Criação de match e conversa
 * - onInteractionCreated: Atualiza estatísticas
 * - getRemainingLikes: Retorna quota diária
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {DocumentData, FieldValue, Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();

const DAILY_SWIPE_LIMIT = 50;
const INTERACTION_EXPIRY_DAYS = 30;

/**
 * Estrutura do request para submitMatchpointAction.
 */
interface MatchpointActionRequest {
  targetUserId: string;
  action: "like" | "dislike";
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

/**
 * Cloud Function: submitMatchpointAction.
 *
 * Processa ações de like/dislike com:
 * - Rate limit diário de swipes
 * - Verificação de match mútuo
 * - Criação de match e conversa
 */
export const submitMatchpointAction = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
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
    const {targetUserId, action} = request.data as MatchpointActionRequest;

    if (!targetUserId || typeof targetUserId !== "string") {
      throw new HttpsError("invalid-argument", "targetUserId é obrigatório");
    }

    if (!action || !["like", "dislike"].includes(action)) {
      throw new HttpsError(
        "invalid-argument",
        "action deve ser 'like' ou 'dislike'"
      );
    }

    if (currentUserId === targetUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Não pode interagir consigo mesmo"
      );
    }

    try {
      const userRef = db.collection("users").doc(currentUserId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Usuário não encontrado");
      }

      const userData = userDoc.data() || {};
      const remainingLikesSnapshot = getRemainingLikesSnapshot(userData);

      const existingInteractionQuery = await db
        .collection("interactions")
        .where("source_user_id", "==", currentUserId)
        .where("target_user_id", "==", targetUserId)
        .where("type", "in", ["like", "dislike"])
        .limit(1)
        .get();

      const existingInteraction = existingInteractionQuery.empty ?
        null :
        existingInteractionQuery.docs[0];
      const existingData = existingInteraction?.data() || {};
      const existingType = existingData.type as string | undefined;

      let remainingQuota = remainingLikesSnapshot.remainingLikes;

      if (!existingInteraction) {
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
            await existingInteraction.ref.update({
              type: "dislike",
              updated_at: now,
              expires_at: expiresAt,
              resulted_in_match: FieldValue.delete(),
            });
          }
        } else {
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
        await existingInteraction.ref.update({
          type: "like",
          updated_at: now,
          expires_at: FieldValue.delete(),
          resulted_in_match: FieldValue.delete(),
        });
        interactionRef = existingInteraction.ref;
      } else {
        interactionRef = db.collection("interactions").doc();
        await interactionRef.set({
          source_user_id: currentUserId,
          target_user_id: targetUserId,
          type: "like",
          created_at: now,
          updated_at: now,
        });
      }

      const mutualLikeQuery = await db
        .collection("interactions")
        .where("source_user_id", "==", targetUserId)
        .where("target_user_id", "==", currentUserId)
        .where("type", "==", "like")
        .limit(1)
        .get();

      const isMatch = !mutualLikeQuery.empty;

      if (!isMatch) {
        return {
          success: true,
          isMatch: false,
          remainingLikes: remainingQuota,
          message: "Like registrado",
        };
      }

      const matchResult = await createMatch(currentUserId, targetUserId);

      await Promise.all([
        interactionRef.update({
          resulted_in_match: true,
          updated_at: Timestamp.now(),
        }),
        mutualLikeQuery.docs[0].ref.update({resulted_in_match: true}),
      ]);

      return {
        success: true,
        isMatch: true,
        matchId: matchResult.matchId,
        conversationId: matchResult.conversationId,
        remainingLikes: remainingQuota,
        message: "Match! Vocês podem conversar agora",
      };
    } catch (error) {
      console.error("Erro em submitMatchpointAction:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Erro interno ao processar ação");
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
 * Cria um match e a conversa associada.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @return {Promise<{matchId: string, conversationId: string}>} Resultado
 */
async function createMatch(
  userId1: string,
  userId2: string
): Promise<{ matchId: string; conversationId: string }> {
  const now = Timestamp.now();

  const pairKey = [userId1, userId2].sort().join("_");
  const matchId = `match_${pairKey}`;
  const conversationId = pairKey;

  const matchRef = db.collection("matches").doc(matchId);
  const conversationRef = db.collection("conversations").doc(conversationId);

  return await db.runTransaction(async (transaction) => {
    const existingMatch = await transaction.get(matchRef);
    if (existingMatch.exists) {
      const matchData = existingMatch.data() || {};
      return {
        matchId: existingMatch.id,
        conversationId: matchData.conversation_id as string,
      };
    }

    const existingConversation = await transaction.get(conversationRef);

    const user1Doc = await transaction.get(db.collection("users").doc(userId1));
    const user2Doc = await transaction.get(db.collection("users").doc(userId2));
    const user1Data = user1Doc.data() || {};
    const user2Data = user2Doc.data() || {};

    if (!existingConversation.exists) {
      transaction.set(conversationRef, {
        participants: [userId1, userId2],
        participantsMap: {[userId1]: true, [userId2]: true},
        createdAt: now,
        updatedAt: now,
        readUntil: {
          [userId1]: Timestamp.fromMillis(0),
          [userId2]: Timestamp.fromMillis(0),
        },
        lastMessageText: null,
        lastMessageAt: null,
        lastSenderId: null,
        type: "matchpoint",
      });
    }

    const preview1Ref = db
      .collection("users")
      .doc(userId1)
      .collection("conversationPreviews")
      .doc(conversationId);
    const preview2Ref = db
      .collection("users")
      .doc(userId2)
      .collection("conversationPreviews")
      .doc(conversationId);

    const preview1Doc = await transaction.get(preview1Ref);
    const preview2Doc = await transaction.get(preview2Ref);

    if (!preview1Doc.exists) {
      transaction.set(preview1Ref, {
        otherUserId: userId2,
        otherUserName: user2Data.nome || user2Data.nome_artistico || "Usuário",
        otherUserPhoto: user2Data.foto || null,
        lastMessageText: null,
        lastMessageAt: null,
        lastSenderId: null,
        unreadCount: 0,
        updatedAt: now,
        type: "matchpoint",
      });
    }

    if (!preview2Doc.exists) {
      transaction.set(preview2Ref, {
        otherUserId: userId1,
        otherUserName: user1Data.nome || user1Data.nome_artistico || "Usuário",
        otherUserPhoto: user1Data.foto || null,
        lastMessageText: null,
        lastMessageAt: null,
        lastSenderId: null,
        unreadCount: 0,
        updatedAt: now,
        type: "matchpoint",
      });
    }

    transaction.set(matchRef, {
      user_id_1: userId1,
      user_id_2: userId2,
      user_ids: [userId1, userId2],
      pair_key: pairKey,
      conversation_id: conversationId,
      created_at: now,
      updated_at: now,
    });

    return {matchId, conversationId};
  });
}

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
          pool_local_hashtag_sum: FieldValue.increment(payload.poolLocalHashtag),
          pool_local_genre_sum: FieldValue.increment(payload.poolLocalGenre),
          returned_proximity_sum: FieldValue.increment(payload.returnedProximity),
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
    throw new HttpsError("invalid-argument", `${fieldName} fora do intervalo.`);
  }

  return normalized;
}

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
      console.error("Erro em getRemainingLikes:", error);
      throw new HttpsError("internal", "Erro ao consultar swipes");
    }
  }
);
