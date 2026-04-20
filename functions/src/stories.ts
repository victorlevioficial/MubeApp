import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onObjectFinalized} from "firebase-functions/v2/storage";
import * as admin from "firebase-admin";
import {getDownloadURL} from "firebase-admin/storage";
import {
  TranscoderServiceClient,
  protos,
} from "@google-cloud/video-transcoder";

const REGION = "southamerica-east1";
const TRANSCODER_LOCATION = process.env.TRANSCODER_LOCATION || "us-central1";
const STORY_VIDEO_TRIGGER_REGION =
  process.env.STORY_VIDEO_TRIGGER_REGION || "us-central1";
const STORY_TIMEZONE = "America/Sao_Paulo";
const MAX_STORIES_PER_DAY = 3;
const MAX_VIDEO_DURATION_SECONDS = 15;
const MAX_VERTICAL_ASPECT_RATIO = 0.75;
const STORY_LIFETIME_MS = 24 * 60 * 60 * 1000;
const EXPIRE_BATCH_SIZE = 100;
const TRANSCODE_POLL_INTERVAL_MS = 5_000;
const TRANSCODE_TIMEOUT_MS = 8 * 60 * 1_000;
const TRANSCODED_FILE_NAME = "master.mp4";
const VIDEO_JOB_STATE =
  protos.google.cloud.video.transcoder.v1.Job.ProcessingState;

const db = admin.firestore();
const transcoderClient = new TranscoderServiceClient();

type JobState =
  protos.google.cloud.video.transcoder.v1.Job.ProcessingState |
  keyof typeof VIDEO_JOB_STATE |
  null |
  undefined;

interface StoryOwnerData {
  ownerName: string;
  ownerPhoto: string | null;
  ownerPhotoPreview: string | null;
  ownerType: string;
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value) ? value as Record<string, unknown> : {};
}

function firstNonEmptyString(
  values: unknown[],
  fallback = ""
): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }

  return fallback;
}

function parseOptionalString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length > 0 ? normalized : null;
}

function parseRequiredString(value: unknown, fieldName: string): string {
  const normalized = parseOptionalString(value);
  if (normalized == null) {
    throw new HttpsError("invalid-argument", `${fieldName} e obrigatorio.`);
  }

  return normalized;
}

function parseOptionalNumber(value: unknown): number | null {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    return null;
  }

  return value;
}

function isSucceededState(state: JobState): boolean {
  return state === VIDEO_JOB_STATE.SUCCEEDED || state === "SUCCEEDED";
}

function isFailedState(state: JobState): boolean {
  return state === VIDEO_JOB_STATE.FAILED || state === "FAILED";
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function buildStoryDayKey(date: Date): string {
  return new Intl.DateTimeFormat(
    "en-CA",
    {
      timeZone: STORY_TIMEZONE,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
    }
  ).format(date);
}

function resolveStoryOwnerData(userData: Record<string, unknown>): StoryOwnerData {
  const tipoPerfil = firstNonEmptyString(
    [userData.tipo_perfil, userData.tipoPerfil],
    "profissional"
  );
  const profissional = asRecord(userData.profissional);
  const banda = asRecord(userData.banda);
  const estudio = asRecord(userData.estudio);
  const contratante = asRecord(userData.contratante);

  const ownerName = (() => {
    switch (tipoPerfil) {
    case "banda":
      return firstNonEmptyString(
        [banda.nomeBanda, banda.nomeArtistico, userData.nome],
        "Banda"
      );
    case "estudio":
      return firstNonEmptyString(
        [estudio.nomeEstudio, estudio.nomeArtistico, userData.nome],
        "Estudio"
      );
    case "contratante":
      return firstNonEmptyString(
        [contratante.nomeExibicao, userData.nome],
        "Contratante"
      );
    default:
      return firstNonEmptyString(
        [profissional.nomeArtistico, userData.nome_artistico, userData.nome],
        "Profissional"
      );
    }
  })();

  return {
    ownerName,
    ownerPhoto: parseOptionalString(userData.foto),
    ownerPhotoPreview: parseOptionalString(userData.foto_thumb),
    ownerType: tipoPerfil,
  };
}

function validateStoryPayload(data: Record<string, unknown>): {
  storyId: string;
  mediaType: "image" | "video";
  mediaUrl: string;
  thumbnailUrl: string | null;
  caption: string | null;
  durationSeconds: number | null;
  aspectRatio: number | null;
} {
  const storyId = parseRequiredString(data.storyId, "storyId");
  const mediaTypeRaw = parseRequiredString(data.mediaType, "mediaType");
  const mediaType = mediaTypeRaw === "video" ? "video" :
    mediaTypeRaw === "image" ? "image" : null;

  if (mediaType == null) {
    throw new HttpsError(
      "invalid-argument",
      "mediaType precisa ser image ou video."
    );
  }

  const mediaUrl = parseRequiredString(data.mediaUrl, "mediaUrl");
  const thumbnailUrl = parseOptionalString(data.thumbnailUrl);
  const caption = parseOptionalString(data.caption);
  const durationSeconds = parseOptionalNumber(data.durationSeconds);
  const aspectRatio = parseOptionalNumber(data.aspectRatio);

  if (mediaType === "video") {
    if (durationSeconds == null || durationSeconds <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "durationSeconds e obrigatorio para video."
      );
    }

    if (durationSeconds > MAX_VIDEO_DURATION_SECONDS) {
      throw new HttpsError(
        "invalid-argument",
        "O video do story pode ter no maximo 15 segundos."
      );
    }

    if (
      aspectRatio == null ||
      aspectRatio <= 0 ||
      aspectRatio > MAX_VERTICAL_ASPECT_RATIO
    ) {
      throw new HttpsError(
        "invalid-argument",
        "O video do story precisa ser vertical."
      );
    }
  }

  return {
    storyId,
    mediaType,
    mediaUrl,
    thumbnailUrl,
    caption,
    durationSeconds,
    aspectRatio,
  };
}

