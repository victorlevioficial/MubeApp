/**
 * Cloud Functions para painel Admin.
 *
 * Todas as funções verificam `context.auth.token.admin === true`
 * antes de executar qualquer operação.
 */

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";

const db = admin.firestore();

// ================================================================
// HELPER: Verifica se o caller é admin
// ================================================================
/**
 * Verifica se a requisição veio de um admin.
 * @param {Object} context Contexto da requisição.
 */
function assertAdmin(context: { auth?: { token?: Record<string, unknown> } }) {
  if (!context.auth || !context.auth.token?.admin) {
    throw new HttpsError(
      "permission-denied",
      "Acesso restrito a administradores."
    );
  }
}

function readAuditNumber(
  data: FirebaseFirestore.DocumentData,
  field: string
): number {
  const raw = data[field];
  if (typeof raw !== "number" || !Number.isFinite(raw)) {
    return 0;
  }

  return Math.max(0, Math.floor(raw));
}

const USER_PAGE_SCAN_LIMIT = 400;
const USER_QUERY_BATCH_SIZE = 80;

type AdminUserListFilters = {
  status: string;
  profileType: string;
  registrationStatus: string;
};

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value) ? value as Record<string, unknown> : {};
}

function firstNonEmptyString(values: unknown[], fallback = ""): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }

  return fallback;
}

function toNonNegativeInt(value: unknown): number {
  const num = Number(value);
  if (!Number.isFinite(num)) return 0;
  return Math.max(0, Math.floor(num));
}

function parseDateStringToMillis(value: string | null | undefined): number | null {
  if (!value) return null;
  const millis = Date.parse(value);
  return Number.isFinite(millis) ? millis : null;
}

function getTimestampMillis(value: unknown): number | null {
  if (value instanceof Timestamp) {
    return value.toMillis();
  }

  if (value instanceof Date) {
    return value.getTime();
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.floor(value);
  }

  if (typeof value === "string" && value.trim().length > 0) {
    return parseDateStringToMillis(value.trim());
  }

  const raw = asRecord(value);
  const seconds = Number(raw._seconds);
  if (Number.isFinite(seconds)) {
    const nanos = Number(raw._nanoseconds);
    const millisFromNanos = Number.isFinite(nanos) ? nanos / 1e6 : 0;
    return Math.floor(seconds * 1000 + millisFromNanos);
  }

  return null;
}

function normalizeText(value: string): string {
  return value
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .trim();
}

function buildShortPersonName(fullName: string): string {
  const normalized = fullName.trim().replace(/\s+/g, " ");
  if (!normalized) return "";

  const parts = normalized.split(" ");
  if (parts.length <= 2) return normalized;

  const connectors = new Set(["de", "da", "do", "dos", "das", "e"]);
  const takeCount = connectors.has(parts[1].toLowerCase()) ? 3 : 2;
  return parts.slice(0, takeCount).join(" ");
}

function resolveUserDisplayName(userData: Record<string, unknown>): string {
  const profileType = firstNonEmptyString([
    userData.tipo_perfil,
    userData.tipoPerfil,
  ]);
  const professional = asRecord(userData.profissional);
  const band = asRecord(userData.banda);
  const studio = asRecord(userData.estudio);
  const contractor = asRecord(userData.contratante);
  const registrationName = firstNonEmptyString([userData.nome]);

  switch (profileType) {
  case "profissional":
    return firstNonEmptyString([
      professional.nomeArtistico,
      userData.nome_artistico,
      registrationName,
    ], "Profissional");
  case "banda":
    return firstNonEmptyString([
      band.nomeBanda,
      band.nomeArtistico,
      band.nome,
      registrationName,
    ], "Banda");
  case "estudio":
    return firstNonEmptyString([
      studio.nomeEstudio,
      studio.nomeArtistico,
      studio.nome,
      registrationName,
    ], "Estúdio");
  case "contratante":
    return firstNonEmptyString([
      contractor.nomeExibicao,
      buildShortPersonName(registrationName),
      registrationName,
    ], "Contratante");
  default:
    return firstNonEmptyString([registrationName], "Perfil");
  }
}

function resolveProfileType(rawValue: unknown): { key: string; label: string } {
  const raw = firstNonEmptyString([rawValue]).toLowerCase();
  switch (raw) {
  case "profissional":
    return { key: "profissional", label: "Profissional" };
  case "banda":
    return { key: "banda", label: "Banda" };
  case "estudio":
    return { key: "estudio", label: "Estúdio" };
  case "contratante":
    return { key: "contratante", label: "Contratante" };
  default:
    return {
      key: raw || "desconhecido",
      label: raw || "Desconhecido",
    };
  }
}

function normalizeUserStatus(
  rawValue: unknown
): { key: string; label: string; raw: string } {
  const raw = firstNonEmptyString([rawValue], "ativo");
  const normalized = raw.toLowerCase();

  switch (normalized) {
  case "ativo":
  case "active":
    return { key: "active", label: "Ativo", raw };
  case "suspenso":
  case "suspended":
    return { key: "suspended", label: "Suspenso", raw };
  case "rascunho":
  case "draft":
    return { key: "draft", label: "Rascunho", raw };
  case "inativo":
  case "inactive":
    return { key: "inactive", label: "Inativo", raw };
  default:
    return { key: "pending", label: raw || "Pendente", raw };
  }
}

function normalizeRegistrationStatus(
  rawValue: unknown
): { key: string; label: string; raw: string } {
  const raw = firstNonEmptyString([rawValue], "tipo_pendente");

  switch (raw) {
  case "concluido":
    return { key: "completed", label: "Concluído", raw };
  case "perfil_pendente":
    return { key: "profile-pending", label: "Perfil pendente", raw };
  case "tipo_pendente":
    return { key: "type-pending", label: "Tipo pendente", raw };
  default:
    return {
      key: raw || "unknown",
      label: raw || "Desconhecido",
      raw,
    };
  }
}

function resolvePrimaryAddress(userData: Record<string, unknown>): Record<string, unknown> {
  const addresses = Array.isArray(userData.addresses) ? userData.addresses : [];

  const addressRecords = addresses
    .map((item) => asRecord(item))
    .filter((item) => Object.keys(item).length > 0);

  return (
    addressRecords.find((item) => item.isPrimary === true) ||
    addressRecords[0] ||
    asRecord(userData.location)
  );
}

function resolveUserLocation(userData: Record<string, unknown>): {
  bairro: string;
  cidade: string;
  estado: string;
  display: string;
} {
  const address = resolvePrimaryAddress(userData);
  const location = asRecord(userData.location);

  const bairro = firstNonEmptyString([address.bairro, location.bairro]);
  const cidade = firstNonEmptyString([
    address.cidade,
    location.cidade,
    userData.cidade,
  ]);
  const estado = firstNonEmptyString([
    address.estado,
    location.estado,
    userData.estado,
  ]);

  const displayParts = [];
  if (bairro) displayParts.push(bairro);
  if (cidade && estado) {
    displayParts.push(`${cidade} - ${estado}`);
  } else if (cidade) {
    displayParts.push(cidade);
  } else if (estado) {
    displayParts.push(estado);
  }

  return {
    bairro,
    cidade,
    estado,
    display: displayParts.join(" • "),
  };
}

function matchesAdminFilters(
  userData: Record<string, unknown>,
  filters: AdminUserListFilters
): boolean {
  const status = normalizeUserStatus(userData.status).key;
  const profileType = resolveProfileType(
    firstNonEmptyString([userData.tipo_perfil, userData.tipoPerfil])
  ).key;
  const registrationStatus = firstNonEmptyString([
    userData.cadastro_status,
  ], "tipo_pendente");

  if (filters.status !== "all" && status !== filters.status) {
    return false;
  }

  if (filters.profileType !== "all" && profileType !== filters.profileType) {
    return false;
  }

  if (
    filters.registrationStatus !== "all" &&
    registrationStatus !== filters.registrationStatus
  ) {
    return false;
  }

  return true;
}

function buildOrderedUsersQuery(
  createdAtCursor: Timestamp | null = null,
  uidCursor = ""
): FirebaseFirestore.Query {
  let query = db.collection("users")
    .orderBy("created_at", "desc")
    .orderBy(admin.firestore.FieldPath.documentId(), "desc") as
      FirebaseFirestore.Query;

  if (createdAtCursor && uidCursor) {
    query = query.startAfter(createdAtCursor, uidCursor);
  }

  return query;
}

async function loadAuthUsersByUid(
  uids: string[]
): Promise<Map<string, admin.auth.UserRecord>> {
  const authMap = new Map<string, admin.auth.UserRecord>();
  const uniqueUids = [...new Set(uids.filter((uid) => uid.trim().length > 0))];

  for (let i = 0; i < uniqueUids.length; i += 100) {
    const batch = uniqueUids.slice(i, i + 100);
    const result = await admin.auth().getUsers(
      batch.map((uid) => ({ uid }))
    );

    for (const user of result.users) {
      authMap.set(user.uid, user);
    }
  }

  return authMap;
}

async function loadModerationByUid(
  uids: string[]
): Promise<Map<string, Record<string, unknown>>> {
  const moderationMap = new Map<string, Record<string, unknown>>();
  const uniqueUids = [...new Set(uids.filter((uid) => uid.trim().length > 0))];

  if (uniqueUids.length === 0) {
    return moderationMap;
  }

  const snapshots = await db.getAll(
    ...uniqueUids.map((uid) => db.collection("userModerations").doc(uid))
  );

  for (const snapshot of snapshots) {
    if (snapshot.exists) {
      moderationMap.set(snapshot.id, snapshot.data() || {});
    }
  }

  return moderationMap;
}

