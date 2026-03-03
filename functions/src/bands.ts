/**
 * Cloud Functions para gerenciamento de Bandas e Convites.
 *
 * Alinhado ao schema atual do app:
 * - users/{bandId} armazena bandas (tipo_perfil = banda)
 * - invites é a coleção de convites
 * - members é um array dentro do documento de banda
 */

import {
  onCall,
  HttpsError,
} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {Timestamp} from "firebase-admin/firestore";
import {
  MIN_ACTIVE_BAND_MEMBERS,
  getBandStatusForMemberCount,
  buildBandAcceptedMessage,
  buildBandMemberRemovalMessage,
} from "./band_activation";

const db = admin.firestore();

interface ManageBandInviteRequest {
  action: "send" | "accept" | "decline" | "cancel";
  bandId?: string;
  targetUid?: string;
  targetName?: string;
  targetPhoto?: string;
  targetInstrument?: string;
  inviteId?: string;
}

interface ManageBandInviteResponse {
  success: boolean;
  inviteId?: string;
  bandId?: string;
  message: string;
}

type PendingInvite = Record<string, unknown>;

const BAND_PROFILE_TYPE = "banda";
const PROFESSIONAL_PROFILE_TYPE = "profissional";
const REGISTRATION_COMPLETE = "concluido";
const INVITES_ROUTE = "/profile/invites";
const MANAGE_MEMBERS_ROUTE = "/profile/manage-members";

/**
 * Retorna o primeiro texto nao vazio de uma lista.
 *
 * @param {unknown[]} values - Valores candidatos.
 * @param {string=} fallback - Valor padrao quando nada e valido.
 * @return {string} Primeiro texto valido encontrado.
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
 * Normaliza a lista de integrantes aceitos da banda.
 *
 * @param {unknown} rawMembers - Valor bruto vindo do Firestore.
 * @return {string[]} Lista unica de UIDs validos.
 */
function normalizeMemberIds(rawMembers: unknown): string[] {
  if (!Array.isArray(rawMembers)) return [];

  return [...new Set(rawMembers.filter((item): item is string => {
    return typeof item === "string" && item.trim().length > 0;
  }))];
}

/**
 * Converte um valor arbitrario em objeto indexavel.
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
 * Verifica se o documento representa uma banda.
 *
 * @param {Record<string, unknown>} data - Documento de usuario.
 * @return {boolean} True quando o tipo do perfil e banda.
 */
function isBandProfile(data: Record<string, unknown>): boolean {
  return data.tipo_perfil === BAND_PROFILE_TYPE;
}

/**
 * Verifica se a banda esta apta a gerenciar convites.
 *
 * @param {Record<string, unknown>} data - Documento da banda.
 * @return {boolean} True quando o perfil esta concluido e nao bloqueado.
 */
function canBandManageInvites(data: Record<string, unknown>): boolean {
  return isBandProfile(data) &&
      data.cadastro_status === REGISTRATION_COMPLETE &&
      data.status !== "suspenso" &&
      data.status !== "inativo";
}

/**
 * Verifica se o alvo do convite e um perfil individual.
 *
 * @param {Record<string, unknown>} data - Documento do usuario alvo.
 * @return {boolean} True quando o perfil e profissional.
 */
function isEligibleInviteTarget(data: Record<string, unknown>): boolean {
  return data.tipo_perfil === PROFESSIONAL_PROFILE_TYPE;
}

/**
 * Retorna o nome de exibicao da banda.
 *
 * @param {Record<string, unknown>} data - Documento da banda.
 * @return {string} Nome amigavel para UI/notificacoes.
 */
function getBandDisplayName(data: Record<string, unknown>): string {
  const bandProfile = asRecord(data.banda);
  return firstNonEmptyString([
    bandProfile.nomeBanda,
    bandProfile.nomeArtistico,
    bandProfile.nome,
  ], "Banda");
}

/**
 * Retorna o nome de exibicao de um usuario profissional.
 *
 * @param {Record<string, unknown>} data - Documento do usuario.
 * @param {string=} fallback - Texto de fallback.
 * @return {string} Nome amigavel para UI/notificacoes.
 */
function getProfessionalDisplayName(
  data: Record<string, unknown>,
  fallback = "Novo integrante"
): string {
  const professionalProfile = asRecord(data.profissional);
  return firstNonEmptyString([
    professionalProfile.nomeArtistico,
  ], fallback);
}

interface NotificationInput {
  userId: string;
  notificationId: string;
  type: string;
  title: string;
  body: string;
  senderId?: string;
  route?: string;
  data?: Record<string, string>;
}

/**
 * Cria/atualiza uma notificacao no Firestore do usuario.
 *
 * @param {NotificationInput} input - Dados da notificacao.
 * @return {Promise<void>} Promise concluida apos persistencia.
 */
