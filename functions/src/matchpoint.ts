/**
 * Cloud Functions para o feature Matchpoint.
 *
 * Funcionalidades:
 * - submitMatchpointAction: Processa ações de like/dislike
 * - Criação de match e reserva do conversationId do chat
 * - onInteractionCreated: Atualiza estatísticas
 * - getRemainingLikes: Retorna quota diária
 */

import {HttpsError, onCall} from "firebase-functions/v2/https";
import {onDocumentCreated, onDocumentWritten} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {
  DocumentData,
  DocumentReference,
  FieldValue,
  Timestamp,
} from "firebase-admin/firestore";

const db = admin.firestore();

/**
 * Daily MatchPoint swipe quota for free accounts.
 *
 * Premium is planned to make this unlimited. When the premium entitlement is
 * launched, resolveDailySwipeLimit will use users/{uid}.is_premium as the
 * switch point without changing the public callable contract.
 */
export const FREE_DAILY_SWIPE_LIMIT = 50;
const INTERACTION_EXPIRY_DAYS = 30;
const MATCH_NOTIFICATION_TYPE = "system";
const MATCH_NOTIFICATION_ROUTE_PREFIX = "/conversation/";
const MATCHPOINT_COMMANDS_COLLECTION = "matchpointCommands";
const MATCHPOINT_FEEDS_COLLECTION = "matchpointFeeds";
const MATCHPOINT_FEED_REFRESH_REQUESTS_COLLECTION =
  "matchpointFeedRefreshRequests";
const MATCHPOINT_FEED_LIMIT = 20;
const MATCHPOINT_FEED_POOL_LIMIT = 48;
const MATCHPOINT_FEED_TTL_MS = 30 * 60 * 1000;
const REGISTRATION_COMPLETE = "concluido";
const STATUS_ACTIVE = "ativo";
const PROFILE_TYPE_PROFESSIONAL = "profissional";
const PROFILE_TYPE_BAND = "banda";
const SUPPORT_ONLY_PROFESSIONAL_CATEGORY_IDS = new Set([
  "audiovisual",
  "audio_visual",
  "educacao",
  "education",
  "luthier",
  "luthieria",
  "performance",
]);

type MatchpointSwipeAction = "like" | "dislike";
type MatchpointCommandStatus = "pending" | "processing" | "completed" | "failed";

/**
 * Estrutura do request para submitMatchpointAction.
 */
interface MatchpointActionRequest {
  targetUserId: string;
  action: MatchpointSwipeAction;
}

/**
 * Estrutura da resposta de submitMatchpointAction.
 */
interface MatchpointActionResponse {
  success: boolean;
  isMatch?: boolean;
  matchId?: string;
  conversationId?: string;
  remainingLikes?: number;
  message?: string;
}

interface MatchpointCommandRequest {
  userId: string;
  targetUserId: string;
  action: MatchpointSwipeAction;
  idempotencyKey: string;
}

interface MatchpointCommandError {
  code: string;
  message: string;
}

interface MatchpointFeedProjection {
  userId: string;
  candidateIds: string[];
  totalCandidates: number;
  generatedAt: Timestamp;
  expiresAt: Timestamp;
  reason: string;
}

interface Coordinates {
  lat: number;
  lng: number;
}

interface ScoredFeedCandidate {
  userId: string;
  locationBucket: number;
  hashtagMatches: number;
  genreMatches: number;
  distanceKm: number | null;
}

interface RemainingLikesResponse {
  remaining: number;
  limit: number;
  resetTime: string;
}

interface RankingAuditRequest {
  poolTotal: number;
  returnedTotal: number;
  poolProximity: number;
  poolHashtag: number;
  poolGenre: number;
  poolFallback: number;
  poolLocalTotal: number;
  poolLocalHashtag: number;
  poolLocalGenre: number;
  returnedProximity: number;
  returnedHashtag: number;
  returnedGenre: number;
  returnedFallback: number;
  returnedLocalTotal: number;
  returnedLocalHashtag: number;
  returnedLocalGenre: number;
  queryGenres: number;
  queryHashtags: number;
  usedGeohash: boolean;
}

interface RankingAuditResponse {
  success: boolean;
  bucketId: string;
}

interface NotificationInput {
  userId: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  senderId?: string;
  conversationId?: string;
  route?: string;
  data?: Record<string, string>;
}

interface MatchNotificationInput {
  senderUserId: string;
  recipientUserId: string;
  conversationId: string;
}

function logCleanupFailure(context: string, error: unknown): void {
  console.warn(`[matchpoint] Cleanup failed: ${context}`, error);
}

/**
 * Valida e normaliza o payload do callable de swipe.
 *
 * Evita TypeError em payload nulo/inesperado e garante mensagens explícitas
 * para o cliente.
 *
 * @param {unknown} rawData - Payload bruto recebido do callable.
 * @return {MatchpointActionRequest} Payload validado e normalizado.
 */
function readMatchpointActionRequest(
  rawData: unknown
): MatchpointActionRequest {
  const payload = asRecord(rawData);
  const targetUserId = firstNonEmptyString([payload.targetUserId]);
  const rawAction = readMatchpointSwipeAction(payload.action);

  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "targetUserId é obrigatório");
  }

  return {
    targetUserId,
    action: rawAction,
  };
}

export function readMatchpointSwipeAction(
  value: unknown
): MatchpointSwipeAction {
  const rawAction = firstNonEmptyString([value]).toLowerCase();
  if (rawAction !== "like" && rawAction !== "dislike") {
    throw new HttpsError(
      "invalid-argument",
      "action deve ser 'like' ou 'dislike'"
    );
  }

  return rawAction;
}

export function readMatchpointCommandRequest(
  rawData: unknown,
  commandId: string
): MatchpointCommandRequest {
  const payload = asRecord(rawData);
  const userId = firstNonEmptyString([payload.user_id, payload.userId]);
  const targetUserId = firstNonEmptyString([
    payload.target_user_id,
    payload.targetUserId,
  ]);
  const idempotencyKey = firstNonEmptyString([
    payload.idempotency_key,
    payload.idempotencyKey,
  ], commandId);

  if (!userId) {
    throw new HttpsError("invalid-argument", "user_id é obrigatório");
  }

  if (!targetUserId) {
    throw new HttpsError("invalid-argument", "target_user_id é obrigatório");
  }

  if (userId === targetUserId) {
    throw new HttpsError(
      "invalid-argument",
      "Não pode interagir consigo mesmo"
    );
  }

  return {
    userId,
    targetUserId,
    action: readMatchpointSwipeAction(payload.action),
    idempotencyKey,
  };
}

export function buildMatchpointCommandResult(
  request: MatchpointCommandRequest,
  response: MatchpointActionResponse
): Record<string, unknown> {
  return {
    targetUserId: request.targetUserId,
    action: request.action,
    isMatch: response.isMatch === true,
    matchId: response.matchId ?? null,
    conversationId: response.conversationId ?? null,
    remainingLikes: response.remainingLikes ?? null,
    message: response.message ?? null,
  };
}