function buildAdminUserPayload(
  uid: string,
  userData: Record<string, unknown>,
  authRecord?: admin.auth.UserRecord | null,
  moderationData?: Record<string, unknown> | null
): Record<string, unknown> {
  const registrationName = firstNonEmptyString([userData.nome]);
  const displayName = resolveUserDisplayName(userData);
  const profileType = resolveProfileType(
    firstNonEmptyString([userData.tipo_perfil, userData.tipoPerfil])
  );
  const status = normalizeUserStatus(userData.status);
  const registrationStatus = normalizeRegistrationStatus(userData.cadastro_status);
  const location = resolveUserLocation(userData);
  const privacySettings = asRecord(userData.privacy_settings);
  const matchpointProfile = asRecord(userData.matchpoint_profile);
  const blockedUsers = Array.isArray(userData.blocked_users) ?
    userData.blocked_users.filter((item) => typeof item === "string") :
    [];
  const addresses = Array.isArray(userData.addresses) ?
    userData.addresses
      .map((item) => asRecord(item))
      .filter((item) => Object.keys(item).length > 0) :
    [];
  const favoritesCount = toNonNegativeInt(
    userData.favorites_count ?? userData.likeCount
  );

  return {
    uid,
    nome: displayName || registrationName || uid,
    displayName: displayName || registrationName || uid,
    nomeCadastro: registrationName,
    email: firstNonEmptyString([userData.email, authRecord?.email]),
    foto: firstNonEmptyString([userData.foto, authRecord?.photoURL]),
    tipoPerfil: profileType.key,
    tipoPerfilLabel: profileType.label,
    status: status.key,
    statusKey: status.key,
    statusLabel: status.label,
    statusRaw: status.raw,
    cadastroStatus: registrationStatus.raw,
    cadastroStatusKey: registrationStatus.key,
    cadastroStatusLabel: registrationStatus.label,
    bairro: location.bairro,
    cidade: location.cidade,
    estado: location.estado,
    displayLocation: location.display,
    bio: firstNonEmptyString([userData.bio]),
    createdAt:
      getTimestampMillis(userData.created_at) ||
      getTimestampMillis(userData.createdAt) ||
      parseDateStringToMillis(authRecord?.metadata.creationTime),
    updatedAt:
      getTimestampMillis(userData.updated_at) ||
      getTimestampMillis(userData.updatedAt),
    lastSignInAt: parseDateStringToMillis(authRecord?.metadata.lastSignInTime),
    suspendedUntil:
      getTimestampMillis(userData.suspended_until) ||
      getTimestampMillis(userData.suspension_end_date),
    likeCount: favoritesCount,
    favoritesCount,
    reportCount: toNonNegativeInt(
      moderationData?.report_count ?? userData.report_count
    ),
    suspensionCount: toNonNegativeInt(moderationData?.suspension_count),
    blockedUsersCount: blockedUsers.length,
    addressesCount: addresses.length,
    emailVerified: authRecord?.emailVerified ?? false,
    authDisabled: authRecord?.disabled ?? false,
    authExists: Boolean(authRecord),
    providerIds: (authRecord?.providerData || [])
      .map((provider) => provider.providerId)
      .filter((providerId) => typeof providerId === "string"),
    visibleInHome: privacySettings.visible_in_home !== false,
    visibleInSearch: privacySettings.visible_in_search !== false,
    ghostMode: privacySettings.ghost_mode === true,
    matchpointActive: matchpointProfile.is_active === true,
    hasPhoto: firstNonEmptyString([userData.foto, authRecord?.photoURL]).length > 0,
  };
}

async function buildAdminUsersFromDocs(
  docs: Array<
    FirebaseFirestore.QueryDocumentSnapshot |
    FirebaseFirestore.DocumentSnapshot
  >
): Promise<Record<string, unknown>[]> {
  const items = docs
    .filter((doc) => doc.exists)
    .map((doc) => ({
      uid: doc.id,
      data: (doc.data() || {}) as Record<string, unknown>,
    }));
  const authMap = await loadAuthUsersByUid(items.map((item) => item.uid));
  const moderationMap = await loadModerationByUid(items.map((item) => item.uid));

  return items.map((item) => buildAdminUserPayload(
    item.uid,
    item.data,
    authMap.get(item.uid) || null,
    moderationMap.get(item.uid) || null
  ));
}

function matchesAdminSearch(
  user: Record<string, unknown>,
  query: string
): boolean {
  const normalizedQuery = normalizeText(query);
  if (!normalizedQuery) return true;

  const haystack = [
    user.uid,
    user.nome,
    user.displayName,
    user.nomeCadastro,
    user.email,
    user.tipoPerfilLabel,
    user.bairro,
    user.cidade,
    user.estado,
  ]
    .map((value) => normalizeText(String(value || "")))
    .join(" ");

  return haystack.includes(normalizedQuery);
}

async function collectAdminUserDocsPage(params: {
  pageSize: number;
  cursorCreatedAtMs?: number | null;
  cursorUid?: string;
  filters: AdminUserListFilters;
  scanLimit?: number;
}): Promise<{
  docs: FirebaseFirestore.QueryDocumentSnapshot[];
  lastScannedDoc: FirebaseFirestore.QueryDocumentSnapshot | null;
  hasMore: boolean;
  scannedCount: number;
}> {
  const {
    pageSize,
    cursorCreatedAtMs,
    cursorUid = "",
    filters,
    scanLimit = USER_PAGE_SCAN_LIMIT,
  } = params;

  let query = buildOrderedUsersQuery(
    cursorCreatedAtMs != null ? Timestamp.fromMillis(cursorCreatedAtMs) : null,
    cursorUid
  );
  const matchedDocs: FirebaseFirestore.QueryDocumentSnapshot[] = [];
  let lastScannedDoc: FirebaseFirestore.QueryDocumentSnapshot | null = null;
  let scannedCount = 0;
  let hasMore = false;

  while (matchedDocs.length < pageSize && scannedCount < scanLimit) {
    const remainingToScan = scanLimit - scannedCount;
    const batchSize = Math.min(USER_QUERY_BATCH_SIZE, remainingToScan);
    const snap = await query.limit(batchSize).get();

    if (snap.empty) {
      hasMore = false;
      break;
    }

    for (let i = 0; i < snap.docs.length; i++) {
      const doc = snap.docs[i];
      const data = doc.data() as Record<string, unknown>;

      scannedCount += 1;
      lastScannedDoc = doc;

      if (matchesAdminFilters(data, filters)) {
        matchedDocs.push(doc);
      }

      if (matchedDocs.length >= pageSize) {
        hasMore = i < snap.docs.length - 1 || snap.docs.length === batchSize;
        break;
      }
    }

    if (matchedDocs.length >= pageSize) {
      break;
    }

    if (snap.docs.length < batchSize) {
      hasMore = false;
      break;
    }

    if (!lastScannedDoc) {
      hasMore = false;
      break;
    }

    const lastCreatedAt = lastScannedDoc.get("created_at");
    if (!(lastCreatedAt instanceof Timestamp)) {
      hasMore = false;
      break;
    }

    hasMore = true;
    query = buildOrderedUsersQuery(lastCreatedAt, lastScannedDoc.id);
  }

  if (scannedCount >= scanLimit && matchedDocs.length < pageSize) {
    hasMore = true;
  }

  return {
    docs: matchedDocs,
    lastScannedDoc,
    hasMore,
    scannedCount,
  };
}

type QueryFilter = [string, FirebaseFirestore.WhereFilterOp, unknown];

type QueryDocsOptions = {
  collectionPath?: string;
  collectionGroupId?: string;
  filters?: QueryFilter[];
  orderByField?: string;
  direction?: FirebaseFirestore.OrderByDirection;
  limit?: number;
};

function normalizePath(path: string): string {
  return path
    .trim()
    .replace(/\\/g, "/")
    .replace(/^\/+|\/+$/g, "");
}

function normalizeLimit(
  value: unknown,
  fallback = 20,
  max = 100
): number {
  const raw = Number(value);
  if (!Number.isFinite(raw)) return fallback;
  return Math.min(Math.max(Math.floor(raw), 1), max);
}

function uniqueStrings(values: string[]): string[] {
  return [...new Set(values.map((value) => value.trim()).filter(Boolean))];
}

function isDocumentReferenceLike(
  value: unknown
): value is { id: string; path: string; get: unknown } {
  const raw = value as Record<string, unknown>;
  return raw != null &&
    typeof raw === "object" &&
    typeof raw.id === "string" &&
    typeof raw.path === "string" &&
    "get" in raw;
}

function serializeAdminValue(value: unknown): unknown {
  if (value == null) return null;

  if (value instanceof Timestamp) {
    return {
      __type: "timestamp",
      millis: value.toMillis(),
      iso: value.toDate().toISOString(),
    };
  }

  if (value instanceof Date) {
    return {
      __type: "date",
      millis: value.getTime(),
      iso: value.toISOString(),
    };
  }

  if (
    typeof value === "string" ||
    typeof value === "number" ||
    typeof value === "boolean"
  ) {
    return value;
  }

  if (Array.isArray(value)) {
    return value.map((item) => serializeAdminValue(item));
  }

  const maybeGeoPoint = value as Record<string, unknown>;
  if (
    typeof maybeGeoPoint.latitude === "number" &&
    typeof maybeGeoPoint.longitude === "number"
  ) {
    return {
      __type: "geopoint",
      latitude: maybeGeoPoint.latitude,
      longitude: maybeGeoPoint.longitude,
    };
  }

  if (isDocumentReferenceLike(value)) {
    return {
      __type: "document_reference",
      id: value.id,
      path: value.path,
    };
  }

  const record = asRecord(value);
  const serializedEntries = Object.entries(record).map(([key, itemValue]) => [
    key,
    serializeAdminValue(itemValue),
  ]);
  return Object.fromEntries(serializedEntries);
}

function serializeSnapshot(
  snapshot:
    | FirebaseFirestore.DocumentSnapshot
    | FirebaseFirestore.QueryDocumentSnapshot
): Record<string, unknown> {
  return {
    id: snapshot.id,
    path: snapshot.ref.path,
    exists: snapshot.exists,
    data: snapshot.exists ? serializeAdminValue(snapshot.data() || {}) : null,
  };
}