async function upsertUserNotification(input: NotificationInput): Promise<void> {
  const {
    userId,
    notificationId,
    type,
    title,
    body,
    senderId,
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
      route: route ?? null,
      ...data,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
}

/**
 * Envia push notification best-effort para o usuario.
 *
 * @param {NotificationInput} input - Dados da notificacao.
 * @return {Promise<void>} Promise concluida apos tentativa de envio.
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
 * Persiste a notificacao e tenta enviar push sem derrubar o fluxo principal.
 *
 * @param {NotificationInput} input - Dados da notificacao.
 * @return {Promise<void>} Promise concluida apos tentativa.
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
 * Cloud Function: manageBandInvite
 *
 * Ações suportadas:
 * - send: cria convite
 * - accept: aceita convite e adiciona membro
 * - decline: recusa convite
 * - cancel: cancela convite enviado
 */
export const manageBandInvite = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<ManageBandInviteResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const currentUserId = request.auth.uid;
    const {
      action,
      bandId,
      targetUid,
      targetPhoto,
      targetInstrument,
      inviteId,
    } = request.data as ManageBandInviteRequest;

    if (!action || !["send", "accept", "decline", "cancel"].includes(action)) {
      throw new HttpsError("invalid-argument", "action inválido");
    }

    try {
      switch (action) {
      case "send":
        if (!bandId || !targetUid) {
          throw new HttpsError(
            "invalid-argument",
            "bandId e targetUid são obrigatórios"
          );
        }
        return await sendInvite(
          currentUserId,
          bandId,
          targetUid,
          targetPhoto,
          targetInstrument
        );
      case "accept":
        if (!inviteId) {
          throw new HttpsError("invalid-argument", "inviteId é obrigatório");
        }
        return await respondInvite(currentUserId, inviteId, true);
      case "decline":
        if (!inviteId) {
          throw new HttpsError("invalid-argument", "inviteId é obrigatório");
        }
        return await respondInvite(currentUserId, inviteId, false);
      case "cancel":
        if (!inviteId) {
          throw new HttpsError("invalid-argument", "inviteId é obrigatório");
        }
        return await cancelInvite(currentUserId, inviteId);
      default:
        throw new HttpsError("invalid-argument", "action inválido");
      }
    } catch (error) {
      console.error("Erro em manageBandInvite:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Erro interno ao processar convite");
    }
  }
);

/**
 * Envia um convite para um usuário.
 *
 * @param {string} currentUserId - UID do usuário autenticado
 * @param {string} bandId - UID da banda
 * @param {string} targetUid - UID do usuário convidado
 * @param {string=} targetPhoto - Foto do usuário convidado
 * @param {string=} targetInstrument - Instrumento do usuário convidado
 * @return {Promise<ManageBandInviteResponse>} Resposta da operação
 */
async function sendInvite(
  currentUserId: string,
  bandId: string,
  targetUid: string,
  targetPhoto?: string,
  targetInstrument?: string
): Promise<ManageBandInviteResponse> {
  if (currentUserId !== bandId) {
    throw new HttpsError(
      "permission-denied",
      "Apenas a banda pode enviar convites"
    );
  }

  if (bandId === targetUid) {
    throw new HttpsError(
      "invalid-argument",
      "A banda não pode convidar o próprio perfil"
    );
  }

  const bandRef = db.collection("users").doc(bandId);
  const targetRef = db.collection("users").doc(targetUid);
  const [bandDoc, targetDoc] = await Promise.all([
    bandRef.get(),
    targetRef.get(),
  ]);

  if (!bandDoc.exists) {
    throw new HttpsError("not-found", "Banda não encontrada");
  }

  const bandData = asRecord(bandDoc.data());
  if (!canBandManageInvites(bandData)) {
    throw new HttpsError(
      "failed-precondition",
      "Apenas bandas concluídas podem enviar convites"
    );
  }

  const members = normalizeMemberIds(bandData.members);
  if (members.includes(targetUid)) {
    throw new HttpsError("already-exists", "Usuário já é membro da banda");
  }

  if (!targetDoc.exists) {
    throw new HttpsError("not-found", "Usuário convidado não encontrado");
  }

  const targetData = asRecord(targetDoc.data());
  if (!isEligibleInviteTarget(targetData)) {
    throw new HttpsError(
      "failed-precondition",
      "Convites de banda só podem ser enviados para perfis " +
          "individuais ativos e com cadastro concluído"
    );
  }

  const existingInvite = await db
    .collection("invites")
    .where("band_id", "==", bandId)
    .where("target_uid", "==", targetUid)
    .where("status", "==", "pendente")
    .limit(1)
    .get();

  if (!existingInvite.empty) {
    throw new HttpsError("already-exists", "Convite pendente já existe");
  }

  const now = Timestamp.now();
  const inviteRef = db.collection("invites").doc();
  const bandName = getBandDisplayName(bandData);
  const targetDisplayName = getProfessionalDisplayName(targetData);

  await inviteRef.set({
    band_id: bandId,
    band_name: bandName,
    band_photo: firstNonEmptyString([bandData.foto]),
    target_uid: targetUid,
    target_name: targetDisplayName,
    target_photo: targetPhoto || "",
    target_instrument: targetInstrument || "",
    sender_uid: bandId,
    status: "pendente",
    created_at: now,
    updated_at: now,
  });

  await notifyUser({
    userId: targetUid,
    notificationId: `band_invite_${inviteRef.id}`,
    type: "band_invite",
    title: `${bandName} convidou voce`,
    body: "Abra o app para aceitar ou recusar o convite da banda.",
    senderId: bandId,
    route: INVITES_ROUTE,
    data: {
      invite_id: inviteRef.id,
      band_id: bandId,
    },
  });

  return {
    success: true,
    inviteId: inviteRef.id,
    bandId,
    message: "Convite enviado",
  };
}

