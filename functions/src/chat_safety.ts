import {createHash} from "crypto";

import * as admin from "firebase-admin";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";

const EMAIL_PATTERN = /\b[\w.+-]+@[\w-]+\.[\w.-]+\b/i;
const URL_PATTERN =
  /\b(?:https?:\/\/|www\.|[\w-]+\.(?:com(?:\.br)?|br|net|org|io|me|app))\S*/i;
const PHONE_PATTERN =
  /(?:\+?55\s*)?(?:\(?\d{2}\)?\s*)?(?:9?\d{4})[-.\s]?\d{4}\b/;
const SPACED_DIGITS_PATTERN = /(?:\d[\s.-]?){8,}\d/;
const HANDLE_PATTERN = /(^|[\s:])@[a-z0-9._]{3,}\b/i;
const CONTACT_INTENT_PATTERN = new RegExp(
  "\\b(" +
    "me chama|chama la|chama lá|me segue|me adiciona|me add|" +
    "manda mensagem|manda msg|fala comigo|me procura|contato|" +
    "numero|número|telefone|email|e-mail|arroba|direct|dm|" +
    "inbox|link na bio|linktree|passa" +
  ")\\b",
  "i"
);

const CHANNEL_KEYWORDS: Record<string, string[]> = {
  whatsapp: ["whatsapp", "whats", "wpp", "zap", "zapzap"],
  instagram: ["instagram", "insta"],
  telegram: ["telegram", "t.me"],
  discord: ["discord", "disc.gg"],
  linktree: ["linktree"],
};
const NUMBER_WORDS = new Set([
  "zero",
  "um",
  "uma",
  "dois",
  "duas",
  "tres",
  "três",
  "quatro",
  "cinco",
  "seis",
  "sete",
  "oito",
  "nove",
  "meia",
]);

type ChatSafetySeverity = "medium" | "high";
type ChatSafetySource =
  "pre_send_warning" |
  "post_send_detected" |
  "initial_message_detected";

interface ChatSafetyAnalysis {
  isSuspicious: boolean;
  patterns: string[];
  channels: string[];
  severity: ChatSafetySeverity | null;
}

interface ChatSafetyEventInput {
  userId: string;
  text: string;
  source: ChatSafetySource;
  conversationId?: string;
  messageId?: string;
  clientPatterns?: string[];
  clientChannels?: string[];
  clientSeverity?: string;
  platform?: string;
}

interface LogChatPreSendWarningRequest {
  conversationId?: unknown;
  text?: unknown;
  clientPatterns?: unknown;
  clientChannels?: unknown;
  severity?: unknown;
  platform?: unknown;
}

/**
 * Retorna instância lazy do Firestore após o app estar inicializado.
 *
 * @return {unknown} Instância do Firestore.
 */
function getDb() {
  return admin.firestore();
}

/**
 * Normaliza o texto para hash e deduplicação.
 *
 * @param {string} text Texto bruto recebido.
 * @return {string} Texto normalizado.
 */
export function normalizeChatText(text: string): string {
  return text.trim().toLowerCase().replace(/\s+/g, " ");
}

/**
 * Remove separadores para capturar obfuscação simples.
 *
 * @param {string} text Texto bruto recebido.
 * @return {string} Texto colapsado.
 */
function collapseChatText(text: string): string {
  return normalizeChatText(text).replace(/[^a-z0-9@]+/g, "");
}

/**
 * Sanitiza listas arbitrárias recebidas do cliente.
 *
 * @param {unknown} raw Valor bruto.
 * @return {string[]} Lista limpa e sem duplicidade.
 */
function sanitizeStringList(raw: unknown): string[] {
  if (!Array.isArray(raw)) return [];

  return [...new Set(
    raw
      .filter((item): item is string => typeof item === "string")
      .map((item) => item.trim())
      .filter(Boolean)
  )].sort();
}

