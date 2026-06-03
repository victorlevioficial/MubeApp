// Users section: search/filter the base, paginated list, and a tabbed dossier
// drawer (Conta / Perfil / Moderação / Atividade / JSON) with suspend/lift
// actions (parity with the legacy panel — backend already exposes them).
import { h, mount, frag } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, asObject, stringValue, toInteger, formatNumber, formatDateTime, prettyJson, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, avatar, badge, pill, statTile } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";
import { openDrawer } from "../ui/Drawer.js";
import { showToast, handleError } from "../ui/toast.js";

const PAGE_SIZE = 24;

const STATUS_OPTIONS = [
  ["all", "Todos os status"],
  ["active", "Ativos"],
  ["suspended", "Suspensos"],
  ["draft", "Rascunho"],
  ["inactive", "Inativos"],
];
const PROFILE_OPTIONS = [
  ["all", "Todos os tipos"],
  ["profissional", "Profissional"],
  ["contratante", "Contratante"],
  ["banda", "Banda"],
  ["estudio", "Estúdio"],
];
const REGISTRATION_OPTIONS = [
  ["all", "Qualquer cadastro"],
  ["concluido", "Concluído"],
  ["perfil_pendente", "Perfil pendente"],
  ["tipo_pendente", "Tipo pendente"],
];

const state = {
  items: [],
  mode: "list",
  totalBase: 0,
  hasMore: false,
  nextCursor: null,
  loaded: false,
  filters: { search: "", status: "all", profileType: "all", registrationStatus: "all" },
};

let resultsHost = null;

export async function mountUsers(container, ctx = {}) {
  resultsHost = h("div", { class: "section-body" });
  mount(container, lead(), toolbar(), resultsHost);

  if (!state.loaded || ctx.force) {
    await runSearch({ reset: true });
  } else {
    renderResults();
  }
}

function lead() {
  return sectionLead("Base e perfis", "Usuários", "Busca, filtros, atividade e moderação de cada conta.");
}

function toolbar() {
  const searchInput = h("input", {
    type: "search",
    placeholder: "Nome, email, UID, cidade ou username",
    value: state.filters.search,
    onKeydown: (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        state.filters.search = searchInput.value.trim();
        runSearch({ reset: true });
      }
    },
  });

  const statusSel = selectField(STATUS_OPTIONS, state.filters.status, (value) => {
    state.filters.status = value;
    runSearch({ reset: true });
  });
  const profileSel = selectField(PROFILE_OPTIONS, state.filters.profileType, (value) => {
    state.filters.profileType = value;
    runSearch({ reset: true });
  });
  const registrationSel = selectField(REGISTRATION_OPTIONS, state.filters.registrationStatus, (value) => {
    state.filters.registrationStatus = value;
    runSearch({ reset: true });
  });

  return panel(
    {},
    h(
      "div",
      { class: "toolbar" },
      h("label", { class: "field field-grow" }, h("span", {}, "Busca"), searchInput),
      h("label", { class: "field" }, h("span", {}, "Status"), statusSel),
      h("label", { class: "field" }, h("span", {}, "Tipo"), profileSel),
      h("label", { class: "field" }, h("span", {}, "Cadastro"), registrationSel),
    ),
    h(
      "div",
      { class: "toolbar-actions" },
      button("Buscar", {
        variant: "primary",
        icon: "search",
        onClick: () => {
          state.filters.search = searchInput.value.trim();
          runSearch({ reset: true });
        },
      }),
      button("Limpar", {
        variant: "ghost",
        icon: "close",
        onClick: () => {
          state.filters = { search: "", status: "all", profileType: "all", registrationStatus: "all" };
          runSearch({ reset: true });
        },
      }),
    ),
  );
}

function selectField(options, current, onChange) {
  return h(
    "select",
    { onChange: (event) => onChange(event.currentTarget.value) },
    ...options.map(([value, label]) => h("option", { value, selected: value === current }, label)),
  );
}

