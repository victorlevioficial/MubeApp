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

// ============================================
// STATE
// ============================================
let currentUser = null;
let featuredUids = [];
let featuredProfiles = [];
let matchpointAuditState = null;
let selectedAdminUser = null;
const usersState = {
  items: [],
  baseTotal: null,
  nextCursor: null,
  hasMore: false,
  loading: false,
  mode: "browse",
};
const DEFAULT_AVATAR_DATA_URL =
  "data:image/svg+xml,<svg xmlns=%22http://www.w3.org/2000/svg%22 " +
  "viewBox=%220 0 40 40%22><rect fill=%22%231a1a26%22 width=%2240%22 " +
  "height=%2240%22/><text x=%2250%%22 y=%2255%%22 text-anchor=%22middle%22 " +
  "fill=%22%238b8ba0%22 font-size=%2216%22>?</text></svg>";

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
const matchpointAuditBody = $("#matchpoint-audit-body");
const matchpointAuditRefreshBtn = $("#matchpoint-audit-refresh-btn");
const userSearchInput = $("#user-search-input");
const userSearchResults = $("#user-search-results");
const userSearchBtn = $("#user-search-btn");
const userClearBtn = $("#user-clear-btn");
const usersRefreshBtn = $("#users-refresh-btn");
const usersStatusFilter = $("#users-status-filter");
const usersProfileFilter = $("#users-profile-filter");
const usersRegistrationFilter = $("#users-registration-filter");
const usersPageSize = $("#users-page-size");
const usersLoadMoreBtn = $("#users-load-more-btn");

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
    case "users": loadUsersSection({ reset: true }); break;
    case "reports": loadReports(); break;
    case "suspensions": loadSuspensions(); break;
    case "tickets": loadTickets(); break;
  }
}

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

  try {
    await loadMatchpointAuditDashboard();
  } catch (err) {
    console.error("Dashboard audit error:", err);
  }
}

async function loadMatchpointAuditDashboard() {
  if (matchpointAuditBody) {
    matchpointAuditBody.innerHTML =
      '<p class="empty-state">Carregando auditoria do MatchPoint...</p>';
  }

  try {
    const result = await functions
      .httpsCallable("getMatchpointRankingAuditDashboard")({ limit: 24 });
    matchpointAuditState = result.data || null;
    renderMatchpointAuditDashboard(matchpointAuditState);
    return result;
  } catch (err) {
    console.error("MatchPoint audit error:", err);
    if (matchpointAuditBody) {
      matchpointAuditBody.innerHTML =
        `<p class="empty-state" style="color:red;font-weight:bold;">` +
        `Erro ao carregar auditoria do MatchPoint: ${esc(err.message || "desconhecido")}` +
        `</p>`;
    }
    throw err;
  }
}

