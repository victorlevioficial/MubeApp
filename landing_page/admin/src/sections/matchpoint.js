// MatchPoint: matching-engine overview — KPIs, trending hashtags, recent
// matches (with deep links to users/conversation) and an interactions table.
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, asObject, stringValue, formatNumber, formatDecimal, formatDateTime, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, badge, pill, statTile } from "../ui/primitives.js";
import { dataList } from "../ui/DataList.js";
import { openUserDrawer } from "./users.js";
import { openConversationDrawer } from "./conversations.js";

let cache = null;
let host = null;

export async function mountMatchpoint(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), host);
  if (cache && !ctx.force) {
    render();
    return;
  }
  await load();
}

function lead() {
  return sectionLead("Motor de matching", "MatchPoint", "Matches, hashtags em alta e auditoria de ranking.");
}

async function load() {
  if (!host) return;
  mount(host, statePanel("loading", "Carregando MatchPoint…"));
  try {
    cache = await callFunction("getMatchpointAdminOverview", { limit: 24 });
    render();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: load }));
  }
}

function render() {
  const data = asObject(cache);
  const counts = asObject(data.counts);
  const summary = asObject(asObject(data.rankingAudit).summary);

  const kpis = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "bolt", label: "Perfis ativos", value: formatNumber(counts.activeProfiles) }),
    statTile({ iconName: "favorite", label: "Matches", value: formatNumber(counts.matches) }),
    statTile({ iconName: "swap_horiz", label: "Interações recentes", value: formatNumber(counts.recentInteractions) }),
    statTile({ iconName: "analytics", label: "Média retornada/evento", value: formatDecimal(summary.averageReturnedPerEvent) }),
  );

  mount(
    host,
    kpis,
    h("div", { class: "grid-2" }, hashtagsPanel(asArray(data.hashtags)), matchesPanel(asArray(data.matches))),
    panel({ kicker: "Atividade", title: "Interações recentes" }, interactionsList(asArray(data.interactions))),
  );
}

function hashtagsPanel(hashtags) {
  const body = hashtags.length
    ? h(
        "div",
        { class: "card-list" },
        ...hashtags.map((item) =>
          h(
            "article",
            { class: "list-card" },
            h(
              "div",
              { class: "cell-stack" },
              h("strong", {}, `#${stringValue(item.label)}`),
              h("span", { class: "meta" }, `Uso ${formatNumber(item.useCount)} · semana ${formatNumber(item.weeklyCount)}`),
            ),
            item.isTrending === true ? pill("Trending", "ok") : pill("Estável", "info"),
          ),
        ),
      )
    : statePanel("empty", "Nenhuma hashtag encontrada.", { icon: "tag" });
  return panel({ kicker: "Descoberta", title: "Hashtags" }, body);
}

function matchesPanel(matches) {
  const body = matches.length
    ? h(
        "div",
        { class: "card-list" },
        ...matches.map((match) => {
          const users = asArray(match.users);
          const conversationId = stringValue(match.conversationId);
          const title = users.map((u) => stringValue(u.nome, stringValue(u.uid))).filter(Boolean).join(" × ") || stringValue(match.id);
          return h(
            "article",
            { class: "list-card list-card-col" },
            h(
              "div",
              { class: "list-card-head" },
              h("div", { class: "cell-stack" }, h("strong", {}, title), h("span", { class: "meta" }, formatDateTime(match.createdAt))),
            ),
            h(
              "div",
              { class: "row-actions" },
              ...users
                .filter((u) => u.uid)
                .map((u) => button(stringValue(u.nome, "Usuário"), { variant: "ghost", icon: "person", onClick: () => openUserDrawer(stringValue(u.uid)) })),
              conversationId ? button("Conversa", { variant: "secondary", icon: "chat", onClick: () => openConversationDrawer(conversationId) }) : null,
            ),
          );
        }),
      )
    : statePanel("empty", "Nenhum match recente.", { icon: "favorite_border" });
  return panel({ kicker: "Resultados", title: "Matches recentes" }, body);
}

function interactionsList(items) {
  return dataList({
    columns: [
      { label: "Data", render: (i) => formatDateTime(i.createdAt) },
      { label: "Tipo", render: (i) => badge(stringValue(i.type, "unknown"), stringValue(i.type, "pending")) },
      { label: "Origem", render: (i) => userRef(i.sourceUser, i.sourceUserId), width: "minmax(0, 1.4fr)" },
      { label: "Destino", render: (i) => userRef(i.targetUser, i.targetUserId), width: "minmax(0, 1.4fr)" },
    ],
    rows: items,
    emptyMessage: "Nenhuma interação recente encontrada.",
  });
}

function userRef(userObj, fallbackId) {
  const user = asObject(userObj);
  const uid = stringValue(user.uid, stringValue(fallbackId));
  const label = stringValue(user.nome, uid || "—");
  if (!uid) return label;
  return h("button", { class: "link-btn", type: "button", onClick: () => openUserDrawer(uid) }, label);
}
