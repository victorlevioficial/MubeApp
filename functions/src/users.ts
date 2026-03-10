import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {onCall, HttpsError, onRequest} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import * as admin from "firebase-admin";
import type {Request, Response} from "express";

const db = admin.firestore();
const CONTRACTOR_PROFILE_TYPE = "contratante";
const NAME_CONNECTORS = new Set(["de", "da", "do", "dos", "das", "e"]);
const migrationToken = defineSecret("MIGRATION_TOKEN");
const BACKFILL_PAGE_SIZE = 400;
const BACKFILL_BATCH_SIZE = 400;

/**
 * Normalizes unknown values into a safe object map.
 *
 * @param {unknown} value Raw value from Firestore.
 * @return {Record<string, unknown>} Safe map.
 */
function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value) ? value as Record<string, unknown> : {};
}

/**
 * Returns the first non-empty string from candidates.
 *
 * @param {unknown[]} values Candidate values.
 * @return {string} Trimmed first non-empty string or empty.
 */
function firstNonEmptyString(values: unknown[]): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }
  return "";
}

/**
 * Builds a short display name from a full personal name.
 *
 * Rules:
 * - Keeps the name as-is when it has 1-2 words.
 * - Uses first 2 words when it has more words.
 * - Uses first 3 when the 2nd word is a connector (de/da/do/dos/das/e).
 *
 * @param {string} fullName Full name from profile.
 * @return {string} Short display name.
 */
function buildShortPersonName(fullName: string): string {
  const normalized = fullName.trim().replace(/\s+/g, " ");
  if (!normalized) return "";

  const parts = normalized.split(" ");
  if (parts.length <= 2) return normalized;

  const secondWord = parts[1].toLowerCase();
  const takeCount = NAME_CONNECTORS.has(secondWord) ? 3 : 2;
  return parts.slice(0, takeCount).join(" ");
}

/**
 * Validates migration endpoint authorization using an HTTP header token.
 *
 * @param {Request} req Incoming HTTP request.
 * @param {Response} res HTTP response writer.
 * @return {boolean} True when authorized, false otherwise.
 */
function ensureMigrationAuthorized(req: Request, res: Response): boolean {
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
 * Parses a positive integer query/body parameter with a safe cap.
 *
 * @param {unknown} value Raw value.
 * @param {number} fallback Default value.
 * @param {number} max Max allowed value.
 * @return {number} Parsed bounded integer.
 */
function parsePositiveInt(
  value: unknown,
  fallback: number,
  max: number
): number {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) return fallback;
  return Math.min(Math.floor(parsed), max);
}

/**
 * Parses dry-run mode from request query/body.
 *
 * @param {Request} req HTTP request.
 * @return {boolean} Whether migration should only simulate writes.
 */
function parseDryRun(req: Request): boolean {
  const queryValue = String(req.query.dryRun ?? "").trim().toLowerCase();
  const body = req.body as Record<string, unknown> | null;
  const bodyValue = String(body?.dryRun ?? "").trim().toLowerCase();
  return queryValue === "true" || bodyValue === "true";
}

/**
 * Keeps contractor short display name in sync with full registration name.
 *
 * Trigger path: users/{userId}
 * Persisted field: contratante.nomeExibicao
 */
export const syncContractorDisplayName = onDocumentWritten(
  "users/{userId}",
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;

    const userData = asRecord(after.data());
    const profileType = firstNonEmptyString([
      userData.tipo_perfil,
      userData.tipoPerfil,
    ]);
    if (profileType !== CONTRACTOR_PROFILE_TYPE) return;

    const fullName = firstNonEmptyString([userData.nome]);
    if (!fullName) return;

    const contractorData = asRecord(userData.contratante);
    const expectedDisplayName = buildShortPersonName(fullName);
    if (!expectedDisplayName) return;

    const currentDisplayName = firstNonEmptyString([
      contractorData.nomeExibicao,
    ]);
    if (currentDisplayName === expectedDisplayName) return;

    await after.ref.set({
      contratante: {
        ...contractorData,
        nomeExibicao: expectedDisplayName,
      },
    }, {merge: true});

    console.log(
      `[users] synced contractor display name for ${event.params.userId}: ` +
      `${expectedDisplayName}`
    );
  }
);

/**
 * Backfills `contratante.nomeExibicao` for legacy contractor users.
 *
 * URL: https://us-central1-<project-id>.cloudfunctions.net/backfillContractorDisplayNames
 * Method: POST
 * Header: x-migration-token: <MIGRATION_TOKEN>
 * Optional:
 * - `dryRun=true` (query or JSON body)
 * - `limit=<n>` (query or JSON body) to cap processed users
 */