function ensureStoryMediaOwnership(
  mediaUrl: string,
  uid: string,
  storyId: string,
  mediaType: "image" | "video"
): void {
  const normalizedUrl = decodeURIComponent(mediaUrl).toLowerCase();
  const expectedRoot = mediaType === "image" ?
    `stories_images/${uid}/${storyId}/` :
    `stories_videos_source/${uid}/${storyId}/`;

  if (!normalizedUrl.includes(expectedRoot.toLowerCase())) {
    throw new HttpsError(
      "permission-denied",
      "A midia do story nao pertence ao usuario autenticado."
    );
  }
}

function ensureStoryThumbnailOwnership(
  thumbnailUrl: string | null,
  uid: string,
  storyId: string,
  mediaType: "image" | "video"
): void {
  if (!thumbnailUrl) {
    return;
  }

  const normalizedUrl = decodeURIComponent(thumbnailUrl).toLowerCase();
  const expectedRoot = mediaType === "image" ?
    `stories_images/${uid}/${storyId}/` :
    `stories_videos_thumbs/${uid}/${storyId}/`;

  if (!normalizedUrl.includes(expectedRoot.toLowerCase())) {
    throw new HttpsError(
      "permission-denied",
      "A thumbnail do story nao pertence ao usuario autenticado."
    );
  }
}

async function recomputeStoryState(ownerUid: string): Promise<void> {
  const snapshot = await db
    .collection("stories")
    .where("owner_uid", "==", ownerUid)
    .where("status", "==", "active")
    .orderBy("created_at", "desc")
    .limit(10)
    .get();

  const now = Date.now();
  const activeStories = snapshot.docs.filter((doc) => {
    const expiresAt = doc.data().expires_at;
    return expiresAt instanceof admin.firestore.Timestamp &&
      expiresAt.toMillis() > now;
  });

  const latestStory = activeStories[0]?.data();
  await db.collection("users").doc(ownerUid).set({
    story_state: {
      has_active_story: activeStories.length > 0,
      latest_story_id: activeStories[0]?.id ?? null,
      latest_story_at: latestStory?.created_at ?? null,
      latest_story_thumbnail: latestStory?.thumbnail_url ?? null,
      active_story_count: activeStories.length,
    },
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});
}