function buildMatchpointCommandError(error: unknown): MatchpointCommandError {
  if (error instanceof HttpsError) {
    return {
      code: error.code,
      message: error.message || "Erro ao processar comando do MatchPoint.",
    };
  }

  return {
    code: "internal",
    message: "Erro interno ao processar comando do MatchPoint.",
  };
}

/**
 * Retorna o primeiro texto não vazio de uma lista.
 *
 * @param {unknown[]} values - Valores candidatos.
 * @param {string=} fallback - Valor padrão quando nada é válido.
 * @return {string} Primeiro texto válido encontrado.
 */
function firstNonEmptyString(values: unknown[], fallback = ""): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }

  return fallback;
}

/**
 * Converte um valor arbitrário em objeto indexável.
 *
 * @param {unknown} value - Valor recebido do Firestore.
 * @return {Record<string, unknown>} Objeto seguro para leitura.
 */
function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
      typeof value === "object" &&
      !Array.isArray(value) ? value as Record<string, unknown> : {};
}

/**
 * Resolve nome de exibição para notificações de match.
 *
 * @param {Record<string, unknown>} userData - Documento do usuário.
 * @return {string} Nome amigável para título da notificação.
 */
function resolveMatchSenderName(userData: Record<string, unknown>): string {
  const professionalProfile = asRecord(userData.profissional);
  const bandProfile = asRecord(userData.banda);
  const studioProfile = asRecord(userData.estudio);
  const contractorProfile = asRecord(userData.contratante);

  return firstNonEmptyString([
    professionalProfile.nomeArtistico,
    bandProfile.nomeBanda,
    bandProfile.nomeArtistico,
    studioProfile.nomeEstudio,
    studioProfile.nomeArtistico,
    contractorProfile.nomeExibicao,
    userData.nome_artistico,
    userData.nome,
  ], "Novo match");
}

/**
 * Normaliza o tipo salvo em um documento de interação.
 *
 * @param {DocumentData|undefined} data - Dados brutos do documento.
 * @return {string} Tipo normalizado ou string vazia.
 */
function readInteractionType(data: DocumentData | undefined): string {
  return typeof data?.type === "string" ? data.type : "";
}

/**
 * Resolve o conversationId persistido em documentos de match legados/atuais.
 *
 * @param {DocumentData|undefined} matchData - Dados do match.
 * @param {string} fallback - conversationId determinístico padrão.
 * @return {string} conversationId utilizável.
 */
function resolveMatchConversationId(
  matchData: DocumentData | undefined,
  fallback: string
): string {
  return firstNonEmptyString([
    matchData?.conversation_id,
    matchData?.conversationId,
  ], fallback);
}

function matchpointStringList(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value
      .map((item) => String(item ?? "").trim())
      .filter((item) => item.length > 0);
  }

  if (typeof value === "string" && value.trim().length > 0) {
    return [value.trim()];
  }

  return [];
}

function normalizeWhitespace(value: string): string {
  return value.trim().replace(/\s+/g, " ");
}

