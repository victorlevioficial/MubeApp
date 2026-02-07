/**
 * Cloud Functions Agendadas (Scheduled)
 *
 * Funcionalidades:
 * - pruneOldInteractions: Remove interações antigas (expiradas)
 * - liftSuspensions: Remove suspensões expiradas (movida para moderation.ts)
 */

import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import {Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();

// Constantes
const BATCH_SIZE = 500; // Máximo de operações por batch

/**
 * Scheduled Function: pruneOldInteractions
 *
 * Remove interações expiradas diariamente:
 * - Interações com expires_at no passado
 * - Mantém histórico de matches (não remove)
 * - Roda às 2h da manhã (horário de menor uso)
 */
export const pruneOldInteractions = onSchedule(
  {
    schedule: "0 2 * * *", // 2h da manhã todo dia
    region: "southamerica-east1",
    memory: "512MiB", // Mais memória para processar muitos documentos
    timeoutSeconds: 540, // 9 minutos (máximo para scheduled functions)
    concurrency: 1,
  },
  async () => {
    const now = Timestamp.now();
    console.log("Iniciando pruneOldInteractions:", now.toDate());

    let totalDeleted = 0;
    let hasMore = true;

    try {
      while (hasMore) {
        // Buscar interações expiradas
        const expiredInteractions = await db
          .collection("interactions")
          .where("type", "==", "dislike")
          .where("expires_at", "<=", now)
          .limit(BATCH_SIZE)
          .get();

        if (expiredInteractions.empty) {
          hasMore = false;
          break;
        }

        // Deletar em batch
        const batch = db.batch();
        let batchCount = 0;

        for (const doc of expiredInteractions.docs) {
          batch.delete(doc.ref);
          batchCount++;
        }

        if (batchCount > 0) {
          await batch.commit();
          totalDeleted += batchCount;
          console.log(
            `Deletadas ${batchCount} interações (total: ${totalDeleted})`
          );
        }

        // Se retornou menos que BATCH_SIZE, acabou
        hasMore = expiredInteractions.size >= BATCH_SIZE && batchCount > 0;

        // Pequena pausa para não sobrecarregar
        if (hasMore) {
          await new Promise((resolve) => setTimeout(resolve, 100));
        }
      }

      console.log(
        `pruneOldInteractions concluído: ${totalDeleted} interações removidas`
      );
    } catch (error) {
      console.error("Erro em pruneOldInteractions:", error);
      throw error;
    }
  }
);

/**
 * Scheduled Function: cleanupOrphanedData
 *
 * Remove dados órfãos semanalmente:
 * - Conversation previews sem conversa associada
 * - Band memberships de bandas deletadas
 * - Invites expirados (mais de 30 dias pendentes)
 *
 * Roda aos domingos às 3h da manhã
 */
export const cleanupOrphanedData = onSchedule(
  {
    schedule: "0 3 * * 0", // 3h da manhã aos domingos
    region: "southamerica-east1",
    memory: "512MiB",
    timeoutSeconds: 540,
  },
  async () => {
    const now = Timestamp.now();
    console.log("Iniciando cleanupOrphanedData:", now.toDate());

    try {
      // 1. Limpar invites expirados
      const thirtyDaysAgo = Timestamp.fromDate(
        new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
      );

      const expiredInvites = await db
        .collection("invites")
        .where("status", "==", "pendente")
        .where("created_at", "<=", thirtyDaysAgo)
        .limit(BATCH_SIZE)
        .get();

      const inviteBatch = db.batch();
      for (const doc of expiredInvites.docs) {
        inviteBatch.update(doc.ref, {
          status: "expirado",
          updated_at: now,
        });
      }

      if (expiredInvites.size > 0) {
        await inviteBatch.commit();
        console.log(`Expirados ${expiredInvites.size} invites antigos`);
      }

      // 2. Limpar previews de conversa sem conversa associada
      // (Implementação mais complexa, requer query em subcoleção)
      // Por enquanto apenas logamos
      console.log("Verificação de previews órfãos: implementação futura");

      console.log("cleanupOrphanedData concluído");
    } catch (error) {
      console.error("Erro em cleanupOrphanedData:", error);
      throw error;
    }
  }
);

/**
 * Scheduled Function: updateMatchpointStats
 *
 * Atualiza estatísticas diárias do matchpoint:
 * - Total de likes/dislikes do dia
 * - Total de matches
 * - Taxa de match
 *
 * Roda às 23:55 todo dia
 */
export const updateMatchpointStats = onSchedule(
  {
    schedule: "55 23 * * *", // 23:55 todo dia
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 60,
  },
  async () => {
    const now = Timestamp.now();
    const today = new Date(now.toDate());
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    console.log("Calculando estatísticas do dia:", today);

    try {
      // Contar interações do dia
      const todayStart = Timestamp.fromDate(today);
      const todayEnd = Timestamp.fromDate(tomorrow);

      const [likesSnap, dislikesSnap, matchesSnap] = await Promise.all([
        db.collection("interactions")
          .where("type", "==", "like")
          .where("created_at", ">=", todayStart)
          .where("created_at", "<", todayEnd)
          .count()
          .get(),
        db.collection("interactions")
          .where("type", "==", "dislike")
          .where("created_at", ">=", todayStart)
          .where("created_at", "<", todayEnd)
          .count()
          .get(),
        db.collection("matches")
          .where("created_at", ">=", todayStart)
          .where("created_at", "<", todayEnd)
          .count()
          .get(),
      ]);

      const stats = {
        date: todayStart,
        likes: likesSnap.data().count,
        dislikes: dislikesSnap.data().count,
        matches: matchesSnap.data().count,
        match_rate: likesSnap.data().count > 0 ?
          (matchesSnap.data().count / likesSnap.data().count) * 100 :
          0,
        created_at: now,
      };

      // Salvar estatísticas
      await db.collection("matchpointStats").add(stats);

      console.log("Estatísticas atualizadas:", stats);
    } catch (error) {
      console.error("Erro em updateMatchpointStats:", error);
      throw error;
    }
  }
);