/**
 * Remove acentos para comparação léxica simples.
 *
 * @param {string} token Token bruto.
 * @return {string} Token normalizado.
 */
function normalizeToken(token: string): string {
  return token
    .replace(/[áàâã]/g, "a")
    .replace(/[éê]/g, "e")
    .replace(/[í]/g, "i")
    .replace(/[óôõ]/g, "o")
    .replace(/[úü]/g, "u")
    .replace(/ç/g, "c");
}

/**
 * Detecta palavras-chave no texto normalizado e colapsado.
 *
 * @param {string} lowerText Texto em lowercase.
 * @param {string} collapsedText Texto colapsado.
 * @param {string[]} keywords Palavras-chave aceitas.
 * @return {boolean} Se alguma keyword foi encontrada.
 */
function containsKeyword(
  lowerText: string,
  collapsedText: string,
  keywords: string[]
): boolean {
  for (const keyword of keywords) {
    const escaped = keyword.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const boundaryPattern = new RegExp(`\\b${escaped}\\b`, "i");
    if (boundaryPattern.test(lowerText)) return true;

    const collapsedKeyword = keyword.toLowerCase().replace(/[^a-z0-9@]+/g, "");
    if (collapsedKeyword && collapsedText.includes(collapsedKeyword)) {
      return true;
    }
  }

  return false;
}

/**
 * Heurística simples para telefone brasileiro ou sequência longa.
 *
 * @param {string} text Texto bruto.
 * @return {boolean} Se parece telefone.
 */
function looksLikePhone(text: string): boolean {
  if (!PHONE_PATTERN.test(text) && !SPACED_DIGITS_PATTERN.test(text)) {
    return false;
  }

  const digitsOnly = text.replace(/\D/g, "");
  return digitsOnly.length >= 10 && digitsOnly.length <= 13;
}

/**
 * Mede a maior sequência consecutiva de dígitos por extenso.
 *
 * @param {string} text Texto bruto.
 * @return {number} Maior sequência encontrada.
 */
function longestNumberWordRun(text: string): number {
  const tokens = text
    .toLowerCase()
    .replace(/[^a-zà-ú]+/g, " ")
    .split(/\s+/)
    .filter(Boolean)
    .map(normalizeToken);

  let currentRun = 0;
  let longestRun = 0;

  for (const token of tokens) {
    if (NUMBER_WORDS.has(token)) {
      currentRun += 1;
      if (currentRun > longestRun) {
        longestRun = currentRun;
      }
      continue;
    }

    currentRun = 0;
  }

  return longestRun;
}

/**
 * Analisa conteúdo de chat e marca padrões suspeitos.
 *
 * @param {string} rawText Texto a analisar.
 * @return {ChatSafetyAnalysis} Resultado da análise.
 */
export function analyzeChatText(rawText: string): ChatSafetyAnalysis {
  const text = rawText.trim();
  if (!text) {
    return {
      isSuspicious: false,
      patterns: [],
      channels: [],
      severity: null,
    };
  }

  const lower = normalizeChatText(text);
  const collapsed = collapseChatText(text);
  const patterns = new Set<string>();
  const channels = new Set<string>();

  const hasEmail = EMAIL_PATTERN.test(text);
  const hasUrl = URL_PATTERN.test(text);
  const hasPhone = looksLikePhone(text);
  const hasHandle = !hasEmail && HANDLE_PATTERN.test(text);
  const hasContactIntent = CONTACT_INTENT_PATTERN.test(lower);
  const numberWordRun = longestNumberWordRun(text);
  const hasNumberWords =
    numberWordRun >= 8 || (numberWordRun >= 6 && hasContactIntent);

  if (hasEmail) patterns.add("email");
  if (hasUrl) patterns.add("url");
  if (hasPhone) patterns.add("phone");
  if (hasHandle) patterns.add("handle");
  if (hasNumberWords) patterns.add("number_words");

  for (const [channel, keywords] of Object.entries(CHANNEL_KEYWORDS)) {
    if (!containsKeyword(lower, collapsed, keywords)) continue;

    const hasDirectIdentifier =
      hasEmail || hasUrl || hasPhone || hasHandle || hasContactIntent;
    if (!hasDirectIdentifier) continue;

    channels.add(channel);
    patterns.add(`channel:${channel}`);
  }

  if (patterns.size === 0) {
    return {
      isSuspicious: false,
      patterns: [],
      channels: [],
      severity: null,
    };
  }

  const hasDirectContactPattern =
    hasEmail ||
    hasUrl ||
    hasPhone ||
    hasHandle ||
    hasNumberWords ||
    channels.size > 0;
  if (!hasDirectContactPattern) {
    return {
      isSuspicious: false,
      patterns: [],
      channels: [],
      severity: null,
    };
  }

  const severity: ChatSafetySeverity =
    hasEmail ||
      hasUrl ||
      hasPhone ||
      hasHandle ||
      hasNumberWords ||
      channels.size > 1 ?
      "high" :
      "medium";

  return {
    isSuspicious: true,
    patterns: [...patterns].sort(),
    channels: [...channels].sort(),
    severity,
  };
}

