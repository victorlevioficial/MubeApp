// Dashboard: KPI strip + work queue (actionable items) + recent activity.
// Replaces the legacy 5-panel wall with a calmer, scannable single view.
import { h, mount, icon } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asObject, asArray, formatNumber, stringValue, toInteger, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, statTile, badge, avatar, button } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";

let cache = null;

export async function mountDashboard(container, ctx = {}) {
  if (cache && !ctx.force) {
    render(container, cache, ctx);
    return;
  }
  mount(
    container,
    lead(),
    statePanel("loading", "Carregando indicadores…"),
  );
  try {
    const data = await callFunction("getDashboardOverview");
    cache = data;
    render(container, data, ctx);
  } catch (error) {
    mount(
      container,
      lead(),
      statePanel("error", getErrorMessage(error), { onRetry: () => mountDashboard(container, { ...ctx, force: true }) }),
    );
  }
}

function lead() {
  return sectionLead("Operação em tempo real", "Dashboard", "Pulso do backend: crescimento, moderação e fila de trabalho.");
}

function render(container, data, ctx) {
  const counts = asObject(data.counts);
  const navigate = ctx.navigate || (() => {});
  const num = (value) => formatNumber(value);

  const kpis = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "groups", label: "Usuários", value: num(counts.totalUsers), hint: `${num(counts.completedProfiles)} com cadastro completo` }),
    statTile({ iconName: "forum", label: "Conversas", value: num(counts.totalConversations), hint: `${num(counts.totalMatches)} matches` }),
    statTile({ iconName: "event_note", label: "Gigs abertas", value: num(counts.openGigs), hint: `${num(counts.totalGigs)} no total` }),
    statTile({ iconName: "outlined_flag", label: "Denúncias pendentes", value: num(counts.pendingReports), tone: toInteger(counts.pendingReports) > 0 ? "danger" : "ok" }),
    statTile({ iconName: "support_agent", label: "Tickets abertos", value: num(counts.openTickets), tone: toInteger(counts.openTickets) > 4 ? "warning" : null }),
    statTile({ iconName: "gpp_bad", label: "Suspensões ativas", value: num(counts.activeSuspensions) }),
  );

  const queueItems = [];
  if (toInteger(counts.pendingReports) > 0) {
    queueItems.push(queueRow("outlined_flag", `${num(counts.pendingReports)} denúncias aguardando`, "Fila de moderação", () => navigate("reports"), "danger"));
  }
  if (toInteger(counts.openTickets) > 0) {
    queueItems.push(queueRow("support_agent", `${num(counts.openTickets)} tickets abertos`, "Suporte", () => navigate("tickets"), "warning"));
  }
  if (toInteger(counts.processingTranscodes) > 0) {
    queueItems.push(queueRow("video_settings", `${num(counts.processingTranscodes)} transcodes processando`, "Pipeline de vídeo", () => navigate("system"), "info"));
  }
  if (toInteger(counts.featuredProfiles) === 0) {
    queueItems.push(queueRow("stars", "Lista de destaque vazia", "Curadoria do feed", () => navigate("featured"), "danger"));
  }
  const queue = panel(
    { kicker: "Saúde operacional", title: "Fila de trabalho" },
    queueItems.length
      ? h("div", { class: "queue-list" }, ...queueItems)
      : statePanel("empty", "Tudo em dia — sem pendências.", { icon: "task_alt" }),
  );

  const recentUsers = panel(
    { kicker: "Crescimento", title: "Usuários recentes", trailing: button("Ver todos", { variant: "ghost", icon: "arrow_forward", onClick: () => navigate("users") }) },
    dataList({
      columns: [
        { label: "Usuário", render: userCell, width: "minmax(0, 2fr)" },
        { label: "Status", render: (u) => badge(stringValue(u.statusLabel, "Ativo"), stringValue(u.statusKey, "active")) },
        { label: "Local", render: (u) => stringValue(u.displayLocation, "—") },
      ],
      rows: asArray(data.recentUsers).slice(0, 6),
      emptyMessage: "Sem usuários recentes.",
    }),
  );

  const recentGigs = panel(
    { kicker: "Marketplace", title: "Gigs recentes", trailing: button("Ver todas", { variant: "ghost", icon: "arrow_forward", onClick: () => navigate("gigs") }) },
    dataList({
      columns: [
        { label: "Gig", render: gigCell, width: "minmax(0, 2fr)" },
        { label: "Status", render: (g) => badge(stringValue(g.status, "open"), stringValue(g.status, "open")) },
        { label: "Candidaturas", render: (g) => formatNumber(g.applicantCount) },
      ],
      rows: asArray(data.recentGigs).slice(0, 6),
      emptyMessage: "Sem gigs recentes.",
    }),
  );

  mount(container, lead(), kpis, h("div", { class: "grid-2" }, queue, recentUsers), recentGigs);
}

function userCell(user) {
  return h(
    "div",
    { class: "media-cell" },
    avatar(user.foto, user.nome),
    h("div", { class: "cell-stack" }, h("strong", {}, stringValue(user.nome, stringValue(user.uid))), h("span", { class: "meta" }, stringValue(user.email, "—"))),
  );
}

function gigCell(gig) {
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, stringValue(gig.title, "Sem título")),
    h("span", { class: "meta" }, stringValue(asObject(gig.creator).nome, "Criador não identificado")),
  );
}

function queueRow(iconName, title, subtitle, onClick, tone) {
  return h(
    "button",
    { class: "queue-item" + (tone ? ` tone-${tone}` : ""), type: "button", onClick },
    icon(iconName),
    h("div", { class: "cell-stack" }, h("strong", {}, title), h("span", { class: "meta" }, subtitle)),
    icon("chevron_right"),
  );
}
