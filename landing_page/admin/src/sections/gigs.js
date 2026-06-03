// Gigs: searchable/filterable marketplace list + per-gig dossier drawer
// (resumo + descrição, candidaturas, reviews, JSON). Parity with the legacy
// panel's getGigAdminDetail consolidation.
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, asObject, stringValue, toInteger, formatNumber, formatDateTime, formatRelative, prettyJson, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, badge, pill, statTile, kvGrid } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";
import { openDrawer } from "../ui/Drawer.js";
import { openUserDrawer } from "./users.js";

const STATUS_OPTIONS = [
  ["all", "Todos os status"],
  ["open", "Abertas"],
  ["closed", "Fechadas"],
  ["expired", "Expiradas"],
  ["cancelled", "Canceladas"],
];
const LIMIT_OPTIONS = [
  ["20", "20 gigs"],
  ["40", "40 gigs"],
  ["80", "80 gigs"],
];

const state = { items: [], total: 0, loaded: false, search: "", status: "all", limit: 20 };
let host = null;

export async function mountGigs(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), toolbar(), host);
  if (!state.loaded || ctx.force) await load();
  else renderResults();
}

function lead() {
  return sectionLead("Marketplace", "Gigs", "Oportunidades, candidaturas e avaliações por gig.");
}

function selectField(options, current, onChange) {
  return h(
    "select",
    { onChange: (event) => onChange(event.currentTarget.value) },
    ...options.map(([value, label]) => h("option", { value, selected: value === current }, label)),
  );
}

function toolbar() {
  const searchInput = h("input", {
    type: "search",
    placeholder: "Título, descrição ou criador",
    value: state.search,
    onKeydown: (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        state.search = searchInput.value.trim();
        load();
      }
    },
  });
  return panel(
    {},
    h(
      "div",
      { class: "filter-bar" },
      h("label", { class: "field field-grow" }, h("span", {}, "Busca"), searchInput),
      h("label", { class: "field" }, h("span", {}, "Status"), selectField(STATUS_OPTIONS, state.status, (v) => { state.status = v; load(); })),
      h("label", { class: "field" }, h("span", {}, "Limite"), selectField(LIMIT_OPTIONS.map(([v, l]) => [v, l]), String(state.limit), (v) => { state.limit = toInteger(v, 20); load(); })),
      button("Buscar", { variant: "primary", icon: "search", onClick: () => { state.search = searchInput.value.trim(); load(); } }),
    ),
  );
}

async function load() {
  if (!host) return;
  mount(host, statePanel("loading", "Carregando gigs…"));
  try {
    const response = await callFunction("listGigsAdmin", {
      search: state.search,
      status: state.status,
      limit: Math.min(state.limit, 80),
    });
    state.items = asArray(response.gigs);
    state.total = toInteger(response.total, state.items.length);
    state.loaded = true;
    renderResults();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: load }));
  }
}

function renderResults() {
  const open = state.items.filter((g) => stringValue(g.status, "open") === "open").length;
  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "event_note", label: "Gigs carregadas", value: formatNumber(state.items.length) }),
    statTile({ iconName: "event_available", label: "Abertas (página)", value: formatNumber(open) }),
    statTile({ iconName: "database", label: "Total reportado", value: formatNumber(state.total) }),
  );

  const list = dataList({
    columns: [
      { label: "Gig", render: gigCell, width: "minmax(0, 2.4fr)" },
      { label: "Status", render: (g) => badge(stringValue(g.status, "open"), stringValue(g.status, "open")) },
      { label: "Candidaturas", render: (g) => formatNumber(g.applicantCount) },
      { label: "Criada", render: (g) => formatRelative(g.createdAt) },
    ],
    rows: state.items,
    onRowClick: (g) => openGigDrawer(stringValue(g.id)),
    emptyMessage: "Nenhuma gig encontrada com os filtros atuais.",
  });

  mount(host, summary, panel({ kicker: "Marketplace", title: "Gigs" }, list));
}

function gigCell(gig) {
  const creator = asObject(gig.creator);
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, stringValue(gig.title, "Gig sem título")),
    h("span", { class: "meta" }, stringValue(creator.nome, stringValue(gig.creatorId, "Criador não identificado"))),
  );
}

// ---------- Detail drawer ----------