/**
 * Responde um convite (aceitar ou recusar).
 *
 * @param {string} currentUserId - UID do usuário autenticado
 * @param {string} inviteId - ID do convite
 * @param {boolean} accept - Flag de aceite
 * @return {Promise<ManageBandInviteResponse>} Resposta da operação
 */
async function respondInvite(
  currentUserId: string,
  inviteId: string,
  accept: boolean
): Promise<ManageBandInviteResponse> {
  const inviteRef = db.collection("invites").doc(inviteId);
  const inviteDoc = await inviteRef.get();

  if (!inviteDoc.exists) {
    throw new HttpsError("not-found", "Convite não encontrado");
  }

  const inviteData = inviteDoc.data() || {};
  if (inviteData.target_uid !== currentUserId) {
    throw new HttpsError(
      "permission-denied",
      "Apenas o convidado pode responder"
    );
  }

  if (inviteData.status !== "pendente") {
    throw new HttpsError(
      "failed-precondition",
      "Convite já foi respondido"
    );
  }

  const bandId = inviteData.band_id as string;
  const bandRef = db.collection("users").doc(bandId);
  const now = Timestamp.now();
  const bandName = firstNonEmptyString([inviteData.band_name], "Banda");

  if (!accept) {
    await inviteRef.update({
      status: "recusado",
      updated_at: now,
      responded_at: now,
    });

    return {
      success: true,
      bandId,
      message: "Convite recusado",
    };
  }

  let nextMemberCount = 0;
  let acceptedMemberName = "Novo integrante";
  await db.runTransaction(async (transaction) => {
    const [transactionInviteDoc, bandDoc, targetDoc] = await Promise.all([
      transaction.get(inviteRef),
      transaction.get(bandRef),
      transaction.get(db.collection("users").doc(currentUserId)),
    ]);

    if (!transactionInviteDoc.exists) {
      throw new HttpsError("not-found", "Convite não encontrado");
    }

    const transactionInviteData = asRecord(transactionInviteDoc.data());
    if (transactionInviteData.target_uid !== currentUserId) {
      throw new HttpsError(
        "permission-denied",
        "Apenas o convidado pode responder"
      );
    }

    if (transactionInviteData.status !== "pendente") {
      throw new HttpsError(
        "failed-precondition",
        "Convite já foi respondido"
      );
    }

    if (!bandDoc.exists) {
      throw new HttpsError("not-found", "Banda não encontrada");
    }

    const bandData = asRecord(bandDoc.data());
    if (!canBandManageInvites(bandData)) {
      throw new HttpsError(
        "failed-precondition",
        "Esta banda não pode receber novos integrantes agora"
      );
    }

    if (!targetDoc.exists) {
      throw new HttpsError("not-found", "Usuário convidado não encontrado");
    }

    const targetData = asRecord(targetDoc.data());
    if (!isEligibleInviteTarget(targetData)) {
      throw new HttpsError(
        "failed-precondition",
        "Seu perfil precisa estar ativo e concluído para aceitar " +
            "convites de banda"
      );
    }

    acceptedMemberName = getProfessionalDisplayName(targetData);
    const members = normalizeMemberIds(bandData.members);

    if (members.includes(currentUserId)) {
      throw new HttpsError("already-exists", "Você já é membro desta banda");
    }

    const nextMembers = [...members, currentUserId];
    nextMemberCount = nextMembers.length;

    transaction.update(bandRef, {
      members: nextMembers,
      status: getBandStatusForMemberCount(nextMemberCount),
      updated_at: now,
    });

    transaction.update(inviteRef, {
      status: "aceito",
      updated_at: now,
      responded_at: now,
    });
  });

  const body = nextMemberCount >= MIN_ACTIVE_BAND_MEMBERS ?
    `${acceptedMemberName} aceitou o convite. Sua banda agora esta ativa.` :
    `${acceptedMemberName} aceitou o convite. ` +
      `Sua banda esta com ${nextMemberCount} de ` +
      `${MIN_ACTIVE_BAND_MEMBERS} integrantes confirmados.`;

  await notifyUser({
    userId: bandId,
    notificationId: `band_invite_accepted_${inviteId}`,
    type: "band_invite_accepted",
    title: `${acceptedMemberName} entrou em ${bandName}`,
    body,
    senderId: currentUserId,
    route: MANAGE_MEMBERS_ROUTE,
    data: {
      invite_id: inviteId,
      band_id: bandId,
      member_id: currentUserId,
    },
  });

  return {
    success: true,
    bandId,
    message: buildBandAcceptedMessage(nextMemberCount),
  };
}

