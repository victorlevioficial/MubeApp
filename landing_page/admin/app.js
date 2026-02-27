/* ============================================
   Mube Admin Panel — app.js
   Firebase Auth + Cloud Functions Integration
   ============================================ */

// Firebase Config
const firebaseConfig = {
  apiKey: "AIzaSyA9uPQy-IFGxFjqJ5bAHGS_gxK8S91jwBo",
  authDomain: "mube-63a93.firebaseapp.com",
  projectId: "mube-63a93",
  storageBucket: "mube-63a93.firebasestorage.app",
  messagingSenderId: "798301748829",
  appId: "1:798301748829:web:f1b96526dcd3f99b47d7b4",
};

// Initialize only if not already initialized by hosting init.js
if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}
const auth = firebase.auth();
const functions = firebase.app().functions("southamerica-east1");
const functionsUsCentral = firebase.app().functions("us-central1");
const VIDEO_BACKFILL_CALLABLE_TIMEOUT_MS = 540000;

// ============================================
// STATE
// ============================================
let currentUser = null;
let featuredUids = [];
let featuredProfiles = [];
let videoBackfillRunning = false;
let videoBackfillCursorValue = null;
let videoBackfillHasMoreValue = false;
let videoBackfillLastMode = null; // "dryRun" | "run" | null

// ============================================
// DOM REFS
// ============================================
const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

const loginScreen = $("#login-screen");
const adminPanel = $("#admin-panel");
const loginForm = $("#login-form");
const loginError = $("#login-error");
const loginBtn = $("#login-btn");
const logoutBtn = $("#logout-btn");
const pageTitle = $("#page-title");
const adminEmail = $("#admin-email");
const videoBackfillLimit = $("#video-backfill-limit");
const videoBackfillDryRunBtn = $("#video-backfill-dry-run-btn");
const videoBackfillRunBtn = $("#video-backfill-run-btn");
const videoBackfillResetBtn = $("#video-backfill-reset-btn");
const videoBackfillCursor = $("#video-backfill-cursor");
const videoBackfillHasMore = $("#video-backfill-has-more");
const videoBackfillReport = $("#video-backfill-report");

// ============================================
// AUTH
// ============================================
auth.onAuthStateChanged(async (user) => {
  if (user) {
    const token = await user.getIdTokenResult();
    if (token.claims.admin) {
      currentUser = user;
      loginScreen.classList.add("hidden");
      adminPanel.classList.remove("hidden");
      adminEmail.textContent = user.email;
      loadDashboard();
    } else {
      showLoginError("Conta sem permissão de administrador.");
      auth.signOut();
    }
  } else {
    currentUser = null;
    loginScreen.classList.remove("hidden");
    adminPanel.classList.add("hidden");
  }
});

loginForm.addEventListener("submit", async (e) => {
  e.preventDefault();
  const email = $("#login-email").value;
  const password = $("#login-password").value;

  setLoginLoading(true);
  hideLoginError();

  try {
    await auth.signInWithEmailAndPassword(email, password);
  } catch (err) {
    showLoginError(translateAuthError(err.code));
  } finally {
    setLoginLoading(false);
  }
});

logoutBtn.addEventListener("click", () => auth.signOut());

function setLoginLoading(loading) {
  loginBtn.querySelector(".btn-text").classList.toggle("hidden", loading);
  loginBtn.querySelector(".btn-loader").classList.toggle("hidden", !loading);
  loginBtn.disabled = loading;
}

function showLoginError(msg) {
  loginError.textContent = msg;
  loginError.classList.remove("hidden");
}

function hideLoginError() {
  loginError.classList.add("hidden");
}

function translateAuthError(code) {
  const map = {
    "auth/user-not-found": "Usuário não encontrado.",
    "auth/wrong-password": "Senha incorreta.",
    "auth/invalid-email": "Email inválido.",
    "auth/too-many-requests": "Muitas tentativas. Tente mais tarde.",
    "auth/invalid-credential": "Credenciais inválidas.",
  };
  return map[code] || "Erro ao fazer login.";
}

// ============================================
// NAVIGATION
// ============================================
$$(".nav-item").forEach((item) => {
  item.addEventListener("click", () => {
    const section = item.dataset.section;
    $$(".nav-item").forEach((n) => n.classList.remove("active"));
    item.classList.add("active");
    $$(".section").forEach((s) => s.classList.add("hidden"));
    $(`#section-${section}`).classList.remove("hidden");
    pageTitle.textContent = item.querySelector("span:last-child").textContent;
    loadSectionData(section);
  });
});