function removeDiacritics(value: string): string {
  return value.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function normalizeGenreToken(value: string): string {
  return normalizeWhitespace(removeDiacritics(value).toLowerCase());
}

function normalizeHashtagToken(value: string): string {
  return removeDiacritics(value.replace(/#/g, ""))
    .toLowerCase()
    .trim()
    .replace(/\s+/g, "")
    .replace(/[^a-z0-9_]/g, "");
}

function normalizeCategoryId(value: string): string {
  return removeDiacritics(value)
    .toLowerCase()
    .trim()
    .replace(/[\s-]+/g, "_")
    .replace(/[^a-z0-9_]/g, "");
}

function asStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((item): item is string => typeof item === "string");
}

function extractCoordinatesFromMap(rawLocation: unknown): Coordinates | null {
  const location = asRecord(rawLocation);
  const rawLat = location.lat;
  const rawLng = location.lng ?? location.long;

  if (typeof rawLat !== "number" || typeof rawLng !== "number") {
    return null;
  }

  return {lat: rawLat, lng: rawLng};
}

function readCurrentUserGeohash(
  userData: Record<string, unknown>,
  location: Coordinates | null
): string {
  const persistedGeohash = firstNonEmptyString([userData.geohash]);
  if (persistedGeohash) return persistedGeohash;
  if (!location) return "";
  return `${location.lat.toFixed(2)}:${location.lng.toFixed(2)}`;
}

function resolveSearchRadiusKm(userData: Record<string, unknown>): number {
  const matchpointProfile = asRecord(userData.matchpoint_profile);
  const rawRadius = matchpointProfile.search_radius;
  if (typeof rawRadius === "number" && Number.isFinite(rawRadius) && rawRadius > 0) {
    return rawRadius;
  }
  return 50;
}

function extractCandidateGenres(userData: Record<string, unknown>): string[] {
  const genres = new Set<string>();
  const matchpointProfile = asRecord(userData.matchpoint_profile);
  for (const value of [
    matchpointProfile.generosMusicais,
    matchpointProfile.musicalGenres,
    matchpointProfile.musical_genres,
    matchpointProfile.genres,
  ]) {
    for (const genre of matchpointStringList(value)) {
      genres.add(genre);
    }
  }

  const professional = asRecord(userData.profissional);
  const band = asRecord(userData.banda);
  for (const genre of matchpointStringList(professional.generosMusicais)) {
    genres.add(genre);
  }
  for (const genre of matchpointStringList(band.generosMusicais)) {
    genres.add(genre);
  }

  return [...genres];
}

function extractCandidateHashtags(userData: Record<string, unknown>): string[] {
  const hashtags = new Set<string>();
  const matchpointProfile = asRecord(userData.matchpoint_profile);
  for (const hashtag of matchpointStringList(matchpointProfile.hashtags)) {
    hashtags.add(hashtag);
  }
  for (const hashtag of matchpointStringList(userData.hashtags)) {
    hashtags.add(hashtag);
  }
  return [...hashtags];
}

function readCurrentUserGenres(userData: Record<string, unknown>): string[] {
  return extractCandidateGenres(userData)
    .map(normalizeGenreToken)
    .filter((value) => value.length > 0);
}

function readCurrentUserHashtags(userData: Record<string, unknown>): string[] {
  return extractCandidateHashtags(userData)
    .map(normalizeHashtagToken)
    .filter((value) => value.length > 0);
}

function isEligibleMatchpointType(userData: Record<string, unknown>): boolean {
  const profileType = firstNonEmptyString([userData.tipo_perfil]);
  if (profileType === PROFILE_TYPE_BAND) return true;
  if (profileType !== PROFILE_TYPE_PROFESSIONAL) return false;

  const professional = asRecord(userData.profissional);
  const rawCategories = [
    ...matchpointStringList(professional.categorias),
    ...matchpointStringList(professional.categoria),
  ];
  const normalized = rawCategories
    .map(normalizeCategoryId)
    .filter((value) => value.length > 0);
  if (normalized.length === 0) return true;

  return !normalized.every((value) =>
    SUPPORT_ONLY_PROFESSIONAL_CATEGORY_IDS.has(value)
  );
}

function isVisibleCandidate(userData: Record<string, unknown>): boolean {
  const registrationStatus = firstNonEmptyString([
    userData.cadastro_status,
  ]);
  const status = firstNonEmptyString([userData.status], STATUS_ACTIVE);
  const matchpointProfile = asRecord(userData.matchpoint_profile);

  return registrationStatus === REGISTRATION_COMPLETE &&
    status === STATUS_ACTIVE &&
    matchpointProfile.is_active === true &&
    isEligibleMatchpointType(userData);
}

function haversineKm(from: Coordinates, to: Coordinates): number {
  const toRadians = (value: number): number => value * Math.PI / 180;
  const earthRadiusKm = 6371;
  const deltaLat = toRadians(to.lat - from.lat);
  const deltaLng = toRadians(to.lng - from.lng);
  const a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(toRadians(from.lat)) *
      Math.cos(toRadians(to.lat)) *
      Math.sin(deltaLng / 2) *
      Math.sin(deltaLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return earthRadiusKm * c;
}

function resolveLocationBucket(
  currentLocation: Coordinates | null,
  candidateLocation: Coordinates | null,
  searchRadiusKm: number
): {bucket: number; distanceKm: number | null} {
  if (!currentLocation) return {bucket: 0, distanceKm: null};
  if (!candidateLocation) return {bucket: 2, distanceKm: null};

  const distanceKm = haversineKm(currentLocation, candidateLocation);
  if (distanceKm <= searchRadiusKm) {
    return {bucket: 0, distanceKm};
  }

  return {bucket: 1, distanceKm};
}

function compareScoredFeedCandidates(
  a: ScoredFeedCandidate,
  b: ScoredFeedCandidate
): number {
  const locationOrder = a.locationBucket - b.locationBucket;
  if (locationOrder !== 0) return locationOrder;

  const hashtagOrder = b.hashtagMatches - a.hashtagMatches;
  if (hashtagOrder !== 0) return hashtagOrder;

  const genreOrder = b.genreMatches - a.genreMatches;
  if (genreOrder !== 0) return genreOrder;

  const distanceOrder = (a.distanceKm ?? Number.POSITIVE_INFINITY) -
    (b.distanceKm ?? Number.POSITIVE_INFINITY);
  if (distanceOrder !== 0) return distanceOrder;

  return a.userId.localeCompare(b.userId);
}

async function readBlockedUserIds(userId: string): Promise<Set<string>> {
  const blockedDocIds = new Set<string>();
  const blockedSnapshot = await db
    .collection("users")
    .doc(userId)
    .collection("blocked")
    .limit(200)
    .get();

  for (const doc of blockedSnapshot.docs) {
    blockedDocIds.add(doc.id);
  }

  return blockedDocIds;
}

async function readExistingInteractionTargetIds(userId: string): Promise<Set<string>> {
  const snapshot = await db
    .collection("interactions")
    .where("source_user_id", "==", userId)
    .where("type", "in", ["like", "dislike"])
    .get();

  const now = Timestamp.now();
  const targetIds = new Set<string>();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const targetUserId = firstNonEmptyString([data.target_user_id]);
    if (!targetUserId) continue;

    if (data.type === "like") {
      targetIds.add(targetUserId);
      continue;
    }

    if (data.type !== "dislike") continue;
    const expiresAt = data.expires_at;
    if (expiresAt instanceof Timestamp && expiresAt.toMillis() > now.toMillis()) {
      targetIds.add(targetUserId);
    }
  }

  return targetIds;
}

async function enqueueMatchpointFeedRefresh(
  userId: string,
  reason: string
): Promise<void> {
  if (!userId) return;

  await db.collection(MATCHPOINT_FEED_REFRESH_REQUESTS_COLLECTION).add({
    user_id: userId,
    reason,
    requested_at: Timestamp.now(),
    created_at: FieldValue.serverTimestamp(),
  });
}

async function rebuildMatchpointFeedForUser(
  userId: string,
  reason: string
): Promise<MatchpointFeedProjection | null> {
  const userRef = db.collection("users").doc(userId);
  const userDoc = await userRef.get();
  if (!userDoc.exists) {
    await db.collection(MATCHPOINT_FEEDS_COLLECTION).doc(userId).delete()
      .catch((error) => logCleanupFailure(`delete feed for missing user ${userId}`, error));
    return null;
  }

  const userData = asRecord(userDoc.data());
  const matchpointProfile = asRecord(userData.matchpoint_profile);
  if (matchpointProfile.is_active !== true || !isVisibleCandidate(userData)) {
    await db.collection(MATCHPOINT_FEEDS_COLLECTION).doc(userId).delete()
      .catch((error) => logCleanupFailure(`delete inactive feed ${userId}`, error));
    return null;
  }

  const currentLocation = extractCoordinatesFromMap(userData.location);
  const currentGeohash = readCurrentUserGeohash(userData, currentLocation);
  const searchRadiusKm = resolveSearchRadiusKm(userData);
  const targetGenres = new Set(readCurrentUserGenres(userData));
  const targetHashtags = new Set(readCurrentUserHashtags(userData));

  const blockedUsers = new Set(asStringArray(userData.blocked_users));
  const blockedSubcollectionUsers = await readBlockedUserIds(userId);
  for (const blockedUserId of blockedSubcollectionUsers) {
    blockedUsers.add(blockedUserId);
  }

  const interactedTargetIds = await readExistingInteractionTargetIds(userId);
  const excludedIds = new Set<string>([
    userId,
    ...blockedUsers,
    ...interactedTargetIds,
  ]);

  const candidateSnapshot = await db
    .collection("users")
    .where("matchpoint_profile.is_active", "==", true)
    .limit(MATCHPOINT_FEED_POOL_LIMIT)
    .get();

  const scored = candidateSnapshot.docs
    .filter((doc) => !excludedIds.has(doc.id))
    .map((doc) => {
      const candidateData = asRecord(doc.data());
      if (!isVisibleCandidate(candidateData)) return null;

      const candidateLocation = extractCoordinatesFromMap(candidateData.location);
      const {bucket, distanceKm} = resolveLocationBucket(
        currentLocation,
        candidateLocation,
        searchRadiusKm
      );
      const hashtagMatches = extractCandidateHashtags(candidateData)
        .map(normalizeHashtagToken)
        .filter((token) => targetHashtags.has(token))
        .length;
      const genreMatches = extractCandidateGenres(candidateData)
        .map(normalizeGenreToken)
        .filter((token) => targetGenres.has(token))
        .length;

      return {
        userId: doc.id,
        locationBucket: bucket,
        hashtagMatches,
        genreMatches,
        distanceKm,
      } as ScoredFeedCandidate;
    })
    .filter((candidate): candidate is ScoredFeedCandidate => candidate !== null)
    .sort(compareScoredFeedCandidates);

  const candidateIds = scored
    .slice(0, MATCHPOINT_FEED_LIMIT)
    .map((candidate) => candidate.userId);
  const generatedAt = Timestamp.now();
  const expiresAt = Timestamp.fromMillis(
    generatedAt.toMillis() + MATCHPOINT_FEED_TTL_MS
  );

  await db.collection(MATCHPOINT_FEEDS_COLLECTION).doc(userId).set({
    user_id: userId,
    current_user_geohash: currentGeohash,
    candidate_ids: candidateIds,
    total_candidates: scored.length,
    generated_at: generatedAt,
    expires_at: expiresAt,
    reason,
    source: "server_projection",
    version: 1,
    updated_at: FieldValue.serverTimestamp(),
  });

  return {
    userId,
    candidateIds,
    totalCandidates: scored.length,
    generatedAt,
    expiresAt,
    reason,
  };
}

function buildRelevantFeedSignature(userData: Record<string, unknown>): string {
  const matchpointProfile = asRecord(userData.matchpoint_profile);
  const location = asRecord(userData.location);
  return JSON.stringify({
    cadastro_status: userData.cadastro_status ?? "",
    status: userData.status ?? "",
    tipo_perfil: userData.tipo_perfil ?? "",
    geohash: userData.geohash ?? "",
    blocked_users: [...asStringArray(userData.blocked_users)].sort(),
    location: {
      lat: location.lat ?? null,
      lng: location.lng ?? location.long ?? null,
    },
    matchpoint_profile: {
      is_active: matchpointProfile.is_active ?? false,
      generosMusicais: matchpointStringList(
        matchpointProfile.generosMusicais ?? matchpointProfile.musicalGenres
      ),
      hashtags: matchpointStringList(matchpointProfile.hashtags),
      search_radius: matchpointProfile.search_radius ?? null,
    },
  });
}

/**
 * Cria/atualiza uma notificação no Firestore do usuário.
 *
 * @param {NotificationInput} input - Dados da notificação.
 * @return {Promise<void>} Promise concluída após persistência.
 */
async function upsertUserNotification(input: NotificationInput): Promise<void> {
  const {
    userId,
    notificationId,
    type,
    title,
    body,
    senderId,
    conversationId,
    route,
    data,
  } = input;

  await db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .doc(notificationId)
    .set({
      type,
      title,
      body,
      senderId: senderId ?? null,
      conversationId: conversationId ?? null,
      route: route ?? null,
      ...data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
}

/**
 * Envia push notification best-effort para o usuário.
 *
 * @param {NotificationInput} input - Dados da notificação.
 * @return {Promise<void>} Promise concluída após tentativa de envio.
 */
async function sendPushNotification(input: NotificationInput): Promise<void> {
  const userDoc = await db.collection("users").doc(input.userId).get();
  const userData = userDoc.data() || {};
  const fcmToken = userData.fcm_token;

  if (typeof fcmToken !== "string" || fcmToken.trim().length === 0) {
    return;
  }

  await admin.messaging().send({
    token: fcmToken,
    notification: {
      title: input.title,
      body: input.body,
    },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: input.type,
      route: input.route ?? "",
      sender_id: input.senderId ?? "",
      conversation_id: input.conversationId ?? "",
      ...(input.data ?? {}),
    },
    android: {
      notification: {
        channelId: "high_importance_channel",
        tag: input.notificationId,
      },
      collapseKey: input.notificationId,
    },
    apns: {
      headers: {
        "apns-collapse-id": input.notificationId,
      },
    },
  });
}

/**
 * Persiste a notificação e tenta enviar push sem derrubar o fluxo principal.
 *
 * @param {NotificationInput} input - Dados da notificação.
 * @return {Promise<void>} Promise concluída após tentativa.
 */
async function notifyUser(input: NotificationInput): Promise<void> {
  try {
    await upsertUserNotification(input);
    await sendPushNotification(input);
  } catch (error) {
    console.error(`Erro ao notificar usuario ${input.userId}:`, error);
  }
}

/**
 * Notifica o usuário que recebeu match de volta no MatchPoint.
 *
 * @param {MatchNotificationInput} input - Dados do match.
 * @return {Promise<void>} Promise concluída após tentativa.
 */
async function notifyMatchCreated(
  input: MatchNotificationInput
): Promise<void> {
  const {
    senderUserId,
    recipientUserId,
    conversationId,
  } = input;

  try {
    const senderDoc = await db.collection("users").doc(senderUserId).get();
    const senderData = senderDoc.data() || {};
    const senderName = resolveMatchSenderName(senderData);
    const route = `${MATCH_NOTIFICATION_ROUTE_PREFIX}${conversationId}`;

    await notifyUser({
      userId: recipientUserId,
      notificationId: `match_${conversationId}`,
      type: MATCH_NOTIFICATION_TYPE,
      title: "Novo match no MatchPoint",
      body: `${senderName} curtiu você também.`,
      senderId: senderUserId,
      conversationId,
      route,
      data: {
        conversation_id: conversationId,
        conversation_type: "matchpoint",
        sender_name: senderName,
      },
    });
  } catch (error) {
    console.error(
      `Erro ao enviar notificacao de match para ${recipientUserId}:`,
      error
    );
  }
}

/**
 * Núcleo compartilhado de processamento de swipe do MatchPoint.
 *
 * Mantém a regra de negócio central em um único lugar para o callable legado
 * e para o novo pipeline assíncrono por documento em `matchpointCommands`.
 *
 * @param {string} currentUserId - UID do usuário que executou a ação.
 * @param {string} targetUserId - UID do perfil alvo do swipe.
 * @param {MatchpointSwipeAction} action - Ação solicitada pelo usuário.
 * @return {Promise<MatchpointActionResponse>} Resultado autoritativo do swipe.
 */
async function processMatchpointAction(
  currentUserId: string,
  targetUserId: string,
  action: MatchpointSwipeAction
): Promise<MatchpointActionResponse> {
  let stage = "load_current_user";

  try {
    const userRef = db.collection("users").doc(currentUserId);
    const interactionsRef = db.collection("interactions");
    const existingInteractionPromise = interactionsRef
      .where("source_user_id", "==", currentUserId)
      .where("target_user_id", "==", targetUserId)
      .where("type", "in", ["like", "dislike"])
      .limit(1)
      .get();
    const mutualLikePromise = action === "like" ?
      interactionsRef
        .where("source_user_id", "==", targetUserId)
        .where("target_user_id", "==", currentUserId)
        .where("type", "==", "like")
        .limit(1)
        .get() :
      Promise.resolve(null);

    const [userDoc, existingInteractionQuery, mutualLikeQuery] =
      await Promise.all([
        userRef.get(),
        existingInteractionPromise,
        mutualLikePromise,
      ]);

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado");
    }

    const userData = userDoc.data() || {};
    const remainingLikesSnapshot = getRemainingLikesSnapshot(userData);

    const existingInteraction = existingInteractionQuery.empty ?
      null :
      existingInteractionQuery.docs[0];
    const existingData = existingInteraction?.data() || {};
    const existingType = existingData.type as string | undefined;

    let remainingQuota = remainingLikesSnapshot.remainingLikes;

    if (!existingInteraction) {
      stage = "check_rate_limit";
      const rateLimitResult = await checkAndUpdateRateLimit(currentUserId);
      if (!rateLimitResult.allowed) {
        throw new HttpsError(
          "resource-exhausted",
          `Limite diário de ${rateLimitResult.limit} swipes atingido. ` +
          "Tente novamente amanhã."
        );
      }
      remainingQuota = rateLimitResult.remainingLikes;
    }

    if (action === "dislike") {
      const now = Timestamp.now();
      const expiresAt = Timestamp.fromDate(
        new Date(Date.now() + INTERACTION_EXPIRY_DAYS * 24 * 60 * 60 * 1000)
      );

      if (existingInteraction) {
        if (existingType !== "dislike") {
          stage = "persist_dislike_existing";
          await existingInteraction.ref.update({
            type: "dislike",
            updated_at: now,
            expires_at: expiresAt,
            resulted_in_match: FieldValue.delete(),
          });
        }
      } else {
        stage = "persist_dislike_new";
        const interactionRef = db.collection("interactions").doc();
        await interactionRef.set({
          source_user_id: currentUserId,
          target_user_id: targetUserId,
          type: "dislike",
          created_at: now,
          updated_at: now,
          expires_at: expiresAt,
        });
      }

      stage = "remove_match";
      const removedMatch = await removeMatch(currentUserId, targetUserId);
      stage = "enqueue_feed_refresh";
      await Promise.all([
        enqueueMatchpointFeedRefresh(currentUserId, "interaction_dislike"),
        enqueueMatchpointFeedRefresh(targetUserId, "interaction_dislike"),
      ]);

      return {
        success: true,
        remainingLikes: remainingQuota,
        message: removedMatch ? "Match desfeito" : "Dislike registrado",
      };
    }

    const now = Timestamp.now();
    let interactionRef = existingInteraction?.ref;

    if (existingInteraction && existingType === "like") {
      return {
        success: true,
        remainingLikes: remainingQuota,
        message: "Interação já registrada",
      };
    }

    if (existingInteraction) {
      stage = "persist_like_existing";
      await existingInteraction.ref.update({
        type: "like",
        updated_at: now,
        expires_at: FieldValue.delete(),
        resulted_in_match: FieldValue.delete(),
      });
      interactionRef = existingInteraction.ref;
    } else {
      stage = "persist_like_new";
      interactionRef = interactionsRef.doc();
      await interactionRef.set({
        source_user_id: currentUserId,
        target_user_id: targetUserId,
        type: "like",
        created_at: now,
        updated_at: now,
      });
    }

    const isMatch = mutualLikeQuery !== null && !mutualLikeQuery.empty;

    if (!isMatch) {
      stage = "enqueue_feed_refresh";
      await Promise.all([
        enqueueMatchpointFeedRefresh(currentUserId, "interaction_like"),
        enqueueMatchpointFeedRefresh(targetUserId, "interaction_like"),
      ]);
      return {
        success: true,
        isMatch: false,
        remainingLikes: remainingQuota,
        message: "Like registrado",
      };
    }

    stage = "finalize_match";
    const matchResult = await createMatch(
      currentUserId,
      targetUserId,
      interactionRef,
      mutualLikeQuery.docs[0].ref
    );

    if (matchResult === null) {
      stage = "enqueue_feed_refresh";
      await Promise.all([
        enqueueMatchpointFeedRefresh(currentUserId, "interaction_like"),
        enqueueMatchpointFeedRefresh(targetUserId, "interaction_like"),
      ]);
      return {
        success: true,
        isMatch: false,
        remainingLikes: remainingQuota,
        message: "Like registrado",
      };
    }

    stage = "enqueue_feed_refresh";
    await Promise.all([
      enqueueMatchpointFeedRefresh(currentUserId, "match_created"),
      enqueueMatchpointFeedRefresh(targetUserId, "match_created"),
    ]);

    return {
      success: true,
      isMatch: true,
      matchId: matchResult.matchId,
      conversationId: matchResult.conversationId,
      remainingLikes: remainingQuota,
      message: "Match! Vocês podem conversar agora",
    };
  } catch (error) {
    console.error("Erro ao processar ação do MatchPoint:", {
      currentUserId,
      targetUserId,
      action,
      stage,
      error,
    });

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError("internal", "Erro interno ao processar ação");
  }
}

/**
 * Cloud Function: submitMatchpointAction.
 *
 * Compatibilidade do fluxo legado por callable.
 */
export const submitMatchpointAction = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    concurrency: 1,
    maxInstances: 10,
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<MatchpointActionResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const currentUserId = request.auth.uid;
    const {targetUserId, action} = readMatchpointActionRequest(request.data);

    if (currentUserId === targetUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Não pode interagir consigo mesmo"
      );
    }

    return processMatchpointAction(currentUserId, targetUserId, action);
  }
);

