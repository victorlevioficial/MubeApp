import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";

/**
 * Cloud Function para migrar usuários existentes adicionando geohash.
 *
 * Esta função pode ser chamada via HTTP para atualizar todos os usuários
 * que têm localização mas não têm geohash salvo.
 *
 * URL: https://us-central1-<project-id>.cloudfunctions.net/migrategeohashes
 */
export const migrategeohashes = functions.https.onRequest(async (req, res) => {
  try {
    console.log("🚀 Iniciando migração de geohashes...");

    const db = admin.firestore();
    const usersRef = db.collection("users");

    // Busca todos os usuários
    const snapshot = await usersRef.get();

    let updatedCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    const batch = db.batch();
    let batchCount = 0;
    const BATCH_SIZE = 500; // Firestore limit

    for (const doc of snapshot.docs) {
      const userData = doc.data();

      // Pula se já tiver geohash
      if (userData.geohash) {
        skippedCount++;
        continue;
      }

      // Verifica se tem localização válida
      const location = userData.location;
      if (!location ||
          location.lat == null ||
          location.lng == null ||
          isNaN(location.lat) ||
          isNaN(location.lng)) {
        console.log(`⚠️ Usuário ${doc.id} sem localização válida`);
        skippedCount++;
        continue;
      }

      try {
        // Calcula geohash
        const lat = parseFloat(location.lat);
        const lng = parseFloat(location.lng);
        const geohash = encodeGeohash(lat, lng, 5);

        // Atualiza no batch
        batch.update(doc.ref, {
          geohash: geohash,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });

        updatedCount++;
        batchCount++;

        // Commit a cada BATCH_SIZE
        if (batchCount >= BATCH_SIZE) {
          await batch.commit();
          console.log(`✅ Batch de ${batchCount} usuários atualizado`);
          batchCount = 0;
        }
      } catch (error) {
        console.error(`❌ Erro ao processar usuário ${doc.id}:`, error);
        errorCount++;
      }
    }

    // Commit do batch final
    if (batchCount > 0) {
      await batch.commit();
      console.log(`✅ Batch final de ${batchCount} usuários atualizado`);
    }

    const result = {
      success: true,
      totalUsers: snapshot.size,
      updated: updatedCount,
      skipped: skippedCount,
      errors: errorCount,
      message: `Migração concluída! ${updatedCount} usuários atualizados.`,
    };

    console.log("✅ Migração concluída:", result);
    res.status(200).json(result);
  } catch (error) {
    console.error("❌ Erro na migração:", error);
    res.status(500).json({
      success: false,
      error: (error as Error).message,
    });
  }
});

/**
 * Cloud Function para atualizar geohash quando localização muda.
 * Usa sintaxe v2 do Firestore.
 */
export const updateusergeohash = onDocumentUpdated(
  "users/{userId}",
  async (event) => {
    const newData = event.data?.after?.data();
    const oldData = event.data?.before?.data();

    if (!newData) {
      console.log("No data found");
      return;
    }

    // Só atualiza se a localização mudou
    const newLocation = newData.location;
    const oldLocation = oldData?.location;

    if (!newLocation ||
        (oldLocation &&
         newLocation.lat === oldLocation.lat &&
         newLocation.lng === oldLocation.lng)) {
      return;
    }

    // Verifica se tem coordenadas válidas
    if (newLocation.lat == null ||
        newLocation.lng == null ||
        isNaN(newLocation.lat) ||
        isNaN(newLocation.lng)) {
      console.log(
        `⚠️ Usuário ${event.params.userId} com coordenadas inválidas`
      );
      return;
    }

    try {
      const lat = parseFloat(newLocation.lat);
      const lng = parseFloat(newLocation.lng);
      const geohash = encodeGeohash(lat, lng, 5);

      // Atualiza o documento
      await event.data?.after?.ref.update({
        geohash: geohash,
      });

      console.log(
        `✅ Geohash atualizado para ${event.params.userId}: ${geohash}`
      );
    } catch (error) {
      console.error(
        `❌ Erro ao atualizar geohash de ${event.params.userId}:`,
        error
      );
    }
  }
);

/**
 * Codifica coordenadas lat/lng em geohash.
 *
 * @param {number} lat - Latitude (-90 to 90)
 * @param {number} lng - Longitude (-180 to 180)
 * @param {number} precision - Precisão (padrão: 5 = ~5km)
 * @return {string} Geohash
 */
function encodeGeohash(lat: number, lng: number, precision = 5): string {
  const BASE32 = "0123456789bcdefghjkmnpqrstuvwxyz";

  const latRange: [number, number] = [-90.0, 90.0];
  const lngRange: [number, number] = [-180.0, 180.0];
  let geohash = "";
  let isEven = true;
  let bit = 0;
  let ch = 0;

  while (geohash.length < precision) {
    if (isEven) {
      // Longitude
      const mid = (lngRange[0] + lngRange[1]) / 2;
      if (lng > mid) {
        ch |= (1 << (4 - bit));
        lngRange[0] = mid;
      } else {
        lngRange[1] = mid;
      }
    } else {
      // Latitude
      const mid = (latRange[0] + latRange[1]) / 2;
      if (lat > mid) {
        ch |= (1 << (4 - bit));
        latRange[0] = mid;
      } else {
        latRange[1] = mid;
      }
    }

    isEven = !isEven;

    if (bit < 4) {
      bit++;
    } else {
      geohash += BASE32[ch];
      bit = 0;
      ch = 0;
    }
  }

  return geohash;
}