function loadSectionData(section) {
  switch (section) {
    case "dashboard": loadDashboard(); break;
    case "featured": loadFeatured(); break;
    case "reports": loadReports(); break;
    case "suspensions": loadSuspensions(); break;
    case "tickets": loadTickets(); break;
    case "chats": loadChats(); break;
    case "users":
      if ($("#user-search-results").innerHTML === "") {
        $("#user-search-btn").click();
      }
      break;
    case "videos":
      refreshVideoBackfillUi();
      break;
  }
}

// ============================================
// VIDEOS BACKFILL
// ============================================
function parseBackfillLimit() {
  const raw = parseInt(videoBackfillLimit?.value || "20", 10);
  const fallback = Number.isFinite(raw) ? raw : 20;
  const clamped = Math.max(1, Math.min(100, fallback));
  if (videoBackfillLimit) videoBackfillLimit.value = String(clamped);
  return clamped;
}

function asBackfillInt(value) {
  if (typeof value === "number" && Number.isFinite(value)) {
    return Math.trunc(value);
  }
  const parsed = parseInt(String(value || "0"), 10);
  return Number.isFinite(parsed) ? parsed : 0;
}

function setBackfillReport(text) {
  if (!videoBackfillReport) return;
  videoBackfillReport.textContent = text;
}

function refreshVideoBackfillUi() {
  const runContinuation =
    videoBackfillLastMode === "run" && videoBackfillHasMoreValue;

  if (videoBackfillCursor) {
    videoBackfillCursor.textContent = videoBackfillCursorValue || "-";
  }
  if (videoBackfillHasMore) {
    videoBackfillHasMore.textContent = videoBackfillHasMoreValue ? "sim" : "nao";
  }
  if (videoBackfillRunBtn) {
    videoBackfillRunBtn.innerHTML = runContinuation ?
      '<span class="material-icons-round">skip_next</span> Proximo Lote' :
      '<span class="material-icons-round">play_arrow</span> Executar Lote';
  }
}

function formatBackfillResult(data) {
  const lines = [
    "Backfill de videos - resultado:",
    `dryRun: ${data.dryRun === true ? "true" : "false"}`,
    `usersScanned: ${asBackfillInt(data.usersScanned)}`,
    `usersWithVideos: ${asBackfillInt(data.usersWithVideos)}`,
    `videosDiscovered: ${asBackfillInt(data.videosDiscovered)}`,
    `alreadyTranscodedUrl: ${asBackfillInt(data.alreadyTranscodedUrl)}`,
    `alreadyTranscodedFile: ${asBackfillInt(data.alreadyTranscodedFile)}`,
    `updatedFromExistingFile: ${asBackfillInt(data.updatedFromExistingFile)}`,
    `wouldTranscode: ${asBackfillInt(data.wouldTranscode)}`,
    `transcodeTriggered: ${asBackfillInt(data.transcodeTriggered)}`,
    `transcodeFailures: ${asBackfillInt(data.transcodeFailures)}`,
    `missingSource: ${asBackfillInt(data.missingSource)}`,
    `hasMore: ${data.hasMore === true ? "true" : "false"}`,
    `nextCursor: ${data.nextCursor || "-"}`,
  ];

  const failures = Array.isArray(data.failures) ? data.failures : [];
  if (failures.length > 0) {
    lines.push("");
    lines.push("Failures (max 5):");
    failures.slice(0, 5).forEach((item) => {
      const failure = item || {};
      lines.push(
        `- user=${failure.userId || "-"} media=${failure.mediaId || "-"} error=${failure.error || "-"}`,
      );
    });
  }

  return lines.join("\n");
}

function setBackfillRunning(running, mode = "") {
  videoBackfillRunning = running;
  const disableAll = running;
  if (videoBackfillLimit) videoBackfillLimit.disabled = disableAll;
  if (videoBackfillDryRunBtn) videoBackfillDryRunBtn.disabled = disableAll;
  if (videoBackfillRunBtn) videoBackfillRunBtn.disabled = disableAll;
  if (videoBackfillResetBtn) videoBackfillResetBtn.disabled = disableAll;

  if (!running) return;

  setBackfillReport(
    mode === "dryRun" ?
      "Executando simulacao..." :
      "Executando lote real...",
  );
}

function getVideoBackfillCallable() {
  return functionsUsCentral.httpsCallable(
    "backfillGalleryVideoTranscodes",
    { timeout: VIDEO_BACKFILL_CALLABLE_TIMEOUT_MS },
  );
}

