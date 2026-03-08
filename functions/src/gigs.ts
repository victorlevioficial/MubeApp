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
const APP_CONFIG_COLLECTION = "config";
const APP_CONFIG_DOC = "app_data";
const GIG_OPPORTUNITY_RADIUS_KM = 50;

type ConfigItem = {
  id?: unknown;
  label?: unknown;
  aliases?: unknown;
};

type AppConfigData = {
  genres?: ConfigItem[];
  instruments?: ConfigItem[];
  crewRoles?: ConfigItem[];
  studioServices?: ConfigItem[];
};

type GigMatcherSet = {
  genres: Set<string>;
  requiredInstruments: Set<string>;
  requiredCrewRoles: Set<string>;
  requiredStudioServices: Set<string>;
};

type LatLng = {
  lat: number | null;
  lng: number | null;
};

type NotificationPayload = {
  userId: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  route?: string;
  senderId?: string;
};

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

function asConfigItems(value: unknown): ConfigItem[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter((item) => item !== null && typeof item === "object")
    .map((item) => item as ConfigItem);
}

function readStringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];

  return value
    .filter((item) => typeof item === "string")
    .map((item) => (item as string).trim())
    .filter((item) => item.length > 0);
}

function normalizeToken(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");
}

function createCanonicalizer(items: ConfigItem[]): (values: string[]) => Set<string> {
  const aliases = new Map<string, string>();

  for (const item of items) {
    const canonicalSource = firstNonEmptyString([item.id, item.label]);
    if (!canonicalSource) continue;

    const canonical = normalizeToken(canonicalSource);
    if (!canonical) continue;

    aliases.set(normalizeToken(firstNonEmptyString([item.id])), canonical);
    aliases.set(normalizeToken(firstNonEmptyString([item.label])), canonical);

    for (const alias of readStringList(item.aliases)) {
      aliases.set(normalizeToken(alias), canonical);
    }
  }

  return (values: string[]) => {
    const normalized = new Set<string>();
    for (const value of values) {
      const token = normalizeToken(value);
      if (!token) continue;
      normalized.add(aliases.get(token) ?? token);
    }
    return normalized;
  };
}

function intersects(left: Set<string>, right: Set<string>): boolean {
  if (left.size === 0 || right.size === 0) return false;

  for (const value of left) {
    if (right.has(value)) return true;
  }

  return false;
}

function parseCoordinate(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;

  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : null;
  }

  return null;
}

function haversineDistanceKm(from: LatLng, to: LatLng): number {
  const earthRadiusKm = 6371;
  const dLat = degreesToRadians((to.lat ?? 0) - (from.lat ?? 0));
  const dLng = degreesToRadians((to.lng ?? 0) - (from.lng ?? 0));
  const lat1 = degreesToRadians(from.lat ?? 0);
  const lat2 = degreesToRadians(to.lat ?? 0);

  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.sin(dLng / 2) * Math.sin(dLng / 2) *
      Math.cos(lat1) * Math.cos(lat2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

  return earthRadiusKm * c;
}

function degreesToRadians(value: number): number {
  return value * (Math.PI / 180);
}

function readLatLng(record: Record<string, unknown>): LatLng {
  return {
    lat: parseCoordinate(record.lat),
    lng: parseCoordinate(record.lng ?? record.long),
  };
}

function resolveUserLatLng(userData: Record<string, unknown>): LatLng {
  const addresses = Array.isArray(userData.addresses) ? userData.addresses : [];
  const primaryAddress = addresses.find((item) =>
    item !== null &&
    typeof item === "object" &&
    (item as Record<string, unknown>).isPrimary === true
  );

  if (primaryAddress !== undefined) {
    const candidate = readLatLng(asRecord(primaryAddress));
    if (candidate.lat !== null && candidate.lng !== null) return candidate;
  }

  for (const address of addresses) {
    const candidate = readLatLng(asRecord(address));
    if (candidate.lat !== null && candidate.lng !== null) return candidate;
  }

  return readLatLng(asRecord(userData.location));
}

function chunk<T>(items: T[], size: number): T[][] {
  if (items.length === 0) return [];

  const result: T[][] = [];
  for (let index = 0; index < items.length; index += size) {
    result.push(items.slice(index, index + size));
  }

  return result;
}

async function loadAppConfig(): Promise<AppConfigData> {
  const snapshot = await db
    .collection(APP_CONFIG_COLLECTION)
    .doc(APP_CONFIG_DOC)
    .get();

  if (!snapshot.exists) return {};

  const data = snapshot.data() || {};
  return {
    genres: asConfigItems(data.genres),
    instruments: asConfigItems(data.instruments),
    crewRoles: asConfigItems(data.crewRoles),
    studioServices: asConfigItems(data.studioServices),
  };
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

async function createNotification(params: NotificationPayload): Promise<void> {
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

async function sendPushNotification(params: NotificationPayload): Promise<void> {
  const userDoc = await db.collection(USERS_COLLECTION).doc(params.userId).get();
  const userData = userDoc.data() || {};
  const fcmToken = firstNonEmptyString([userData.fcm_token]);

  if (!fcmToken) return;

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: params.title,
      body: params.body,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: params.type,
      route: params.route ?? "",
      sender_id: params.senderId ?? "",
    },
    android: {
      notification: {
        channelId: "high_importance_channel",
        tag: params.notificationId,
      },
      collapseKey: params.notificationId,
    },
    apns: {
      headers: {
        "apns-collapse-id": params.notificationId,
      },
    },
  });
}