async function deleteStoryStorageObjects(
  ownerUid: string,
  storyId: string
): Promise<void> {
  const bucket = admin.storage().bucket();
  const prefixes = [
    `stories_images/${ownerUid}/${storyId}/`,
    `stories_videos_source/${ownerUid}/${storyId}/`,
    `stories_videos_master/${ownerUid}/${storyId}/`,
    `stories_videos_thumbs/${ownerUid}/${storyId}/`,
  ];

  await Promise.allSettled(
    prefixes.map((prefix) => bucket.deleteFiles({prefix, force: true}))
  );
}

async function waitForJobCompletion(
  jobName: string
): Promise<protos.google.cloud.video.transcoder.v1.IJob> {
  const deadline = Date.now() + TRANSCODE_TIMEOUT_MS;
  while (Date.now() < deadline) {
    const [job] = await transcoderClient.getJob({name: jobName});
    if (isSucceededState(job.state as JobState)) {
      return job;
    }

    if (isFailedState(job.state as JobState)) {
      throw new Error(job.error?.message || "Story video transcode failed.");
    }

    await sleep(TRANSCODE_POLL_INTERVAL_MS);
  }

  throw new Error("Story video transcode timed out.");
}

function isAudioRelatedFailure(errorMessage: string): boolean {
  const lower = errorMessage.toLowerCase();
  return lower.includes("audio") || lower.includes("aac");
}

function buildStoryTranscodeConfig(
  includeAudio: boolean
): protos.google.cloud.video.transcoder.v1.IJobConfig {
  const elementaryStreams: protos.google.cloud.video.transcoder.v1.IElementaryStream[] = [
    {
      key: "video-stream0",
      videoStream: {
        h264: {
          profile: "high",
          heightPixels: 1280,
          bitrateBps: 3_000_000,
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
        key: "story-master",
        container: "mp4",
        fileName: TRANSCODED_FILE_NAME,
        elementaryStreams: muxElementaryStreamKeys,
      },
    ],
  };
}

async function submitAndAwaitStoryTranscodeJob(
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
      config: buildStoryTranscodeConfig(includeAudio),
    },
  });

  if (!job.name) {
    throw new Error("Story transcode job was created without a name.");
  }

  return waitForJobCompletion(job.name);
}