export async function openGigDrawer(id) {
  if (!id) return;
  openDrawer({ kicker: "Gig", title: id, subtitle: "Carregando dossiê…", content: statePanel("loading", "Buscando descrição, candidaturas e reviews…") });

  let detail;
  try {
    detail = await callFunction("getGigAdminDetail", { gigId: id });
  } catch (error) {
    openDrawer({ kicker: "Gig", title: id, content: statePanel("error", getErrorMessage(error), { onRetry: () => openGigDrawer(id) }) });
    return;
  }

  const gig = asObject(detail.gig);
  const creator = asObject(gig.creator);
  const applications = asArray(detail.applications);
  const reviews = asArray(detail.reviews);

  openDrawer({
    kicker: "Gig",
    title: stringValue(gig.title, id),
    subtitle: [stringValue(gig.status, "open"), stringValue(creator.nome, gig.creatorId)].filter(Boolean).join(" · "),
    tabs: [
      { label: "Resumo", content: () => summaryTab(gig, creator) },
      { label: `Candidaturas (${applications.length})`, content: () => applicationsTab(applications) },
      { label: `Reviews (${reviews.length})`, content: () => reviewsTab(reviews) },
      { label: "JSON", content: () => h("pre", { class: "code-block" }, prettyJson(detail)) },
    ],
  });
}

function summaryTab(gig, creator) {
  const uid = stringValue(creator.uid);
  return h(
    "div",
    {},
    kvGrid([
      ["Título", stringValue(gig.title)],
      ["Status", badge(stringValue(gig.status, "open"), stringValue(gig.status, "open"))],
      ["Tipo", stringValue(gig.gigType, "Outro")],
      ["Modelo de data", stringValue(gig.dateMode, "Não informado")],
      ["Local", stringValue(gig.locationType, "Não informado")],
      ["Compensação", `${stringValue(gig.compensationType, "—")} / ${stringValue(gig.compensationValue, "—")}`],
      ["Candidaturas", formatNumber(gig.applicantCount)],
      ["Slots", `${formatNumber(gig.slotsFilled)} / ${formatNumber(gig.slotsTotal)}`],
      ["Criada em", formatDateTime(gig.createdAt)],
      ["Expira em", formatDateTime(gig.expiresAt)],
      ["Criador", stringValue(creator.nome, stringValue(gig.creatorId, "Não identificado"))],
    ]),
    h("p", { class: "rich-text" }, stringValue(gig.description, "Sem descrição da gig.")),
    uid ? h("div", { class: "drawer-actions" }, button("Abrir criador", { variant: "secondary", icon: "person", onClick: () => openUserDrawer(uid) })) : null,
  );
}

function applicationsTab(applications) {
  if (!applications.length) return statePanel("empty", "Nenhuma candidatura para esta gig.", { icon: "group_add" });
  return h(
    "div",
    { class: "card-list" },
    ...applications.map((item) => {
      const applicant = asObject(item.applicant);
      const uid = stringValue(item.applicantId, applicant.uid);
      return h(
        "article",
        { class: "list-card list-card-col" },
        h(
          "div",
          { class: "list-card-head" },
          h(
            "div",
            { class: "cell-stack" },
            h("strong", {}, stringValue(applicant.nome, stringValue(uid, "Candidato"))),
            h("span", { class: "meta" }, `Aplicado em ${formatDateTime(item.appliedAt)}`),
          ),
          badge(stringValue(item.status, "pending"), stringValue(item.status, "pending")),
        ),
        h("p", { class: "meta" }, stringValue(item.message, "Sem mensagem enviada.")),
        uid ? h("div", { class: "drawer-actions" }, button("Abrir usuário", { variant: "ghost", icon: "person", onClick: () => openUserDrawer(uid) })) : null,
      );
    }),
  );
}

function reviewsTab(reviews) {
  if (!reviews.length) return statePanel("empty", "Nenhuma review localizada para esta gig.", { icon: "rate_review" });
  return h(
    "div",
    { class: "card-list" },
    ...reviews.map((item) => {
      const reviewer = asObject(item.reviewer);
      const reviewedUser = asObject(item.reviewedUser);
      const reviewedId = stringValue(item.reviewedUserId, reviewedUser.uid);
      return h(
        "article",
        { class: "list-card list-card-col" },
        h(
          "div",
          { class: "list-card-head" },
          h(
            "div",
            { class: "cell-stack" },
            h("strong", {}, stringValue(reviewer.nome, stringValue(item.reviewerId, "Avaliador"))),
            h("span", { class: "meta" }, `Para ${stringValue(reviewedUser.nome, stringValue(reviewedId, "usuário"))} · ${formatDateTime(item.createdAt)}`),
          ),
          pill(`Nota ${formatNumber(item.rating)}`, "info"),
        ),
        h("p", { class: "meta" }, stringValue(item.comment, "Sem comentário.")),
        reviewedId ? h("div", { class: "drawer-actions" }, button("Ver avaliado", { variant: "ghost", icon: "person", onClick: () => openUserDrawer(reviewedId) })) : null,
      );
    }),
  );
}
