/**
 * Cloud Functions para Chat/Contato
 *
 * Funcionalidades:
 * - initiateContact: Inicia contato após match ou em contextos específicos
 * - Validações de segurança e privacidade
 */

import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {Timestamp} from "firebase-admin/firestore";

const db = admin.firestore();

/**
 * Estrutura do request para initiateContact
 */
interface InitiateContactRequest {
  targetUserId: string;
  context: "match" | "band" | "event";
  contextId?: string;
  initialMessage?: string;
}

/**
 * Estrutura da resposta de initiateContact
 */
interface InitiateContactResponse {
  success: boolean;
  conversationId?: string;
  message: string;
}

const ALLOWED_CONTEXTS = ["match", "band", "event"] as const;

/**
 * Cloud Function: initiateContact
 *
 * Inicia uma conversa entre dois usuários:
 * - Valida se o contato é permitido (match mútuo, mesma banda, etc.)
 * - Cria conversa se não existir
 * - Opcionalmente envia mensagem inicial
 *
 * NOTA: Esta função é primariamente para contextos não-match.
 * Para matches, a conversa já é criada automaticamente por
 * submitMatchpointAction.
 */
export const initiateContact = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    timeoutSeconds: 10,
    enforceAppCheck: true,
    cors: true,
  },
  async (request): Promise<InitiateContactResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const currentUserId = request.auth.uid;
    const {targetUserId, context, contextId, initialMessage} =
      request.data as InitiateContactRequest;

    if (!targetUserId || typeof targetUserId !== "string") {
      throw new HttpsError("invalid-argument", "targetUserId é obrigatório");
    }

    if (!context || !ALLOWED_CONTEXTS.includes(context)) {
      throw new HttpsError("invalid-argument", "context inválido");
    }

    if (currentUserId === targetUserId) {
      throw new HttpsError(
        "invalid-argument",
        "Não pode iniciar conversa consigo mesmo"
      );
    }

    try {
      const canContact = await validateContactPermission(
        currentUserId,
        targetUserId,
        context,
        contextId
      );

      if (!canContact.allowed) {
        throw new HttpsError(
          "permission-denied",
          canContact.reason || "Contato não permitido"
        );
      }

      const existingConversation = await findExistingConversation(
        currentUserId,
        targetUserId
      );

      if (existingConversation) {
        return {
          success: true,
          conversationId: existingConversation,
          message: "Conversa existente encontrada",
        };
      }

      const conversationResult = await createConversation(
        currentUserId,
        targetUserId,
        context,
        initialMessage
      );

      let responseMessage = "Conversa criada";
      if (initialMessage) {
        responseMessage = "Conversa criada com mensagem inicial";
      }

      return {
        success: true,
        conversationId: conversationResult.conversationId,
        message: responseMessage,
      };
    } catch (error) {
      console.error("Erro em initiateContact:", error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError("internal", "Erro interno ao iniciar contato");
    }
  }
);

/**
 * Valida se o contato é permitido entre dois usuários.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @param {string} context - Contexto do contato
 * @param {string=} contextId - ID do contexto (banda, evento, etc)
 * @return {Promise<Object>} Resultado
 */
async function validateContactPermission(
  userId1: string,
  userId2: string,
  context: string,
  contextId?: string
): Promise<{ allowed: boolean; reason?: string }> {
  switch (context) {
  case "match": {
    const pairKey = [userId1, userId2].sort().join("_");
    const matchQuery = await db
      .collection("matches")
      .where("pair_key", "==", pairKey)
      .limit(1)
      .get();

    if (matchQuery.empty) {
      return {allowed: false, reason: "Match não encontrado"};
    }

    return {allowed: true};
  }
  case "band": {
    if (!contextId) {
      return {
        allowed: false,
        reason: "bandId é obrigatório para contexto 'band'",
      };
    }

    const bandDoc = await db
      .collection("users")
      .doc(contextId)
      .get();
    if (!bandDoc.exists) {
      return {allowed: false, reason: "Banda não encontrada"};
    }

    const bandData = bandDoc.data() || {};
    let members: string[] = [];
    if (Array.isArray(bandData.members)) {
      members = bandData.members as string[];
    }

    if (!members.includes(userId1) || !members.includes(userId2)) {
      return {allowed: false, reason: "Ambos devem ser membros da banda"};
    }

    return {allowed: true};
  }
  case "event": {
    return {
      allowed: false,
      reason: "Contato via evento ainda não implementado",
    };
  }
  default:
    return {allowed: false, reason: "Contexto inválido"};
  }
}