/**
 * Trigger: processa comandos assíncronos de swipe criados pelo app.
 *
 * Caminho: matchpointCommands/{commandId}
 */
export const onMatchpointCommandCreated = onDocumentCreated(
  {
    document: `${MATCHPOINT_COMMANDS_COLLECTION}/{commandId}`,
    region: "southamerica-east1",
    memory: "256MiB",
    concurrency: 1,
    maxInstances: 10,
    timeoutSeconds: 20,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const commandId = event.params.commandId;
    const commandRef = snapshot.ref;

    try {
      const request = readMatchpointCommandRequest(snapshot.data(), commandId);
      const processingStatus: MatchpointCommandStatus = "processing";
      await commandRef.set({
        status: processingStatus,
        processing_started_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      }, {merge: true});

      const result = await processMatchpointAction(
        request.userId,
        request.targetUserId,
        request.action
      );

      const completedStatus: MatchpointCommandStatus = "completed";
      await commandRef.set({
        status: completedStatus,
        processed_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        result: buildMatchpointCommandResult(request, result),
        error: FieldValue.delete(),
      }, {merge: true});
    } catch (error) {
      const failedStatus: MatchpointCommandStatus = "failed";
      const commandError = buildMatchpointCommandError(error);
      console.error("Erro ao processar matchpoint command:", {
        commandId,
        error,
      });
      await commandRef.set({
        status: failedStatus,
        processed_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
        error: commandError,
      }, {merge: true});
    }
  }
);

