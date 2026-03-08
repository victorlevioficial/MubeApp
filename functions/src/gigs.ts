import {
  onDocumentCreated,
  onDocumentDeleted,
  onDocumentUpdated,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import {FieldValue, Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();
const REGION = "southamerica-east1";
const GIGS_COLLECTION = "gigs";
const APPLICATIONS_COLLECTION = "gig_applications";
const USERS_COLLECTION = "users";
const NOTIFICATIONS_COLLECTION = "notifications";

function buildGigRoute(gigId: string): string {
  return `/gigs/${gigId}`;
}

function buildGigApplicantsRoute(gigId: string): string {
  return `/gigs/${gigId}/applicants`;
}

function buildGigReviewRoute(gigId: string, userId: string): string {
  return `/gigs/${gigId}/review/${userId}`;
}

function firstNonEmptyString(values: unknown[], fallback = ""): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }

  return fallback;
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value) ? value as Record<string, unknown> : {};
}

function shortenPersonName(fullName: string): string {
  const normalized = fullName.trim().replace(/\s+/g, " ");
  if (!normalized) return "";

  const parts = normalized.split(" ");
  if (parts.length <= 2) return normalized;

  const connectors = new Set(["de", "da", "do", "dos", "das", "e"]);
  const takeCount = connectors.has(parts[1].toLowerCase()) ? 3 : 2;
  return parts.slice(0, takeCount).join(" ");
}

function resolveUserDisplayName(data: Record<string, unknown>): string {
  const tipoPerfil = firstNonEmptyString([data.tipo_perfil, data.tipoPerfil]);
  const profissional = asRecord(data.profissional);
  const banda = asRecord(data.banda);
  const estudio = asRecord(data.estudio);
  const contratante = asRecord(data.contratante);

  switch (tipoPerfil) {
  case "profissional":
    return firstNonEmptyString([
      profissional.nomeArtistico,
      data.nome,
    ], "Profissional");
  case "banda":
    return firstNonEmptyString([
      banda.nomeBanda,
      banda.nomeArtistico,
      banda.nome,
      data.nome,
    ], "Banda");
  case "estudio":
    return firstNonEmptyString([
      estudio.nomeEstudio,
      estudio.nomeArtistico,
      estudio.nome,
      data.nome,
    ], "Estudio");
  case "contratante":
    return firstNonEmptyString([
      contratante.nomeExibicao,
      shortenPersonName(firstNonEmptyString([data.nome])),
      data.nome,
    ], "Contratante");
  default:
    return firstNonEmptyString([data.nome], "Usuario");
  }
}

async function getUserDisplayName(userId: string): Promise<string> {
  if (!userId) return "Usuario";

  const snapshot = await db.collection(USERS_COLLECTION).doc(userId).get();
  if (!snapshot.exists) return "Usuario";

  return resolveUserDisplayName(snapshot.data() || {});
}

async function createNotification(params: {
  userId: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  route?: string;
  senderId?: string;
}): Promise<void> {
  const {
    userId,
    notificationId,
    type,
    title,
    body,
    route,
    senderId,
  } = params;

  if (!userId || !notificationId) return;

  await db
    .collection(USERS_COLLECTION)
    .doc(userId)
    .collection(NOTIFICATIONS_COLLECTION)
    .doc(notificationId)
    .set({
      type,
      title,
      body,
      route: route ?? null,
      senderId: senderId ?? null,
      isRead: false,
      createdAt: FieldValue.serverTimestamp(),
    }, {merge: true});
}

async function syncGigCounters(gigId: string): Promise<void> {
  const applicationsRef = db
    .collection(GIGS_COLLECTION)
    .doc(gigId)
    .collection(APPLICATIONS_COLLECTION);

  const [applicantCountSnap, acceptedCountSnap] = await Promise.all([
    applicationsRef.count().get(),
    applicationsRef.where("status", "==", "accepted").count().get(),
  ]);

  await db.collection(GIGS_COLLECTION).doc(gigId).set({
    applicant_count: applicantCountSnap.data().count,
    slots_filled: acceptedCountSnap.data().count,
    updated_at: Timestamp.now(),
  }, {merge: true});
}

async function syncCreatorOpenGigCount(creatorId: string): Promise<void> {
  if (!creatorId) return;

  const openCountSnap = await db
    .collection(GIGS_COLLECTION)
    .where("creator_id", "==", creatorId)
    .where("status", "==", "open")
    .count()
    .get();

  await db.collection(USERS_COLLECTION).doc(creatorId).set({
    gigs_open_count: openCountSnap.data().count,
    updated_at: Timestamp.now(),
  }, {merge: true});
}