async function runSearch({ reset = false, append = false } = {}) {
  if (!resultsHost) return;
  if (reset) state.nextCursor = null;
  if (!append) mount(resultsHost, statePanel("loading", "Carregando usuários…"));

  try {
    const { search, status, profileType, registrationStatus } = state.filters;
    if (search) {
      const response = await callFunction("searchUsers", { query: search, limit: PAGE_SIZE });
      state.items = asArray(response.results || response.users);
      state.mode = "search";
      state.hasMore = false;
      state.totalBase = toInteger(response.total, state.items.length);
    } else {
      const response = await callFunction("listUsersAdmin", {
        pageSize: PAGE_SIZE,
        cursor: append ? state.nextCursor : null,
        status,
        profileType,
        registrationStatus,
        includeTotal: !append,
      });
      const incoming = asArray(response.users);
      state.mode = "list";
      state.items = append ? state.items.concat(incoming) : incoming;
      state.hasMore = response.hasMore === true;
      state.nextCursor = response.nextCursor || null;
      if (!append) state.totalBase = toInteger(response.totalUsersBase, incoming.length);
    }
    state.loaded = true;
    renderResults();
  } catch (error) {
    mount(resultsHost, statePanel("error", getErrorMessage(error), { onRetry: () => runSearch({ reset: true }) }));
  }
}

function renderResults() {
  const users = state.items;
  const suspended = users.filter((u) => stringValue(u.statusKey, stringValue(u.status)) === "suspended").length;
  const matchpoint = users.filter((u) => u.matchpointActive === true).length;

  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "groups", label: "Carregados", value: formatNumber(users.length) }),
    statTile({ iconName: "database", label: "Base total", value: formatNumber(state.totalBase) }),
    statTile({ iconName: "gpp_bad", label: "Suspensos (página)", value: formatNumber(suspended), tone: suspended > 0 ? "warning" : null }),
    statTile({ iconName: "bolt", label: "MatchPoint ativo", value: formatNumber(matchpoint) }),
  );

  const list = dataList({
    columns: [
      { label: "Usuário", render: userCell, width: "minmax(0, 2.2fr)" },
      { label: "Tipo", render: (u) => pill(stringValue(u.tipoPerfilLabel, stringValue(u.tipoPerfil, "—")), "info") },
      { label: "Status", render: (u) => badge(stringValue(u.statusLabel, "Ativo"), stringValue(u.statusKey, stringValue(u.status, "active"))) },
      { label: "Local", render: (u) => stringValue(u.displayLocation, "—") },
    ],
    rows: users,
    onRowClick: (u) => openUserDrawer(stringValue(u.uid)),
    emptyMessage: "Nenhum usuário encontrado com os filtros atuais.",
  });

  const footer =
    state.hasMore && state.mode === "list"
      ? h("div", { class: "load-more" }, button("Carregar mais", { variant: "secondary", icon: "expand_more", onClick: () => runSearch({ append: true }) }))
      : null;

  mount(resultsHost, summary, panel({ kicker: state.mode === "search" ? "Resultado da busca" : "Base de usuários", title: "Contas" }, list), footer);
}

function userCell(user) {
  const uid = stringValue(user.uid);
  return h(
    "div",
    { class: "media-cell" },
    avatar(user.foto, stringValue(user.nome, uid)),
    h(
      "div",
      { class: "cell-stack" },
      h("strong", {}, stringValue(user.nome, uid)),
      h("span", { class: "meta" }, stringValue(user.email, "—")),
    ),
  );
}

// ---------- Detail dossier (drawer with tabs) ----------