async function executeVideoBackfill({ dryRun, resetCursor }) {
  if (videoBackfillRunning) return;
  if (!currentUser) {
    toast("Faca login novamente para executar o backfill.", "error");
    return;
  }

  const limit = parseBackfillLimit();
  const payload = { dryRun, limit };

  if (!resetCursor && videoBackfillCursorValue) {
    payload.startAfterUserId = videoBackfillCursorValue;
  }

  if (resetCursor) {
    videoBackfillCursorValue = null;
    videoBackfillHasMoreValue = false;
    refreshVideoBackfillUi();
  }

  setBackfillRunning(true, dryRun ? "dryRun" : "run");

  try {
    const result = await getVideoBackfillCallable()(payload);
    const data = result?.data || {};

    videoBackfillHasMoreValue = data.hasMore === true;
    videoBackfillCursorValue = typeof data.nextCursor === "string" ?
      data.nextCursor :
      null;
    videoBackfillLastMode = dryRun ? "dryRun" : "run";
    refreshVideoBackfillUi();
    setBackfillReport(formatBackfillResult(data));
    toast("Backfill executado com sucesso.", "success");
  } catch (err) {
    console.error("Video backfill error:", err);
    const code = String(err?.code || "");
    const message = err?.message || "Erro ao executar backfill.";
    const isDeadline = code.includes("deadline-exceeded") ||
      message.toLowerCase().includes("deadline-exceeded");

    if (isDeadline) {
      setBackfillReport(
        "A chamada expirou (deadline-exceeded), mas o processamento pode ter continuado no backend.\n" +
        "Rode Simular (Dry Run) para verificar o estado atual antes de repetir.",
      );
    } else {
      setBackfillReport(`Erro ao executar backfill: ${message}`);
    }
    toast("Erro ao executar backfill de videos.", "error");
  } finally {
    setBackfillRunning(false);
  }
}

if (videoBackfillDryRunBtn) {
  videoBackfillDryRunBtn.addEventListener("click", () => {
    executeVideoBackfill({ dryRun: true, resetCursor: true });
  });
}

if (videoBackfillRunBtn) {
  videoBackfillRunBtn.addEventListener("click", () => {
    const shouldContinueFromCursor =
      videoBackfillLastMode === "run" &&
      videoBackfillHasMoreValue === true &&
      typeof videoBackfillCursorValue === "string" &&
      videoBackfillCursorValue.trim().length > 0;

    const shouldResetCursor = !shouldContinueFromCursor;
    executeVideoBackfill({
      dryRun: false,
      resetCursor: shouldResetCursor,
    });
  });
}

if (videoBackfillResetBtn) {
  videoBackfillResetBtn.addEventListener("click", () => {
    if (videoBackfillRunning) return;
    videoBackfillCursorValue = null;
    videoBackfillHasMoreValue = false;
    videoBackfillLastMode = null;
    refreshVideoBackfillUi();
    setBackfillReport(
      "Cursor reiniciado. O proximo lote vai recomecar do inicio.",
    );
    toast("Cursor de backfill reiniciado.", "success");
  });
}

refreshVideoBackfillUi();

// ============================================
// DASHBOARD
// ============================================
async function loadDashboard() {
  try {
    const result = await functions.httpsCallable("getDashboardStats")();
    const d = result.data;
    $("#stat-users").textContent = formatNumber(d.totalUsers);
    $("#stat-new24h").textContent = formatNumber(d.newUsers24h);
    $("#stat-new7d").textContent = formatNumber(d.newUsers7d);
    $("#stat-reports").textContent = formatNumber(d.pendingReports);
    $("#stat-suspensions").textContent = formatNumber(d.activeSuspensions);
    $("#stat-tickets").textContent = formatNumber(d.openTickets);
  } catch (err) {
    console.error("Dashboard error:", err);
    toast("Erro ao carregar dashboard", "error");
  }
}

// ============================================
// FEATURED PROFILES
// ============================================
async function loadFeatured() {
  try {
    const result = await functions.httpsCallable("getFeaturedProfiles")();
    featuredUids = result.data.uids || [];
    featuredProfiles = result.data.profiles || [];
    renderFeaturedList();
  } catch (err) {
    console.error("Featured error:", err);
    toast("Erro ao carregar destaques", "error");
  }
}

function renderFeaturedList() {
  const list = $("#featured-list");
  const saveBtn = $("#featured-save-btn");

  if (featuredProfiles.length === 0) {
    list.innerHTML = '<p class="empty-state">Nenhum perfil em destaque. Adicione usando o campo acima.</p>';
    saveBtn.classList.add("hidden");
    return;
  }

  list.innerHTML = featuredProfiles
    .map((p, i) => `
      <div class="featured-item" data-uid="${p.uid}">
        <span class="order">${i + 1}</span>
        <img class="user-avatar" src="${p.foto || ''}" alt="" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 40 40%22><rect fill=%22%231a1a26%22 width=%2240%22 height=%2240%22/><text x=%2250%%22 y=%2255%%22 text-anchor=%22middle%22 fill=%22%238b8ba0%22 font-size=%2216%22>?</text></svg>'">
        <div class="user-info">
          <div class="name">${esc(p.nome)}</div>
          <div class="meta">${esc(p.tipoPerfil)} · ${esc(p.cidade)} · ❤ ${p.likeCount}</div>
        </div>
        <div class="actions">
          <button class="btn btn-sm btn-danger" onclick="removeFeatured('${p.uid}')">
            <span class="material-icons-round">close</span>
          </button>
        </div>
      </div>
    `)
    .join("");

  saveBtn.classList.remove("hidden");
}