function renderMatchpointAuditDashboard(data) {
  if (!matchpointAuditBody) return;

  const summary = data?.summary || {};
  const buckets = Array.isArray(data?.buckets) ? data.buckets : [];

  if (buckets.length === 0) {
    matchpointAuditBody.innerHTML = `
      <p class="empty-state">
        Ainda nao existem buckets de auditoria do MatchPoint para exibir.
      </p>
    `;
    return;
  }

  const totalEvents = numberOrZero(summary.totalEvents);
  const totalReturned = numberOrZero(summary.returnedTotal);
  const geohashUsedCount = numberOrZero(summary.geohashUsedCount);
  const returnedProximity = numberOrZero(summary.returnedProximity);
  const returnedHashtag = numberOrZero(summary.returnedHashtag);
  const returnedGenre = numberOrZero(summary.returnedGenre);
  const returnedFallback = numberOrZero(summary.returnedFallback);
  const returnedLocalTotal = numberOrZero(summary.returnedLocalTotal);
  const returnedLocalHashtag = numberOrZero(summary.returnedLocalHashtag);
  const returnedLocalGenre = numberOrZero(summary.returnedLocalGenre);

  matchpointAuditBody.innerHTML = `
    <div class="audit-summary-grid">
      <div class="audit-summary-card">
        <span class="audit-summary-label">Eventos (24 buckets)</span>
        <span class="audit-summary-value">${formatNumber(totalEvents)}</span>
        <span class="audit-summary-meta">${formatNumber(totalReturned)} perfis retornados</span>
      </div>
      <div class="audit-summary-card">
        <span class="audit-summary-label">Media por busca</span>
        <span class="audit-summary-value">${formatDecimal(summary.averageReturnedPerEvent)}</span>
        <span class="audit-summary-meta">${formatDecimal(summary.averagePoolPerEvent)} perfis no pool</span>
      </div>
      <div class="audit-summary-card">
        <span class="audit-summary-label">Busca com geohash</span>
        <span class="audit-summary-value">${formatPercent(geohashUsedCount, totalEvents)}</span>
        <span class="audit-summary-meta">${formatNumber(geohashUsedCount)}/${formatNumber(totalEvents)} eventos</span>
      </div>
      <div class="audit-summary-card">
        <span class="audit-summary-label">Mix retornado</span>
        <span class="audit-summary-value">P ${formatPercent(returnedProximity, totalReturned)}</span>
        <span class="audit-summary-meta">H ${formatPercent(returnedHashtag, totalReturned)} | G ${formatPercent(returnedGenre, totalReturned)} | F ${formatPercent(returnedFallback, totalReturned)}</span>
      </div>
      <div class="audit-summary-card">
        <span class="audit-summary-label">Locais com afinidade</span>
        <span class="audit-summary-value">H ${formatNumber(returnedLocalHashtag)} | G ${formatNumber(returnedLocalGenre)}</span>
        <span class="audit-summary-meta">${formatNumber(returnedLocalTotal)} perfis dentro do raio</span>
      </div>
    </div>
    <div class="audit-buckets">
      ${buckets.slice(0, 8).map((bucket) => `
        <div class="audit-bucket">
          <div>
            <div class="audit-bucket-title">${formatAuditBucketStart(bucket.bucketStart)}</div>
            <div class="audit-bucket-meta">
              ${formatNumber(bucket.totalEvents)} buscas | ${formatNumber(bucket.returnedTotal)} perfis retornados | ${formatNumber(bucket.poolTotal)} no pool
            </div>
          </div>
          <div class="audit-bucket-right">
            <div class="audit-bucket-mix">
              P ${formatNumber(bucket.returnedProximity)} | H ${formatNumber(bucket.returnedHashtag)} | G ${formatNumber(bucket.returnedGenre)} | F ${formatNumber(bucket.returnedFallback)}
            </div>
            <div class="audit-bucket-extra">
              Locais ${formatNumber(bucket.returnedLocalTotal)} | H ${formatNumber(bucket.returnedLocalHashtag)} | G ${formatNumber(bucket.returnedLocalGenre)}
            </div>
          </div>
        </div>
      `).join("")}
    </div>
  `;
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
    saveBtn.classList.remove("hidden"); // <-- BOTÃO FICA VISÍVEL MESMO COM LISTA VAZIA
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
      <img class="user-avatar" src="${u.foto || ''}" alt="" onerror="this.src='${DEFAULT_AVATAR_DATA_URL}'">
      <div class="user-info">
        <div class="name">${esc(u.nome)}</div>
        <div class="meta">${esc(u.tipoPerfilLabel || u.tipoPerfil)} · ${esc(u.cidade || '—')} · ❤ ${u.likeCount || 0} · Status: ${esc(u.statusLabel || u.status)}</div>
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
function readUsersFilters() {
  return {
    status: usersStatusFilter?.value || "all",
    profileType: usersProfileFilter?.value || "all",
    registrationStatus: usersRegistrationFilter?.value || "all",
    pageSize: parseInt(usersPageSize?.value || "24", 10) || 24,
  };
}

function matchesUsersUiFilters(user, filters = readUsersFilters()) {
  if (filters.status !== "all" && (user.statusKey || user.status) !== filters.status) {
    return false;
  }

  if (
    filters.profileType !== "all" &&
    (user.tipoPerfil || "").toLowerCase() !== filters.profileType
  ) {
    return false;
  }

  if (
    filters.registrationStatus !== "all" &&
    user.cadastroStatus !== filters.registrationStatus
  ) {
    return false;
  }

  return true;
}

function getDisplayedUsers() {
  const filters = readUsersFilters();
  return usersState.items.filter((user) => matchesUsersUiFilters(user, filters));
}

function updateUsersSummary(displayedUsers) {
  $("#users-total-base").textContent = formatNumber(usersState.baseTotal);
  $("#users-loaded-count").textContent = formatNumber(displayedUsers.length);
  $("#users-pending-count").textContent = formatNumber(
    displayedUsers.filter((user) => user.cadastroStatus !== "concluido").length
  );
  $("#users-suspended-count").textContent = formatNumber(
    displayedUsers.filter((user) => (user.statusKey || user.status) === "suspended").length
  );
}

function updateUsersLoadMoreButton() {
  if (!usersLoadMoreBtn) return;

  const canLoadMore = usersState.mode === "browse" && usersState.hasMore;
  usersLoadMoreBtn.classList.toggle("hidden", !canLoadMore);
  usersLoadMoreBtn.disabled = usersState.loading;

  const label = usersLoadMoreBtn.querySelector("span:last-child");
  if (label) {
    label.textContent = usersState.loading ? "Carregando..." : "Carregar mais";
  }
}

function renderUsersEmptyState(message) {
  updateUsersSummary([]);
  userSearchResults.innerHTML = `<p class="empty-state">${esc(message)}</p>`;
  updateUsersLoadMoreButton();
}

function renderUserCard(user) {
  const statusKey = user.statusKey || user.status || "active";
  const statusLabel = user.statusLabel || user.status || "Ativo";
  const cadastroKey = user.cadastroStatusKey || "type-pending";
  const cadastroLabel = user.cadastroStatusLabel || user.cadastroStatus || "—";
  const categoryLabel = user.tipoPerfilLabel || user.tipoPerfil || "Sem categoria";
  const location = [user.bairro, user.cidade].filter(Boolean).join(" · ") ||
    user.estado ||
    "Localização pendente";

  return `
    <div class="user-preview user-preview-extended" onclick="showUserDetail('${user.uid}')">
      <img class="user-avatar" src="${user.foto || ''}" alt="" onerror="this.src='${DEFAULT_AVATAR_DATA_URL}'">
      <div class="user-info">
        <div class="user-card-header">
          <div class="name">${esc(user.nome || "Sem nome")}</div>
          <div class="user-badges">
            <span class="badge badge-neutral">${esc(categoryLabel)}</span>
            <span class="badge badge-${statusKey}">${esc(statusLabel)}</span>
            <span class="badge badge-${cadastroKey}">${esc(cadastroLabel)}</span>
          </div>
        </div>
        <div class="meta">${esc(location)}</div>
        <div class="user-kv-grid">
          <span><strong>UID:</strong> <span class="mono-text">${esc(user.uid || "—")}</span></span>
          <span><strong>Email:</strong> ${esc(user.email || "—")}</span>
          <span><strong>Criado:</strong> ${formatDate(user.createdAt)}</span>
          <span><strong>Último login:</strong> ${formatDate(user.lastSignInAt)}</span>
        </div>
        <div class="user-inline-stats">
          <span>❤ ${formatNumber(user.likeCount || 0)}</span>
          <span>Reports ${formatNumber(user.reportCount || 0)}</span>
          <span>Suspensões ${formatNumber(user.suspensionCount || 0)}</span>
        </div>
      </div>
    </div>
  `;
}

function renderUsersList() {
  const displayedUsers = getDisplayedUsers();
  updateUsersSummary(displayedUsers);

  if (displayedUsers.length === 0) {
    const hasQuery = userSearchInput.value.trim().length > 0;
    const message = usersState.items.length > 0 ?
      "Nenhum usuário corresponde aos filtros atuais." :
      hasQuery ? "Nenhum usuário encontrado." : "Nenhum usuário carregado.";
    renderUsersEmptyState(message);
    return;
  }

  userSearchResults.innerHTML = displayedUsers.map((user) => renderUserCard(user)).join("");
  updateUsersLoadMoreButton();
}

async function loadUsersSection({ reset = false } = {}) {
  if (usersState.loading) return;

  const query = userSearchInput.value.trim();
  if (query) {
    await searchAdminUsers();
    return;
  }

  if (reset) {
    usersState.items = [];
    usersState.nextCursor = null;
    usersState.hasMore = false;
  }

  const filters = readUsersFilters();
  usersState.loading = true;
  usersState.mode = "browse";
  updateUsersLoadMoreButton();

  if (reset) {
    userSearchResults.innerHTML = '<p class="empty-state">Carregando usuários...</p>';
  }

  try {
    const result = await functions.httpsCallable("listUsersAdmin")({
      pageSize: filters.pageSize,
      cursor: reset ? null : usersState.nextCursor,
      status: filters.status,
      profileType: filters.profileType,
      registrationStatus: filters.registrationStatus,
      includeTotal: reset || usersState.baseTotal === null,
    });

    const data = result.data || {};
    const incomingUsers = Array.isArray(data.users) ? data.users : [];
    usersState.items = reset ?
      incomingUsers :
      [...usersState.items, ...incomingUsers];
    usersState.nextCursor = data.nextCursor || null;
    usersState.hasMore = data.hasMore === true;

    if (data.totalUsersBase !== undefined && data.totalUsersBase !== null) {
      usersState.baseTotal = data.totalUsersBase;
    }

    renderUsersList();
  } catch (err) {
    console.error("Users list error:", err);
    renderUsersEmptyState("Erro ao carregar usuários.");
  } finally {
    usersState.loading = false;
    updateUsersLoadMoreButton();
  }
}

async function searchAdminUsers() {
  const query = userSearchInput.value.trim();
  if (!query) {
    await loadUsersSection({ reset: true });
    return;
  }

  usersState.loading = true;
  usersState.mode = "search";
  usersState.hasMore = false;
  updateUsersLoadMoreButton();
  userSearchResults.innerHTML = '<p class="empty-state">Buscando usuários...</p>';

  try {
    const result = await functions.httpsCallable("searchUsers")({
      query,
      limit: readUsersFilters().pageSize,
    });
    usersState.items = Array.isArray(result.data?.results) ? result.data.results : [];
    renderUsersList();
  } catch (err) {
    console.error("Search error:", err);
    renderUsersEmptyState("Erro na busca.");
  } finally {
    usersState.loading = false;
    updateUsersLoadMoreButton();
  }
}

function closeUserModal() {
  $("#user-detail-modal").classList.add("hidden");
}

userSearchBtn.addEventListener("click", async () => {
  if (userSearchInput.value.trim()) {
    await searchAdminUsers();
    return;
  }

  await loadUsersSection({ reset: true });
});

userSearchInput.addEventListener("keydown", async (e) => {
  if (e.key === "Enter") {
    if (userSearchInput.value.trim()) {
      await searchAdminUsers();
    } else {
      await loadUsersSection({ reset: true });
    }
  }
});

userClearBtn.addEventListener("click", async () => {
  userSearchInput.value = "";
  await loadUsersSection({ reset: true });
});

usersRefreshBtn.addEventListener("click", async () => {
  if (userSearchInput.value.trim()) {
    await searchAdminUsers();
    return;
  }

  await loadUsersSection({ reset: true });
});

[usersStatusFilter, usersProfileFilter, usersRegistrationFilter].forEach((el) => {
  el.addEventListener("change", async () => {
    if (userSearchInput.value.trim()) {
      renderUsersList();
      return;
    }

    await loadUsersSection({ reset: true });
  });
});

usersPageSize.addEventListener("change", async () => {
  if (userSearchInput.value.trim()) {
    await searchAdminUsers();
    return;
  }

  await loadUsersSection({ reset: true });
});

usersLoadMoreBtn.addEventListener("click", async () => {
  await loadUsersSection({ reset: false });
});

window.showUserDetail = async function (uid) {
  try {
    const result = await functions.httpsCallable("lookupUser")({ uid });
    const u = result.data;
    selectedAdminUser = u;
    const modal = $("#user-detail-modal");
    const body = $("#user-detail-body");

    body.innerHTML = `
      <div class="modal-user-header">
        <img class="user-avatar modal-user-avatar" src="${u.foto || ''}" alt="" onerror="this.src='${DEFAULT_AVATAR_DATA_URL}'">
        <div class="modal-user-meta">
          <h3>${esc(u.nome || "Sem nome")}</h3>
          <div class="user-badges">
            <span class="badge badge-neutral">${esc(u.tipoPerfilLabel || u.tipoPerfil || "Sem categoria")}</span>
            <span class="badge badge-${u.statusKey || u.status || "active"}">${esc(u.statusLabel || u.status || "Ativo")}</span>
            <span class="badge badge-${u.cadastroStatusKey || "type-pending"}">${esc(u.cadastroStatusLabel || u.cadastroStatus || "—")}</span>
          </div>
        </div>
      </div>
      <table class="data-table" style="width:100%">
        <tbody>
          <tr><td style="color:var(--text-muted);width:160px">UID</td><td><span class="mono-text">${esc(u.uid || "—")}</span></td></tr>
          <tr><td style="color:var(--text-muted)">Nome de cadastro</td><td>${esc(u.nomeCadastro || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Email</td><td>${esc(u.email || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Categoria</td><td>${esc(u.tipoPerfilLabel || u.tipoPerfil || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Bairro</td><td>${esc(u.bairro || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Cidade</td><td>${esc(u.cidade || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Estado</td><td>${esc(u.estado || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Criado em</td><td>${formatDate(u.createdAt)}</td></tr>
          <tr><td style="color:var(--text-muted)">Último login</td><td>${formatDate(u.lastSignInAt)}</td></tr>
          <tr><td style="color:var(--text-muted)">Email verificado</td><td>${u.emailVerified ? "Sim" : "Não"}</td></tr>
          <tr><td style="color:var(--text-muted)">Auth desabilitado</td><td>${u.authDisabled ? "Sim" : "Não"}</td></tr>
          <tr><td style="color:var(--text-muted)">Providers</td><td>${esc((u.providerIds || []).join(", ") || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Bio</td><td>${esc(u.bio || "—")}</td></tr>
          <tr><td style="color:var(--text-muted)">Likes</td><td>❤ ${formatNumber(u.likeCount || 0)}</td></tr>
          <tr><td style="color:var(--text-muted)">Reports</td><td>${formatNumber(u.reportCount || 0)}</td></tr>
          <tr><td style="color:var(--text-muted)">Suspensões</td><td>${formatNumber(u.suspensionCount || 0)}</td></tr>
          <tr><td style="color:var(--text-muted)">Endereços</td><td>${formatNumber(u.addressesCount || 0)}</td></tr>
          <tr><td style="color:var(--text-muted)">Bloqueados</td><td>${formatNumber(u.blockedUsersCount || 0)}</td></tr>
          <tr><td style="color:var(--text-muted)">MatchPoint</td><td>${u.matchpointActive ? "Ativo" : "Inativo"}</td></tr>
          <tr><td style="color:var(--text-muted)">Visível no home</td><td>${u.visibleInHome ? "Sim" : "Não"}</td></tr>
          <tr><td style="color:var(--text-muted)">Ghost mode</td><td>${u.ghostMode ? "Sim" : "Não"}</td></tr>
        </tbody>
      </table>
      <div class="modal-actions">
        <button id="user-detail-featured-btn" class="btn btn-primary btn-sm">
          <span class="material-icons-round">stars</span> Add Destaque
        </button>
        ${(u.statusKey || u.status) !== "suspended" ? `
          <button id="user-detail-suspend-btn" class="btn btn-danger btn-sm">
            <span class="material-icons-round">block</span> Suspender
          </button>
        ` : ""}
      </div>
    `;

    $("#user-detail-featured-btn")?.addEventListener("click", () => {
      window.addCurrentUserToFeatured();
    });
    $("#user-detail-suspend-btn")?.addEventListener("click", () => {
      window.quickSuspendCurrentUser();
    });

    modal.classList.remove("hidden");
  } catch (err) {
    toast("Erro ao carregar detalhes", "error");
  }
};

$("#user-modal-close").addEventListener("click", closeUserModal);

window.addCurrentUserToFeatured = function () {
  if (!selectedAdminUser) return;

  if (featuredUids.includes(selectedAdminUser.uid)) {
    toast("Já está em destaque", "error");
    return;
  }

  featuredUids.push(selectedAdminUser.uid);
  featuredProfiles.push({
    uid: selectedAdminUser.uid,
    nome: selectedAdminUser.nome,
    foto: selectedAdminUser.foto,
    tipoPerfil: selectedAdminUser.tipoPerfilLabel || selectedAdminUser.tipoPerfil,
    cidade: selectedAdminUser.cidade || "",
    likeCount: selectedAdminUser.likeCount || 0,
  });
  toast("Adicionado! Vá em Em Destaque para salvar.", "success");
  closeUserModal();
};

window.quickSuspend = function (uid) {
  closeUserModal();
  // Switch to suspensions section and open modal
  $$(".nav-item").forEach((n) => n.classList.remove("active"));
  $('[data-section="suspensions"]').classList.add("active");
  $$(".section").forEach((s) => s.classList.add("hidden"));
  $("#section-suspensions").classList.remove("hidden");
  pageTitle.textContent = "Suspensões";

  $("#suspend-uid").value = uid;
  $("#suspension-modal").classList.remove("hidden");
};

window.quickSuspendCurrentUser = function () {
  if (!selectedAdminUser?.uid) return;
  window.quickSuspend(selectedAdminUser.uid);
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
            <th>ID Reportado</th>
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
              <td style="font-family:monospace;font-size:12px">${r.reportedItemId.substring(0, 16)}...</td>
              <td>${esc(r.reason)}</td>
              <td><span class="badge badge-${r.status}">${r.status}</span></td>
              <td>${formatDate(r.createdAt)}</td>
              <td>
                ${r.status !== 'processed' ? `<button class="btn btn-sm btn-primary" onclick="updateReport('${r.id}','processed')">Processar</button>` : ''}
                ${r.status !== 'rejected' ? `<button class="btn btn-sm btn-secondary" onclick="updateReport('${r.id}','rejected')">Rejeitar</button>` : ''}
              </td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    `;
  } catch (err) {
    console.error("Reports error:", err);
    container.innerHTML = `<p class="empty-state" style="color:red;font-weight:bold;">Erro ao carregar denúncias: ${err.message}</p>`;
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
              <td style="font-family:monospace;font-size:12px">${s.userId.substring(0, 16)}...</td>
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
    container.innerHTML = `<p class="empty-state" style="color:red;font-weight:bold;">Erro ao carregar suspensões: ${err.message}</p>`;
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
          ${tickets.map((t) => `
            <tr>
              <td>${esc(t.subject || t.message?.substring(0, 40) || '—')}</td>
              <td>${esc(t.category || '—')}</td>
              <td><span class="badge badge-${t.status}">${t.status}</span></td>
              <td>${formatDate(t.createdAt)}</td>
              <td>
                <button class="btn btn-sm btn-secondary" onclick="viewTicket('${t.id}', ${JSON.stringify(t).replace(/'/g, "\\'")})"">Ver</button>
              </td>
            </tr>
          `).join("")}
        </tbody>
      </table>
    `;
  } catch (err) {
    console.error("Tickets error:", err);
    container.innerHTML = `<p class="empty-state" style="color:red;font-weight:bold;">Erro ao carregar tickets: ${err.message}</p>`;
  }
}