export const backfillContractorDisplayNames = onRequest(
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

    const dryRun = parseDryRun(req);
    const rawLimit =
      req.query.limit ??
      (req.body as Record<string, unknown> | null)?.limit;
    const limit = parsePositiveInt(rawLimit, 1000000, 1000000);

    const summary = {
      success: true,
      dryRun: dryRun,
      limit: limit,
      scanned: 0,
      wouldUpdate: 0,
      updated: 0,
      skippedNoName: 0,
      skippedAlreadyUpToDate: 0,
      errors: 0,
    };

    try {
      let cursor: FirebaseFirestore.QueryDocumentSnapshot | null = null;
      let shouldStop = false;

      while (!shouldStop) {
        let query = db
          .collection("users")
          .where("tipo_perfil", "==", CONTRACTOR_PROFILE_TYPE)
          .orderBy(admin.firestore.FieldPath.documentId())
          .limit(BACKFILL_PAGE_SIZE);

        if (cursor != null) {
          query = query.startAfter(cursor);
        }

        const snapshot = await query.get();
        if (snapshot.empty) break;

        let batch = db.batch();
        let pendingWrites = 0;

        for (const doc of snapshot.docs) {
          if (summary.scanned >= limit) {
            shouldStop = true;
            break;
          }

          summary.scanned++;
          const userData = asRecord(doc.data());
          const fullName = firstNonEmptyString([userData.nome]);
          if (!fullName) {
            summary.skippedNoName++;
            continue;
          }

          const expectedDisplayName = buildShortPersonName(fullName);
          if (!expectedDisplayName) {
            summary.skippedNoName++;
            continue;
          }

          const contractorData = asRecord(userData.contratante);
          const currentDisplayName = firstNonEmptyString([
            contractorData.nomeExibicao,
          ]);

          if (currentDisplayName === expectedDisplayName) {
            summary.skippedAlreadyUpToDate++;
            continue;
          }

          summary.wouldUpdate++;
          if (dryRun) {
            continue;
          }

          batch.set(doc.ref, {
            contratante: {
              ...contractorData,
              nomeExibicao: expectedDisplayName,
            },
          }, {merge: true});
          pendingWrites++;
          summary.updated++;

          if (pendingWrites >= BACKFILL_BATCH_SIZE) {
            await batch.commit();
            batch = db.batch();
            pendingWrites = 0;
          }
        }

        if (!dryRun && pendingWrites > 0) {
          await batch.commit();
        }

        cursor = snapshot.docs[snapshot.docs.length - 1];
        if (snapshot.size < BACKFILL_PAGE_SIZE) {
          break;
        }
      }

      console.log("[users] contractor display name backfill finished", summary);
      res.status(200).json(summary);
    } catch (error) {
      summary.success = false;
      summary.errors++;
      console.error("[users] contractor display name backfill failed", error);
      res.status(500).json({
        ...summary,
        error: (error as Error).message,
      });
    }
  }
);

/**
 * Callable function to securely delete a user's account and data.
 *
 * Flow:
 * 1. Ensure the user is authenticated.
 * 2. Fetch all user data from the `users` collection.
 * 3. Store the user data in a backup collection `deletedUsers`.
 * 4. Remove the user data from the `users` collection.
 * 5. Delete the user from Firebase Authentication.
 */
export const deleteAccount = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    enforceAppCheck: true,
    invoker: "public",
  },
  async (request) => {
    // 1. Ensure user is authenticated
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
      );
    }

    try {
      const userRef = db.collection("users").doc(uid);
      const userDoc = await userRef.get();

      // If user profile exists, back it up
      if (userDoc.exists) {
        const userData = userDoc.data() || {};

        // Add exact deletion timestamp metadata to the backup
        userData.deleted_at = admin.firestore.FieldValue.serverTimestamp();

        // 3. Keep a backup in "deletedUsers"
        await db.collection("deletedUsers").doc(uid).set(userData);

        // 4. Delete from Main Users collection
        await userRef.delete();
      }

      // 5. Delete from Firebase Authentication
      await admin.auth().deleteUser(uid);

      console.log(`User ${uid} successfully backed up and deleted.`);
      return {success: true};
    } catch (error) {
      console.error(`Error deleting user account with uid: ${uid}`, error);
      throw new HttpsError(
        "internal",
        "An error occurred while attempting to delete the account."
      );
    }
  }
);