async function notifyGigApplicationCreated(
  gigId: string,
  applicantId: string,
  gigData: Record<string, unknown>
): Promise<void> {
  const creatorId = firstNonEmptyString([gigData.creator_id]);
  if (!creatorId || creatorId === applicantId) return;

  const [applicantName] = await Promise.all([getUserDisplayName(applicantId)]);
  const gigTitle = firstNonEmptyString([gigData.title], "sua gig");

  await createNotification({
    userId: creatorId,
    notificationId: `gig_application_${gigId}_${applicantId}`,
    type: "gig_application",
    title: "Nova candidatura",
    body: `${applicantName} se candidatou para "${gigTitle}".`,
    route: buildGigApplicantsRoute(gigId),
    senderId: applicantId,
  });
}

async function notifyGigApplicationDecision(params: {
  gigId: string;
  applicantId: string;
  creatorId: string;
  gigTitle: string;
  status: string;
}): Promise<void> {
  const {gigId, applicantId, creatorId, gigTitle, status} = params;

  if (!applicantId) return;

  if (status === "accepted") {
    await createNotification({
      userId: applicantId,
      notificationId: `gig_application_accepted_${gigId}_${applicantId}`,
      type: "gig_application_accepted",
      title: "Candidatura aceita",
      body: `Sua candidatura em "${gigTitle}" foi aceita.`,
      route: buildGigRoute(gigId),
      senderId: creatorId,
    });
    return;
  }

  if (status === "rejected") {
    await createNotification({
      userId: applicantId,
      notificationId: `gig_application_rejected_${gigId}_${applicantId}`,
      type: "gig_application_rejected",
      title: "Candidatura recusada",
      body: `Sua candidatura em "${gigTitle}" nao foi aprovada.`,
      route: buildGigRoute(gigId),
      senderId: creatorId,
    });
    return;
  }

  if (status === "gig_cancelled") {
    await createNotification({
      userId: applicantId,
      notificationId: `gig_cancelled_${gigId}_${applicantId}`,
      type: "gig_cancelled",
      title: "Gig cancelada",
      body: `A gig "${gigTitle}" foi cancelada pelo criador.`,
      route: buildGigRoute(gigId),
      senderId: creatorId,
    });
  }
}

async function cancelActiveApplications(gigId: string): Promise<void> {
  const applicationsRef = db
    .collection(GIGS_COLLECTION)
    .doc(gigId)
    .collection(APPLICATIONS_COLLECTION);

  for (const status of ["pending", "accepted"]) {
    const snapshot = await applicationsRef.where("status", "==", status).get();
    if (snapshot.empty) continue;

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      batch.update(doc.ref, {
        status: "gig_cancelled",
        responded_at: Timestamp.now(),
      });
    }
    await batch.commit();
  }
}

async function queueReviewNotifications(
  gigId: string,
  gigData: Record<string, unknown>
): Promise<void> {
  const creatorId = firstNonEmptyString([gigData.creator_id]);
  if (!creatorId) return;

  const gigTitle = firstNonEmptyString([gigData.title], "Gig");
  const creatorName = await getUserDisplayName(creatorId);
  const acceptedApplications = await db
    .collection(GIGS_COLLECTION)
    .doc(gigId)
    .collection(APPLICATIONS_COLLECTION)
    .where("status", "==", "accepted")
    .get();

  if (acceptedApplications.empty) return;

  for (const applicationDoc of acceptedApplications.docs) {
    const participantId = applicationDoc.id;
    const participantName = await getUserDisplayName(participantId);

    await Promise.all([
      createNotification({
        userId: creatorId,
        notificationId: `gig_review_creator_${gigId}_${participantId}`,
        type: "gig_review_reminder",
        title: "Avaliacao pendente",
        body: `Avalie ${participantName} pela gig "${gigTitle}".`,
        route: buildGigReviewRoute(gigId, participantId),
        senderId: participantId,
      }),
      createNotification({
        userId: participantId,
        notificationId: `gig_review_participant_${gigId}_${creatorId}`,
        type: "gig_review_reminder",
        title: "Avaliacao pendente",
        body: `Avalie ${creatorName} pela gig "${gigTitle}".`,
        route: buildGigReviewRoute(gigId, creatorId),
        senderId: creatorId,
      }),
    ]);
  }
}

