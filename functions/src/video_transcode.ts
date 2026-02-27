import { onObjectFinalized } from "firebase-functions/v2/storage";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { getDownloadURL } from "firebase-admin/storage";
import {
  TranscoderServiceClient,
  protos,
} from "@google-cloud/video-transcoder";

const REGION = "us-central1";
const TRANSCODER_LOCATION = process.env.TRANSCODER_LOCATION || "us-central1";
const TRANSCODED_ROOT = "gallery_videos_transcoded";
const TRANSCODED_FILE_NAME = "master.mp4";
const POLL_INTERVAL_MS = 5_000;
const MAX_WAIT_MS = 8 * 60 * 1_000;
const DEFAULT_BACKFILL_LIMIT = 20;
const MAX_BACKFILL_LIMIT = 100;

const LEGACY_GALLERY_SECTION_KEYS = [
  "profissional",
  "banda",
  "estudio",
  "contratante",
] as const;

const MODERN_GALLERY_SECTION_KEYS = [
  "dadosProfissional",
  "dadosBanda",
  "dadosEstudio",
  "dadosContratante",
] as const;

const GALLERY_SECTION_KEYS = [
  ...LEGACY_GALLERY_SECTION_KEYS,
  ...MODERN_GALLERY_SECTION_KEYS,
] as const;

const transcoderClient = new TranscoderServiceClient();
const JOB_STATE = protos.google.cloud.video.transcoder.v1.Job.ProcessingState;
const db = admin.firestore();

type JobState =
  protos.google.cloud.video.transcoder.v1.Job.ProcessingState |
  keyof typeof JOB_STATE |
  null |
  undefined;

interface ProcessVideoTranscodeParams {
  userId: string;
  mediaId: string;
  sourceObject: string;
  sourceGeneration: string;
  bucketName: string;
}

interface BackfillVideoItem {
  mediaId: string;
  currentUrl: string;
}

interface BackfillStats {
  usersScanned: number;
  usersWithVideos: number;
  videosDiscovered: number;
  alreadyTranscodedUrl: number;
  alreadyTranscodedFile: number;
  updatedFromExistingFile: number;
  galleryNotFoundForExisting: number;
  missingSource: number;
  wouldTranscode: number;
  transcodeTriggered: number;
  transcodeFailures: number;
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function hasState(
  state: JobState,
  expectedEnumValue: number,
  expectedLabel: string
): boolean {
  return state === expectedEnumValue || state === expectedLabel;
}

function isAudioRelatedFailure(errorMessage: string): boolean {
  const lower = errorMessage.toLowerCase();
  return lower.includes("audio") || lower.includes("aac");
}

function assertAdmin(context: {
  auth?: { token?: Record<string, unknown> };
}): void {
  if (!context.auth || !context.auth.token?.admin) {
    throw new HttpsError(
      "permission-denied",
      "Acesso restrito a administradores."
    );
  }
}

function parseBackfillLimit(raw: unknown): number {
  const parsed = Number(raw);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return DEFAULT_BACKFILL_LIMIT;
  }

  return Math.min(Math.floor(parsed), MAX_BACKFILL_LIMIT);
}

function parseStartAfterUserId(raw: unknown): string | null {
  if (typeof raw !== "string") {
    return null;
  }

  const trimmed = raw.trim();
  return trimmed.length > 0 ? trimmed : null;
}

function buildSourceObjectPath(userId: string, mediaId: string): string {
  return `gallery_videos/${userId}/${mediaId}.mp4`;
}

function buildTranscodedObjectPath(userId: string, mediaId: string): string {
  return `${TRANSCODED_ROOT}/${userId}/${mediaId}/${TRANSCODED_FILE_NAME}`;
}

function isTranscodedUrl(url: string): boolean {
  const normalized = url.toLowerCase();
  return (
    normalized.includes("/gallery_videos_transcoded/") ||
    normalized.includes("%2fgallery_videos_transcoded%2f") ||
    normalized.includes("gallery_videos_transcoded%2f")
  );
}