async function loadAdminUsersMapByUid(
  uids: string[]
): Promise<Map<string, Record<string, unknown>>> {
  const uniqueUids = uniqueStrings(uids);
  if (uniqueUids.length === 0) {
    return new Map<string, Record<string, unknown>>();
  }

  const snapshots = await db.getAll(
    ...uniqueUids.map((uid) => db.collection("users").doc(uid))
  );
  const payloads = await buildAdminUsersFromDocs(snapshots);
  return new Map(
    payloads.map((payload) => [String(payload.uid || ""), payload])
  );
}

async function fetchQueryDocs(
  options: QueryDocsOptions
): Promise<FirebaseFirestore.QueryDocumentSnapshot[]> {
  const limit = normalizeLimit(options.limit, 20, 120);
  let query: FirebaseFirestore.Query;

  if (options.collectionGroupId) {
    query = db.collectionGroup(options.collectionGroupId);
  } else if (options.collectionPath) {
    query = db.collection(options.collectionPath);
  } else {
    throw new HttpsError(
      "invalid-argument",
      "collectionPath ou collectionGroupId é obrigatório."
    );
  }

  for (const [field, operator, value] of options.filters || []) {
    query = query.where(field, operator, value);
  }

  if (options.orderByField) {
    try {
      const orderedSnapshot = await query
        .orderBy(options.orderByField, options.direction || "desc")
        .limit(limit)
        .get();
      return orderedSnapshot.docs;
    } catch (error) {
      console.warn(
        "Admin query fallback without orderBy",
        options.collectionPath || options.collectionGroupId,
        options.orderByField,
        error
      );
    }
  }

  const snapshot = await query.limit(limit).get();
  return snapshot.docs;
}

async function countQueryDocuments(
  collectionPath: string,
  filters: QueryFilter[] = []
): Promise<number> {
  let query: FirebaseFirestore.Query = db.collection(collectionPath);
  for (const [field, operator, value] of filters) {
    query = query.where(field, operator, value);
  }

  const snapshot = await query.count().get();
  return snapshot.data().count || 0;
}

async function listDocumentSubcollections(
  docRef: FirebaseFirestore.DocumentReference
): Promise<Array<Record<string, unknown>>> {
  const collections = await docRef.listCollections();
  return collections.map((collection) => ({
    id: collection.id,
    path: collection.path,
  }));
}

function buildAdminGigListItem(
  doc: FirebaseFirestore.QueryDocumentSnapshot | FirebaseFirestore.DocumentSnapshot,
  creatorMap: Map<string, Record<string, unknown>>
): Record<string, unknown> {
  const data = (doc.data() || {}) as Record<string, unknown>;
  const creatorId = firstNonEmptyString([data.creator_id]);

  return {
    id: doc.id,
    path: doc.ref.path,
    title: firstNonEmptyString([data.title], "Sem título"),
    description: firstNonEmptyString([data.description]),
    gigType: firstNonEmptyString([data.gig_type], "outro"),
    status: firstNonEmptyString([data.status], "open"),
    dateMode: firstNonEmptyString([data.date_mode], "unspecified"),
    locationType: firstNonEmptyString([data.location_type], "presencial"),
    applicantCount: toNonNegativeInt(data.applicant_count),
    slotsTotal: toNonNegativeInt(data.slots_total),
    slotsFilled: toNonNegativeInt(data.slots_filled),
    compensationType: firstNonEmptyString([data.compensation_type], "tbd"),
    compensationValue: data.compensation_value ?? null,
    creatorId,
    creator: creatorId ? creatorMap.get(creatorId) || { uid: creatorId } : null,
    createdAt: getTimestampMillis(data.created_at),
    updatedAt: getTimestampMillis(data.updated_at),
    expiresAt: getTimestampMillis(data.expires_at),
    location: serializeAdminValue(data.location),
    raw: serializeAdminValue(data),
  };
}

async function buildAdminGigList(
  docs: Array<FirebaseFirestore.QueryDocumentSnapshot | FirebaseFirestore.DocumentSnapshot>
): Promise<Record<string, unknown>[]> {
  const creatorIds = uniqueStrings(
    docs.map((doc) => firstNonEmptyString([(doc.data() || {}).creator_id]))
  );
  const creatorMap = await loadAdminUsersMapByUid(creatorIds);
  return docs.map((doc) => buildAdminGigListItem(doc, creatorMap));
}

async function buildConversationPayloads(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): Promise<Record<string, unknown>[]> {
  const participantIds = uniqueStrings(
    docs.flatMap((doc) => {
      const data = doc.data();
      return Array.isArray(data.participants) ?
        data.participants.filter(
          (item): item is string => typeof item === "string"
        ) :
        [];
    })
  );
  const userMap = await loadAdminUsersMapByUid(participantIds);

  return docs.map((doc) => {
    const data = doc.data();
    const participantUids = Array.isArray(data.participants) ?
      data.participants.filter(
        (item): item is string => typeof item === "string"
      ) :
      [];

    return {
      id: doc.id,
      path: doc.ref.path,
      type: firstNonEmptyString([data.type], "direct"),
      participants: participantUids.map((uid) => userMap.get(uid) || { uid }),
      participantUids,
      lastMessageText: firstNonEmptyString([data.lastMessageText]),
      lastSenderId: firstNonEmptyString([data.lastSenderId]),
      createdAt: getTimestampMillis(data.createdAt),
      updatedAt: getTimestampMillis(data.updatedAt),
      lastMessageAt: getTimestampMillis(data.lastMessageAt),
      raw: serializeAdminValue(data),
    };
  });
}

async function buildMatchPayloads(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): Promise<Record<string, unknown>[]> {
  const userIds = uniqueStrings(
    docs.flatMap((doc) => {
      const data = doc.data();
      return Array.isArray(data.user_ids) ?
        data.user_ids.filter((item): item is string => typeof item === "string") :
        [];
    })
  );
  const userMap = await loadAdminUsersMapByUid(userIds);

  return docs.map((doc) => {
    const data = doc.data();
    const participants = Array.isArray(data.user_ids) ?
      data.user_ids.filter((item): item is string => typeof item === "string") :
      [];

    return {
      id: doc.id,
      path: doc.ref.path,
      createdAt: getTimestampMillis(data.created_at ?? data.createdAt),
      conversationId: firstNonEmptyString([
        data.conversation_id,
        data.conversationId,
      ]),
      users: participants.map((uid) => userMap.get(uid) || { uid }),
      raw: serializeAdminValue(data),
    };
  });
}

async function buildInteractionPayloads(
  docs: FirebaseFirestore.QueryDocumentSnapshot[]
): Promise<Record<string, unknown>[]> {
  const userIds = uniqueStrings(
    docs.flatMap((doc) => {
      const data = doc.data();
      return [
        firstNonEmptyString([data.source_user_id]),
        firstNonEmptyString([data.target_user_id]),
      ];
    })
  );
  const userMap = await loadAdminUsersMapByUid(userIds);

  return docs.map((doc) => {
    const data = doc.data();
    const sourceUserId = firstNonEmptyString([data.source_user_id]);
    const targetUserId = firstNonEmptyString([data.target_user_id]);

    return {
      id: doc.id,
      path: doc.ref.path,
      type: firstNonEmptyString([data.type], "unknown"),
      sourceUserId,
      targetUserId,
      sourceUser: sourceUserId ?
        userMap.get(sourceUserId) || { uid: sourceUserId } :
        null,
      targetUser: targetUserId ?
        userMap.get(targetUserId) || { uid: targetUserId } :
        null,
      createdAt: getTimestampMillis(data.created_at),
      raw: serializeAdminValue(data),
    };
  });
}

// ================================================================
// AUTH: Definir custom claim admin
// ================================================================
export const setAdminClaim = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    // Bootstrap: permite que o primeiro admin se configure
    // OR já é admin e está configurando outro
    const callerUid = request.auth?.uid;
    const targetEmail = request.data?.email as string;

    if (!targetEmail) {
      throw new HttpsError("invalid-argument", "Email é obrigatório.");
    }

    // Se já existe algum admin, exigir que o caller seja admin
    const isCallerAdmin = request.auth?.token?.admin === true;
    if (!isCallerAdmin) {
      // Verificar se é o bootstrap (nenhum admin existe)
      const configRef = db.collection("config").doc("admin");
      const configDoc = await configRef.get();
      if (configDoc.exists) {
        throw new HttpsError(
          "permission-denied",
          "Admin já configurado. Peça a um admin existente."
        );
      }
    }

    try {
      const userRecord = await admin.auth().getUserByEmail(targetEmail);
      await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });

      // Gravar registro no Firestore
      await db.collection("config").doc("admin").set(
        {
          adminUids: admin.firestore.FieldValue.arrayUnion(userRecord.uid),
          updatedAt: Timestamp.now(),
          updatedBy: callerUid || "bootstrap",
        },
        { merge: true }
      );

      console.log(
        `Admin claim definido para ${targetEmail} (${userRecord.uid})`
      );
      return { success: true, uid: userRecord.uid };
    } catch (error) {
      console.error("Erro ao definir admin claim:", error);
      throw new HttpsError("internal", "Erro ao configurar admin.");
    }
  }
);

// ================================================================
// FEATURED PROFILES
// ================================================================
export const setFeaturedProfiles = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const uids = request.data?.uids as string[];
    if (!Array.isArray(uids)) {
      throw new HttpsError("invalid-argument", "uids deve ser um array.");
    }

    // Validar que os UIDs existem
    const validUids: string[] = [];
    for (const uid of uids) {
      const userDoc = await db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        validUids.push(uid);
      } else {
        console.warn(`UID ${uid} não encontrado, ignorando.`);
      }
    }

    await db.collection("config").doc("featuredProfiles").set({
      uids: validUids,
      updatedAt: Timestamp.now(),
      updatedBy: request.auth?.uid || "unknown",
    });

    console.log(`Featured profiles atualizados: ${validUids.length} perfis`);
    return { success: true, uids: validUids };
  }
);