export const onGigCreated = onDocumentCreated(
  {
    document: `${GIGS_COLLECTION}/{gigId}`,
    region: REGION,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const gigData = snapshot.data() || {};
    const creatorId = firstNonEmptyString([gigData.creator_id]);
    await syncCreatorOpenGigCount(creatorId);
  }
);

export const onGigUpdated = onDocumentUpdated(
  {
    document: `${GIGS_COLLECTION}/{gigId}`,
    region: REGION,
  },
  async (event) => {
    const beforeData = event.data?.before.data() || {};
    const afterData = event.data?.after.data() || {};
    const gigId = event.params.gigId as string;
    const creatorId = firstNonEmptyString([
      afterData.creator_id,
      beforeData.creator_id,
    ]);

    await syncCreatorOpenGigCount(creatorId);

    const beforeStatus = firstNonEmptyString([beforeData.status]);
    const afterStatus = firstNonEmptyString([afterData.status]);
    if (!gigId || beforeStatus == afterStatus) return;

    if (afterStatus === "cancelled") {
      await cancelActiveApplications(gigId);
      return;
    }

    if (afterStatus === "closed") {
      await queueReviewNotifications(gigId, afterData);
    }
  }
);

export const onGigDeleted = onDocumentDeleted(
  {
    document: `${GIGS_COLLECTION}/{gigId}`,
    region: REGION,
  },
  async (event) => {
    const gigData = event.data?.data() || {};
    const creatorId = firstNonEmptyString([gigData.creator_id]);
    await syncCreatorOpenGigCount(creatorId);
  }
);

export const onGigApplicationCreated = onDocumentCreated(
  {
    document: `${GIGS_COLLECTION}/{gigId}/${APPLICATIONS_COLLECTION}/{applicantId}`,
    region: REGION,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const gigId = event.params.gigId as string;
    const applicantId = event.params.applicantId as string;
    const gigSnapshot = await db.collection(GIGS_COLLECTION).doc(gigId).get();
    const gigData = gigSnapshot.data() || {};

    await Promise.all([
      syncGigCounters(gigId),
      notifyGigApplicationCreated(gigId, applicantId, gigData),
    ]);
  }
);

export const onGigApplicationUpdated = onDocumentUpdated(
  {
    document: `${GIGS_COLLECTION}/{gigId}/${APPLICATIONS_COLLECTION}/{applicantId}`,
    region: REGION,
  },
  async (event) => {
    const beforeData = event.data?.before.data() || {};
    const afterData = event.data?.after.data() || {};
    const beforeStatus = firstNonEmptyString([beforeData.status]);
    const afterStatus = firstNonEmptyString([afterData.status]);
    const gigId = event.params.gigId as string;
    const applicantId = event.params.applicantId as string;

    const gigSnapshot = await db.collection(GIGS_COLLECTION).doc(gigId).get();
    const gigData = gigSnapshot.data() || {};
    const creatorId = firstNonEmptyString([gigData.creator_id]);
    const gigTitle = firstNonEmptyString([gigData.title], "Gig");

    await syncGigCounters(gigId);

    if (beforeStatus === afterStatus) return;

    await notifyGigApplicationDecision({
      gigId,
      applicantId,
      creatorId,
      gigTitle,
      status: afterStatus,
    });
  }
);

export const onGigApplicationDeleted = onDocumentDeleted(
  {
    document: `${GIGS_COLLECTION}/{gigId}/${APPLICATIONS_COLLECTION}/{applicantId}`,
    region: REGION,
  },
  async (event) => {
    const gigId = event.params.gigId as string;
    await syncGigCounters(gigId);
  }
);

export const expireFixedDateGigs = onSchedule(
  {
    schedule: "*/30 * * * *",
    region: REGION,
    memory: "256MiB",
    timeoutSeconds: 120,
  },
  async () => {
    const now = Timestamp.now();
    let hasMore = true;

    while (hasMore) {
      const snapshot = await db
        .collection(GIGS_COLLECTION)
        .where("status", "==", "open")
        .where("date_mode", "==", "fixed_date")
        .where("gig_date", "<=", now)
        .limit(200)
        .get();

      if (snapshot.empty) {
        hasMore = false;
        break;
      }

      const batch = db.batch();
      for (const doc of snapshot.docs) {
        batch.update(doc.ref, {
          status: "expired",
          updated_at: Timestamp.now(),
        });
      }

      await batch.commit();
      hasMore = snapshot.size == 200;
    }
  }
);