/**
 * Gera hash estável do texto normalizado.
 *
 * @param {string} text Texto bruto.
 * @return {string} Hash sha256 em hexadecimal.
 */
export function hashNormalizedChatText(text: string): string {
  return createHash("sha256").update(normalizeChatText(text)).digest("hex");
}

/**
 * Mascara marcadores diretos de contato antes de persistir o evento.
 *
 * @param {string} text Texto bruto.
 * @return {string} Texto mascarado.
 */
export function maskChatText(text: string): string {
  const masked = text
    .replace(EMAIL_PATTERN, "[email]")
    .replace(URL_PATTERN, "[url]")
    .replace(PHONE_PATTERN, "[phone]")
    .replace(SPACED_DIGITS_PATTERN, "[digits]")
    .replace(HANDLE_PATTERN, "$1[handle]");

  if (longestNumberWordRun(masked) < 6) {
    return masked;
  }

  const tokens = masked.split(/(\s+)/);
  const result: string[] = [];
  let index = 0;

  while (index < tokens.length) {
    const token = tokens[index];
    if (token.trim().length === 0) {
      result.push(token);
      index += 1;
      continue;
    }

    const normalizedToken = normalizeToken(token.toLowerCase());
    if (!NUMBER_WORDS.has(normalizedToken)) {
      result.push(token);
      index += 1;
      continue;
    }

    const runStart = index;
    let runCount = 0;
    const runParts: string[] = [];

    while (index < tokens.length) {
      const current = tokens[index];
      if (current.trim().length === 0) {
        runParts.push(current);
        index += 1;
        continue;
      }

      const normalizedCurrent = normalizeToken(current.toLowerCase());
      if (!NUMBER_WORDS.has(normalizedCurrent)) {
        break;
      }

      runParts.push(current);
      runCount += 1;
      index += 1;
    }

    if (runCount >= 6) {
      result.push("[number_words]");
      continue;
    }

    result.push(...tokens.slice(runStart, index));
  }

  return result.join("");
}

/**
 * Monta ID determinístico para reduzir duplicidade por minuto.
 *
 * @param {ChatSafetySource} source Origem do evento.
 * @param {string} userId UID do usuário.
 * @param {string|undefined} conversationId ID da conversa.
 * @param {string} normalizedHash Hash do texto normalizado.
 * @param {Date} createdAt Data do evento.
 * @return {string} ID do documento.
 */