/**
 * Trigger: reconstrói o feed projetado quando um refresh é solicitado.
 *
 * Caminho: matchpointFeedRefreshRequests/{requestId}
 */
export const onMatchpointFeedRefreshRequested = onDocumentCreated(
  {
    document: `${MATCHPOINT_FEED_REFRESH_REQUESTS_COLLECTION}/{requestId}`,
    region: "southamerica-east1",
    memory: "256MiB",
    concurrency: 1,
    maxInstances: 10,
    timeoutSeconds: 30,
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const requestData = asRecord(snapshot.data());
    const userId = firstNonEmptyString([requestData.user_id]);
    const reason = firstNonEmptyString([requestData.reason], "refresh_request");

    try {
      await rebuildMatchpointFeedForUser(userId, reason);
    } finally {
      await snapshot.ref.delete().catch(
        (error) => logCleanupFailure(
          `delete refresh request ${snapshot.ref.path}`,
          error
        )
      );
    }
  }
);

/**
 * Trigger: atualiza o feed projetado do próprio usuário quando os dados de
 * MatchPoint mudam no documento `users/{userId}`.
 */
export const onMatchpointProfileWritten = onDocumentWritten(
  {
    document: "users/{userId}",
    region: "southamerica-east1",
    memory: "256MiB",
    concurrency: 1,
    maxInstances: 10,
    timeoutSeconds: 30,
  },
  async (event) => {
    const after = event.data?.after;
    const before = event.data?.before;
    const userId = event.params.userId;

    if (!after?.exists) {
      await db.collection(MATCHPOINT_FEEDS_COLLECTION).doc(userId)
        .delete()
        .catch((error) => logCleanupFailure(`delete feed for removed profile ${userId}`, error));
      return;
    }

    const beforeData = before?.exists ? asRecord(before.data()) : {};
    const afterData = asRecord(after.data());
    const beforeSignature = buildRelevantFeedSignature(beforeData);
    const afterSignature = buildRelevantFeedSignature(afterData);
    if (beforeSignature === afterSignature) {
      return;
    }

    await rebuildMatchpointFeedForUser(userId, "profile_updated");
  }
);

