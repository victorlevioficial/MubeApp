// Tickets: support queue with status filter + cursor pagination, and a detail
// drawer to read the message and update status / write an admin response.
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, stringValue, formatNumber, formatDateTime, formatRelative, prettyJson, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, badge, statTile, kvGrid } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";
import { openDrawer, closeDrawer } from "../ui/Drawer.js";
import { showToast, handleError } from "../ui/toast.js";
import { openUserDrawer } from "./users.js";

const STATUS_OPTIONS = [
  ["all", "Todos"],
  ["open", "Abertos"],
  ["in_progress", "Em andamento"],
  ["resolved", "Resolvidos"],
  ["closed", "Fechados"],
];
const EDIT_OPTIONS = [
  ["open", "Aberto"],
  ["in_progress", "Em andamento"],
  ["resolved", "Resolvido"],
  ["closed", "Fechado"],
];

const state = { items: [], loaded: false, status: "all", hasMore: false, nextCursor: null };
let host = null;

export async function mountTickets(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), toolbar(), host);
  if (!state.loaded || ctx.force) await load({ reset: true });
  else renderResults();
}

function lead() {
  return sectionLead("Suporte", "Tickets", "Atendimento, respostas administrativas e mudança de status.");
}

function toolbar() {
  const sel = h(
    "select",
    { onChange: (event) => { state.status = event.currentTarget.value; load({ reset: true }); } },
    ...STATUS_OPTIONS.map(([value, label]) => h("option", { value, selected: value === state.status }, label)),
  );
  return panel(
    {},
    h(
      "div",
      { class: "filter-bar" },
      h("label", { class: "field" }, h("span", {}, "Status"), sel),
      button("Atualizar", { variant: "secondary", icon: "refresh", onClick: () => load({ reset: true }) }),
    ),
  );
}

async function load({ reset = false, append = false } = {}) {
  if (!host) return;
  if (append && !state.nextCursor) return;
  if (!append) mount(host, statePanel("loading", "Carregando tickets…"));
  try {
    const response = await callFunction("listTickets", {
      status: state.status,
      limit: 30,
      cursor: append ? state.nextCursor : null,
    });
    const incoming = asArray(response.tickets);
    state.items = append ? mergeById(state.items, incoming) : incoming;
    state.hasMore = response.hasMore === true;
    state.nextCursor = response.nextCursor || null;
    state.loaded = true;
    renderResults();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: () => load({ reset: true }) }));
  }
}

function mergeById(existing, next) {
  const byId = new Map();
  asArray(existing).forEach((item) => byId.set(stringValue(item.id), item));
  asArray(next).forEach((item) => byId.set(stringValue(item.id), item));
  return Array.from(byId.values());
}

function renderResults() {
  const open = state.items.filter((t) => stringValue(t.status, "open") === "open").length;
  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "support_agent", label: "Tickets carregados", value: formatNumber(state.items.length) }),
    statTile({ iconName: "mark_email_unread", label: "Abertos (página)", value: formatNumber(open), tone: open > 0 ? "warning" : "ok" }),
  );

  const list = dataList({
    columns: [
      { label: "Assunto", render: subjectCell, width: "minmax(0, 2.2fr)" },
      { label: "Categoria", render: (t) => stringValue(t.category, "—") },
      { label: "Status", render: (t) => badge(stringValue(t.status, "open"), stringValue(t.status, "open")) },
      { label: "Criado", render: (t) => formatRelative(t.createdAt) },
    ],
    rows: state.items,
    onRowClick: (t) => openTicketDrawer(stringValue(t.id)),
    emptyMessage: "Nenhum ticket encontrado com esse status.",
  });

  const footer = state.hasMore
    ? h("div", { class: "load-more" }, button("Carregar mais", { variant: "secondary", icon: "expand_more", onClick: () => load({ append: true }) }))
    : null;

  mount(host, summary, panel({ kicker: "Suporte", title: "Tickets" }, list), footer);
}

function subjectCell(ticket) {
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, stringValue(ticket.subject, stringValue(ticket.title, stringValue(ticket.id)))),
    h("span", { class: "meta" }, stringValue(ticket.contactEmail, stringValue(ticket.userId, "Sem contato"))),
  );
}

// ---------- Detail drawer ----------

function openTicketDrawer(ticketId) {
  const ticket = state.items.find((t) => stringValue(t.id) === ticketId);
  if (!ticket) return;

  const statusSel = h(
    "select",
    {},
    ...EDIT_OPTIONS.map(([value, label]) => h("option", { value, selected: value === stringValue(ticket.status, "open") }, label)),
  );
  const responseArea = h("textarea", { rows: "6", placeholder: "Resposta interna ou enviada ao usuário" }, stringValue(ticket.adminResponse));

  const saveBtn = button("Salvar atualização", {
    variant: "primary",
    icon: "save",
    onClick: async () => {
      saveBtn.disabled = true;
      try {
        await callFunction("updateTicket", { ticketId, status: statusSel.value, response: responseArea.value.trim() });
        showToast("Ticket atualizado.", "success");
        closeDrawer();
        await load({ reset: true });
      } catch (error) {
        handleError(error);
        saveBtn.disabled = false;
      }
    },
  });

  const uid = stringValue(ticket.userId);
  openDrawer({
    kicker: "Ticket",
    title: stringValue(ticket.subject, stringValue(ticket.id)),
    subtitle: [stringValue(ticket.status, "open"), stringValue(ticket.category)].filter(Boolean).join(" · "),
    content: h(
      "div",
      { class: "section-body" },
      kvGrid([
        ["ID", stringValue(ticket.id)],
        ["Status", badge(stringValue(ticket.status, "open"), stringValue(ticket.status, "open"))],
        ["Categoria", stringValue(ticket.category, "Não informada")],
        ["Origem", stringValue(ticket.source, "app")],
        ["Contato", stringValue(ticket.contactName, "Não informado")],
        ["Email", stringValue(ticket.contactEmail, "Não informado")],
        ["Criado em", formatDateTime(ticket.createdAt)],
        ["Atualizado em", formatDateTime(ticket.updatedAt)],
      ]),
      h("p", { class: "rich-text" }, stringValue(ticket.message, stringValue(ticket.description, "Sem descrição."))),
      h(
        "div",
        { class: "mod-block" },
        h("h4", {}, "Atualizar ticket"),
        h("label", { class: "field" }, h("span", {}, "Status"), statusSel),
        h("label", { class: "field" }, h("span", {}, "Resposta administrativa"), responseArea),
        h(
          "div",
          { class: "drawer-actions" },
          saveBtn,
          uid ? button("Abrir usuário", { variant: "secondary", icon: "person", onClick: () => openUserDrawer(uid) }) : null,
        ),
      ),
      h("details", { class: "json-fold" }, h("summary", {}, "Ver JSON bruto"), h("pre", { class: "code-block" }, prettyJson(ticket))),
    ),
  });
}