$("#tickets-filter").addEventListener("change", loadTickets);

if (matchpointAuditRefreshBtn) {
  matchpointAuditRefreshBtn.addEventListener("click", async () => {
    try {
      await loadMatchpointAuditDashboard();
      toast("Auditoria MatchPoint atualizada!", "success");
    } catch (_) {
      toast("Erro ao atualizar auditoria MatchPoint", "error");
    }
  });
}

window.viewTicket = function (ticketId, ticket) {
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

function formatDecimal(n) {
  const value = Number(n);
  if (!Number.isFinite(value)) return "0,0";
  return value.toLocaleString("pt-BR", {
    minimumFractionDigits: 1,
    maximumFractionDigits: 1,
  });
}

function numberOrZero(value) {
  const num = Number(value);
  return Number.isFinite(num) ? num : 0;
}

function formatPercent(value, total) {
  const safeValue = numberOrZero(value);
  const safeTotal = numberOrZero(total);
  if (safeTotal <= 0) return "0%";
  const percent = (safeValue / safeTotal) * 100;
  return `${percent.toLocaleString("pt-BR", {
    minimumFractionDigits: percent >= 10 ? 0 : 1,
    maximumFractionDigits: percent >= 10 ? 0 : 1,
  })}%`;
}

function formatAuditBucketStart(bucketStart) {
  if (!bucketStart) return "Bucket sem horario";
  const date = new Date(bucketStart);
  if (Number.isNaN(date.getTime())) return "Bucket sem horario";
  return date.toLocaleString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
  }).replace(",", "");
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