// Lookup user for preview
$("#featured-lookup-btn").addEventListener("click", async () => {
  const uid = $("#featured-uid-input").value.trim();
  if (!uid) return;

  try {
    const result = await functions.httpsCallable("lookupUser")({ uid });
    const u = result.data;
    const preview = $("#featured-preview");
    preview.innerHTML = `
      <img class="user-avatar" src="${u.foto || ''}" alt="" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 40 40%22><rect fill=%22%231a1a26%22 width=%2240%22 height=%2240%22/><text x=%2250%%22 y=%2255%%22 text-anchor=%22middle%22 fill=%22%238b8ba0%22 font-size=%2216%22>?</text></svg>'">
      <div class="user-info">
        <div class="name">${esc(u.nome)}</div>
        <div class="meta">${esc(u.tipoPerfil)} · ${esc(u.cidade)} · ❤ ${u.likeCount} · Status: ${u.status}</div>
      </div>
    `;
    preview.classList.remove("hidden");
    $("#featured-add-btn").classList.remove("hidden");
    $("#featured-add-btn").dataset.uid = uid;
  } catch (err) {
    toast("Usuário não encontrado", "error");
    $("#featured-preview").classList.add("hidden");
    $("#featured-add-btn").classList.add("hidden");
  }
});

// Add to featured
$("#featured-add-btn").addEventListener("click", () => {
  const uid = $("#featured-add-btn").dataset.uid;
  if (!uid || featuredUids.includes(uid)) {
    toast("Perfil já está na lista", "error");
    return;
  }

  const preview = $("#featured-preview");
  const name = preview.querySelector(".name")?.textContent || "";
  const meta = preview.querySelector(".meta")?.textContent || "";
  const foto = preview.querySelector(".user-avatar")?.src || "";

  featuredUids.push(uid);
  featuredProfiles.push({
    uid,
    nome: name,
    foto: foto,
    tipoPerfil: meta.split(" · ")[0] || "",
    cidade: meta.split(" · ")[1] || "",
    likeCount: 0,
  });

  renderFeaturedList();
  $("#featured-uid-input").value = "";
  preview.classList.add("hidden");
  $("#featured-add-btn").classList.add("hidden");
  toast("Perfil adicionado! Clique em Salvar para confirmar.", "success");
});

// Remove from featured
window.removeFeatured = function (uid) {
  featuredUids = featuredUids.filter((u) => u !== uid);
  featuredProfiles = featuredProfiles.filter((p) => p.uid !== uid);
  renderFeaturedList();
  toast("Perfil removido. Salve para confirmar.", "success");
};

// Save featured
$("#featured-save-btn").addEventListener("click", async () => {
  try {
    await functions.httpsCallable("setFeaturedProfiles")({ uids: featuredUids });
    toast("Perfis em destaque salvos!", "success");
  } catch (err) {
    console.error("Save featured error:", err);
    toast("Erro ao salvar destaques", "error");
  }
});

// ============================================
// USERS
// ============================================
$("#user-search-btn").addEventListener("click", async () => {
  const query = $("#user-search-input").value.trim();
  if (!query) return;

  const results = $("#user-search-results");
  results.innerHTML = '<p class="empty-state">Buscando...</p>';

  try {
    // If looks like a UID (long string, no spaces), try direct lookup
    if (query.length > 20 && !query.includes(" ")) {
      const result = await functions.httpsCallable("lookupUser")({ uid: query });
      const u = result.data;
      results.innerHTML = renderUserCard(u, true);
      return;
    }

    const result = await functions.httpsCallable("searchUsers")({ query, limit: 20 });
    const users = result.data.results || [];

    if (users.length === 0) {
      results.innerHTML = '<p class="empty-state">Nenhum resultado.</p>';
      return;
    }

    results.innerHTML = users.map((u) => renderUserCard(u, false)).join("");
  } catch (err) {
    console.error("Search error:", err);
    results.innerHTML = '<p class="empty-state">Erro na busca.</p>';
  }
});

// Enter key on search
$("#user-search-input").addEventListener("keydown", (e) => {
  if (e.key === "Enter") $("#user-search-btn").click();
});

