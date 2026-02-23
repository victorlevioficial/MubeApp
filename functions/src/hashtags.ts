/**
 * Cloud Functions para Ranking de Hashtags
 *
 * Funcionalidades:
 * - onHashtagUsed: Atualiza contagem quando hashtag é usada
 * - recalculateHashtagRanking: Recalcula ranking diariamente
 * - getTrendingHashtags: Retorna hashtags em alta
 */

import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {
  DocumentData,
  FieldValue,
  QuerySnapshot,
  Timestamp,
} from "firebase-admin/firestore";

const db = admin.firestore();

const TRENDING_WINDOW_DAYS = 7;
const RANKING_UPDATE_HOUR = 4;
const TRENDING_MIN_WEEKLY_USES = 1;

interface HashtagResponse {
  hashtags: Record<string, unknown>[];
  total: number;
}

/**
 * Trigger: onHashtagUsed
 *
 * Disparado quando um usuário atualiza suas hashtags.
 */
export const onHashtagUsed = onDocumentUpdated(
  {
    document: "users/{userId}",
    region: "southamerica-east1",
    memory: "256MiB",
  },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;

    if (!before || !after) return;

    const beforeData = before.data();
    const afterData = after.data();

    const beforeHashtags = getUserHashtags(beforeData);
    const afterHashtags = getUserHashtags(afterData);

    const beforeKey = [...beforeHashtags].sort().join("|");
    const afterKey = [...afterHashtags].sort().join("|");

    if (beforeKey === afterKey) return;

    const added = afterHashtags.filter((tag) => !beforeHashtags.includes(tag));
    const removed = beforeHashtags.filter(
      (tag) => !afterHashtags.includes(tag)
    );

    if (added.length === 0 && removed.length === 0) return;

    const now = Timestamp.now();
    const batch = db.batch();

    for (const hashtag of added) {
      const normalized = normalizeHashtag(hashtag);
      const hashtagRef = db.collection("hashtagRanking").doc(normalized);

      batch.set(
        hashtagRef,
        {
          hashtag: normalized,
          display_name: hashtag.trim(),
          use_count: FieldValue.increment(1),
          current_position: 0,
          previous_position: 0,
          trend: "stable",
          trend_delta: 0,
          weekly_count: FieldValue.increment(1),
          is_trending: false,
          last_used_at: now,
          updated_at: now,
        },
        {merge: true}
      );

      const dailyUseRef = hashtagRef
        .collection("dailyUses")
        .doc(getDateKey(now));
      batch.set(
        dailyUseRef,
        {
          date: getDateKey(now),
          count: FieldValue.increment(1),
          updated_at: now,
        },
        {merge: true}
      );
    }

    for (const hashtag of removed) {
      const normalized = normalizeHashtag(hashtag);
      const hashtagRef = db.collection("hashtagRanking").doc(normalized);

      batch.update(hashtagRef, {
        use_count: FieldValue.increment(-1),
        updated_at: now,
      });
    }

    await batch.commit();
    console.log(`Hashtags atualizadas: +${added.length}, -${removed.length}`);
  }
);

/**
 * Recalcula o ranking de hashtags diariamente.
 */
export const recalculateHashtagRanking = onSchedule(
  {
    schedule: `0 ${RANKING_UPDATE_HOUR} * * *`,
    region: "southamerica-east1",
    memory: "512MiB",
    timeoutSeconds: 300,
  },
  async () => {
    const now = Timestamp.now();
    console.log("Recalculando ranking de hashtags:", now.toDate());

    try {
      const hashtagsSnap = await db
        .collection("hashtagRanking")
        .orderBy("use_count", "desc")
        .limit(1000)
        .get();

      console.log(`Processando ${hashtagsSnap.size} hashtags`);

      const batch = db.batch();
      let position = 1;

      const sevenDaysAgo = Timestamp.fromDate(
        new Date(Date.now() - TRENDING_WINDOW_DAYS * 24 * 60 * 60 * 1000)
      );

      for (const doc of hashtagsSnap.docs) {
        const data = doc.data();
        let previousPosition = position;
        if (typeof data.current_position === "number") {
          previousPosition = data.current_position;
        }

        let trend: "up" | "down" | "stable" = "stable";
        let trendDelta = 0;

        if (previousPosition > position) {
          trend = "up";
          trendDelta = previousPosition - position;
        } else if (previousPosition < position) {
          trend = "down";
          trendDelta = position - previousPosition;
        }

        const recentUses = await doc.ref
          .collection("dailyUses")
          .where("date", ">=", getDateKey(sevenDaysAgo))
          .get();

        const weeklyCount = recentUses.docs.reduce((sum, dailyDoc) => {
          const value = dailyDoc.data().count;
          const count = typeof value === "number" ? value : 0;
          return sum + count;
        }, 0);

        const isTrending = weeklyCount >= TRENDING_MIN_WEEKLY_USES;

        batch.update(doc.ref, {
          current_position: position,
          previous_position: previousPosition,
          trend: trend,
          trend_delta: trendDelta,
          weekly_count: weeklyCount,
          is_trending: isTrending,
          updated_at: now,
        });

        position += 1;
      }

      await batch.commit();
      console.log(`Ranking atualizado: ${position - 1} hashtags posicionadas`);

      await cleanupUnusedHashtags();
    } catch (error) {
      console.error("Erro em recalculateHashtagRanking:", error);
      throw error;
    }
  }
);

