// Suspensions: create a suspension by UID + browse active/lifted suspensions
// with a lift action. Mirrors the legacy manageSuspension create/lift calls.
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, stringValue, toInteger, formatNumber, formatDateTime, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, badge, statTile } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";
import { showToast, handleError } from "../ui/toast.js";
import { openUserDrawer } from "./users.js";

const STATUS_OPTIONS = [
  ["active", "Ativas"],
  ["lifted", "Levantadas"],
  ["all", "Todas"],
];

const state = { items: [], loaded: false, status: "active" };
let host = null;

export async function mountSuspensions(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), createForm(), toolbar(), host);
  if (!state.loaded || ctx.force) await load();
  else renderResults();
}

function lead() {
  return sectionLead("Controle de acesso", "Suspensões", "Bloqueios temporários e banimentos de contas.");
}

function createForm() {
  const uid = h("input", { type: "text", placeholder: "UID do usuário" });
  const reason = h("textarea", { rows: "2", placeholder: "Motivo da suspensão" });
  const days = h("input", { type: "number", min: "1", max: "365", value: "7" });

  const confirmBtn = button("Suspender", {
    variant: "danger",
    icon: "gpp_bad",
    onClick: async () => {
      const userId = uid.value.trim();
      const reasonText = reason.value.trim();
      const duration = Math.min(Math.max(toInteger(days.value, 7), 1), 365);
      if (!userId || !reasonText) {
        showToast("Informe o UID e o motivo da suspensão.", "error");
        return;
      }
      if (!window.confirm(`Suspender o usuário ${userId} por ${duration} dia(s)?`)) return;
      confirmBtn.disabled = true;
      try {
        await callFunction("manageSuspension", { action: "create", userId, reason: reasonText, durationDays: duration });
        showToast("Suspensão criada.", "success");
        uid.value = "";
        reason.value = "";
        days.value = "7";
        await load();
      } catch (error) {
        handleError(error);
      } finally {
        confirmBtn.disabled = false;
      }
    },
  });

  return panel(
    { kicker: "Nova ação", title: "Suspender usuário" },
    h(
      "div",
      { class: "form-grid" },
      h("label", { class: "field" }, h("span", {}, "UID"), uid),
      h("label", { class: "field" }, h("span", {}, "Duração (dias)"), days),
      h("label", { class: "field field-grow" }, h("span", {}, "Motivo"), reason),
    ),
    h("div", { class: "toolbar-actions" }, confirmBtn),
  );
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
  mount(host, statePanel("loading", "Carregando suspensões…"));
  try {
    const response = await callFunction("listSuspensions", { status: state.status, limit: 60 });
    state.items = asArray(response.suspensions);
    state.loaded = true;
    renderResults();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: load }));
  }
}

function renderResults() {
  const active = state.items.filter((s) => stringValue(s.status, "active") === "active").length;
  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "gpp_bad", label: "Suspensões carregadas", value: formatNumber(state.items.length) }),
    statTile({ iconName: "lock", label: "Ativas (página)", value: formatNumber(active), tone: active > 0 ? "warning" : "ok" }),
  );

  const list = dataList({
    columns: [
      { label: "Usuário", render: userCell, width: "minmax(0, 1.6fr)" },
      { label: "Motivo", render: (s) => stringValue(s.reason, "Sem motivo"), width: "minmax(0, 1.8fr)" },
      { label: "Período", render: periodCell, width: "minmax(0, 1.4fr)" },
      { label: "Status", render: (s) => badge(stringValue(s.status, "active"), stringValue(s.status, "active")) },
      { label: "Ações", render: actionsCell },
    ],
    rows: state.items,
    emptyMessage: "Nenhuma suspensão encontrada.",
  });

  mount(host, summary, panel({ kicker: "Controle de acesso", title: "Suspensões" }, list));
}

function userCell(item) {
  const userId = stringValue(item.userId);
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, stringValue(item.userName, userId || "—")),
    h("span", { class: "meta mono" }, userId),
  );
}

function periodCell(item) {
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, `Até ${formatDateTime(item.suspendedUntil)}`),
    h("span", { class: "meta" }, `Criada ${formatDateTime(item.createdAt)}`),
  );
}

function actionsCell(item) {
  const userId = stringValue(item.userId);
  const isActive = stringValue(item.status) === "active";
  return h(
    "div",
    { class: "row-actions" },
    userId ? button("Usuário", { variant: "ghost", icon: "person", onClick: () => openUserDrawer(userId) }) : null,
    isActive ? button("Levantar", { variant: "secondary", icon: "lock_open", onClick: () => lift(stringValue(item.id)) }) : null,
  );
}

async function lift(suspensionId) {
  if (!suspensionId) return;
  if (!window.confirm("Levantar esta suspensão e reativar o usuário?")) return;
  try {
    await callFunction("manageSuspension", { action: "lift", suspensionId });
    showToast("Suspensão levantada.", "success");
    await load();
  } catch (error) {
    handleError(error);
  }
}
