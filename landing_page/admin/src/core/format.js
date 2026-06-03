// Data normalization and formatting helpers, ported from the legacy panel.
// The backend returns Firestore values in several timestamp shapes; toMillis()
// normalizes all of them. UI-facing strings are pt-BR.

export function stringValue(value, fallback = "") {
  if (value === null || value === undefined) return fallback;
  return String(value);
}

export function toInteger(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? Math.floor(n) : fallback;
}

export function asArray(value) {
  return Array.isArray(value) ? value : [];
}

export function asObject(value) {
  return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}

export function firstWord(value) {
  return String(value || "").trim().split(/\s+/)[0] || "U";
}

export function initialOf(value) {
  return firstWord(value).slice(0, 1).toUpperCase();
}

/** Normalize the many timestamp shapes the backend can return into millis. */
export function toMillis(value) {
  if (!value && value !== 0) return null;
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? null : parsed;
  }
  if (value instanceof Date) return value.getTime();
  if (typeof value.toMillis === "function") return value.toMillis();
  if (typeof value.millis === "number") return value.millis;
  if (typeof value._seconds === "number") {
    return value._seconds * 1000 + Math.floor((value._nanoseconds || 0) / 1e6);
  }
  if (typeof value.seconds === "number") {
    return value.seconds * 1000 + Math.floor((value.nanoseconds || 0) / 1e6);
  }
  if (typeof value.iso === "string") {
    const parsed = Date.parse(value.iso);
    return Number.isNaN(parsed) ? null : parsed;
  }
  return null;
}

export function formatNumber(value) {
  const n = Number(value);
  return Number.isFinite(n) ? new Intl.NumberFormat("pt-BR").format(n) : "0";
}

export function formatDecimal(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return "0";
  return new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 1, maximumFractionDigits: 2 }).format(n);
}

export function formatDateTime(value) {
  const millis = toMillis(value);
  if (!millis) return "—";
  return new Intl.DateTimeFormat("pt-BR", { dateStyle: "short", timeStyle: "short" }).format(new Date(millis));
}

/** Compact relative time, e.g. "agora", "há 5 min", "há 3 h", "há 2 d". */
export function formatRelative(value) {
  const millis = toMillis(value);
  if (!millis) return "—";
  const diff = Date.now() - millis;
  if (diff < 0) return formatDateTime(value);
  const min = Math.floor(diff / 60000);
  if (min < 1) return "agora";
  if (min < 60) return `há ${min} min`;
  const hours = Math.floor(min / 60);
  if (hours < 24) return `há ${hours} h`;
  const days = Math.floor(hours / 24);
  if (days < 30) return `há ${days} d`;
  return formatDateTime(value);
}

export function prettyJson(value) {
  try {
    return JSON.stringify(value, null, 2);
  } catch (_error) {
    return String(value);
  }
}

export function isPermissionDeniedError(error) {
  const code = stringValue(error && error.code);
  return code === "functions/permission-denied" || code === "permission-denied";
}

/** Map raw auth/functions errors to friendly pt-BR messages. */
export function getErrorMessage(error) {
  const code = stringValue(error && error.code);
  const message = stringValue(error && error.message, "Falha inesperada.");
  if (code === "auth/wrong-password" || code === "auth/invalid-credential") return "Email ou senha inválidos.";
  if (code === "auth/user-not-found") return "Conta não encontrada.";
  if (code === "auth/too-many-requests") return "Muitas tentativas. Tente novamente em alguns minutos.";
  if (isPermissionDeniedError(error)) return "Sua conta não possui permissão para esta operação.";
  return message.replace(/^Firebase:\s*/i, "").trim();
}

/** Normalize a value into a CSS-safe key for badge/pill variants. */
export function sanitizeKey(value) {
  return String(value || "default").trim().toLowerCase().replace(/\s+/g, "_").replace(/[^a-z0-9_-]/g, "_");
}