export const getFeaturedProfiles = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const doc = await db.collection("config").doc("featuredProfiles").get();
    if (!doc.exists) {
      return { uids: [], profiles: [] };
    }

    const data = doc.data() || {};
    const uids = (data.uids as string[]) || [];

    // Buscar dados de cada perfil
    const profiles = [];
    for (const uid of uids) {
      const userDoc = await db.collection("users").doc(uid).get();
      if (userDoc.exists) {
        const userData = userDoc.data() || {};
        const payload = buildAdminUserPayload(
          uid,
          userData as Record<string, unknown>
        );
        profiles.push({
          uid,
          nome: payload.nome,
          foto: payload.foto,
          tipoPerfil: payload.tipoPerfilLabel,
          likeCount: payload.likeCount,
          cidade: payload.cidade,
        });
      }
    }

    return { uids, profiles };
  }
);

// ================================================================
// USER LOOKUP & SEARCH
// ================================================================
export const lookupUser = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const uid = request.data?.uid as string;
    if (!uid) {
      throw new HttpsError("invalid-argument", "UID é obrigatório.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const userData = userDoc.data() || {};

    let authRecord: admin.auth.UserRecord | null = null;
    try {
      authRecord = await admin.auth().getUser(uid);
    } catch (error) {
      console.warn(`Auth record não encontrado para ${uid}:`, error);
    }

    const modDoc = await db.collection("userModerations").doc(uid).get();
    const modData = modDoc.exists ? modDoc.data() : null;

    return buildAdminUserPayload(
      uid,
      userData as Record<string, unknown>,
      authRecord,
      modData as Record<string, unknown> | null
    );
  }
);

export const searchUsers = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const rawQuery = (request.data?.query as string || "").trim();
    const limit = Math.min((request.data?.limit as number) || 20, 50);

    if (!rawQuery || rawQuery.length < 2) {
      const page = await collectAdminUserDocsPage({
        pageSize: limit,
        filters: {
          status: "all",
          profileType: "all",
          registrationStatus: "all",
        },
        scanLimit: Math.max(limit * 4, 120),
      });

      const results = await buildAdminUsersFromDocs(page.docs);
      return { results, total: results.length };
    }

    const userDocsByUid = new Map<string, FirebaseFirestore.DocumentSnapshot>();
    const trimmedQuery = rawQuery.trim();

    if (trimmedQuery.length > 20 && !trimmedQuery.includes(" ")) {
      const exactDoc = await db.collection("users").doc(trimmedQuery).get();
      if (exactDoc.exists) {
        userDocsByUid.set(exactDoc.id, exactDoc);
      }
    }

    if (trimmedQuery.includes("@")) {
      const emailSnap = await db.collection("users")
        .where("email", "==", trimmedQuery)
        .limit(Math.min(limit, 10))
        .get();

      for (const doc of emailSnap.docs) {
        userDocsByUid.set(doc.id, doc);
      }
    }

    const searchPoolLimit = Math.min(Math.max(limit * 12, 200), 500);
    const recentSnap = await buildOrderedUsersQuery()
      .limit(searchPoolLimit)
      .get();

    for (const doc of recentSnap.docs) {
      userDocsByUid.set(doc.id, doc);
    }

    const enrichedUsers = await buildAdminUsersFromDocs([...userDocsByUid.values()]);
    const results = enrichedUsers
      .filter((user) => matchesAdminSearch(user, trimmedQuery))
      .sort((a, b) => toNonNegativeInt(b.createdAt) - toNonNegativeInt(a.createdAt))
      .slice(0, limit);

    return { results, total: results.length };
  }
);

export const listUsersAdmin = onCall(
  { region: "southamerica-east1", memory: "512MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const rawPageSize = Number(request.data?.pageSize ?? 24);
    const pageSize = Math.min(
      Math.max(Number.isFinite(rawPageSize) ? Math.floor(rawPageSize) : 24, 1),
      60
    );
    const cursor = asRecord(request.data?.cursor);
    const includeTotal = request.data?.includeTotal !== false;
    const filters: AdminUserListFilters = {
      status: firstNonEmptyString([request.data?.status], "all"),
      profileType: firstNonEmptyString([request.data?.profileType], "all"),
      registrationStatus: firstNonEmptyString(
        [request.data?.registrationStatus],
        "all"
      ),
    };

    const page = await collectAdminUserDocsPage({
      pageSize,
      cursorCreatedAtMs: getTimestampMillis(cursor.createdAt),
      cursorUid: firstNonEmptyString([cursor.uid]),
      filters,
    });
    const users = await buildAdminUsersFromDocs(page.docs);
    const lastReturnedDoc = page.lastScannedDoc;
    const totalUsersBase = includeTotal ?
      (await db.collection("users").count().get()).data().count || 0 :
      null;

    return {
      users,
      totalUsersBase,
      scannedCount: page.scannedCount,
      hasMore: page.hasMore,
      nextCursor: lastReturnedDoc ? {
        uid: lastReturnedDoc.id,
        createdAt: getTimestampMillis(lastReturnedDoc.get("created_at")),
      } : null,
    };
  }
);

// ================================================================
// REPORTS / DENÚNCIAS
// ================================================================
export const listReports = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const status = (request.data?.status as string) || "all";
    const limit = normalizeLimit(request.data?.limit, 20, 100);

    let query = db.collection("reports")
      .orderBy("created_at", "desc") as FirebaseFirestore.Query;

    if (status !== "all") {
      query = query.where("status", "==", status);
    }

    const snap = await query.limit(limit).get();

    // Processar de forma paralela as leituras de nomes
    const reports = await Promise.all(snap.docs.map(async (doc) => {
      const data = doc.data();

      let reportedName = data.reported_item_id || "";
      if (data.reported_item_type === "user" && data.reported_item_id) {
        const u = await db.collection("users").doc(data.reported_item_id).get();
        if (u.exists) {
          reportedName = u.data()?.nome ||
            u.data()?.name ||
            data.reported_item_id;
        }
      }

      return {
        id: doc.id,
        reporterUserId: data.reporter_user_id || "",
        reportedItemId: data.reported_item_id || "",
        reportedItemType: data.reported_item_type || "",
        reportedName,
        reason: data.reason || "",
        description: data.description || "",
        status: data.status || "pending",
        createdAt: data.created_at || null,
        processedAt: data.processed_at || null,
      };
    }));

    return { reports, total: reports.length };
  }
);

export const updateReportStatus = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const reportId = request.data?.reportId as string;
    const newStatus = request.data?.status as string;

    if (!reportId || !newStatus) {
      throw new HttpsError(
        "invalid-argument",
        "reportId e status são obrigatórios."
      );
    }

    const validStatuses = ["pending", "processing", "processed",
      "rejected", "invalid", "rate_limited"];
    if (!validStatuses.includes(newStatus)) {
      throw new HttpsError("invalid-argument", "Status inválido.");
    }

    await db.collection("reports").doc(reportId).update({
      status: newStatus,
      processed_at: Timestamp.now(),
      processed_by: request.auth?.uid,
    });

    return { success: true };
  }
);

// ================================================================
// SUSPENSÕES
// ================================================================
export const listSuspensions = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const statusFilter = (request.data?.status as string) || "active";
    const limit = Math.min((request.data?.limit as number) || 20, 100);

    let query = db.collection("suspensions")
      .orderBy("created_at", "desc") as FirebaseFirestore.Query;

    if (statusFilter !== "all") {
      query = query.where("status", "==", statusFilter);
    }

    const snap = await query.limit(limit).get();

    const suspensions = await Promise.all(snap.docs.map(async (doc) => {
      const data = doc.data();

      let userName = data.user_id || "";
      if (data.user_id) {
        const u = await db.collection("users").doc(data.user_id).get();
        if (u.exists) {
          userName = u.data()?.nome || u.data()?.name || data.user_id;
        }
      }

      return {
        id: doc.id,
        userId: data.user_id || "",
        userName,
        reason: data.reason || "",
        status: data.status || "active",
        createdAt: data.created_at || null,
        suspendedUntil: data.suspended_until || null,
        liftedAt: data.lifted_at || null,
        liftedBy: data.lifted_by || null,
      };
    }));

    return { suspensions, total: suspensions.length };
  }
);

export const manageSuspension = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const action = request.data?.action as string;

    if (action === "create") {
      const userId = request.data?.userId as string;
      const reason = request.data?.reason as string;
      const durationDays = (request.data?.durationDays as number) || 7;

      if (!userId || !reason) {
        throw new HttpsError(
          "invalid-argument",
          "userId e reason são obrigatórios."
        );
      }

      const now = Timestamp.now();
      const suspendedUntil = Timestamp.fromDate(
        new Date(Date.now() + durationDays * 24 * 60 * 60 * 1000)
      );

      await db.collection("suspensions").add({
        user_id: userId,
        reason,
        status: "active",
        created_at: now,
        suspended_until: suspendedUntil,
        lifted_at: null,
        lifted_by: null,
        created_by: request.auth?.uid,
      });

      await db.collection("users").doc(userId).update({
        status: "suspended",
        suspended_until: suspendedUntil,
        updated_at: now,
      });

      return { success: true, action: "created" };
    }

    if (action === "lift") {
      const suspensionId = request.data?.suspensionId as string;
      if (!suspensionId) {
        throw new HttpsError(
          "invalid-argument",
          "suspensionId é obrigatório."
        );
      }

      const now = Timestamp.now();
      const suspDoc = await db
        .collection("suspensions").doc(suspensionId).get();
      if (!suspDoc.exists) {
        throw new HttpsError("not-found", "Suspensão não encontrada.");
      }

      const suspData = suspDoc.data() || {};
      const userId = suspData.user_id as string;

      await db.collection("suspensions").doc(suspensionId).update({
        status: "lifted",
        lifted_at: now,
        lifted_by: request.auth?.uid,
      });

      await db.collection("users").doc(userId).update({
        status: "active",
        suspended_until: null,
        updated_at: now,
      });

      return { success: true, action: "lifted" };
    }

    throw new HttpsError(
      "invalid-argument",
      "action deve ser 'create' ou 'lift'."
    );
  }
);