function renderUserCard(u, detailed) {
  const statusBadge = `<span class="badge badge-${u.status || 'active'}">${u.status || 'active'}</span>`;
  let extra = "";
  if (detailed) {
    extra = `
      <div style="margin-top:8px; font-size:13px; color:var(--text-secondary);">
        <div>Email: ${esc(u.email || '—')}</div>
        <div>Bio: ${esc(u.bio || '—')}</div>
        <div>Reports: ${u.reportCount || 0} · Suspensões: ${u.suspensionCount || 0}</div>
      </div>
    `;
  }

  return `
    <div class="user-preview" style="cursor:pointer" onclick="showUserDetail('${u.uid}')">
      <img class="user-avatar" src="${u.foto || ''}" alt="" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 40 40%22><rect fill=%22%231a1a26%22 width=%2240%22 height=%2240%22/><text x=%2250%%22 y=%2255%%22 text-anchor=%22middle%22 fill=%22%238b8ba0%22 font-size=%2216%22>?</text></svg>'">
      <div class="user-info">
        <div class="name">${esc(u.nome)} ${statusBadge}</div>
        <div class="meta">${esc(u.tipoPerfil)} · ${esc(u.cidade || u.estado || '')} · UID: ${u.uid.substring(0, 12)}...</div>
        ${extra}
      </div>
    </div>
  `;
}

window.showUserDetail = async function (uid) {
  try {
    const result = await functions.httpsCallable("lookupUser")({ uid });
    const u = result.data;
    const modal = $("#user-detail-modal");
    const body = $("#user-detail-body");

    body.innerHTML = `
      <div style="display:flex; align-items:center; gap:16px; margin-bottom:20px;">
        <img class="user-avatar" src="${u.foto || ''}" style="width:72px;height:72px;" alt="" onerror="this.src='data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 40 40%22><rect fill=%22%231a1a26%22 width=%2240%22 height=%2240%22/><text x=%2250%%22 y=%2255%%22 text-anchor=%22middle%22 fill=%22%238b8ba0%22 font-size=%2216%22>?</text></svg>'">
        <div>
          <h3>${esc(u.nome)}</h3>
          <span class="badge badge-${u.status || 'active'}">${u.status || 'active'}</span>
        </div>
      </div>
      <table class="data-table" style="width:100%">
        <tbody>
          <tr><td style="color:var(--text-muted);width:140px">UID</td><td>${u.uid}</td></tr>
          <tr><td style="color:var(--text-muted)">Email</td><td>${esc(u.email || '—')}</td></tr>
          <tr><td style="color:var(--text-muted)">Tipo</td><td>${esc(u.tipoPerfil)}</td></tr>
          <tr><td style="color:var(--text-muted)">Cidade</td><td>${esc(u.cidade || '—')}</td></tr>
          <tr><td style="color:var(--text-muted)">Estado</td><td>${esc(u.estado || '—')}</td></tr>
          <tr><td style="color:var(--text-muted)">Bio</td><td>${esc(u.bio || '—')}</td></tr>
          <tr><td style="color:var(--text-muted)">Likes</td><td>❤ ${u.likeCount}</td></tr>
          <tr><td style="color:var(--text-muted)">Reports</td><td>${u.reportCount || 0}</td></tr>
          <tr><td style="color:var(--text-muted)">Suspensões</td><td>${u.suspensionCount || 0}</td></tr>
        </tbody>
      </table>
      <div style="margin-top:20px;display:flex;gap:8px;">
        <button class="btn btn-primary btn-sm" onclick="addToFeaturedFromModal('${u.uid}','${esc(u.nome)}','${u.foto || ''}','${esc(u.tipoPerfil)}','${esc(u.cidade || '')}')">
          <span class="material-icons-round">stars</span> Add Destaque
        </button>
        ${u.status === 'active' ? `
          <button class="btn btn-danger btn-sm" onclick="quickSuspend('${u.uid}')">
            <span class="material-icons-round">block</span> Suspender
          </button>
        ` : ''}
      </div>
    `;
    modal.classList.remove("hidden");
  } catch (err) {
    toast("Erro ao carregar detalhes", "error");
  }
};

$("#user-modal-close").addEventListener("click", () => {
  $("#user-detail-modal").classList.add("hidden");
});

window.addToFeaturedFromModal = function (uid, nome, foto, tipo, cidade) {
  if (featuredUids.includes(uid)) {
    toast("Já está em destaque", "error");
    return;
  }
  featuredUids.push(uid);
  featuredProfiles.push({ uid, nome, foto, tipoPerfil: tipo, cidade, likeCount: 0 });
  toast("Adicionado! Vá em Em Destaque para salvar.", "success");
  $("#user-detail-modal").classList.add("hidden");
};

window.quickSuspend = function (uid) {
  $("#user-detail-modal").classList.add("hidden");
  // Switch to suspensions section and open modal
  $$(".nav-item").forEach((n) => n.classList.remove("active"));
  $('[data-section="suspensions"]').classList.add("active");
  $$(".section").forEach((s) => s.classList.add("hidden"));
  $("#section-suspensions").classList.remove("hidden");
  pageTitle.textContent = "Suspensões";

  $("#suspend-uid").value = uid;
  $("#suspension-modal").classList.remove("hidden");
};

