// Reports: moderation queue with status filter and inline actions
// (processing / processar / rejeitar) plus a link to the reported user.
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, stringValue, formatNumber, formatDateTime, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, badge, statTile } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";
import { showToast, handleError } from "../ui/toast.js";
import { openUserDrawer } from "./users.js";

const STATUS_OPTIONS = [
  ["all", "Todas"],
  ["pending", "Pendentes"],
  ["processing", "Em processamento"],
  ["processed", "Processadas"],
  ["rejected", "Rejeitadas"],
];

const state = { items: [], loaded: false, status: "all" };
let host = null;

export async function mountReports(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), toolbar(), host);
  if (!state.loaded || ctx.force) await load();
  else renderResults();
}

function lead() {
  return sectionLead("Moderação", "Denúncias", "Fila de denúncias com ação acoplada de moderação.");
}

function toolbar() {
  const sel = h(
    "select",
    { onChange: (event) => { state.status = event.currentTarget.value; load(); } },
    ...STATUS_OPTIONS.map(([value, label]) => h("option", { value, selected: value === state.status }, label)),
  );
  return panel(
    {},
    h(
      "div",
      { class: "filter-bar" },
      h("label", { class: "field" }, h("span", {}, "Status"), sel),
      button("Atualizar", { variant: "secondary", icon: "refresh", onClick: load }),
    ),
  );
}

async function load() {
  if (!host) return;
  mount(host, statePanel("loading", "Carregando denúncias…"));
  try {
    const response = await callFunction("listReports", { status: state.status, limit: 60 });
    state.items = asArray(response.reports);
    state.loaded = true;
    renderResults();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: load }));
  }
}

function renderResults() {
  const pending = state.items.filter((r) => stringValue(r.status, "pending") === "pending").length;
  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "outlined_flag", label: "Denúncias carregadas", value: formatNumber(state.items.length) }),
    statTile({ iconName: "pending_actions", label: "Pendentes (página)", value: formatNumber(pending), tone: pending > 0 ? "danger" : "ok" }),
  );

  const list = dataList({
    columns: [
      { label: "Reportado", render: reportedCell, width: "minmax(0, 1.6fr)" },
      { label: "Motivo", render: reasonCell, width: "minmax(0, 1.8fr)" },
      { label: "Status", render: (r) => badge(stringValue(r.status, "pending"), stringValue(r.status, "pending")) },
      { label: "Ações", render: actionsCell, width: "minmax(0, 2fr)" },
    ],
    rows: state.items,
    emptyMessage: "Nenhuma denúncia retornada para este filtro.",
  });

  mount(host, summary, panel({ kicker: "Moderação", title: "Fila de denúncias" }, list));
}

function reportedCell(report) {
  const reportedId = stringValue(report.reportedItemId);
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, stringValue(report.reportedName, reportedId || "—")),
    h("span", { class: "meta mono" }, [reportedId, formatDateTime(report.createdAt)].filter(Boolean).join(" · ")),
  );
}

function reasonCell(report) {
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, stringValue(report.reason, "Sem motivo")),
    h("span", { class: "meta" }, stringValue(report.description, "Sem descrição")),
  );
}

function actionsCell(report) {
  const reportId = stringValue(report.id);
  const reportedId = stringValue(report.reportedItemId);
  const isUser = stringValue(report.reportedItemType) === "user";
  return h(
    "div",
    { class: "row-actions" },
    isUser && reportedId ? button("Usuário", { variant: "ghost", icon: "person", onClick: () => openUserDrawer(reportedId) }) : null,
    button("Processar", { variant: "primary", icon: "done", onClick: () => updateStatus(reportId, "processed") }),
    button("Rejeitar", { variant: "danger", icon: "close", onClick: () => updateStatus(reportId, "rejected") }),
  );
}

async function updateStatus(reportId, status) {
  if (!reportId) return;
  try {
    await callFunction("updateReportStatus", { reportId, status });
    showToast("Status da denúncia atualizado.", "success");
    await load();
  } catch (error) {
    handleError(error);
  }
}