/**
 * Verifica e atualiza o rate limit diário (lazy reset).
 *
 * @param {string} userId - UID do usuário
 * @return {Promise<{allowed: boolean, remainingLikes: number}>} Resultado
 */
async function checkAndUpdateRateLimit(
  userId: string
): Promise<{ allowed: boolean; remainingLikes: number; limit: number }> {
  const userRef = db.collection("users").doc(userId);

  return await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);

    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado");
    }

    const userData = userDoc.data() || {};
    const now = Timestamp.now();
    const today = new Date(now.toDate().setHours(0, 0, 0, 0));
    const todayTimestamp = Timestamp.fromDate(today);
    const dailySwipeLimit = resolveDailySwipeLimit(userData);

    let dailyLikesCount = readDailySwipeCount(userData);
    const lastLikeDate = readLastLikeDate(userData);

    if (!lastLikeDate || lastLikeDate < today) {
      dailyLikesCount = 0;
    }

    if (dailyLikesCount >= dailySwipeLimit) {
      return {allowed: false, remainingLikes: 0, limit: dailySwipeLimit};
    }

    transaction.update(userRef, {
      daily_swipes_count: dailyLikesCount + 1,
      last_swipe_date: todayTimestamp,
      daily_likes_count: dailyLikesCount + 1,
      last_like_date: todayTimestamp,
      updated_at: now,
    });

    return {
      allowed: true,
      remainingLikes: dailySwipeLimit - dailyLikesCount - 1,
      limit: dailySwipeLimit,
    };
  });
}

function resolveDailySwipeLimit(_userData: DocumentData): number {
  return FREE_DAILY_SWIPE_LIMIT;
}

/**
 * Calcula a quantidade de swipes restantes sem escrever no banco.
 *
 * @param {DocumentData} userData - Dados do usuário
 * @return {{remainingLikes: number, dailyLikesCount: number}} Snapshot
 */
function getRemainingLikesSnapshot(userData: DocumentData): {
  remainingLikes: number;
  dailyLikesCount: number;
  dailySwipeLimit: number;
} {
  const now = Timestamp.now();
  const today = new Date(now.toDate().setHours(0, 0, 0, 0));
  const lastLikeDate = readLastLikeDate(userData);
  const dailySwipeLimit = resolveDailySwipeLimit(userData);
  let dailyLikesCount = readDailySwipeCount(userData);

  if (!lastLikeDate || lastLikeDate < today) {
    dailyLikesCount = 0;
  }

  return {
    remainingLikes: Math.max(0, dailySwipeLimit - dailyLikesCount),
    dailyLikesCount,
    dailySwipeLimit,
  };
}

/**
 * Lê e normaliza contador diário de swipes.
 *
 * @param {DocumentData} userData - Dados do usuário
 * @return {number} contador diário >= 0
 */
function readDailySwipeCount(userData: DocumentData): number {
  const rawCount = userData.daily_swipes_count ?? userData.daily_likes_count;
  if (typeof rawCount !== "number" || !Number.isFinite(rawCount)) {
    return 0;
  }

  return Math.max(0, Math.floor(rawCount));
}

/**
 * Lê e normaliza a data de último swipe/like.
 *
 * @param {DocumentData} userData - Dados do usuário
 * @return {Date|null} data válida ou null
 */
function readLastLikeDate(userData: DocumentData): Date | null {
  const rawDate = userData.last_swipe_date ?? userData.last_like_date;
  if (rawDate instanceof Timestamp) {
    return rawDate.toDate();
  }

  if (rawDate && typeof rawDate.toDate === "function") {
    try {
      const parsed = rawDate.toDate();
      if (parsed instanceof Date) return parsed;
    } catch (_) {
      return null;
    }
  }

  return null;
}

/**
 * Cria um match e reserva o conversationId do chat associado.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @param {DocumentReference<DocumentData>} sourceInteractionRef - Interação
 *   atual persistida pelo usuário que acabou de curtir.
 * @param {DocumentReference<DocumentData>} reciprocalInteractionRef -
 *   Interação recíproca já encontrada para o potencial match.
 * @return {Promise<{matchId: string, conversationId: string} | null>}
 *   Resultado do match ou null quando a reciprocidade sumiu durante a corrida.
 */