export function buildChatSafetyEventId(
  source: ChatSafetySource,
  userId: string,
  conversationId: string | undefined,
  normalizedHash: string,
  createdAt: Date
): string {
  const bucket = Math.floor(createdAt.getTime() / 60000);
  const safeConversationId = (conversationId || "none").replace(/\//g, "_");
  return `${source}_${userId}_${safeConversationId}_` +
    `${normalizedHash.slice(0, 16)}_${bucket}`;
}

/**
 * Registra um evento de chat safety quando o conteúdo é suspeito.
 *
 * @param {ChatSafetyEventInput} input Payload do evento.
 * @return {Promise<boolean>} Se o evento foi persistido.
 */
export async function logChatSafetyEvent(
  input: ChatSafetyEventInput
): Promise<boolean> {
  const trimmedText = input.text.trim();
  if (!trimmedText) return false;

  const analysis = analyzeChatText(trimmedText);
  if (!analysis.isSuspicious || analysis.severity == null) {
    return false;
  }

  const nowDate = new Date();
  const now = Timestamp.fromDate(nowDate);
  const normalizedHash = hashNormalizedChatText(trimmedText);
  const eventId = buildChatSafetyEventId(
    input.source,
    input.userId,
    input.conversationId,
    normalizedHash,
    nowDate
  );
  const eventRef = getDb().collection("chatSafetyEvents").doc(eventId);
  const clientPatterns = sanitizeStringList(input.clientPatterns);
  const clientChannels = sanitizeStringList(input.clientChannels);
  const platform =
    typeof input.platform === "string" ? input.platform.trim() : "";
  const clientSeverity =
    typeof input.clientSeverity === "string" ?
      input.clientSeverity.trim() :
      "";

  await getDb().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(eventRef);

    if (snapshot.exists) {
      const updateData: Record<string, unknown> = {
        attempt_count: FieldValue.increment(1),
        last_seen_at: now,
      };

      if (clientPatterns.length > 0) {
        updateData.client_patterns = FieldValue.arrayUnion(...clientPatterns);
      }
      if (clientChannels.length > 0) {
        updateData.client_channels = FieldValue.arrayUnion(...clientChannels);
      }
      if (clientSeverity) {
        updateData.client_severity = clientSeverity;
      }
      if (platform) {
        updateData.platform = platform;
      }

      transaction.update(eventRef, updateData);
      return;
    }

    transaction.set(eventRef, {
      user_id: input.userId,
      conversation_id: input.conversationId || null,
      message_id: input.messageId || null,
      source: input.source,
      patterns: analysis.patterns,
      channels: analysis.channels,
      severity: analysis.severity,
      masked_text: maskChatText(trimmedText),
      normalized_hash: normalizedHash,
      message_length: trimmedText.length,
      attempt_count: 1,
      client_patterns: clientPatterns,
      client_channels: clientChannels,
      client_severity: clientSeverity || null,
      platform: platform || null,
      created_at: now,
      last_seen_at: now,
    });
  });

  return true;
}

/**
 * Callable para registrar aviso pré-envio detectado no cliente.
 *
 * @return {Promise<{logged: boolean}>} Resultado da persistência.
 */
export const logChatPreSendWarning = onCall(
  {
    region: "southamerica-east1",
    memory: "256MiB",
    enforceAppCheck: true,
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const data = request.data as LogChatPreSendWarningRequest;
    const conversationId =
      typeof data.conversationId === "string" ? data.conversationId.trim() : "";
    const text = typeof data.text === "string" ? data.text.trim() : "";

    if (!conversationId) {
      throw new HttpsError(
        "invalid-argument",
        "conversationId é obrigatório"
      );
    }

    if (!text || text.length > 1000) {
      throw new HttpsError(
        "invalid-argument",
        "text deve ter entre 1 e 1000 caracteres"
      );
    }

    const logged = await logChatSafetyEvent({
      userId: request.auth.uid,
      conversationId,
      text,
      source: "pre_send_warning",
      clientPatterns: sanitizeStringList(data.clientPatterns),
      clientChannels: sanitizeStringList(data.clientChannels),
      clientSeverity:
        typeof data.severity === "string" ? data.severity.trim() : "",
      platform: typeof data.platform === "string" ? data.platform.trim() : "",
    });

    return {logged};
  }
);