export async function openUserDrawer(uid) {
  if (!uid) return;
  openDrawer({ kicker: "Usuário", title: uid, subtitle: "Carregando dossiê…", content: statePanel("loading", "Buscando perfil, auth, moderação e relações…") });

  let detail;
  try {
    detail = await callFunction("getUserAdminDetail", { uid });
  } catch (error) {
    openDrawer({ kicker: "Usuário", title: uid, content: statePanel("error", getErrorMessage(error), { onRetry: () => openUserDrawer(uid) }) });
    return;
  }

  const profile = asObject(detail.profile);
  const subtitle = [stringValue(profile.email), stringValue(profile.tipoPerfilLabel), stringValue(profile.displayLocation)].filter(Boolean).join(" · ");

  openDrawer({
    kicker: "Usuário",
    title: stringValue(profile.nome, uid),
    subtitle,
    tabs: [
      { label: "Conta", content: () => accountTab(detail) },
      { label: "Perfil", content: () => profileTab(detail) },
      { label: "Moderação", content: () => moderationTab(detail) },
      { label: "Atividade", content: () => activityTab(detail) },
      { label: "JSON", content: () => h("pre", { class: "code-block" }, prettyJson(detail)) },
    ],
  });
}

function kv(pairs) {
  return h(
    "dl",
    { class: "kv-grid" },
    ...pairs.filter(Boolean).map(([label, value]) => frag(h("dt", {}, label), h("dd", {}, value == null || value === "" ? "—" : value))),
  );
}

function accountTab(detail) {
  const profile = asObject(detail.profile);
  const auth = asObject(detail.auth);
  return kv([
    ["UID", stringValue(profile.uid)],
    ["Email", stringValue(profile.email)],
    ["Perfil", stringValue(profile.tipoPerfilLabel, stringValue(profile.tipoPerfil))],
    ["Status", badge(stringValue(profile.statusLabel, "Ativo"), stringValue(profile.statusKey, "active"))],
    ["Cadastro", stringValue(profile.cadastroStatusLabel, stringValue(profile.cadastroStatusKey))],
    ["Localização", stringValue(profile.displayLocation, "Não informada")],
    ["Criado em", formatDateTime(profile.createdAt)],
    ["Último login", formatDateTime(profile.lastSignInAt)],
    ["Email verificado", profile.emailVerified === true ? "Sim" : "Não"],
    ["Auth desabilitado", profile.authDisabled === true ? "Sim" : "Não"],
    ["Providers", asArray(profile.providerIds).join(", ") || "Nenhum"],
    ["Claims", Object.keys(asObject(auth.customClaims)).join(", ") || "Nenhuma"],
    ["Suspenso até", profile.suspendedUntil ? formatDateTime(profile.suspendedUntil) : "—"],
  ]);
}

function profileTab(detail) {
  const profile = asObject(detail.profile);
  const interactions = asObject(detail.interactions);
  const bio = stringValue(profile.bio, "Sem bio cadastrada.");
  return frag(
    h("p", { class: "rich-text" }, bio),
    kv([
      ["Likes", formatNumber(profile.likeCount)],
      ["Reports", formatNumber(profile.reportCount)],
      ["Favoritos", formatNumber(asArray(detail.favoritesSent).length)],
      ["Bloqueados", formatNumber(profile.blockedUsersCount)],
      ["Gigs criadas", formatNumber(asArray(detail.gigsCreated).length)],
      ["Candidaturas", formatNumber(asArray(detail.gigApplications).length)],
      ["Matches", formatNumber(asArray(detail.matches).length)],
      ["Interações enviadas", formatNumber(asArray(interactions.sent).length)],
      ["Interações recebidas", formatNumber(asArray(interactions.received).length)],
      ["Visível no feed", profile.visibleInHome === true ? "Sim" : "Não"],
      ["Visível na busca", profile.visibleInSearch === true ? "Sim" : "Não"],
      ["Storage", asArray(detail.derivedStoragePrefixes).join(", ") || "—"],
    ]),
  );
}