// ================================================================
// TICKETS DE SUPORTE
// ================================================================
export const listTickets = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const statusFilter = (request.data?.status as string) || "all";
    const limit = normalizeLimit(request.data?.limit, 20, 100);
    const cursor = asRecord(request.data?.cursor);
    const cursorId = firstNonEmptyString([request.data?.cursor, cursor.id]);

    let query = db.collection("tickets")
      .orderBy("createdAt", "desc") as FirebaseFirestore.Query;

    if (statusFilter !== "all") {
      query = query.where("status", "==", statusFilter);
    }

    if (cursorId) {
      const cursorDoc = await db.collection("tickets").doc(cursorId).get();
      if (cursorDoc.exists) {
        query = query.startAfter(cursorDoc);
      }
    }

    const snap = await query.limit(limit + 1).get();
    const hasMore = snap.docs.length > limit;
    const pageDocs = hasMore ? snap.docs.slice(0, limit) : snap.docs;
    const tickets = pageDocs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        userId: data.userId || "",
        subject: data.subject || data.title || "",
        title: data.title || data.subject || "",
        message: data.message || data.description || "",
        description: data.description || data.message || "",
        status: data.status || "open",
        category: data.category || "",
        source: data.source || "app",
        contactName: data.contactName || "",
        contactEmail: data.contactEmail || "",
        createdAt: data.createdAt || null,
        updatedAt: data.updatedAt || null,
        adminResponse: data.adminResponse || null,
      };
    });

    return {
      tickets,
      total: tickets.length,
      hasMore,
      nextCursor: hasMore && pageDocs.length > 0 ? {
        id: pageDocs[pageDocs.length - 1].id,
      } : null,
    };
  }
);

export const updateTicket = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const ticketId = request.data?.ticketId as string;
    const newStatus = request.data?.status as string;
    const response = request.data?.response as string;

    if (!ticketId) {
      throw new HttpsError("invalid-argument", "ticketId é obrigatório.");
    }

    const updateData: Record<string, unknown> = {
      updatedAt: Timestamp.now(),
      updatedBy: request.auth?.uid,
    };

    if (newStatus) updateData.status = newStatus;
    if (response) updateData.adminResponse = response;

    await db.collection("tickets").doc(ticketId).update(updateData);

    return { success: true };
  }
);

// ================================================================
// DASHBOARD STATS
// ================================================================
export const getDashboardStats = onCall(
  { region: "southamerica-east1", memory: "512MiB" },
  async (request) => {
    assertAdmin(request);

    const now = new Date();
    const oneDayAgo = Timestamp.fromDate(
      new Date(now.getTime() - 24 * 60 * 60 * 1000)
    );
    const sevenDaysAgo = Timestamp.fromDate(
      new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
    );

    // Total users (approximation via count)
    const usersSnap = await db.collection("users").count().get();
    const totalUsers = usersSnap.data().count;

    // New users last 24h
    const newUsers24h = await db.collection("users")
      .where("created_at", ">=", oneDayAgo)
      .count().get();

    // New users last 7d
    const newUsers7d = await db.collection("users")
      .where("created_at", ">=", sevenDaysAgo)
      .count().get();

    // Pending reports
    const pendingReports = await db.collection("reports")
      .where("status", "==", "pending")
      .count().get();

    // Active suspensions
    const activeSuspensions = await db.collection("suspensions")
      .where("status", "==", "active")
      .count().get();

    // Open tickets
    const openTickets = await db.collection("tickets")
      .where("status", "==", "open")
      .count().get();

    return {
      totalUsers: totalUsers || 0,
      newUsers24h: newUsers24h.data().count || 0,
      newUsers7d: newUsers7d.data().count || 0,
      pendingReports: pendingReports.data().count || 0,
      activeSuspensions: activeSuspensions.data().count || 0,
      openTickets: openTickets.data().count || 0,
    };
  }
);

export const getMatchpointRankingAuditDashboard = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const requestedLimit = Number(request.data?.limit ?? 24);
    const limit = Math.min(
      Math.max(Number.isFinite(requestedLimit) ? Math.floor(requestedLimit) : 24, 1),
      48
    );

    const snap = await db.collection("matchpointStats")
      .where("type", "==", "ranking_audit_hourly")
      .orderBy("bucket_start", "desc")
      .limit(limit)
      .get();

    const buckets = snap.docs.map((doc) => {
      const data = doc.data();
      const bucketStart = data.bucket_start instanceof Timestamp ?
        data.bucket_start.toMillis() :
        null;

      return {
        id: doc.id,
        bucketStart,
        totalEvents: readAuditNumber(data, "total_events"),
        poolTotal: readAuditNumber(data, "pool_total_sum"),
        returnedTotal: readAuditNumber(data, "returned_total_sum"),
        returnedProximity: readAuditNumber(data, "returned_proximity_sum"),
        returnedHashtag: readAuditNumber(data, "returned_hashtag_sum"),
        returnedGenre: readAuditNumber(data, "returned_genre_sum"),
        returnedFallback: readAuditNumber(data, "returned_fallback_sum"),
        returnedLocalTotal: readAuditNumber(data, "returned_local_total_sum"),
        returnedLocalHashtag: readAuditNumber(
          data,
          "returned_local_hashtag_sum"
        ),
        returnedLocalGenre: readAuditNumber(data, "returned_local_genre_sum"),
        geohashUsedCount: readAuditNumber(data, "geohash_used_count"),
      };
    });

    const summary = buckets.reduce((acc, bucket) => {
      acc.totalEvents += bucket.totalEvents;
      acc.poolTotal += bucket.poolTotal;
      acc.returnedTotal += bucket.returnedTotal;
      acc.returnedProximity += bucket.returnedProximity;
      acc.returnedHashtag += bucket.returnedHashtag;
      acc.returnedGenre += bucket.returnedGenre;
      acc.returnedFallback += bucket.returnedFallback;
      acc.returnedLocalTotal += bucket.returnedLocalTotal;
      acc.returnedLocalHashtag += bucket.returnedLocalHashtag;
      acc.returnedLocalGenre += bucket.returnedLocalGenre;
      acc.geohashUsedCount += bucket.geohashUsedCount;
      return acc;
    }, {
      totalEvents: 0,
      poolTotal: 0,
      returnedTotal: 0,
      returnedProximity: 0,
      returnedHashtag: 0,
      returnedGenre: 0,
      returnedFallback: 0,
      returnedLocalTotal: 0,
      returnedLocalHashtag: 0,
      returnedLocalGenre: 0,
      geohashUsedCount: 0,
    });

    return {
      buckets,
      summary: {
        ...summary,
        averagePoolPerEvent: summary.totalEvents > 0 ?
          summary.poolTotal / summary.totalEvents :
          0,
        averageReturnedPerEvent: summary.totalEvents > 0 ?
          summary.returnedTotal / summary.totalEvents :
          0,
      },
    };
  }
);

// ================================================================
// CHAT MODERATION
// ================================================================
export const listConversationsLegacy = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const limit = Math.min((request.data?.limit as number) || 20, 100);

    const query = db.collection("conversations")
      .orderBy("updatedAt", "desc") as FirebaseFirestore.Query;

    const snap = await query.limit(limit).get();

    // Processar nomes dos participantes
    const conversations = await Promise.all(snap.docs.map(async (doc) => {
      const data = doc.data();
      const participants = data.participants || [];
      const usersData: Record<string, unknown>[] = [];

      for (const uid of participants) {
        if (typeof uid === "string") {
          const u = await db.collection("users").doc(uid).get();
          if (u.exists) {
            const uInfo = u.data() || {};
            usersData.push({
              uid,
              name: uInfo.nome || uInfo.name || uid,
              email: uInfo.email || "",
              photo: uInfo.foto || uInfo.photoUrl || "",
            });
          } else {
            usersData.push({ uid, name: "Usuário Desconhecido" });
          }
        }
      }

      return {
        id: doc.id,
        participants: usersData,
        type: data.type || "direct",
        createdAt: data.createdAt || null,
        updatedAt: data.updatedAt || null,
        lastMessageText: data.lastMessageText || null,
      };
    }));

    return { conversations, total: conversations.length };
  }
);

export const getConversationMessages = onCall(
  { region: "southamerica-east1", memory: "256MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const conversationId = request.data?.conversationId as string;
    const limit = Math.min((request.data?.limit as number) || 50, 200);

    if (!conversationId) {
      throw new HttpsError("invalid-argument", "conversationId é obrigatório.");
    }

    const snap = await db.collection("conversations")
      .doc(conversationId)
      .collection("messages")
      .orderBy("createdAt", "desc")
      .limit(limit)
      .get();

    const messages = snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        senderId: data.senderId,
        text: data.text || "",
        type: data.type || "text",
        createdAt: data.createdAt || null,
      };
    }).reverse();

    return { messages };
  }
);