/**
 * Cancela um convite enviado.
 *
 * @param {string} currentUserId - UID do usuário autenticado
 * @param {string} inviteId - ID do convite
 * @return {Promise<ManageBandInviteResponse>} Resposta da operação
 */
async function cancelInvite(
  currentUserId: string,
  inviteId: string
): Promise<ManageBandInviteResponse> {
  const inviteRef = db.collection("invites").doc(inviteId);
  const inviteDoc = await inviteRef.get();

  if (!inviteDoc.exists) {
    throw new HttpsError("not-found", "Convite não encontrado");
  }

  const inviteData = inviteDoc.data() || {};
  if (inviteData.sender_uid !== currentUserId) {
    throw new HttpsError(
      "permission-denied",
      "Apenas quem enviou pode cancelar"
    );
  }

  if (inviteData.status !== "pendente") {
    throw new HttpsError(
      "failed-precondition",
      "Apenas convites pendentes podem ser cancelados"
    );
  }

  await inviteRef.delete();

  return {
    success: true,
    bandId: inviteData.band_id,
    message: "Convite cancelado",
  };
}

/**
 * Cloud Function: leaveBand
 *
 * Remove um usuário da banda (pelo próprio usuário ou pela banda).
 */
export const leaveBand = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 10,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<{ success: boolean; message: string }> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const currentUserId = request.auth.uid;
    const {bandId, userId} = request.data as {
      bandId?: string;
      userId?: string;
    };

    if (!bandId || !userId) {
      throw new HttpsError(
        "invalid-argument",
        "bandId e userId são obrigatórios"
      );
    }

    if (currentUserId !== userId && currentUserId !== bandId) {
      throw new HttpsError(
        "permission-denied",
        "Sem permissão para remover este membro"
      );
    }

    const bandRef = db.collection("users").doc(bandId);
    const now = Timestamp.now();
    let nextMemberCount = 0;

    await db.runTransaction(async (transaction) => {
      const bandDoc = await transaction.get(bandRef);
      if (!bandDoc.exists) {
        throw new HttpsError("not-found", "Banda não encontrada");
      }

      const bandData = asRecord(bandDoc.data());
      if (!isBandProfile(bandData)) {
        throw new HttpsError(
          "failed-precondition",
          "Perfil informado não é uma banda"
        );
      }

      const members = normalizeMemberIds(bandData.members);
      if (!members.includes(userId)) {
        throw new HttpsError(
          "failed-precondition",
          "Usuário não é integrante desta banda"
        );
      }

      const nextMembers = members.filter((memberId) => memberId !== userId);
      nextMemberCount = nextMembers.length;

      transaction.update(bandRef, {
        members: nextMembers,
        status: getBandStatusForMemberCount(nextMemberCount),
        updated_at: now,
      });
    });

    return {
      success: true,
      message: buildBandMemberRemovalMessage(nextMemberCount),
    };
  }
);

/**
 * Cloud Function: getPendingInvites
 *
 * Retorna convites pendentes para o usuário atual.
 */
export const getPendingInvites = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 5,
    enforceAppCheck: true,
    invoker: "public",
    cors: true,
  },
  async (request): Promise<{ invites: PendingInvite[]; count: number }> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const userId = request.auth.uid;

    try {
      const invitesQuery = await db
        .collection("invites")
        .where("target_uid", "==", userId)
        .where("status", "==", "pendente")
        .orderBy("created_at", "desc")
        .limit(50)
        .get();

      const invites: PendingInvite[] = invitesQuery.docs.map((doc) => ({
        id: doc.id,
        ...(doc.data() as PendingInvite),
      }));

      return {
        invites,
        count: invites.length,
      };
    } catch (error) {
      console.error("Erro em getPendingInvites:", error);
      throw new HttpsError("internal", "Erro ao buscar convites");
    }
  }
);
