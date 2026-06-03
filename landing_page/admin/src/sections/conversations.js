// Conversations: searchable list + per-conversation dossier drawer (resumo,
// mensagens, participantes, chat safety, JSON). Backend exposes a consolidated
// detail endpoint with a messages fallback (parity with the legacy panel).
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, asObject, stringValue, toInteger, formatNumber, formatDateTime, formatRelative, prettyJson, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, badge, statTile, avatar, kvGrid } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";
import { openDrawer } from "../ui/Drawer.js";
import { openUserDrawer } from "./users.js";

const LIMIT_OPTIONS = [
  ["20", "20 conversas"],
  ["40", "40 conversas"],
  ["80", "80 conversas"],
];

const state = { items: [], total: 0, loaded: false, search: "", limit: 20 };
let host = null;

export async function mountConversations(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), toolbar(), host);
  if (!state.loaded || ctx.force) await load();
  else renderResults();
}

function lead() {
  return sectionLead("Chat e compliance", "Conversas", "Mensagens, participantes e sinais de chat safety por conversa.");
}

function toolbar() {
  const searchInput = h("input", {
    type: "search",
    placeholder: "Nome do participante, UID ou ID da conversa",
    value: state.search,
    onKeydown: (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        state.search = searchInput.value.trim();
        load();
      }
    },
  });
  const limitSel = h(
    "select",
    { onChange: (event) => { state.limit = toInteger(event.currentTarget.value, 20); load(); } },
    ...LIMIT_OPTIONS.map(([value, label]) => h("option", { value, selected: toInteger(value) === state.limit }, label)),
  );
  return panel(
    {},
    h(
      "div",
      { class: "filter-bar" },
      h("label", { class: "field field-grow" }, h("span", {}, "Busca"), searchInput),
      h("label", { class: "field" }, h("span", {}, "Limite"), limitSel),
      button("Buscar", { variant: "primary", icon: "search", onClick: () => { state.search = searchInput.value.trim(); load(); } }),
    ),
  );
}

async function load() {
  if (!host) return;
  mount(host, statePanel("loading", "Carregando conversas…"));
  const payload = { search: state.search, limit: Math.min(state.limit, 80) };
  try {
    let response;
    try {
      response = await callFunction("listConversationsAdmin", payload);
    } catch (_error) {
      response = await callFunction("listConversations", payload);
    }
    state.items = asArray(response.conversations);
    state.total = toInteger(response.total, state.items.length);
    state.loaded = true;
    renderResults();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: load }));
  }
}

function participantsTitle(conversation) {
  const names = asArray(conversation.participants)
    .map((u) => stringValue(u.nome, stringValue(u.uid)))
    .filter(Boolean);
  return names.join(" × ") || stringValue(conversation.id, "Conversa");
}

function renderResults() {
  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "forum", label: "Conversas carregadas", value: formatNumber(state.items.length) }),
    statTile({ iconName: "database", label: "Total reportado", value: formatNumber(state.total) }),
  );

  const list = dataList({
    columns: [
      { label: "Conversa", render: conversationCell, width: "minmax(0, 2.4fr)" },
      { label: "Tipo", render: (c) => badge(stringValue(c.type, "direct"), stringValue(c.type, "direct")) },
      { label: "Atualizada", render: (c) => formatRelative(c.updatedAt || c.lastMessageAt) },
    ],
    rows: state.items,
    onRowClick: (c) => openConversationDrawer(stringValue(c.id)),
    emptyMessage: "Nenhuma conversa encontrada com esse filtro.",
  });

  mount(host, summary, panel({ kicker: "Chat", title: "Conversas" }, list));
}

function conversationCell(conversation) {
  return h(
    "div",
    { class: "cell-stack" },
    h("strong", {}, participantsTitle(conversation)),
    h("span", { class: "meta" }, stringValue(conversation.lastMessageText, "Sem última mensagem")),
  );
}

// ---------- Detail drawer ----------