export const getDashboardOverview = onCall(
  { region: "southamerica-east1", memory: "512MiB", invoker: "public" },
  async (request) => {
    assertAdmin(request);

    const recentUserDocsPromise = fetchQueryDocs({
      collectionPath: "users",
      orderByField: "created_at",
      limit: 8,
    });
    const recentGigDocsPromise = fetchQueryDocs({
      collectionPath: "gigs",
      orderByField: "created_at",
      limit: 6,
    });
    const recentTicketDocsPromise = fetchQueryDocs({
      collectionPath: "tickets",
      orderByField: "createdAt",
      limit: 6,
    });
    const recentReportDocsPromise = fetchQueryDocs({
      collectionPath: "reports",
      orderByField: "created_at",
      limit: 6,
    });
    const recentConversationDocsPromise = fetchQueryDocs({
      collectionPath: "conversations",
      orderByField: "updatedAt",
      limit: 6,
    });
    const recentTranscodeDocsPromise = fetchQueryDocs({
      collectionPath: "mediaTranscodeJobs",
      orderByField: "updatedAt",
      limit: 6,
    });
    const trendingHashtagsPromise = fetchQueryDocs({
      collectionPath: "hashtagRanking",
      orderByField: "use_count",
      limit: 8,
    });

    const [
      totalUsers,
      completedProfiles,
      activeMatchpointProfiles,
      totalGigs,
      openGigs,
      totalConversations,
      totalMatches,
      totalInteractions,
      pendingReports,
      activeSuspensions,
      openTickets,
      processingTranscodes,
      featuredDoc,
      appDataDoc,
      recentUserDocs,
      recentGigDocs,
      recentTicketDocs,
      recentReportDocs,
      recentConversationDocs,
      recentTranscodeDocs,
      trendingHashtagsDocs,
    ] = await Promise.all([
      countQueryDocuments("users"),
      countQueryDocuments("users", [["cadastro_status", "==", "concluido"]]),
      countQueryDocuments(
        "users",
        [["matchpoint_profile.is_active", "==", true]]
      ),
      countQueryDocuments("gigs"),
      countQueryDocuments("gigs", [["status", "==", "open"]]),
      countQueryDocuments("conversations"),
      countQueryDocuments("matches"),
      countQueryDocuments("interactions"),
      countQueryDocuments("reports", [["status", "==", "pending"]]),
      countQueryDocuments("suspensions", [["status", "==", "active"]]),
      countQueryDocuments("tickets", [["status", "==", "open"]]),
      countQueryDocuments(
        "mediaTranscodeJobs",
        [["status", "==", "processing"]]
      ),
      db.collection("config").doc("featuredProfiles").get(),
      db.collection("config").doc("app_data").get(),
      recentUserDocsPromise,
      recentGigDocsPromise,
      recentTicketDocsPromise,
      recentReportDocsPromise,
      recentConversationDocsPromise,
      recentTranscodeDocsPromise,
      trendingHashtagsPromise,
    ]);

    const recentUsers = await buildAdminUsersFromDocs(recentUserDocs);
    const recentGigs = await buildAdminGigList(recentGigDocs);
    const recentConversations = await buildConversationPayloads(
      recentConversationDocs
    );

    const trendingHashtags = trendingHashtagsDocs.map((doc) => ({
      id: doc.id,
      path: doc.ref.path,
      label: doc.id,
      useCount: toNonNegativeInt(doc.data().use_count),
      weeklyCount: toNonNegativeInt(doc.data().weekly_count),
      trend: firstNonEmptyString([doc.data().trend], "stable"),
      trendDelta: toNonNegativeInt(doc.data().trend_delta),
      isTrending: doc.data().is_trending === true,
      raw: serializeAdminValue(doc.data()),
    }));

    const featuredData = featuredDoc.data() || {};
    const featuredUids = Array.isArray(featuredData.uids) ?
      featuredData.uids.filter((item): item is string => typeof item === "string") :
      [];

    return {
      counts: {
        totalUsers,
        completedProfiles,
        activeMatchpointProfiles,
        totalGigs,
        openGigs,
        totalConversations,
        totalMatches,
        totalInteractions,
        pendingReports,
        activeSuspensions,
        openTickets,
        processingTranscodes,
        featuredProfiles: featuredUids.length,
      },
      recentUsers,
      recentGigs,
      recentTickets: recentTicketDocs.map((doc) => serializeSnapshot(doc)),
      recentReports: recentReportDocs.map((doc) => serializeSnapshot(doc)),
      recentConversations,
      recentTranscodeJobs: recentTranscodeDocs.map((doc) => serializeSnapshot(doc)),
      trendingHashtags,
      featured: {
        updatedAt: getTimestampMillis(featuredData.updatedAt),
        uids: featuredUids,
      },
      configSummary: {
        exists: appDataDoc.exists,
        updatedAt: getTimestampMillis(appDataDoc.data()?.updated_at),
        data: appDataDoc.exists ? serializeAdminValue(appDataDoc.data() || {}) : null,
      },
    };
  }
);

export const getUserAdminDetail = onCall(
  { region: "southamerica-east1", memory: "1GiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const uid = firstNonEmptyString([request.data?.uid]);
    if (!uid) {
      throw new HttpsError("invalid-argument", "UID é obrigatório.");
    }

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new HttpsError("not-found", "Usuário não encontrado.");
    }

    const userData = (userDoc.data() || {}) as Record<string, unknown>;

    let authRecord: admin.auth.UserRecord | null = null;
    try {
      authRecord = await admin.auth().getUser(uid);
    } catch (error) {
      console.warn(`Auth record não encontrado para ${uid}:`, error);
    }

    const moderationDocPromise = db.collection("userModerations").doc(uid).get();
    const favoritesDocsPromise = fetchQueryDocs({
      collectionPath: `users/${uid}/favorites`,
      limit: 40,
    });
    const blockedDocsPromise = fetchQueryDocs({
      collectionPath: `users/${uid}/blocked`,
      limit: 40,
    });
    const notificationDocsPromise = fetchQueryDocs({
      collectionPath: `users/${uid}/notifications`,
      orderByField: "updatedAt",
      limit: 25,
    });
    const previewDocsPromise = fetchQueryDocs({
      collectionPath: `users/${uid}/conversationPreviews`,
      orderByField: "updatedAt",
      limit: 25,
    });
    const gigDocsPromise = fetchQueryDocs({
      collectionPath: "gigs",
      filters: [["creator_id", "==", uid]],
      orderByField: "created_at",
      limit: 25,
    });
    const applicationDocsPromise = fetchQueryDocs({
      collectionGroupId: "gig_applications",
      filters: [["applicant_id", "==", uid]],
      orderByField: "applied_at",
      limit: 25,
    });
    const ticketDocsPromise = fetchQueryDocs({
      collectionPath: "tickets",
      filters: [["userId", "==", uid]],
      orderByField: "createdAt",
      limit: 20,
    });
    const reportDocsPromise = fetchQueryDocs({
      collectionPath: "reports",
      filters: [["reporter_user_id", "==", uid]],
      orderByField: "created_at",
      limit: 20,
    });
    const receivedReportDocsPromise = fetchQueryDocs({
      collectionPath: "reports",
      filters: [["reported_item_id", "==", uid]],
      orderByField: "created_at",
      limit: 20,
    });
    const suspensionDocsPromise = fetchQueryDocs({
      collectionPath: "suspensions",
      filters: [["user_id", "==", uid]],
      orderByField: "created_at",
      limit: 20,
    });
    const inviteTargetDocsPromise = fetchQueryDocs({
      collectionPath: "invites",
      filters: [["target_uid", "==", uid]],
      orderByField: "created_at",
      limit: 20,
    });
    const inviteSenderDocsPromise = fetchQueryDocs({
      collectionPath: "invites",
      filters: [["sender_uid", "==", uid]],
      orderByField: "created_at",
      limit: 20,
    });
    const inviteBandDocsPromise = fetchQueryDocs({
      collectionPath: "invites",
      filters: [["band_id", "==", uid]],
      orderByField: "created_at",
      limit: 20,
    });
    const matchDocsPromise = fetchQueryDocs({
      collectionPath: "matches",
      filters: [["user_ids", "array-contains", uid]],
      orderByField: "created_at",
      limit: 20,
    });
    const interactionsSentPromise = fetchQueryDocs({
      collectionPath: "interactions",
      filters: [["source_user_id", "==", uid]],
      orderByField: "created_at",
      limit: 15,
    });
    const interactionsReceivedPromise = fetchQueryDocs({
      collectionPath: "interactions",
      filters: [["target_user_id", "==", uid]],
      orderByField: "created_at",
      limit: 15,
    });
    const transcodeJobsPromise = fetchQueryDocs({
      collectionPath: "mediaTranscodeJobs",
      filters: [["userId", "==", uid]],
      orderByField: "updatedAt",
      limit: 20,
    });

    const [
      moderationDoc,
      favoritesDocs,
      blockedDocs,
      notificationDocs,
      previewDocs,
      gigDocs,
      applicationDocs,
      ticketDocs,
      reportDocs,
      receivedReportDocs,
      suspensionDocs,
      inviteTargetDocs,
      inviteSenderDocs,
      inviteBandDocs,
      matchDocs,
      interactionsSentDocs,
      interactionsReceivedDocs,
      transcodeJobDocs,
    ] = await Promise.all([
      moderationDocPromise,
      favoritesDocsPromise,
      blockedDocsPromise,
      notificationDocsPromise,
      previewDocsPromise,
      gigDocsPromise,
      applicationDocsPromise,
      ticketDocsPromise,
      reportDocsPromise,
      receivedReportDocsPromise,
      suspensionDocsPromise,
      inviteTargetDocsPromise,
      inviteSenderDocsPromise,
      inviteBandDocsPromise,
      matchDocsPromise,
      interactionsSentPromise,
      interactionsReceivedPromise,
      transcodeJobsPromise,
    ]);

    const moderationData = moderationDoc.exists ?
      (moderationDoc.data() || {}) as Record<string, unknown> :
      null;

    const baseProfile = buildAdminUserPayload(
      uid,
      userData,
      authRecord,
      moderationData
    );

    const relatedUserIds = uniqueStrings([
      ...favoritesDocs.map((doc) => doc.id),
      ...blockedDocs.map((doc) => doc.id),
    ]);
    const relatedUsersMap = await loadAdminUsersMapByUid(relatedUserIds);
    const gigsCreated = await buildAdminGigList(gigDocs);
    const matches = await buildMatchPayloads(matchDocs);
    const interactions = await buildInteractionPayloads([
      ...interactionsSentDocs,
      ...interactionsReceivedDocs,
    ]);

    const applicationGigIds = uniqueStrings(
      applicationDocs.map((doc) => firstNonEmptyString([doc.ref.parent.parent?.id]))
    );
    const applicationGigDocs = applicationGigIds.length > 0 ?
      await db.getAll(
        ...applicationGigIds.map((gigId) => db.collection("gigs").doc(gigId))
      ) :
      [];
    const gigMap = new Map(
      applicationGigDocs
        .filter((doc) => doc.exists)
        .map((doc) => [doc.id, doc.data() || {}])
    );

    const inviteDocs = [
      ...inviteTargetDocs,
      ...inviteSenderDocs,
      ...inviteBandDocs,
    ];
    const inviteMap = new Map<string, FirebaseFirestore.QueryDocumentSnapshot>();
    for (const doc of inviteDocs) {
      inviteMap.set(doc.id, doc);
    }

    return {
      profile: baseProfile,
      auth: authRecord ? {
        uid: authRecord.uid,
        email: authRecord.email || "",
        displayName: authRecord.displayName || "",
        photoURL: authRecord.photoURL || "",
        disabled: authRecord.disabled,
        emailVerified: authRecord.emailVerified,
        customClaims: serializeAdminValue(authRecord.customClaims || {}),
        providerData: authRecord.providerData.map((provider) => ({
          providerId: provider.providerId,
          uid: provider.uid,
          email: provider.email || "",
          displayName: provider.displayName || "",
        })),
        metadata: {
          creationTime: authRecord.metadata.creationTime || null,
          lastSignInTime: authRecord.metadata.lastSignInTime || null,
        },
      } : null,
      moderation: moderationData ? serializeAdminValue(moderationData) : null,
      rawUser: serializeAdminValue(userData),
      favoritesSent: favoritesDocs.map((doc) => ({
        id: doc.id,
        path: doc.ref.path,
        targetUser: relatedUsersMap.get(doc.id) || { uid: doc.id },
        raw: serializeAdminValue(doc.data()),
      })),
      blockedUsers: blockedDocs.map((doc) => ({
        id: doc.id,
        path: doc.ref.path,
        user: relatedUsersMap.get(doc.id) || { uid: doc.id },
        raw: serializeAdminValue(doc.data()),
      })),
      notifications: notificationDocs.map((doc) => serializeSnapshot(doc)),
      conversationPreviews: previewDocs.map((doc) => serializeSnapshot(doc)),
      gigsCreated,
      gigApplications: applicationDocs.map((doc) => {
        const gigId = firstNonEmptyString([doc.ref.parent.parent?.id]);
        const gigData = asRecord(gigMap.get(gigId));
        return {
          id: doc.id,
          path: doc.ref.path,
          gigId,
          gigTitle: firstNonEmptyString([gigData.title], "Gig"),
          status: firstNonEmptyString([doc.data().status], "pending"),
          appliedAt: getTimestampMillis(doc.data().applied_at),
          respondedAt: getTimestampMillis(doc.data().responded_at),
          raw: serializeAdminValue(doc.data()),
        };
      }),
      tickets: ticketDocs.map((doc) => serializeSnapshot(doc)),
      reportsFiled: reportDocs.map((doc) => serializeSnapshot(doc)),
      reportsReceived: receivedReportDocs.map((doc) => serializeSnapshot(doc)),
      suspensions: suspensionDocs.map((doc) => serializeSnapshot(doc)),
      invites: [...inviteMap.values()].map((doc) => serializeSnapshot(doc)),
      matches,
      interactions,
      transcodeJobs: transcodeJobDocs.map((doc) => serializeSnapshot(doc)),
      derivedStoragePrefixes: [
        `profile_photos/${uid}/`,
        `gallery_photos/${uid}/`,
        `gallery_videos/${uid}/`,
        `gallery_videos_transcoded/${uid}/`,
        `gallery_thumbnails/${uid}/`,
        `support_tickets/${uid}/`,
      ],
    };
  }
);