function extractGalleryVideoItems(
  userData: Record<string, unknown>
): BackfillVideoItem[] {
  const uniqueItems = new Map<string, string>();

  for (const sectionKey of GALLERY_SECTION_KEYS) {
    const sectionData = userData[sectionKey];
    if (!isRecord(sectionData)) {
      continue;
    }

    const gallery = sectionData["gallery"];
    if (!Array.isArray(gallery)) {
      continue;
    }

    for (const rawItem of gallery) {
      if (!isRecord(rawItem)) {
        continue;
      }

      const mediaId = String(rawItem["id"] || "").trim();
      const itemType = String(rawItem["type"] || "").trim().toLowerCase();
      const currentUrl = String(rawItem["url"] || "");

      if (!mediaId || itemType !== "video") {
        continue;
      }

      const previousUrl = uniqueItems.get(mediaId);
      if (previousUrl === undefined || previousUrl.length === 0) {
        uniqueItems.set(mediaId, currentUrl);
      }
    }
  }

  return Array.from(uniqueItems.entries()).map(([mediaId, currentUrl]) => ({
    mediaId,
    currentUrl,
  }));
}

function buildJobConfig(
  includeAudio: boolean
): protos.google.cloud.video.transcoder.v1.IJobConfig {
  const elementaryStreams: protos.google.cloud.video.transcoder.v1.IElementaryStream[] = [
    {
      key: "video-stream0",
      videoStream: {
        h264: {
          profile: "high",
          widthPixels: 1280,
          heightPixels: 720,
          bitrateBps: 2_500_000,
          frameRate: 30,
          pixelFormat: "yuv420p",
        },
      },
    },
  ];

  const muxElementaryStreamKeys = ["video-stream0"];
  if (includeAudio) {
    elementaryStreams.push({
      key: "audio-stream0",
      audioStream: {
        codec: "aac",
        bitrateBps: 128_000,
        sampleRateHertz: 48_000,
      },
    });
    muxElementaryStreamKeys.push("audio-stream0");
  }

  return {
    elementaryStreams,
    muxStreams: [
      {
        key: "sd",
        container: "mp4",
        fileName: TRANSCODED_FILE_NAME,
        elementaryStreams: muxElementaryStreamKeys,
      },
    ],
  };
}

async function waitForJobCompletion(
  jobName: string
): Promise<protos.google.cloud.video.transcoder.v1.IJob> {
  const deadline = Date.now() + MAX_WAIT_MS;
  while (Date.now() < deadline) {
    const [job] = await transcoderClient.getJob({ name: jobName });
    const state = job.state as JobState;

    if (hasState(state, JOB_STATE.SUCCEEDED, "SUCCEEDED")) {
      return job;
    }

    if (hasState(state, JOB_STATE.FAILED, "FAILED")) {
      const reason = job.error?.message || "unknown-transcoder-error";
      throw new Error(`Transcoder job failed: ${reason}`);
    }

    await sleep(POLL_INTERVAL_MS);
  }

  throw new Error(
    `Transcoder job timeout after ${Math.floor(MAX_WAIT_MS / 1000)} seconds`
  );
}

async function submitAndAwaitJob(
  parent: string,
  inputUri: string,
  outputUri: string,
  includeAudio: boolean
): Promise<protos.google.cloud.video.transcoder.v1.IJob> {
  const [job] = await transcoderClient.createJob({
    parent,
    job: {
      inputUri,
      outputUri,
      config: buildJobConfig(includeAudio),
    },
  });

  if (!job.name) {
    throw new Error("Transcoder job was created without a name");
  }

  return waitForJobCompletion(job.name);
}

async function transcodeWithFallback(
  parent: string,
  inputUri: string,
  outputUri: string
): Promise<protos.google.cloud.video.transcoder.v1.IJob> {
  try {
    return await submitAndAwaitJob(parent, inputUri, outputUri, true);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (!isAudioRelatedFailure(message)) {
      throw error;
    }

    console.warn(
      "Audio pipeline failed, retrying transcode without audio stream.",
      message
    );
    return submitAndAwaitJob(parent, inputUri, outputUri, false);
  }
}