// ============================================
// REPORTS
// ============================================
async function loadReports() {
  const filter = $("#reports-filter").value;
  const container = $("#reports-list");
  container.innerHTML = '<p class="empty-state">Carregando...</p>';

  try {
    const result = await functions.httpsCallable("listReports")({ status: filter, limit: 50 });
    const reports = result.data.reports || [];

    if (reports.length === 0) {
      container.innerHTML = '<p class="empty-state">Nenhuma denúncia encontrada.</p>';
      return;
    }

    container.innerHTML = `
      <table class="data-table">
        <thead>
          <tr>
            <th>Tipo</th>
            <th>Usuário Reportado</th>
            <th>Motivo</th>
            <th>Status</th>
            <th>Data</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          ${reports.map((r) => `
            <tr>
              <td>${esc(r.reportedItemType)}</td>
              <td>
                ${r.reportedItemType === 'user' ? `<div style="font-weight:600">${esc(r.reportedName)}</div>` : ''}
                <div style="font-family:monospace;font-size:11px;color:var(--text-muted)">${r.reportedItemId}</div>
              </td>
              <td>${esc(r.reason)}</td>
              <td><span class="badge badge-${r.status}">${r.status}</span></td>
              <td>${formatDate(r.createdAt)}</td>
              <td>
                ${r.status === 'pending' ? `
                  <button class="btn btn-sm btn-primary" onclick="updateReport('${r.id}','processed')">Processar</button>
                  <button class="btn btn-sm btn-secondary" onclick="updateReport('${r.id}','rejected')">Rejeitar</button>
                ` : '—'}
              </td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    `;
  } catch (err) {
    console.error("Reports error:", err);
    container.innerHTML = '<p class="empty-state">Erro ao carregar.</p>';
  }
}

$("#reports-filter").addEventListener("change", loadReports);

window.updateReport = async function (reportId, status) {
  try {
    await functions.httpsCallable("updateReportStatus")({ reportId, status });
    toast(`Report ${status === 'processed' ? 'processado' : 'rejeitado'}!`, "success");
    loadReports();
  } catch (err) {
    toast("Erro ao atualizar report", "error");
  }
};

// ============================================
// SUSPENSIONS
// ============================================
async function loadSuspensions() {
  const filter = $("#suspensions-filter").value;
  const container = $("#suspensions-list");
  container.innerHTML = '<p class="empty-state">Carregando...</p>';

  try {
    const result = await functions.httpsCallable("listSuspensions")({ status: filter, limit: 50 });
    const suspensions = result.data.suspensions || [];

    if (suspensions.length === 0) {
      container.innerHTML = '<p class="empty-state">Nenhuma suspensão encontrada.</p>';
      return;
    }

    container.innerHTML = `
      <table class="data-table">
        <thead>
          <tr>
            <th>Usuário</th>
            <th>Motivo</th>
            <th>Status</th>
            <th>Expira em</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          ${suspensions.map((s) => `
            <tr>
              <td>
                <div style="font-weight:600">${esc(s.userName)}</div>
                <div style="font-family:monospace;font-size:11px;color:var(--text-muted)">${s.userId}</div>
              </td>
              <td>${esc(s.reason)}</td>
              <td><span class="badge badge-${s.status === 'active' ? 'suspended' : 'lifted'}">${s.status}</span></td>
              <td>${formatDate(s.suspendedUntil)}</td>
              <td>
                ${s.status === 'active' ? `<button class="btn btn-sm btn-primary" onclick="liftSuspension('${s.id}')">Levantar</button>` : '—'}
              </td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    `;
  } catch (err) {
    console.error("Suspensions error:", err);
    container.innerHTML = '<p class="empty-state">Erro ao carregar.</p>';
  }
}

$("#suspensions-filter").addEventListener("change", loadSuspensions);

window.liftSuspension = async function (suspensionId) {
  try {
    await functions.httpsCallable("manageSuspension")({ action: "lift", suspensionId });
    toast("Suspensão levantada!", "success");
    loadSuspensions();
  } catch (err) {
    toast("Erro ao levantar suspensão", "error");
  }
};

// Create suspension modal
$("#create-suspension-btn").addEventListener("click", () => {
  $("#suspension-modal").classList.remove("hidden");
});

$("#suspension-modal-close").addEventListener("click", () => {
  $("#suspension-modal").classList.add("hidden");
});

$("#suspend-confirm-btn").addEventListener("click", async () => {
  const userId = $("#suspend-uid").value.trim();
  const reason = $("#suspend-reason").value.trim();
  const durationDays = parseInt($("#suspend-days").value) || 7;

  if (!userId || !reason) {
    toast("Preencha UID e motivo", "error");
    return;
  }

  try {
    await functions.httpsCallable("manageSuspension")({
      action: "create",
      userId,
      reason,
      durationDays,
    });
    toast("Usuário suspenso!", "success");
    $("#suspension-modal").classList.add("hidden");
    loadSuspensions();
  } catch (err) {
    toast("Erro ao suspender", "error");
  }
});

// ============================================
// TICKETS
// ============================================
async function loadTickets() {
  const filter = $("#tickets-filter").value;
  const container = $("#tickets-list");
  container.innerHTML = '<p class="empty-state">Carregando...</p>';

  try {
    const result = await functions.httpsCallable("listTickets")({ status: filter, limit: 50 });
    const tickets = result.data.tickets || [];

    if (tickets.length === 0) {
      container.innerHTML = '<p class="empty-state">Nenhum ticket encontrado.</p>';
      return;
    }

    container.innerHTML = `
      <table class="data-table">
        <thead>
          <tr>
            <th>Assunto</th>
            <th>Categoria</th>
            <th>Status</th>
            <th>Data</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          ${tickets.map((t) => {
      // encode for html
      const encT = encodeURIComponent(JSON.stringify(t));
      return `
            <tr>
              <td>${esc(t.subject || t.message?.substring(0, 40) || '—')}</td>
              <td>${esc(t.category || '—')}</td>
              <td><span class="badge badge-${t.status}">${t.status}</span></td>
              <td>${formatDate(t.createdAt)}</td>
              <td>
                <button class="btn btn-sm btn-secondary" onclick="viewTicket('${t.id}', decodeURIComponent('${encT}'))">Ver</button>
              </td>
            </tr>
          `}).join("")}
        </tbody>
      </table>
    `;
  } catch (err) {
    console.error("Tickets error:", err);
    container.innerHTML = '<p class="empty-state">Erro ao carregar.</p>';
  }
}

$("#tickets-filter").addEventListener("change", loadTickets);

window.viewTicket = function (ticketId, ticketStr) {
  const ticket = JSON.parse(ticketStr);
  const modal = $("#user-detail-modal");
  const body = $("#user-detail-body");

  body.innerHTML = `
    <h3 style="margin-bottom:16px">Ticket #${ticketId.substring(0, 8)}</h3>
    <table class="data-table" style="width:100%">
      <tbody>
        <tr><td style="color:var(--text-muted);width:120px">Usuário</td><td style="font-family:monospace">${ticket.userId}</td></tr>
        <tr><td style="color:var(--text-muted)">Categoria</td><td>${esc(ticket.category || '—')}</td></tr>
        <tr><td style="color:var(--text-muted)">Status</td><td><span class="badge badge-${ticket.status}">${ticket.status}</span></td></tr>
        <tr><td style="color:var(--text-muted)">Mensagem</td><td>${esc(ticket.message || '—')}</td></tr>
        <tr><td style="color:var(--text-muted)">Resposta</td><td>${esc(ticket.adminResponse || 'Sem resposta')}</td></tr>
      </tbody>
    </table>
    <div style="margin-top:20px;display:flex;gap:8px;flex-wrap:wrap;">
      <button class="btn btn-sm btn-primary" onclick="changeTicketStatus('${ticketId}','in_progress')">Em Andamento</button>
      <button class="btn btn-sm btn-primary" onclick="changeTicketStatus('${ticketId}','resolved')">Resolvido</button>
    </div>
  `;
  modal.classList.remove("hidden");
};

window.changeTicketStatus = async function (ticketId, status) {
  try {
    await functions.httpsCallable("updateTicket")({ ticketId, status });
    toast("Ticket atualizado!", "success");
    $("#user-detail-modal").classList.add("hidden");
    loadTickets();
  } catch (err) {
    toast("Erro ao atualizar ticket", "error");
  }
};

// ============================================
// CHATS
// ============================================
let currentChats = [];

async function loadChats() {
  const container = $("#chats-list");
  container.innerHTML = '<p class="empty-state">Carregando...</p>';

  try {
    const result = await functions.httpsCallable("listConversations")({ limit: 50 });
    const chats = result.data.conversations || [];
    currentChats = chats;

    if (chats.length === 0) {
      container.innerHTML = '<p class="empty-state">Nenhuma conversa encontrada.</p>';
      return;
    }

    container.innerHTML = `
      <table class="data-table">
        <thead>
          <tr>
            <th>Participantes</th>
            <th>Tipo</th>
            <th>Última Mensagem</th>
            <th>Atualização</th>
            <th>Ações</th>
          </tr>
        </thead>
        <tbody>
          ${chats.map((c) => {
      const participantsHtml = c.participants.map(p => `
               <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 4px;">
                 ${p.photo ? `<img src="${p.photo}" style="width:24px;height:24px;border-radius:50%;object-fit:cover;">` : `<div style="width:24px;height:24px;border-radius:50%;background:#444;display:flex;align-items:center;justify-content:center;font-size:10px;color:white;">${p.name.charAt(0)}</div>`}
                 <div style="display:flex; flex-direction:column; line-height: 1.2;">
                    <span style="font-weight:600;font-size:13px;">${esc(p.name)}</span>
                    <span style="font-family:monospace;font-size:11px;color:var(--text-muted)">${p.uid}</span>
                 </div>
               </div>
             `).join('');

      const encC = encodeURIComponent(JSON.stringify(c));
      return `
            <tr>
              <td>${participantsHtml}</td>
              <td><span class="badge badge-${c.type === 'matchpoint' ? 'processed' : 'pending'}">${c.type}</span></td>
              <td style="max-width:200px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;" title="${esc(c.lastMessageText || '')}">
                ${esc(c.lastMessageText || '—')}
              </td>
              <td>${formatDate(c.updatedAt)}</td>
              <td>
                <button class="btn btn-sm btn-secondary" onclick="viewConversation('${c.id}', decodeURIComponent('${encC}'))">Ver Chat</button>
              </td>
            </tr>
          `}).join("")}
        </tbody>
      </table>
    `;
  } catch (err) {
    console.error("Erro ao carregar chats:", err);
    container.innerHTML = '<p class="error-text">Erro ao carregar conversas.</p>';
  }
}

window.viewConversation = async function (conversationId, chatStr) {
  const chat = JSON.parse(chatStr);
  const modal = $("#chat-modal");
  const body = $("#chat-messages-body");

  body.innerHTML = `
    <div style="display:flex;flex-direction:column;align-items:center;padding:20px;">
      <span class="btn-loader" style="display:block;border-color:var(--primary);border-top-color:transparent;"></span>
      <span style="margin-top:10px;color:var(--text-muted);">Carregando mensagens...</span>
    </div>
  `;
  modal.classList.remove("hidden");

  try {
    const result = await functions.httpsCallable("getConversationMessages")({ conversationId, limit: 100 });
    const messages = result.data.messages || [];

    if (messages.length === 0) {
      body.innerHTML = '<p class="empty-state" style="margin-top:20px;">Nenhuma mensagem registrada.</p>';
      return;
    }

    const participantsMap = {};
    chat.participants.forEach(p => participantsMap[p.uid] = p);

    body.innerHTML = messages.map(m => {
      const sender = participantsMap[m.senderId] || { name: 'Desconhecido' };
      const isSystem = m.senderId === 'system';
      const isSender1 = Object.keys(participantsMap)[0] === m.senderId;
      const align = isSystem ? 'center' : (isSender1 ? 'flex-start' : 'flex-end');
      const bgColor = isSystem ? 'transparent' : (isSender1 ? 'var(--bg-card)' : 'var(--primary)');
      const color = isSystem ? 'var(--text-muted)' : (isSender1 ? 'var(--text-main)' : 'white');
      const border = isSystem ? 'none' : '1px solid var(--border-color)';

      return `
        <div style="display:flex; flex-direction:column; align-items:${align}; margin-bottom:4px;">
           ${!isSystem ? `<span style="font-size:10px;color:var(--text-muted);margin-bottom:2px;">${esc(sender.name)} • ${formatDate(m.createdAt)}</span>` : ''}
           <div style="background:${bgColor}; color:${color}; border:${border}; padding:8px 12px; border-radius:12px; max-width:85%; word-break:break-word;">
              ${isSystem ? `<i style="font-size:11px;">${esc(m.text)}</i>` : esc(m.text)}
           </div>
        </div>
      `;
    }).join("");

    // Auto scroll bottom
    setTimeout(() => {
      body.scrollTop = body.scrollHeight;
    }, 100);
  } catch (err) {
    console.error("Erro ao carregar mensagens:", err);
    body.innerHTML = '<p class="error-text">Erro ao buscar mensagens.</p>';
  }
};

window.closeModal = function (id) {
  $("#" + id).classList.add("hidden");
};

// ============================================
// UTILS
// ============================================
function toast(msg, type = "success") {
  const el = $("#toast");
  el.textContent = msg;
  el.className = `toast ${type}`;
  el.classList.remove("hidden");
  setTimeout(() => el.classList.add("hidden"), 3000);
}

function esc(str) {
  const div = document.createElement("div");
  div.textContent = str || "";
  return div.innerHTML;
}

function formatNumber(n) {
  if (n === undefined || n === null) return "—";
  return n.toLocaleString("pt-BR");
}

function formatDate(ts) {
  if (!ts) return "—";
  try {
    const date = ts._seconds ? new Date(ts._seconds * 1000) : new Date(ts);
    return date.toLocaleDateString("pt-BR", {
      day: "2-digit",
      month: "2-digit",
      year: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "—";
  }
}
