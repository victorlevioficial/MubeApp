// Backend access layer: Firebase compat (global `firebase`, loaded via the
// compat CDN scripts in index.html) + callable Cloud Functions resolved per
// region. The real security boundary is assertAdmin() on the server; the
// client only gates the UI.

const REGION = "southamerica-east1";

// Functions deployed outside the default region. Kept in sync with the legacy
// panel. (A future hardening step unifies regions and removes this map.)
const FUNCTION_REGIONS = {
  getConversationAdminDetail: "us-central1",
  listGigsAdmin: "us-central1",
  getGigAdminDetail: "us-central1",
  getMatchpointAdminOverview: "us-central1",
  getSystemAdminData: "us-central1",
  inspectFirestorePath: "us-central1",
  inspectStoragePrefix: "us-central1",
};

const app = firebase.app();
export const auth = firebase.auth();
const functionsByRegion = {};

auth.setPersistence(firebase.auth.Auth.Persistence.LOCAL).catch(() => null);

/** Invoke a callable Cloud Function and return its `.data` payload. */
export function callFunction(name, payload) {
  const region = FUNCTION_REGIONS[name] || REGION;
  if (!functionsByRegion[region]) {
    functionsByRegion[region] = app.functions(region);
  }
  return functionsByRegion[region].httpsCallable(name)(payload || {}).then((response) => response.data);
}

export function onAuth(callback) {
  return auth.onAuthStateChanged(callback);
}

export function signIn(email, password) {
  return auth.signInWithEmailAndPassword(email, password);
}

export function signOutAdmin() {
  return auth.signOut();
}

/**
 * Confirm the signed-in user carries the admin custom claim. Falls back to the
 * legacy self-bootstrap via setAdminClaim (no-op once a non-admin is denied by
 * the server). Resolves with the token result or throws a friendly error.
 */
export async function ensureAdminAccess(user) {
  let token = await user.getIdTokenResult(true);
  if (token.claims && token.claims.admin === true) return token;

  const email = user.email;
  if (!email) throw new Error("Não foi possível validar a conta administrativa.");

  try {
    await callFunction("setAdminClaim", { email });
    await user.getIdToken(true);
    token = await user.getIdTokenResult(true);
    if (token.claims && token.claims.admin === true) return token;
  } catch (error) {
    const code = error && error.code;
    if (code !== "functions/permission-denied" && code !== "permission-denied") throw error;
  }

  throw new Error("Sua conta autenticou, mas ainda não possui permissão de admin.");
}