const listConversationsAdminHandler = async (
  request: { auth?: { token?: Record<string, unknown> }; data?: Record<string, unknown> }
): Promise<Record<string, unknown>> => {
  assertAdmin(request);

  const limit = normalizeLimit(request.data?.limit, 20, 100);
  const search = normalizeText(firstNonEmptyString([request.data?.search]));
  const queryLimit = search ? Math.min(limit * 5, 200) : limit;
  const conversationDocs = await fetchQueryDocs({
    collectionPath: "conversations",
    orderByField: "updatedAt",
    limit: queryLimit,
  });
  const conversations = await buildConversationPayloads(conversationDocs);
  const filtered = search ?
    conversations.filter((conversation) => {
      const participants = Array.isArray(conversation.participants) ?
        conversation.participants as Array<Record<string, unknown>> :
        [];
      const haystack = normalizeText([
        conversation.id,
        conversation.lastMessageText,
        ...participants.flatMap((participant) => [
          participant.uid,
          participant.nome,
          participant.displayName,
          participant.email,
        ]),
      ].map((value) => String(value || "")).join(" "));

      return haystack.includes(search);
    }) :
    conversations;

  return {
    conversations: filtered.slice(0, limit),
    total: filtered.length,
    search: search || null,
  };
};

export const listConversationsAdmin = onCall(
  { region: "southamerica-east1", memory: "512MiB", invoker: "public", maxInstances: 1 },
  async (request) => listConversationsAdminHandler(request)
);

export const getConversationAdminDetail = onCall(
  { region: "us-central1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const conversationId = firstNonEmptyString([request.data?.conversationId]);
    const messageLimit = normalizeLimit(request.data?.messageLimit, 100, 250);
    if (!conversationId) {
      throw new HttpsError(
        "invalid-argument",
        "conversationId é obrigatório."
      );
    }

    const conversationRef = db.collection("conversations").doc(conversationId);
    const conversationDoc = await conversationRef.get();
    if (!conversationDoc.exists) {
      throw new HttpsError("not-found", "Conversa não encontrada.");
    }

    const data = conversationDoc.data() || {};
    const participantUids = Array.isArray(data.participants) ?
      data.participants.filter((item): item is string => typeof item === "string") :
      [];
    const participantsMap = await loadAdminUsersMapByUid(participantUids);

    const [messageDocs, safetyDocs, previewDocs] = await Promise.all([
      fetchQueryDocs({
        collectionPath: `conversations/${conversationId}/messages`,
        orderByField: "createdAt",
        limit: messageLimit,
      }),
      fetchQueryDocs({
        collectionPath: "chatSafetyEvents",
        filters: [["conversation_id", "==", conversationId]],
        orderByField: "created_at",
        limit: 50,
      }),
      Promise.all(
        participantUids.map((uid) =>
          db
            .collection("users")
            .doc(uid)
            .collection("conversationPreviews")
            .doc(conversationId)
            .get()
        )
      ),
    ]);

    return {
      conversation: {
        id: conversationDoc.id,
        path: conversationDoc.ref.path,
        type: firstNonEmptyString([data.type], "direct"),
        participants: participantUids.map(
          (uid) => participantsMap.get(uid) || { uid }
        ),
        createdAt: getTimestampMillis(data.createdAt),
        updatedAt: getTimestampMillis(data.updatedAt),
        lastMessageText: firstNonEmptyString([data.lastMessageText]),
        lastMessageAt: getTimestampMillis(data.lastMessageAt),
        lastSenderId: firstNonEmptyString([data.lastSenderId]),
        raw: serializeAdminValue(data),
      },
      messages: messageDocs.map((doc) => {
        const messageData = doc.data();
        const senderId = firstNonEmptyString([messageData.senderId]);
        return {
          id: doc.id,
          path: doc.ref.path,
          senderId,
          sender: senderId ? participantsMap.get(senderId) || { uid: senderId } : null,
          text: firstNonEmptyString([messageData.text]),
          type: firstNonEmptyString([messageData.type], "text"),
          createdAt: getTimestampMillis(messageData.createdAt),
          raw: serializeAdminValue(messageData),
        };
      }),
      chatSafetyEvents: safetyDocs.map((doc) => serializeSnapshot(doc)),
      participantPreviews: previewDocs
        .filter((doc) => doc.exists)
        .map((doc) => serializeSnapshot(doc)),
    };
  }
);

export const listConversations = onCall(
  { region: "southamerica-east1", memory: "512MiB", invoker: "public", maxInstances: 1 },
  async (request) => listConversationsAdminHandler(request)
);

export const listGigsAdmin = onCall(
  { region: "us-central1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const limit = normalizeLimit(request.data?.limit, 20, 100);
    const status = firstNonEmptyString([request.data?.status], "all");
    const creatorId = firstNonEmptyString([request.data?.creatorId]);
    const search = normalizeText(firstNonEmptyString([request.data?.search]));
    const filters: QueryFilter[] = [];

    if (status !== "all") {
      filters.push(["status", "==", status]);
    }
    if (creatorId) {
      filters.push(["creator_id", "==", creatorId]);
    }

    const docs = await fetchQueryDocs({
      collectionPath: "gigs",
      filters,
      orderByField: "created_at",
      limit: search ? Math.min(limit * 5, 200) : limit,
    });
    const gigs = await buildAdminGigList(docs);
    const filtered = search ?
      gigs.filter((gig) => normalizeText([
        gig.id,
        gig.title,
        gig.description,
        (gig.creator as Record<string, unknown> | null)?.nome,
        (gig.creator as Record<string, unknown> | null)?.email,
      ].map((value) => String(value || "")).join(" ")).includes(search)) :
      gigs;

    return {
      gigs: filtered.slice(0, limit),
      total: filtered.length,
      status,
    };
  }
);