async function transcodeStoryVideoWithFallback(
  parent: string,
  inputUri: string,
  outputUri: string
): Promise<protos.google.cloud.video.transcoder.v1.IJob> {
  try {
    return await submitAndAwaitStoryTranscodeJob(
      parent,
      inputUri,
      outputUri,
      true
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (!isAudioRelatedFailure(message)) {
      throw error;
    }

    console.warn(
      "Story audio pipeline failed, retrying transcode without audio stream.",
      message
    );
    return submitAndAwaitStoryTranscodeJob(
      parent,
      inputUri,
      outputUri,
      false
    );
  }
}

async function createStoryTranscodeJob(
  bucketName: string,
  uid: string,
  storyId: string
): Promise<string | null> {
  const projectId = process.env.GCLOUD_PROJECT;
  if (!projectId) {
    throw new Error("Missing GCLOUD_PROJECT environment variable.");
  }

  const parent = transcoderClient.locationPath(projectId, TRANSCODER_LOCATION);
  const inputUri = `gs://${bucketName}/stories_videos_source/${uid}/${storyId}/source.mp4`;
  const outputUri = `gs://${bucketName}/stories_videos_master/${uid}/${storyId}/`;

  const job = await transcodeStoryVideoWithFallback(parent, inputUri, outputUri);
  return job.name ?? null;
}

export const publishStory = onCall(
  {
    region: REGION,
    memory: "256MiB",
    maxInstances: 10,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Usuario nao autenticado.");
    }

    const payload = validateStoryPayload(asRecord(request.data));
    ensureStoryMediaOwnership(payload.mediaUrl, uid, payload.storyId, payload.mediaType);
    ensureStoryThumbnailOwnership(
      payload.thumbnailUrl,
      uid,
      payload.storyId,
      payload.mediaType
    );

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("failed-precondition", "Perfil do usuario nao encontrado.");
    }

    const userData = userDoc.data() || {};
    const accountStatus = firstNonEmptyString([userData.status], "ativo");

    if (accountStatus === "suspenso") {
      throw new HttpsError(
        "permission-denied",
        "Sua conta nao pode publicar stories neste momento."
      );
    }

    const now = new Date();
    const dayKey = buildStoryDayKey(now);
    const ownerData = resolveStoryOwnerData(userData);
    const dayStories = await db
      .collection("stories")
      .where("owner_uid", "==", uid)
      .where("published_day_key", "==", dayKey)
      .where("status", "in", ["active", "processing"])
      .limit(MAX_STORIES_PER_DAY)
      .get();

    if (dayStories.size >= MAX_STORIES_PER_DAY) {
      throw new HttpsError(
        "resource-exhausted",
        "Voce atingiu o limite diario de 3 stories."
      );
    }

    const createdAt = admin.firestore.Timestamp.now();
    const expiresAt = admin.firestore.Timestamp.fromDate(
      new Date(now.getTime() + STORY_LIFETIME_MS)
    );
    const status = payload.mediaType === "video" ? "processing" : "active";

    await db.collection("stories").doc(payload.storyId).set({
      id: payload.storyId,
      owner_uid: uid,
      owner_name: ownerData.ownerName,
      owner_photo: ownerData.ownerPhoto,
      owner_photo_preview: ownerData.ownerPhotoPreview,
      owner_type: ownerData.ownerType,
      media_type: payload.mediaType,
      media_url: payload.mediaUrl,
      thumbnail_url: payload.thumbnailUrl,
      caption: payload.caption,
      status,
      created_at: createdAt,
      expires_at: expiresAt,
      published_day_key: dayKey,
      duration_seconds: payload.durationSeconds,
      aspect_ratio: payload.aspectRatio,
      viewers_count: 0,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    if (status === "active") {
      await recomputeStoryState(uid);
    }

    return {
      storyId: payload.storyId,
      status,
      expiresAt: expiresAt.toMillis(),
    };
  }
);

export const deleteStory = onCall(
  {
    region: REGION,
    memory: "256MiB",
    maxInstances: 10,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Usuario nao autenticado.");
    }

    const storyId = parseRequiredString(asRecord(request.data).storyId, "storyId");
    const storyRef = db.collection("stories").doc(storyId);
    const storyDoc = await storyRef.get();

    if (!storyDoc.exists) {
      throw new HttpsError("not-found", "Story nao encontrado.");
    }

    const storyData = storyDoc.data() || {};
    if (storyData.owner_uid !== uid) {
      throw new HttpsError(
        "permission-denied",
        "Apenas o autor pode excluir este story."
      );
    }

    await storyRef.set({
      status: "deleted",
      deleted_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    await deleteStoryStorageObjects(uid, storyId);
    await recomputeStoryState(uid);

    return {storyId, deleted: true};
  }
);

export const onStoryViewed = onDocumentCreated(
  {
    document: "stories/{storyId}/views/{viewerUid}",
    region: REGION,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const storyId = event.params.storyId as string;
    const viewerUid = event.params.viewerUid as string;
    const storyRef = db.collection("stories").doc(storyId);
    const storyDoc = await storyRef.get();

    if (!storyDoc.exists) return;
    const storyData = storyDoc.data() || {};
    const ownerUid = firstNonEmptyString([storyData.owner_uid]);
    if (!ownerUid || ownerUid === viewerUid) return;

    const viewData = snapshot.data();
    const viewedAt = viewData.viewed_at instanceof admin.firestore.Timestamp ?
      viewData.viewed_at :
      admin.firestore.Timestamp.now();

    await db.runTransaction(async (transaction) => {
      const currentStoryDoc = await transaction.get(storyRef);
      if (!currentStoryDoc.exists) return;

      const currentViewers = currentStoryDoc.data()?.viewers_count;
      const viewersCount = typeof currentViewers === "number" &&
        Number.isFinite(currentViewers) ? currentViewers : 0;

      transaction.set(storyRef, {
        viewers_count: viewersCount + 1,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      transaction.set(
        db
          .collection("users")
          .doc(viewerUid)
          .collection("story_seen_authors")
          .doc(ownerUid),
        {
          owner_uid: ownerUid,
          last_seen_story_id: storyId,
          last_seen_at: viewedAt,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );
    });
  }
);

export const expireStories = onSchedule(
  {
    schedule: "*/15 * * * *",
    region: REGION,
    memory: "512MiB",
    timeoutSeconds: 540,
    concurrency: 1,
  },
  async () => {
    const now = admin.firestore.Timestamp.now();

    for (;;) {
      const snapshot = await db
        .collection("stories")
        .where("status", "in", ["active", "processing"])
        .where("expires_at", "<=", now)
        .limit(EXPIRE_BATCH_SIZE)
        .get();

      if (snapshot.empty) {
        break;
      }

      const batch = db.batch();
      const ownerIds = new Set<string>();
      const cleanupTargets: Array<{ownerUid: string; storyId: string}> = [];

      for (const doc of snapshot.docs) {
        const data = doc.data();
        const ownerUid = firstNonEmptyString([data.owner_uid]);
        if (ownerUid) {
          ownerIds.add(ownerUid);
          cleanupTargets.push({ownerUid, storyId: doc.id});
        }

        batch.set(doc.ref, {
          status: "expired",
          expired_at: admin.firestore.FieldValue.serverTimestamp(),
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        }, {merge: true});
      }

      await batch.commit();
      await Promise.allSettled(
        cleanupTargets.map((target) =>
          deleteStoryStorageObjects(target.ownerUid, target.storyId)
        )
      );
      await Promise.all(Array.from(ownerIds, (ownerUid) => recomputeStoryState(ownerUid)));
    }
  }
);

export const onStoryVideoUploaded = onObjectFinalized(
  {
    // Keep the story video worker close to the default bucket/event region.
    // This avoids exhausting Cloud Run CPU quota in southamerica-east1 and
    // matches the region already used by the gallery video transcode worker.
    region: STORY_VIDEO_TRIGGER_REGION,
    memory: "512MiB",
    timeoutSeconds: 540,
    maxInstances: 1,
    retry: false,
  },
  async (event) => {
    const object = event.data;
    const objectName = object.name;
    const bucketName = object.bucket;
    if (!objectName || !bucketName) return;

    const match = objectName.match(
      /^stories_videos_source\/([^/]+)\/([^/]+)\/source\.mp4$/
    );
    if (!match) return;

    const uid = match[1];
    const storyId = match[2];
    const storyRef = db.collection("stories").doc(storyId);

    try {
      const storyDeadline = Date.now() + 15_000;
      let storyDoc = await storyRef.get();

      while (
        Date.now() < storyDeadline &&
        (!storyDoc.exists || storyDoc.data()?.status === "processing")
      ) {
        const storyData = storyDoc.data() || {};
        if (
          storyDoc.exists &&
          storyData.owner_uid === uid &&
          storyData.status === "processing"
        ) {
          break;
        }

        if (storyDoc.exists && storyData.owner_uid !== uid) {
          await deleteStoryStorageObjects(uid, storyId);
          console.warn(
            `Story ${storyId} ignored because it belongs to a different owner.`
          );
          return;
        }

        await sleep(500);
        storyDoc = await storyRef.get();
      }

      const storyData = storyDoc.data() || {};
      if (!storyDoc.exists || storyData.owner_uid !== uid) {
        await deleteStoryStorageObjects(uid, storyId);
        console.warn(`Story ${storyId} ignored because it has no processing doc.`);
        return;
      }

      if (storyData.status !== "processing") {
        return;
      }

      const transcoderJobName = await createStoryTranscodeJob(bucketName, uid, storyId);
      const outputFile = admin.storage().bucket(bucketName).file(
        `stories_videos_master/${uid}/${storyId}/${TRANSCODED_FILE_NAME}`
      );
      const mediaUrl = await getDownloadURL(outputFile);
      let thumbnailUrl: string | null = null;

      try {
        const thumbFile = admin.storage().bucket(bucketName).file(
          `stories_videos_thumbs/${uid}/${storyId}/thumb.webp`
        );
        thumbnailUrl = await getDownloadURL(thumbFile);
      } catch (error) {
        console.warn("Story thumbnail not found after video upload.", error);
      }

      await db.collection("stories").doc(storyId).set({
        media_url: mediaUrl,
        thumbnail_url: thumbnailUrl,
        status: "active",
        transcoder_job_name: transcoderJobName,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      await recomputeStoryState(uid);
    } catch (error) {
      console.error(`Story transcode failed for ${storyId}:`, error);
      await db.collection("stories").doc(storyId).set({
        status: "deleted",
        processing_error: error instanceof Error ? error.message : String(error),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
      await recomputeStoryState(uid);
    }
  }
);