function moderationTab(detail) {
  const profile = asObject(detail.profile);
  const moderation = asObject(detail.moderation);
  const uid = stringValue(profile.uid);
  const activeSuspensions = asArray(detail.suspensions).filter((s) => stringValue(asObject(s.data).status, "active") === "active");

  return frag(
    kv([
      ["Report count", formatNumber(moderation.report_count || profile.reportCount)],
      ["Suspension count", formatNumber(moderation.suspension_count || profile.suspensionCount)],
      ["Status atual", badge(stringValue(profile.statusLabel, "Ativo"), stringValue(profile.statusKey, "active"))],
    ]),
    activeSuspensions.length
      ? h(
          "div",
          { class: "mod-block" },
          h("h4", {}, "Suspensões ativas"),
          ...activeSuspensions.map((s) =>
            h(
              "div",
              { class: "mod-row" },
              h("span", { class: "meta" }, `${stringValue(s.id)} · até ${formatDateTime(asObject(s.data).suspended_until || asObject(s.data).suspendedUntil)}`),
              button("Levantar", { variant: "secondary", icon: "lock_open", onClick: () => liftSuspension(stringValue(s.id), uid) }),
            ),
          ),
        )
      : null,
    suspensionForm(uid),
  );
}

function suspensionForm(uid) {
  const reason = h("textarea", { rows: "3", placeholder: "Motivo da suspensão" });
  const days = h("input", { type: "number", min: "1", max: "365", value: "7" });
  return h(
    "div",
    { class: "mod-block" },
    h("h4", {}, "Suspender usuário"),
    h("label", { class: "field" }, h("span", {}, "Motivo"), reason),
    h("label", { class: "field" }, h("span", {}, "Duração (dias)"), days),
    button("Suspender", {
      variant: "danger",
      icon: "gpp_bad",
      onClick: () => {
        const reasonText = reason.value.trim();
        if (!reasonText) {
          showToast("Informe o motivo da suspensão.", "error");
          return;
        }
        const duration = toInteger(days.value, 7);
        if (!window.confirm(`Suspender este usuário por ${duration} dia(s)?`)) return;
        suspendUser(uid, reasonText, duration);
      },
    }),
  );
}

async function suspendUser(uid, reason, durationDays) {
  try {
    await callFunction("manageSuspension", { action: "create", userId: uid, reason, durationDays });
    showToast("Usuário suspenso.", "success");
    state.loaded = false; // force list refresh on next view
    openUserDrawer(uid);
  } catch (error) {
    handleError(error);
  }
}

async function liftSuspension(suspensionId, uid) {
  if (!window.confirm("Levantar esta suspensão e reativar o usuário?")) return;
  try {
    await callFunction("manageSuspension", { action: "lift", suspensionId });
    showToast("Suspensão levantada.", "success");
    state.loaded = false;
    openUserDrawer(uid);
  } catch (error) {
    handleError(error);
  }
}

function activityTab(detail) {
  return frag(
    miniList("Gigs criadas", asArray(detail.gigsCreated), (item) => stringValue(asObject(item.data).title, stringValue(item.id))),
    miniList("Candidaturas", asArray(detail.gigApplications), (item) => stringValue(item.id)),
    miniList("Tickets", asArray(detail.tickets), (item) => `${stringValue(item.subject, stringValue(item.title, stringValue(item.id)))} · ${stringValue(item.status, "open")}`),
    miniList("Previews de conversa", asArray(detail.conversationPreviews), (item) => stringValue(item.id)),
    miniList("Notificações", asArray(detail.notifications), (item) => stringValue(item.id)),
    miniList("Favoritos enviados", asArray(detail.favoritesSent), (item) => stringValue(item.id)),
    miniList("Bloqueados", asArray(detail.blockedUsers), (item) => stringValue(item.id)),
  );
}

function miniList(title, items, lineFn) {
  return h(
    "div",
    { class: "mini-list" },
    h("h4", {}, `${title} (${items.length})`),
    items.length
      ? h("ul", {}, ...items.slice(0, 8).map((item) => h("li", {}, lineFn(item))))
      : h("p", { class: "meta" }, "Nada registrado."),
  );
}