async function applyTranscodedUrlToGallery(
  userId: string,
  mediaId: string,
  transcodedUrl: string
): Promise<boolean> {
  const userRef = db.collection("users").doc(userId);
  const userSnap = await userRef.get();

  if (!userSnap.exists) {
    console.warn(`User document not found for ${userId}`);
    return false;
  }

  const userData = userSnap.data();
  if (!userData) {
    return false;
  }

  const updates: Record<string, unknown> = {};
  let touched = false;

  for (const sectionKey of GALLERY_SECTION_KEYS) {
    const sectionData = userData[sectionKey];
    if (!isRecord(sectionData)) {
      continue;
    }

    const gallery = sectionData["gallery"];
    if (!Array.isArray(gallery)) {
      continue;
    }

    let sectionChanged = false;
    const updatedGallery = gallery.map((item) => {
      if (!isRecord(item)) {
        return item;
      }

      const itemId = String(item["id"] || "").trim();
      const itemType = String(item["type"] || "").trim().toLowerCase();
      if (itemId !== mediaId || itemType !== "video") {
        return item;
      }

      sectionChanged = true;
      return {
        ...item,
        url: transcodedUrl,
      };
    });

    if (sectionChanged) {
      updates[`${sectionKey}.gallery`] = updatedGallery;
      touched = true;
    }
  }

  if (!touched) {
    console.warn(
      `Gallery entry not found while applying transcoded URL: user=${userId}, mediaId=${mediaId}`
    );
    return false;
  }

  updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
  await userRef.update(updates);
  return true;
}

async function getExistingTranscodedDownloadUrl(
  bucketName: string,
  userId: string,
  mediaId: string
): Promise<string | null> {
  const outputPath = buildTranscodedObjectPath(userId, mediaId);
  const outputFile = admin.storage().bucket(bucketName).file(outputPath);
  const [exists] = await outputFile.exists();

  if (!exists) {
    return null;
  }

  return getDownloadURL(outputFile);
}

