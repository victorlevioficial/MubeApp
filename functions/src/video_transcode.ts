import { onObjectFinalized } from "firebase-functions/v2/storage";
import * as admin from "firebase-admin";
import { getDownloadURL } from "firebase-admin/storage";
import {
  TranscoderServiceClient,
  protos,
} from "@google-cloud/video-transcoder";

const REGION = "southamerica-east1";
const TRANSCODER_LOCATION = process.env.TRANSCODER_LOCATION || "us-central1";
const TRANSCODED_ROOT = "gallery_videos_transcoded";
const TRANSCODED_FILE_NAME = "master.mp4";
const POLL_INTERVAL_MS = 5_000;
const MAX_WAIT_MS = 8 * 60 * 1_000;

const transcoderClient = new TranscoderServiceClient();
const JOB_STATE = protos.google.cloud.video.transcoder.v1.Job.ProcessingState;
const db = admin.firestore();

type JobState =
  protos.google.cloud.video.transcoder.v1.Job.ProcessingState |
  keyof typeof JOB_STATE |
  null |
  undefined;

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

function buildJobConfig(includeAudio: boolean):
protos.google.cloud.video.transcoder.v1.IJobConfig {
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

async function waitForJobCompletion(jobName: string):
Promise<protos.google.cloud.video.transcoder.v1.IJob> {
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

  const sectionKeys = [
    "dadosProfissional",
    "dadosBanda",
    "dadosEstudio",
    "dadosContratante",
  ];

  const updates: Record<string, unknown> = {};
  let touched = false;

  for (const sectionKey of sectionKeys) {
    const sectionData = userData[sectionKey];
    if (!isRecord(sectionData)) continue;

    const gallery = sectionData["gallery"];
    if (!Array.isArray(gallery)) continue;

    let sectionChanged = false;
    const updatedGallery = gallery.map((item) => {
      if (!isRecord(item)) return item;
      const itemId = String(item["id"] || "");
      const itemType = String(item["type"] || "");
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

export const onGalleryVideoUploaded = onObjectFinalized(
  {
    region: REGION,
    memory: "1GiB",
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
    const sourceGeneration = object.generation || "unknown";

    const transcodeRef = db.collection("mediaTranscodeJobs").doc(`${userId}_${mediaId}`);
    await transcodeRef.set({
      userId,
      mediaId,
      sourceObject: objectName,
      sourceGeneration,
      bucket: bucketName,
      status: "processing",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    try {
      const projectId = process.env.GCLOUD_PROJECT;
      if (!projectId) {
        throw new Error("Missing GCLOUD_PROJECT environment variable");
      }

      const parent = transcoderClient.locationPath(projectId, TRANSCODER_LOCATION);
      const inputUri = `gs://${bucketName}/${objectName}`;
      const outputPrefix = `${TRANSCODED_ROOT}/${userId}/${mediaId}`;
      const outputUri = `gs://${bucketName}/${outputPrefix}/`;

      const finishedJob = await transcodeWithFallback(parent, inputUri, outputUri);
      const outputPath = `${outputPrefix}/${TRANSCODED_FILE_NAME}`;
      const outputFile = admin.storage().bucket(bucketName).file(outputPath);

      const [exists] = await outputFile.exists();
      if (!exists) {
        throw new Error(`Transcoded output file was not found at ${outputPath}`);
      }

      const transcodedUrl = await getDownloadURL(outputFile);
      const applied = await applyTranscodedUrlToGallery(userId, mediaId, transcodedUrl);

      await transcodeRef.set({
        status: applied ? "succeeded" : "succeeded_without_gallery_update",
        transcodedObject: outputPath,
        transcodedUrl,
        transcoderJobName: finishedJob.name || null,
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      console.log(
        `Transcode done for user=${userId}, mediaId=${mediaId}, applied=${applied}`
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(
        `Transcode failed for user=${userId}, mediaId=${mediaId}:`,
        error
      );
      await transcodeRef.set({
        status: "failed",
        errorMessage: message,
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
  }
);