async function createMatch(
  userId1: string,
  userId2: string,
  sourceInteractionRef: DocumentReference<DocumentData>,
  reciprocalInteractionRef: DocumentReference<DocumentData>
): Promise<{ matchId: string; conversationId: string } | null> {
  const now = Timestamp.now();

  const pairKey = [userId1, userId2].sort().join("_");
  const matchId = `match_${pairKey}`;
  const matchRef = db.collection("matches").doc(matchId);

  return await db.runTransaction(async (transaction) => {
    const sourceInteractionDoc = await transaction.get(sourceInteractionRef);
    const reciprocalInteractionDoc = await transaction.get(
      reciprocalInteractionRef
    );

    if (!sourceInteractionDoc.exists || !reciprocalInteractionDoc.exists) {
      return null;
    }

    if (
      readInteractionType(sourceInteractionDoc.data()) !== "like" ||
      readInteractionType(reciprocalInteractionDoc.data()) !== "like"
    ) {
      return null;
    }

    const existingMatch = await transaction.get(matchRef);
    const conversationId = resolveMatchConversationId(
      existingMatch.data(),
      pairKey
    );

    transaction.set(sourceInteractionRef, {
      resulted_in_match: true,
      updated_at: now,
    }, {merge: true});
    transaction.set(reciprocalInteractionRef, {
      resulted_in_match: true,
      updated_at: now,
    }, {merge: true});

    if (existingMatch.exists) {
      transaction.set(matchRef, {
        conversation_id: conversationId,
        updated_at: now,
      }, {merge: true});
      return {matchId: existingMatch.id, conversationId};
    }

    transaction.set(matchRef, {
      user_id_1: userId1,
      user_id_2: userId2,
      user_ids: [userId1, userId2],
      pair_key: pairKey,
      conversation_id: conversationId,
      matched_by_user_id: userId1,
      notification_recipient_user_id: userId2,
      created_at: now,
      updated_at: now,
    });

    return {matchId, conversationId};
  });
}

/**
 * Trigger: Quando um match e criado.
 *
 * Move notificacao para fora do callable para reduzir latencia do swipe.
 */
export const onMatchCreated = onDocumentCreated(
  {
    document: "matches/{matchId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data() || {};
    const senderUserId = firstNonEmptyString([data.matched_by_user_id]);
    const userIds = Array.isArray(data.user_ids) ?
      data.user_ids.filter((value): value is string => typeof value === "string") :
      [];
    const recipientUserId = firstNonEmptyString([
      data.notification_recipient_user_id,
      userIds.find((userId) => userId !== senderUserId),
    ]);
    const conversationId = resolveMatchConversationId(
      data,
      snapshot.id.startsWith("match_") ? snapshot.id.slice(6) : snapshot.id
    );

    if (!senderUserId || !recipientUserId || senderUserId === recipientUserId) {
      return;
    }

    await notifyMatchCreated({
      senderUserId,
      recipientUserId,
      conversationId,
    });
  }
);

/**
 * Remove apenas o match entre dois usuários.
 *
 * A conversa é mantida para não quebrar o chat direto fora do MatchPoint.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @return {Promise<boolean>} true quando removeu match
 */
async function removeMatch(userId1: string, userId2: string): Promise<boolean> {
  const pairKey = [userId1, userId2].sort().join("_");
  const matchId = `match_${pairKey}`;

  const matchRef = db.collection("matches").doc(matchId);

  const matchDoc = await matchRef.get();

  if (!matchDoc.exists) return false;

  await matchRef.delete();
  return true;
}

/**
 * Trigger: Quando uma interação é criada.
 */
export const onInteractionCreated = onDocumentCreated(
  {
    document: "interactions/{interactionId}",
    region: "southamerica-east1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();
    const sourceUserId = data.source_user_id as string;
    const type = data.type as string;

    try {
      const userRef = db.collection("users").doc(sourceUserId);
      let field = "total_dislikes_sent";
      if (type === "like") {
        field = "total_likes_sent";
      }

      await userRef.update({
        [field]: FieldValue.increment(1),
        updated_at: Timestamp.now(),
      });
    } catch (error) {
      console.error("Erro ao atualizar estatísticas:", error);
    }
  }
);

/**
 * Cloud Function: recordMatchpointRankingAudit.
 *
 * Persiste um espelho agregado por hora da auditoria de ranking do MatchPoint
 * para leitura no painel interno/debug do app.
 */
export const recordMatchpointRankingAudit = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<RankingAuditResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const payload = sanitizeRankingAuditRequest(
      request.data as Partial<RankingAuditRequest>
    );
    const now = Timestamp.now();
    const {bucketId, bucketStart} = getRankingAuditBucket(now.toDate());
    const bucketRef = db.collection("matchpointStats").doc(bucketId);

    try {
      await db.runTransaction(async (transaction) => {
        const snapshot = await transaction.get(bucketRef);

        if (!snapshot.exists) {
          transaction.set(bucketRef, {
            type: "ranking_audit_hourly",
            bucket_id: bucketId,
            bucket_start: bucketStart,
            total_events: 1,
            pool_total_sum: payload.poolTotal,
            returned_total_sum: payload.returnedTotal,
            pool_proximity_sum: payload.poolProximity,
            pool_hashtag_sum: payload.poolHashtag,
            pool_genre_sum: payload.poolGenre,
            pool_fallback_sum: payload.poolFallback,
            pool_local_total_sum: payload.poolLocalTotal,
            pool_local_hashtag_sum: payload.poolLocalHashtag,
            pool_local_genre_sum: payload.poolLocalGenre,
            returned_proximity_sum: payload.returnedProximity,
            returned_hashtag_sum: payload.returnedHashtag,
            returned_genre_sum: payload.returnedGenre,
            returned_fallback_sum: payload.returnedFallback,
            returned_local_total_sum: payload.returnedLocalTotal,
            returned_local_hashtag_sum: payload.returnedLocalHashtag,
            returned_local_genre_sum: payload.returnedLocalGenre,
            query_genres_sum: payload.queryGenres,
            query_hashtags_sum: payload.queryHashtags,
            geohash_used_count: payload.usedGeohash ? 1 : 0,
            created_at: now,
            updated_at: now,
          });
          return;
        }

        transaction.update(bucketRef, {
          total_events: FieldValue.increment(1),
          pool_total_sum: FieldValue.increment(payload.poolTotal),
          returned_total_sum: FieldValue.increment(payload.returnedTotal),
          pool_proximity_sum: FieldValue.increment(payload.poolProximity),
          pool_hashtag_sum: FieldValue.increment(payload.poolHashtag),
          pool_genre_sum: FieldValue.increment(payload.poolGenre),
          pool_fallback_sum: FieldValue.increment(payload.poolFallback),
          pool_local_total_sum: FieldValue.increment(payload.poolLocalTotal),
          pool_local_hashtag_sum: FieldValue.increment(
            payload.poolLocalHashtag
          ),
          pool_local_genre_sum: FieldValue.increment(payload.poolLocalGenre),
          returned_proximity_sum: FieldValue.increment(
            payload.returnedProximity
          ),
          returned_hashtag_sum: FieldValue.increment(payload.returnedHashtag),
          returned_genre_sum: FieldValue.increment(payload.returnedGenre),
          returned_fallback_sum: FieldValue.increment(payload.returnedFallback),
          returned_local_total_sum: FieldValue.increment(
            payload.returnedLocalTotal
          ),
          returned_local_hashtag_sum: FieldValue.increment(
            payload.returnedLocalHashtag
          ),
          returned_local_genre_sum: FieldValue.increment(
            payload.returnedLocalGenre
          ),
          query_genres_sum: FieldValue.increment(payload.queryGenres),
          query_hashtags_sum: FieldValue.increment(payload.queryHashtags),
          geohash_used_count: FieldValue.increment(payload.usedGeohash ? 1 : 0),
          updated_at: now,
        });
      });

      return {success: true, bucketId};
    } catch (error) {
      console.error("Erro em recordMatchpointRankingAudit:", error);
      throw new HttpsError("internal", "Erro ao registrar auditoria");
    }
  }
);

