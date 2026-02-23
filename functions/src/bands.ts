/**
 * Cloud Functions para gerenciamento de Bandas e Convites.
 *
 * Alinhado ao schema atual do app:
 * - users/{bandId} armazena bandas (tipo_perfil = banda)
 * - invites é a coleção de convites
 * - members é um array dentro do documento de banda
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {FieldValue, Timestamp} from "firebase-admin/firestore";

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
      targetName,
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
          targetName,
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
 * @param {string=} targetName - Nome do usuário convidado
 * @param {string=} targetPhoto - Foto do usuário convidado
 * @param {string=} targetInstrument - Instrumento do usuário convidado
 * @return {Promise<ManageBandInviteResponse>} Resposta da operação
 */
async function sendInvite(
  currentUserId: string,
  bandId: string,
  targetUid: string,
  targetName?: string,
  targetPhoto?: string,
  targetInstrument?: string
): Promise<ManageBandInviteResponse> {
  if (currentUserId !== bandId) {
    throw new HttpsError(
      "permission-denied",
      "Apenas a banda pode enviar convites"
    );
  }

  const bandRef = db.collection("users").doc(bandId);
  const bandDoc = await bandRef.get();
  if (!bandDoc.exists) {
    throw new HttpsError("not-found", "Banda não encontrada");
  }

  const bandData = bandDoc.data() || {};
  const members = Array.isArray(bandData.members) ? bandData.members : [];
  if (members.includes(targetUid)) {
    throw new HttpsError("already-exists", "Usuário já é membro da banda");
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

  await inviteRef.set({
    band_id: bandId,
    band_name: bandData.nome || bandData.displayName || "Banda",
    band_photo: bandData.foto || "",
    target_uid: targetUid,
    target_name: targetName || "",
    target_photo: targetPhoto || "",
    target_instrument: targetInstrument || "",
    sender_uid: bandId,
    status: "pendente",
    created_at: now,
    updated_at: now,
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
    throw new HttpsError("failed-precondition", "Convite já foi respondido");
  }

  const bandId = inviteData.band_id as string;
  const bandRef = db.collection("users").doc(bandId);
  const now = Timestamp.now();

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

  await db.runTransaction(async (transaction) => {
    const bandDoc = await transaction.get(bandRef);
    if (!bandDoc.exists) {
      throw new HttpsError("not-found", "Banda não encontrada");
    }

    const bandData = bandDoc.data() || {};
    const members = Array.isArray(bandData.members) ? bandData.members : [];

    if (members.includes(currentUserId)) {
      throw new HttpsError("already-exists", "Você já é membro desta banda");
    }

    transaction.update(bandRef, {
      members: FieldValue.arrayUnion([currentUserId]),
      updated_at: now,
    });

    transaction.update(inviteRef, {
      status: "aceito",
      updated_at: now,
      responded_at: now,
    });
  });

  return {
    success: true,
    bandId,
    message: "Convite aceito! Você agora é membro da banda",
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
    const bandDoc = await bandRef.get();
    if (!bandDoc.exists) {
      throw new HttpsError("not-found", "Banda não encontrada");
    }

    await bandRef.update({
      members: FieldValue.arrayRemove([userId]),
      updated_at: Timestamp.now(),
    });

    return {
      success: true,
      message: "Membro removido da banda",
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