export async function openConversationDrawer(id) {
  if (!id) return;
  openDrawer({ kicker: "Conversa", title: id, subtitle: "Carregando dossiê…", content: statePanel("loading", "Carregando mensagens e contexto…") });

  let detail;
  try {
    detail = await callFunction("getConversationAdminDetail", { conversationId: id, messageLimit: 120 });
  } catch (_error) {
    try {
      const fallback = await callFunction("getConversationMessages", { conversationId: id, limit: 120 });
      const listItem = state.items.find((item) => stringValue(item.id) === id) || {};
      detail = { conversation: listItem, messages: asArray(fallback.messages), chatSafetyEvents: [], participantPreviews: [] };
    } catch (err) {
      openDrawer({ kicker: "Conversa", title: id, content: statePanel("error", getErrorMessage(err), { onRetry: () => openConversationDrawer(id) }) });
      return;
    }
  }

  const conversation = asObject(detail.conversation);
  const participants = asArray(conversation.participants);
  const messages = asArray(detail.messages);

  openDrawer({
    kicker: "Conversa",
    title: participantsTitle(conversation),
    subtitle: [stringValue(conversation.type, "direct"), `Atualizada ${formatRelative(conversation.updatedAt)}`].join(" · "),
    tabs: [
      { label: "Resumo", content: () => summaryTab(conversation) },
      { label: `Mensagens (${messages.length})`, content: () => messagesTab(messages) },
      { label: `Participantes (${participants.length})`, content: () => participantsTab(participants) },
      { label: "Safety", content: () => safetyTab(detail) },
      { label: "JSON", content: () => h("pre", { class: "code-block" }, prettyJson(detail)) },
    ],
  });
}

function summaryTab(conversation) {
  return kvGrid([
    ["ID", stringValue(conversation.id)],
    ["Tipo", badge(stringValue(conversation.type, "direct"), stringValue(conversation.type, "direct"))],
    ["Criada em", formatDateTime(conversation.createdAt)],
    ["Atualizada em", formatDateTime(conversation.updatedAt)],
    ["Último envio", formatDateTime(conversation.lastMessageAt)],
    ["Último remetente", stringValue(conversation.lastSenderId, "Não identificado")],
  ]);
}

function messagesTab(messages) {
  if (!messages.length) return statePanel("empty", "Nenhuma mensagem retornada para esta conversa.", { icon: "sms" });
  return h(
    "div",
    { class: "chat-log" },
    ...messages.map((message) => {
      const sender = asObject(message.sender);
      return h(
        "article",
        { class: "chat-msg" },
        h(
          "div",
          { class: "chat-msg-head" },
          h("strong", {}, stringValue(sender.nome, stringValue(message.senderId, "Sistema"))),
          h("span", { class: "meta" }, formatDateTime(message.createdAt)),
        ),
        h("p", { class: "chat-msg-text" }, stringValue(message.text, "[sem texto]")),
      );
    }),
  );
}

function participantsTab(participants) {
  if (!participants.length) return statePanel("empty", "Nenhum participante identificado.", { icon: "person" });
  return h(
    "div",
    { class: "card-list" },
    ...participants.map((user) => {
      const uid = stringValue(user.uid);
      return h(
        "div",
        { class: "list-card" },
        avatar(user.foto, stringValue(user.nome, uid)),
        h(
          "div",
          { class: "cell-stack" },
          h("strong", {}, stringValue(user.nome, uid)),
          h("span", { class: "meta" }, [stringValue(user.email), stringValue(user.tipoPerfilLabel)].filter(Boolean).join(" · ") || uid),
        ),
        uid ? button("Abrir", { variant: "secondary", icon: "person", onClick: () => openUserDrawer(uid) }) : null,
      );
    }),
  );
}

function safetyTab(detail) {
  return h(
    "div",
    { class: "section-body" },
    relationList("Eventos de chat safety", asArray(detail.chatSafetyEvents), (item) => `${stringValue(item.id)} · ${stringValue(item.path)}`),
    relationList("Conversation previews", asArray(detail.participantPreviews), (item) => `${stringValue(item.id)} · ${stringValue(item.path)}`),
  );
}

function relationList(title, items, lineFn) {
  return h(
    "div",
    { class: "mini-list" },
    h("h4", {}, `${title} (${items.length})`),
    items.length
      ? h("ul", {}, ...items.slice(0, 10).map((item) => h("li", {}, lineFn(item))))
      : h("p", { class: "meta" }, "Nada registrado."),
  );
}