async function notifyUser(params: NotificationPayload): Promise<void> {
  try {
    await createNotification(params);
    await sendPushNotification(params);
  } catch (error) {
    console.error(`Erro ao notificar usuario ${params.userId}:`, error);
  }
}

async function notifyGigOpportunities(
  gigId: string,
  gigData: Record<string, unknown>
): Promise<void> {
  const creatorId = firstNonEmptyString([gigData.creator_id]);
  const gigTitle = firstNonEmptyString([gigData.title], "Nova gig");
  const locationType = firstNonEmptyString([gigData.location_type], "presencial");

  const [config, creatorSnapshot, usersSnapshot] = await Promise.all([
    loadAppConfig(),
    creatorId
      ? db.collection(USERS_COLLECTION).doc(creatorId).get()
      : Promise.resolve(null),
    db.collection(USERS_COLLECTION)
      .where("cadastro_status", "==", "concluido")
      .get(),
  ]);

  const canonicalizeGenres = createCanonicalizer(config.genres ?? []);
  const canonicalizeInstruments = createCanonicalizer(config.instruments ?? []);
  const canonicalizeCrewRoles = createCanonicalizer(config.crewRoles ?? []);
  const canonicalizeStudioServices = createCanonicalizer(
    config.studioServices ?? []
  );

  const gigMatchers: GigMatcherSet = {
    genres: canonicalizeGenres(readStringList(gigData.genres)),
    requiredInstruments: canonicalizeInstruments(
      readStringList(gigData.required_instruments)
    ),
    requiredCrewRoles: canonicalizeCrewRoles(
      readStringList(gigData.required_crew_roles)
    ),
    requiredStudioServices: canonicalizeStudioServices(
      readStringList(gigData.required_studio_services)
    ),
  };

  const hasTargeting =
    gigMatchers.genres.size > 0 &&
    (
      gigMatchers.requiredInstruments.size > 0 ||
      gigMatchers.requiredCrewRoles.size > 0 ||
      gigMatchers.requiredStudioServices.size > 0
    );

  if (!hasTargeting) return;

  const gigLocation = readLatLng(asRecord(gigData.location));
  const creatorLocation = resolveUserLatLng(creatorSnapshot?.data() || {});
  const effectiveGigLocation = {
    lat: gigLocation.lat ?? creatorLocation.lat,
    lng: gigLocation.lng ?? creatorLocation.lng,
  };

  const isRemote = locationType === "remoto";
  const matchedUserIds: string[] = [];

  for (const userDoc of usersSnapshot.docs) {
    if (userDoc.id === creatorId) continue;

    const userData = userDoc.data() || {};
    const userStatus = firstNonEmptyString([userData.status], "ativo");
    if (userStatus !== "ativo") continue;

    const tipoPerfil = firstNonEmptyString([userData.tipo_perfil, userData.tipoPerfil]);
    const profissional = asRecord(userData.profissional);
    const estudio = asRecord(userData.estudio);

    const userGenres = canonicalizeGenres([
      ...readStringList(profissional.generosMusicais),
      ...readStringList(estudio.generosMusicais),
    ]);

    if (!intersects(gigMatchers.genres, userGenres)) continue;

    let requirementMatched = false;

    if (tipoPerfil === "profissional") {
      const userInstruments = canonicalizeInstruments(
        readStringList(profissional.instrumentos)
      );
      const userCrewRoles = canonicalizeCrewRoles(
        readStringList(profissional.funcoes)
      );

      requirementMatched =
        intersects(gigMatchers.requiredInstruments, userInstruments) ||
        intersects(gigMatchers.requiredCrewRoles, userCrewRoles);
    } else if (tipoPerfil === "estudio") {
      const userStudioServices = canonicalizeStudioServices([
        ...readStringList(estudio.servicosOferecidos),
        ...readStringList(estudio.services),
      ]);
      requirementMatched = intersects(
        gigMatchers.requiredStudioServices,
        userStudioServices
      );
    }

    if (!requirementMatched) continue;

    if (!isRemote) {
      if (effectiveGigLocation.lat === null || effectiveGigLocation.lng === null) {
        continue;
      }

      const userLocation = resolveUserLatLng(userData);
      if (userLocation.lat === null || userLocation.lng === null) continue;

      if (
        haversineDistanceKm(effectiveGigLocation, userLocation) >
        GIG_OPPORTUNITY_RADIUS_KM
      ) {
        continue;
      }
    }

    matchedUserIds.push(userDoc.id);
  }

  if (matchedUserIds.length === 0) return;

  for (const batch of chunk(matchedUserIds, 25)) {
    await Promise.all(
      batch.map((userId) =>
        notifyUser({
          userId,
          notificationId: `gig_opportunity_${gigId}`,
          type: "gig_opportunity",
          title: "Nova oportunidade para voce",
          body: `"${gigTitle}" combina com seu perfil.`,
          route: buildGigRoute(gigId),
          senderId: creatorId,
        })
      )
    );
  }
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

  await notifyUser({
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
    await notifyUser({
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
    await notifyUser({
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
    await notifyUser({
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
      notifyUser({
        userId: creatorId,
        notificationId: `gig_review_creator_${gigId}_${participantId}`,
        type: "gig_review_reminder",
        title: "Avaliacao pendente",
        body: `Avalie ${participantName} pela gig "${gigTitle}".`,
        route: buildGigReviewRoute(gigId, participantId),
        senderId: participantId,
      }),
      notifyUser({
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
    await Promise.all([
      syncCreatorOpenGigCount(creatorId),
      notifyGigOpportunities(event.params.gigId as string, gigData),
    ]);
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