async function processVideoTranscode(
  params: ProcessVideoTranscodeParams
): Promise<{ applied: boolean; transcodedUrl: string }> {
  const { userId, mediaId, sourceObject, sourceGeneration, bucketName } = params;

  const transcodeRef = db.collection("mediaTranscodeJobs").doc(`${userId}_${mediaId}`);
  await transcodeRef.set(
    {
      userId,
      mediaId,
      sourceObject,
      sourceGeneration,
      bucket: bucketName,
      status: "processing",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  try {
    const outputPath = buildTranscodedObjectPath(userId, mediaId);
    const outputPrefix = `${TRANSCODED_ROOT}/${userId}/${mediaId}`;
    const outputUri = `gs://${bucketName}/${outputPrefix}/`;
    const outputFile = admin.storage().bucket(bucketName).file(outputPath);

    let transcoderJobName: string | null = null;
    const [alreadyExists] = await outputFile.exists();

    if (!alreadyExists) {
      const projectId = process.env.GCLOUD_PROJECT;
      if (!projectId) {
        throw new Error("Missing GCLOUD_PROJECT environment variable");
      }

      const parent = transcoderClient.locationPath(projectId, TRANSCODER_LOCATION);
      const inputUri = `gs://${bucketName}/${sourceObject}`;
      const finishedJob = await transcodeWithFallback(parent, inputUri, outputUri);
      transcoderJobName = finishedJob.name || null;
    }

    const [existsAfter] = await outputFile.exists();
    if (!existsAfter) {
      throw new Error(`Transcoded output file was not found at ${outputPath}`);
    }

    const transcodedUrl = await getDownloadURL(outputFile);
    const applied = await applyTranscodedUrlToGallery(userId, mediaId, transcodedUrl);

    await transcodeRef.set(
      {
        status: applied ? "succeeded" : "succeeded_without_gallery_update",
        transcodedObject: outputPath,
        transcodedUrl,
        transcoderJobName,
        errorMessage: admin.firestore.FieldValue.delete(),
        failedAt: admin.firestore.FieldValue.delete(),
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { applied, transcodedUrl };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);

    await transcodeRef.set(
      {
        status: "failed",
        errorMessage: message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    throw error;
  }
}

export const onGalleryVideoUploaded = onObjectFinalized(
  {
    region: REGION,
    memory: "512MiB",
    maxInstances: 1,
    timeoutSeconds: 540,
    retry: false,
  },
  async (event) => {
    const object = event.data;
    const objectName = object.name;
    const bucketName = object.bucket;

    if (!objectName || !bucketName) {
      console.log("Storage event without object name/bucket; skipping.");
      return;
    }

    const pathMatch = objectName.match(/^gallery_videos\/([^/]+)\/([^/]+)\.mp4$/);
    if (!pathMatch) {
      return;
    }

    if (object.metadata?.transcoded === "true") {
      console.log("Skipping already transcoded object:", objectName);
      return;
    }

    const userId = pathMatch[1];
    const mediaId = pathMatch[2];
    const sourceGeneration = object.generation ?
      String(object.generation) :
      "unknown";

    try {
      const result = await processVideoTranscode({
        userId,
        mediaId,
        sourceObject: objectName,
        sourceGeneration,
        bucketName,
      });

      console.log(
        `Transcode done for user=${userId}, mediaId=${mediaId}, applied=${result.applied}`
      );
    } catch (error) {
      console.error(
        `Transcode failed for user=${userId}, mediaId=${mediaId}:`,
        error
      );
    }
  }
);

export const backfillGalleryVideoTranscodes = onCall(
  {
    region: REGION,
    memory: "512MiB",
    maxInstances: 1,
    timeoutSeconds: 540,
    invoker: "public",
  },
  async (request) => {
    assertAdmin(request);

    const data = isRecord(request.data) ? request.data : {};
    const limit = parseBackfillLimit(data.limit);
    const startAfterUserId = parseStartAfterUserId(data.startAfterUserId);
    const dryRun = data.dryRun === true;

    let userQuery: FirebaseFirestore.Query<FirebaseFirestore.DocumentData> = db
      .collection("users")
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(limit);

    if (startAfterUserId) {
      userQuery = userQuery.startAfter(startAfterUserId);
    }

    const userSnapshot = await userQuery.get();
    const defaultBucket = admin.storage().bucket();
    const bucketName = defaultBucket.name;

    const stats: BackfillStats = {
      usersScanned: 0,
      usersWithVideos: 0,
      videosDiscovered: 0,
      alreadyTranscodedUrl: 0,
      alreadyTranscodedFile: 0,
      updatedFromExistingFile: 0,
      galleryNotFoundForExisting: 0,
      missingSource: 0,
      wouldTranscode: 0,
      transcodeTriggered: 0,
      transcodeFailures: 0,
    };

    const failures: Array<{ userId: string; mediaId: string; error: string }> = [];

    for (const userDoc of userSnapshot.docs) {
      stats.usersScanned += 1;

      const userId = userDoc.id;
      const userData = userDoc.data();
      if (!isRecord(userData)) {
        continue;
      }

      const videoItems = extractGalleryVideoItems(userData);
      if (videoItems.length === 0) {
        continue;
      }

      stats.usersWithVideos += 1;
      stats.videosDiscovered += videoItems.length;

      for (const videoItem of videoItems) {
        const mediaId = videoItem.mediaId;

        if (isTranscodedUrl(videoItem.currentUrl)) {
          stats.alreadyTranscodedUrl += 1;
          continue;
        }

        const existingUrl = await getExistingTranscodedDownloadUrl(
          bucketName,
          userId,
          mediaId
        );

        if (existingUrl) {
          stats.alreadyTranscodedFile += 1;

          if (!dryRun) {
            const applied = await applyTranscodedUrlToGallery(
              userId,
              mediaId,
              existingUrl
            );
            if (applied) {
              stats.updatedFromExistingFile += 1;
            } else {
              stats.galleryNotFoundForExisting += 1;
            }
          }

          continue;
        }

        const sourceObject = buildSourceObjectPath(userId, mediaId);
        const sourceFile = defaultBucket.file(sourceObject);
        const [sourceExists] = await sourceFile.exists();

        if (!sourceExists) {
          stats.missingSource += 1;
          continue;
        }

        if (dryRun) {
          stats.wouldTranscode += 1;
          continue;
        }

        try {
          await processVideoTranscode({
            userId,
            mediaId,
            sourceObject,
            sourceGeneration: "backfill",
            bucketName,
          });
          stats.transcodeTriggered += 1;
        } catch (error) {
          stats.transcodeFailures += 1;

          if (failures.length < 50) {
            failures.push({
              userId,
              mediaId,
              error: error instanceof Error ? error.message : String(error),
            });
          }
        }
      }
    }

    const nextCursor = userSnapshot.empty ?
      null :
      userSnapshot.docs[userSnapshot.docs.length - 1].id;

    return {
      ...stats,
      dryRun,
      requestedLimit: limit,
      startAfterUserId,
      nextCursor,
      hasMore: userSnapshot.size === limit,
      failures,
    };
  }
);
