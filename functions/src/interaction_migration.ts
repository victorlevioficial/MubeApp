import * as admin from "firebase-admin";
import {defineSecret} from "firebase-functions/params";
import {onRequest} from "firebase-functions/v2/https";
import type {Request, Response} from "express";

const migrationToken = defineSecret("MIGRATION_TOKEN");

/**
 * Validates migration endpoint authorization using an HTTP header token.
 *
 * @param {Request} req Incoming HTTP request.
 * @param {Response} res HTTP response writer.
 * @return {boolean} True when authorized, false otherwise.
 */
function ensureMigrationAuthorized(
  req: Request,
  res: Response
): boolean {
  if (req.method !== "POST") {
    res.status(405).json({success: false, error: "Method Not Allowed"});
    return false;
  }

  const configuredToken = migrationToken.value();
  if (!configuredToken) {
    res.status(500).json({
      success: false,
      error: "MIGRATION_TOKEN is not configured",
    });
    return false;
  }

  const providedToken = req.get("x-migration-token");
  if (!providedToken || providedToken !== configuredToken) {
    res.status(403).json({success: false, error: "Forbidden"});
    return false;
  }

  return true;
}

/**
 * Cloud Function para migrar interactions de subcoleções
 * (users/{uid}/interactions/{targetId}) para a coleção global.
 *
 * Esta função deve ser chamada via HTTP para rodar a migração.
 *
 * URL: [project].cloudfunctions.net/migrateinteractions
 */
export const migrateinteractions = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: [migrationToken],
  },
  async (req, res) => {
    if (!ensureMigrationAuthorized(req, res)) {
      return;
    }

    try {
      console.log("🚀 Iniciando migração de interações...");

      const db = admin.firestore();
      const usersRef = db.collection("users");

      const snapshot = await usersRef.get();

      let migratedCount = 0;
      let deletedCount = 0;
      let errorCount = 0;

      let batch = db.batch();
      let batchCount = 0;
      // Firestore hard limit is 500 ops per batch.
      // Each interaction uses 2 ops (set + delete), so flush before exceeding.
      const BATCH_SIZE = 498;

      for (const doc of snapshot.docs) {
        const senderId = doc.id;
        const interactionsRef = doc.ref.collection("interactions");
        const interactionsSnapshot = await interactionsRef.get();

        for (const interactionDoc of interactionsSnapshot.docs) {
          const receiverId = interactionDoc.id;
          const interactionData = interactionDoc.data();

          try {
            const globalId = `${senderId}_${receiverId}`;
            const globalInteractionRef = db
              .collection("interactions")
              .doc(globalId);

            batch.set(globalInteractionRef, {
              senderId: senderId,
              receiverId: receiverId,
              type: interactionData.type || "like",
              timestamp: interactionData.timestamp ||
                                admin.firestore.FieldValue.serverTimestamp(),
            }, {merge: true});

            batch.delete(interactionDoc.ref);

            migratedCount++;
            deletedCount++;
            batchCount += 2; // set and delete count as 2 ops

            if (batchCount >= BATCH_SIZE) {
              await batch.commit();
              console.log(`✅ Batch ${batchCount} ops commitadas`);
              batch = db.batch();
              batchCount = 0;
            }
          } catch (error) {
            console.error(`❌ Erro em ${senderId}->${receiverId}:`, error);
            errorCount++;
          }
        }
      }

      if (batchCount > 0) {
        await batch.commit();
        console.log(`✅ Batch final de ${batchCount} ops`);
      }

      const result = {
        success: true,
        totalUsersProcessed: snapshot.size,
        migratedInteractions: migratedCount,
        deletedOldInteractions: deletedCount,
        errors: errorCount,
      };

      console.log("✅ Migração de interações concluída:", result);
      res.status(200).json(result);
    } catch (error) {
      console.error("❌ Erro na migração de interações:", error);
      res.status(500).json({
        success: false,
        error: (error as Error).message,
      });
    }
  });