/**
 * Retorna hashtags em alta para o app.
 */
export const getTrendingHashtags = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<HashtagResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const limit = Math.min(Number(request.data?.limit || 50), 100);
    const includeAll = Boolean(request.data?.includeAll || false);

    try {
      let snapshot: QuerySnapshot<DocumentData>;

      if (!includeAll) {
        snapshot = await db
          .collection("hashtagRanking")
          .where("is_trending", "==", true)
          .orderBy("current_position", "asc")
          .limit(limit)
          .get();
      } else {
        snapshot = await db
          .collection("hashtagRanking")
          .orderBy("current_position", "asc")
          .limit(limit)
          .get();
      }

      // Fallback para evitar tela vazia em fase inicial.
      if (snapshot.empty) {
        snapshot = await db
          .collection("hashtagRanking")
          .orderBy("use_count", "desc")
          .limit(limit)
          .get();
      }

      const hashtags = snapshot.docs.map((doc, index) => {
        const data = doc.data() as Record<string, unknown>;
        let currentPosition = index + 1;
        if (typeof data.current_position === "number") {
          currentPosition = data.current_position;
        }

        return {
          id: doc.id,
          ...data,
          current_position: currentPosition,
        };
      });

      return {
        hashtags,
        total: hashtags.length,
      };
    } catch (error) {
      console.error("Erro em getTrendingHashtags:", error);
      throw new HttpsError("internal", "Erro ao buscar hashtags");
    }
  }
);

/**
 * Busca hashtags por texto.
 */
export const searchHashtags = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<HashtagResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const searchTerm = String(request.data?.query || "").toLowerCase().trim();
    if (!searchTerm || searchTerm.length < 2) {
      throw new HttpsError("invalid-argument", "Termo de busca muito curto");
    }

    const limit = Math.min(Number(request.data?.limit || 20), 50);

    try {
      const snapshot = await db
        .collection("hashtagRanking")
        .where("hashtag", ">=", searchTerm)
        .where("hashtag", "<=", `${searchTerm}\uf8ff`)
        .orderBy("hashtag")
        .orderBy("use_count", "desc")
        .limit(limit)
        .get();

      const hashtags = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...(doc.data() as Record<string, unknown>),
      }));

      return {
        hashtags,
        total: hashtags.length,
      };
    } catch (error) {
      console.error("Erro em searchHashtags:", error);
      throw new HttpsError("internal", "Erro ao buscar hashtags");
    }
  }
);

/**
 * Retorna hashtags do usuário.
 *
 * @param {Record<string, unknown>} data - Documento do usuário
 * @return {string[]} Lista de hashtags
 */
function getUserHashtags(data: Record<string, unknown>): string[] {
  const matchpointProfile = data.matchpoint_profile as Record<string, unknown>;
  const matchpointHashtags = matchpointProfile?.hashtags as unknown;
  const raw = matchpointHashtags ?? data.hashtags ?? [];

  if (!Array.isArray(raw)) return [];

  return raw
    .filter((item) => typeof item === "string")
    .map((item) => (item as string).trim())
    .filter((item) => item.length > 0);
}

/**
 * Normaliza uma hashtag para uso como ID de documento.
 *
 * @param {string} hashtag - Hashtag original
 * @return {string} Hashtag normalizada
 */
function normalizeHashtag(hashtag: string): string {
  return hashtag
    .trim()
    .toLowerCase()
    .replace(/^#/, "")
    .replace(/\s+/g, "_")
    .replace(/[^a-z0-9_]/g, "");
}

/**
 * Gera chave de data (YYYY-MM-DD).
 *
 * @param {Timestamp} timestamp - Timestamp do Firestore
 * @return {string} Chave de data
 */
function getDateKey(timestamp: Timestamp): string {
  const date = timestamp.toDate();
  return date.toISOString().split("T")[0];
}

/**
 * Remove hashtags sem uso do ranking.
 *
 * @return {Promise<void>} conclusão da limpeza
 */
async function cleanupUnusedHashtags(): Promise<void> {
  const unusedHashtags = await db
    .collection("hashtagRanking")
    .where("use_count", "<=", 0)
    .limit(100)
    .get();

  if (unusedHashtags.empty) return;

  const batch = db.batch();
  for (const doc of unusedHashtags.docs) {
    batch.delete(doc.ref);
  }

  await batch.commit();
  console.log(`Removidas ${unusedHashtags.size} hashtags sem uso`);
}