/**
 * Busca conversa existente entre dois usuários.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @return {Promise<string|null>} conversationId existente ou null
 */
async function findExistingConversation(
  userId1: string,
  userId2: string
): Promise<string | null> {
  const conversationId = getConversationId(userId1, userId2);
  const conversationDoc = await db
    .collection("conversations")
    .doc(conversationId)
    .get();

  if (conversationDoc.exists) {
    return conversationId;
  }

  return null;
}

/**
 * Cria uma nova conversa entre dois usuários.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @param {string} context - Contexto do contato
 * @param {string=} initialMessage - Mensagem inicial opcional
 * @return {Promise<Object>} conversationId criado
 */
async function createConversation(
  userId1: string,
  userId2: string,
  context: string,
  initialMessage?: string
): Promise<{ conversationId: string }> {
  const now = Timestamp.now();
  const conversationId = getConversationId(userId1, userId2);
  let conversationType = "direct";
  if (context === "match") {
    conversationType = "matchpoint";
  }

  return await db.runTransaction(async (transaction) => {
    const conversationRef = db
      .collection("conversations")
      .doc(conversationId);
    const conversationDoc = await transaction.get(conversationRef);

    if (!conversationDoc.exists) {
      transaction.set(conversationRef, {
        participants: [userId1, userId2],
        participantsMap: {[userId1]: true, [userId2]: true},
        createdAt: now,
        updatedAt: now,
        readUntil: {
          [userId1]: Timestamp.fromMillis(0),
          [userId2]: Timestamp.fromMillis(0),
        },
        lastMessageText: null,
        lastMessageAt: null,
        lastSenderId: null,
        type: conversationType,
      });
    }

    const user1Doc = await transaction.get(
      db.collection("users").doc(userId1)
    );
    const user2Doc = await transaction.get(
      db.collection("users").doc(userId2)
    );
    const user1Data = user1Doc.data() || {};
    const user2Data = user2Doc.data() || {};

    const preview1Ref = db
      .collection("users")
      .doc(userId1)
      .collection("conversationPreviews")
      .doc(conversationId);

    const preview2Ref = db
      .collection("users")
      .doc(userId2)
      .collection("conversationPreviews")
      .doc(conversationId);

    const preview1Doc = await transaction.get(preview1Ref);
    const preview2Doc = await transaction.get(preview2Ref);

    if (!preview1Doc.exists) {
      transaction.set(preview1Ref, {
        otherUserId: userId2,
        otherUserName: user2Data.nome ||
          user2Data.nome_artistico ||
          "Usuário",
        otherUserPhoto: user2Data.foto || null,
        lastMessageText: initialMessage || null,
        lastMessageAt: initialMessage ? now : null,
        lastSenderId: initialMessage ? userId1 : null,
        unreadCount: 0,
        updatedAt: now,
        type: conversationType,
      });
    }

    if (!preview2Doc.exists) {
      transaction.set(preview2Ref, {
        otherUserId: userId1,
        otherUserName: user1Data.nome ||
          user1Data.nome_artistico ||
          "Usuário",
        otherUserPhoto: user1Data.foto || null,
        lastMessageText: initialMessage || null,
        lastMessageAt: initialMessage ? now : null,
        lastSenderId: initialMessage ? userId1 : null,
        unreadCount: initialMessage ? 1 : 0,
        updatedAt: now,
        type: conversationType,
      });
    }

    if (initialMessage) {
      const messageRef = conversationRef.collection("messages").doc();
      transaction.set(messageRef, {
        senderId: userId1,
        text: initialMessage,
        createdAt: now,
        type: "text",
      });

      transaction.update(conversationRef, {
        lastMessageText: initialMessage,
        lastMessageAt: now,
        lastSenderId: userId1,
      });
    }

    return {conversationId};
  });
}

/**
 * Gera conversationId determinístico.
 *
 * @param {string} userId1 - UID do usuário atual
 * @param {string} userId2 - UID do usuário alvo
 * @return {string} conversationId
 */
function getConversationId(userId1: string, userId2: string): string {
  if (userId1 < userId2) {
    return `${userId1}_${userId2}`;
  }

  return `${userId2}_${userId1}`;
}