export const getGigAdminDetail = onCall(
  { region: "us-central1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const gigId = firstNonEmptyString([request.data?.gigId]);
    if (!gigId) {
      throw new HttpsError("invalid-argument", "gigId é obrigatório.");
    }

    const gigDoc = await db.collection("gigs").doc(gigId).get();
    if (!gigDoc.exists) {
      throw new HttpsError("not-found", "Gig não encontrada.");
    }

    const gigData = (gigDoc.data() || {}) as Record<string, unknown>;
    const creatorId = firstNonEmptyString([gigData.creator_id]);
    const [creatorMap, applicationDocs, reviewDocs] = await Promise.all([
      loadAdminUsersMapByUid(creatorId ? [creatorId] : []),
      fetchQueryDocs({
        collectionPath: `gigs/${gigId}/gig_applications`,
        orderByField: "applied_at",
        limit: 100,
      }),
      fetchQueryDocs({
        collectionPath: "gig_reviews",
        filters: [["gig_id", "==", gigId]],
        limit: 100,
      }),
    ]);

    const applicantIds = uniqueStrings(
      applicationDocs.map((doc) => firstNonEmptyString([doc.data().applicant_id]))
    );
    const reviewerIds = uniqueStrings(
      reviewDocs.flatMap((doc) => [
        firstNonEmptyString([doc.data().reviewer_id]),
        firstNonEmptyString([doc.data().reviewed_user_id]),
      ])
    );
    const userMap = await loadAdminUsersMapByUid([
      ...applicantIds,
      ...reviewerIds,
    ]);

    return {
      gig: buildAdminGigListItem(gigDoc, creatorMap),
      applications: applicationDocs.map((doc) => {
        const data = doc.data();
        const applicantId = firstNonEmptyString([data.applicant_id]);
        return {
          id: doc.id,
          path: doc.ref.path,
          applicantId,
          applicant: applicantId ? userMap.get(applicantId) || { uid: applicantId } : null,
          status: firstNonEmptyString([data.status], "pending"),
          message: firstNonEmptyString([data.message]),
          appliedAt: getTimestampMillis(data.applied_at),
          respondedAt: getTimestampMillis(data.responded_at),
          raw: serializeAdminValue(data),
        };
      }),
      reviews: reviewDocs.map((doc) => {
        const data = doc.data();
        const reviewerId = firstNonEmptyString([data.reviewer_id]);
        const reviewedUserId = firstNonEmptyString([data.reviewed_user_id]);
        return {
          id: doc.id,
          path: doc.ref.path,
          reviewerId,
          reviewer: reviewerId ? userMap.get(reviewerId) || { uid: reviewerId } : null,
          reviewedUserId,
          reviewedUser: reviewedUserId ?
            userMap.get(reviewedUserId) || { uid: reviewedUserId } :
            null,
          rating: toNonNegativeInt(data.rating),
          comment: firstNonEmptyString([data.comment]),
          reviewType: firstNonEmptyString([data.review_type]),
          createdAt: getTimestampMillis(data.created_at ?? data.createdAt),
          raw: serializeAdminValue(data),
        };
      }),
    };
  }
);

export const getMatchpointAdminOverview = onCall(
  { region: "us-central1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const limit = normalizeLimit(request.data?.limit, 20, 60);
    const [matchDocs, interactionDocs, hashtagDocs, auditDocs, activeProfiles] =
      await Promise.all([
        fetchQueryDocs({
          collectionPath: "matches",
          orderByField: "created_at",
          limit,
        }),
        fetchQueryDocs({
          collectionPath: "interactions",
          orderByField: "created_at",
          limit,
        }),
        fetchQueryDocs({
          collectionPath: "hashtagRanking",
          orderByField: "use_count",
          limit: 20,
        }),
        fetchQueryDocs({
          collectionPath: "matchpointStats",
          filters: [["type", "==", "ranking_audit_hourly"]],
          orderByField: "bucket_start",
          limit: 12,
        }),
        countQueryDocuments(
          "users",
          [["matchpoint_profile.is_active", "==", true]]
        ),
      ]);

    const matches = await buildMatchPayloads(matchDocs);
    const interactions = await buildInteractionPayloads(interactionDocs);
    const rankingAuditSummary = auditDocs.reduce((acc, doc) => {
      const data = doc.data();
      acc.totalEvents += readAuditNumber(data, "total_events");
      acc.returnedTotal += readAuditNumber(data, "returned_total_sum");
      acc.poolTotal += readAuditNumber(data, "pool_total_sum");
      acc.geohashUsedCount += readAuditNumber(data, "geohash_used_count");
      return acc;
    }, {
      totalEvents: 0,
      returnedTotal: 0,
      poolTotal: 0,
      geohashUsedCount: 0,
    });

    return {
      counts: {
        activeProfiles,
        matches: matches.length,
        recentInteractions: interactions.length,
      },
      matches,
      interactions,
      hashtags: hashtagDocs.map((doc) => ({
        id: doc.id,
        path: doc.ref.path,
        label: doc.id,
        useCount: toNonNegativeInt(doc.data().use_count),
        weeklyCount: toNonNegativeInt(doc.data().weekly_count),
        trend: firstNonEmptyString([doc.data().trend], "stable"),
        trendDelta: toNonNegativeInt(doc.data().trend_delta),
        isTrending: doc.data().is_trending === true,
        raw: serializeAdminValue(doc.data()),
      })),
      rankingAudit: {
        buckets: auditDocs.map((doc) => serializeSnapshot(doc)),
        summary: {
          ...rankingAuditSummary,
          averageReturnedPerEvent: rankingAuditSummary.totalEvents > 0 ?
            rankingAuditSummary.returnedTotal / rankingAuditSummary.totalEvents :
            0,
          averagePoolPerEvent: rankingAuditSummary.totalEvents > 0 ?
            rankingAuditSummary.poolTotal / rankingAuditSummary.totalEvents :
            0,
        },
      },
    };
  }
);

export const getSystemAdminData = onCall(
  { region: "us-central1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const limit = normalizeLimit(request.data?.limit, 20, 80);
    const [
      appDataDoc,
      featuredDoc,
      adminDoc,
      deletedUserDocs,
      transcodeJobDocs,
      hashtagDocs,
      rootCollections,
    ] = await Promise.all([
      db.collection("config").doc("app_data").get(),
      db.collection("config").doc("featuredProfiles").get(),
      db.collection("config").doc("admin").get(),
      fetchQueryDocs({
        collectionPath: "deletedUsers",
        orderByField: "deleted_at",
        limit,
      }).catch(() => []),
      fetchQueryDocs({
        collectionPath: "mediaTranscodeJobs",
        orderByField: "updatedAt",
        limit,
      }),
      fetchQueryDocs({
        collectionPath: "hashtagRanking",
        orderByField: "use_count",
        limit: 20,
      }),
      db.listCollections(),
    ]);

    return {
      config: {
        appData: serializeSnapshot(appDataDoc),
        featuredProfiles: serializeSnapshot(featuredDoc),
        admin: serializeSnapshot(adminDoc),
      },
      recentDeletedUsers: deletedUserDocs.map((doc) => serializeSnapshot(doc)),
      transcodeJobs: transcodeJobDocs.map((doc) => serializeSnapshot(doc)),
      hashtags: hashtagDocs.map((doc) => serializeSnapshot(doc)),
      rootCollections: rootCollections.map((collection) => ({
        id: collection.id,
        path: collection.path,
      })),
    };
  }
);

export const inspectFirestorePath = onCall(
  { region: "us-central1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const path = normalizePath(firstNonEmptyString([request.data?.path]));
    const limit = normalizeLimit(request.data?.limit, 20, 120);
    const cursor = firstNonEmptyString([request.data?.cursor]);

    if (!path) {
      const collections = await db.listCollections();
      return {
        kind: "root",
        path: "",
        collections: collections.map((collection) => ({
          id: collection.id,
          path: collection.path,
        })),
      };
    }

    const segments = path.split("/").filter(Boolean);
    const isDocumentPath = segments.length % 2 === 0;

    if (isDocumentPath) {
      const docRef = db.doc(path);
      const snapshot = await docRef.get();
      return {
        kind: "document",
        path,
        document: serializeSnapshot(snapshot),
        subcollections: await listDocumentSubcollections(docRef),
      };
    }

    let query: FirebaseFirestore.Query = db.collection(path)
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(limit);
    if (cursor) {
      query = query.startAfter(cursor);
    }
    const snapshot = await query.get();
    return {
      kind: "collection",
      path,
      documents: snapshot.docs.map((doc) => serializeSnapshot(doc)),
      nextCursor: snapshot.empty ? null : snapshot.docs[snapshot.docs.length - 1].id,
    };
  }
);

export const inspectStoragePrefix = onCall(
  { region: "us-central1", memory: "256MiB", invoker: "public", maxInstances: 1 },
  async (request) => {
    assertAdmin(request);

    const prefix = normalizePath(firstNonEmptyString([request.data?.prefix]));
    const limit = normalizeLimit(request.data?.limit, 20, 100);
    const bucket = admin.storage().bucket();
    const [files, nextQuery] = await bucket.getFiles({
      prefix,
      maxResults: limit,
      autoPaginate: false,
    });

    const items = await Promise.all(files.map(async (file) => {
      const [metadata] = await file.getMetadata();
      return {
        name: file.name,
        bucket: file.bucket.name,
        size: metadata.size || null,
        contentType: metadata.contentType || null,
        updated: metadata.updated || null,
        timeCreated: metadata.timeCreated || null,
        metadata: metadata.metadata || {},
      };
    }));

    return {
      bucket: bucket.name,
      prefix,
      files: items,
      nextPageToken:
        typeof nextQuery?.pageToken === "string" ? nextQuery.pageToken : null,
    };
  }
);