/**
 * Valida e normaliza payload de auditoria de ranking.
 *
 * @param {Partial<RankingAuditRequest>} payload - Payload bruto recebido.
 * @return {RankingAuditRequest} Payload sanitizado.
 */
function sanitizeRankingAuditRequest(
  payload: Partial<RankingAuditRequest>
): RankingAuditRequest {
  const result: RankingAuditRequest = {
    poolTotal: readAuditInteger(payload.poolTotal, "poolTotal"),
    returnedTotal: readAuditInteger(payload.returnedTotal, "returnedTotal"),
    poolProximity: readAuditInteger(payload.poolProximity, "poolProximity"),
    poolHashtag: readAuditInteger(payload.poolHashtag, "poolHashtag"),
    poolGenre: readAuditInteger(payload.poolGenre, "poolGenre"),
    poolFallback: readAuditInteger(payload.poolFallback, "poolFallback"),
    poolLocalTotal: readAuditInteger(
      payload.poolLocalTotal ?? 0,
      "poolLocalTotal"
    ),
    poolLocalHashtag: readAuditInteger(
      payload.poolLocalHashtag ?? 0,
      "poolLocalHashtag"
    ),
    poolLocalGenre: readAuditInteger(
      payload.poolLocalGenre ?? 0,
      "poolLocalGenre"
    ),
    returnedProximity: readAuditInteger(
      payload.returnedProximity,
      "returnedProximity"
    ),
    returnedHashtag: readAuditInteger(
      payload.returnedHashtag,
      "returnedHashtag"
    ),
    returnedGenre: readAuditInteger(payload.returnedGenre, "returnedGenre"),
    returnedFallback: readAuditInteger(
      payload.returnedFallback,
      "returnedFallback"
    ),
    returnedLocalTotal: readAuditInteger(
      payload.returnedLocalTotal ?? 0,
      "returnedLocalTotal"
    ),
    returnedLocalHashtag: readAuditInteger(
      payload.returnedLocalHashtag ?? 0,
      "returnedLocalHashtag"
    ),
    returnedLocalGenre: readAuditInteger(
      payload.returnedLocalGenre ?? 0,
      "returnedLocalGenre"
    ),
    queryGenres: readAuditInteger(payload.queryGenres, "queryGenres", 20),
    queryHashtags: readAuditInteger(
      payload.queryHashtags,
      "queryHashtags",
      20
    ),
    usedGeohash: payload.usedGeohash === true,
  };

  if (
    result.poolProximity +
      result.poolHashtag +
      result.poolGenre +
      result.poolFallback >
    result.poolTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Soma do pool excede poolTotal."
    );
  }

  if (result.poolLocalTotal > result.poolTotal) {
    throw new HttpsError(
      "invalid-argument",
      "poolLocalTotal excede poolTotal."
    );
  }

  if (
    result.poolLocalHashtag > result.poolLocalTotal ||
    result.poolLocalGenre > result.poolLocalTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Afinidade local do pool excede poolLocalTotal."
    );
  }

  if (
    result.returnedProximity +
      result.returnedHashtag +
      result.returnedGenre +
      result.returnedFallback >
    result.returnedTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Soma do retorno excede returnedTotal."
    );
  }

  if (result.returnedLocalTotal > result.returnedTotal) {
    throw new HttpsError(
      "invalid-argument",
      "returnedLocalTotal excede returnedTotal."
    );
  }

  if (
    result.returnedLocalHashtag > result.returnedLocalTotal ||
    result.returnedLocalGenre > result.returnedLocalTotal
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Afinidade local do retorno excede returnedLocalTotal."
    );
  }

  return result;
}

/**
 * Lê e valida um inteiro não-negativo para auditoria.
 *
 * @param {unknown} value - Valor bruto.
 * @param {string} fieldName - Nome do campo para erro.
 * @param {number=} max - Máximo permitido.
 * @return {number} Valor inteiro validado.
 */
function readAuditInteger(
  value: unknown,
  fieldName: string,
  max = 1000
): number {
  if (typeof value !== "number" || !Number.isFinite(value)) {
    throw new HttpsError("invalid-argument", `${fieldName} inválido.`);
  }

  const normalized = Math.floor(value);
  if (normalized < 0 || normalized > max) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} fora do intervalo.`
    );
  }

  return normalized;
}

/**
 * Gera identificador/bucket horário para agregação de auditoria.
 *
 * @param {Date} now - Data/hora de referência.
 * @return {{bucketId: string, bucketStart: Timestamp}} Bucket normalizado.
 */
function getRankingAuditBucket(now: Date): {
  bucketId: string;
  bucketStart: Timestamp;
} {
  const bucketDate = new Date(
    Date.UTC(
      now.getUTCFullYear(),
      now.getUTCMonth(),
      now.getUTCDate(),
      now.getUTCHours()
    )
  );

  const bucketId = [
    "ranking_audit_hourly",
    bucketDate.getUTCFullYear(),
    String(bucketDate.getUTCMonth() + 1).padStart(2, "0"),
    String(bucketDate.getUTCDate()).padStart(2, "0"),
    String(bucketDate.getUTCHours()).padStart(2, "0"),
  ].join("_");

  return {
    bucketId,
    bucketStart: Timestamp.fromDate(bucketDate),
  };
}

/**
 * Cloud Function: getRemainingLikes.
 */
export const getRemainingLikes = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 5,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<RemainingLikesResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const userId = request.auth.uid;

    try {
      const userDoc = await db.collection("users").doc(userId).get();

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Usuário não encontrado");
      }

      const userData = userDoc.data() || {};
      const now = Timestamp.now();
      const today = new Date(now.toDate().setHours(0, 0, 0, 0));
      const dailyLikesSnapshot = getRemainingLikesSnapshot(userData);

      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      return {
        remaining: dailyLikesSnapshot.remainingLikes,
        limit: dailyLikesSnapshot.dailySwipeLimit,
        resetTime: tomorrow.toISOString(),
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      console.error("Erro em getRemainingLikes:", error);
      throw new HttpsError("internal", "Erro ao consultar swipes");
    }
  }
);
