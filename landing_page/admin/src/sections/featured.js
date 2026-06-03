// Featured profiles: curate the ordered list shown on the app home. Lookup a
// UID to preview, add/remove/reorder locally, then persist with
// setFeaturedProfiles (parity with the legacy curation editor).
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, stringValue, formatNumber, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, iconButton, statTile, avatar, pill } from "../ui/primitives.js";
import { showToast, handleError } from "../ui/toast.js";
import { openUserDrawer } from "./users.js";

const state = { uids: [], profiles: new Map(), preview: null, loaded: false, dirty: false };
let host = null;

export async function mountFeatured(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), lookupPanel(), host);
  if (!state.loaded || ctx.force) await load();
  else renderList();
}

function lead() {
  return sectionLead("Curadoria do feed", "Em destaque", "Perfis destacados na home do app, na ordem exibida.");
}

function setProfile(profile) {
  const uid = stringValue(profile && profile.uid);
  if (uid) state.profiles.set(uid, profile);
}

async function load() {
  if (!host) return;
  mount(host, statePanel("loading", "Carregando curadoria…"));
  try {
    const response = await callFunction("getFeaturedProfiles", {});
    state.uids = asArray(response.uids).map((uid) => String(uid || "")).filter(Boolean);
    state.profiles = new Map();
    asArray(response.profiles).forEach(setProfile);
    state.preview = null;
    state.dirty = false;
    state.loaded = true;
    renderList();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: load }));
  }
}

function lookupPanel() {
  const input = h("input", {
    type: "text",
    placeholder: "UID do perfil",
    onKeydown: (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        lookup(input.value.trim());
      }
    },
  });
  return panel(
    { kicker: "Adicionar", title: "Buscar perfil" },
    h(
      "div",
      { class: "filter-bar" },
      h("label", { class: "field field-grow" }, h("span", {}, "UID"), input),
      button("Buscar", { variant: "secondary", icon: "search", onClick: () => lookup(input.value.trim()) }),
    ),
    h("div", { class: "preview-slot", ref: (node) => { previewHost = node; renderPreview(); } }),
  );
}

let previewHost = null;

async function lookup(uid) {
  if (!uid) {
    showToast("Informe um UID para buscar.", "error");
    return;
  }
  try {
    state.preview = await callFunction("lookupUser", { uid });
    renderPreview();
  } catch (error) {
    handleError(error);
  }
}

function renderPreview() {
  if (!previewHost) return;
  if (!state.preview) {
    mount(previewHost, statePanel("empty", "Busque um UID para visualizar o perfil antes de adicionar.", { icon: "search" }));
    return;
  }
  const profile = state.preview;
  const uid = stringValue(profile.uid);
  const already = state.uids.includes(uid);
  mount(
    previewHost,
    h(
      "article",
      { class: "list-card" },
      avatar(profile.foto, stringValue(profile.nome, uid)),
      h(
        "div",
        { class: "cell-stack" },
        h("strong", {}, stringValue(profile.nome, uid)),
        h("span", { class: "meta" }, [stringValue(profile.email), stringValue(profile.tipoPerfilLabel)].filter(Boolean).join(" · ") || uid),
      ),
      already
        ? pill("Já está na lista", "warning")
        : button("Adicionar", { variant: "primary", icon: "add", onClick: () => add(uid) }),
    ),
  );
}

function add(uid) {
  if (!uid || state.uids.includes(uid)) return;
  state.uids.push(uid);
  if (state.preview && stringValue(state.preview.uid) === uid) setProfile(state.preview);
  state.dirty = true;
  renderPreview();
  renderList();
}

function remove(uid) {
  state.uids = state.uids.filter((item) => item !== uid);
  state.dirty = true;
  renderPreview();
  renderList();
}

function move(uid, direction) {
  const index = state.uids.indexOf(uid);
  if (index < 0) return;
  const target = index + direction;
  if (target < 0 || target >= state.uids.length) return;
  const next = state.uids.slice();
  [next[index], next[target]] = [next[target], next[index]];
  state.uids = next;
  state.dirty = true;
  renderList();
}

async function save() {
  try {
    await callFunction("setFeaturedProfiles", { uids: state.uids });
    showToast("Perfis em destaque salvos.", "success");
    await load();
  } catch (error) {
    handleError(error);
  }
}

function renderList() {
  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "stars", label: "Perfis em destaque", value: formatNumber(state.uids.length), tone: state.uids.length === 0 ? "danger" : null }),
    statTile({ iconName: "edit_note", label: "Alterações pendentes", value: state.dirty ? "Sim" : "Não", tone: state.dirty ? "warning" : "ok" }),
  );

  const body = state.uids.length
    ? h(
        "div",
        { class: "card-list" },
        ...state.uids.map((uid, index) => featuredRow(uid, index)),
      )
    : statePanel("empty", "Nenhum perfil em destaque configurado.", { icon: "stars" });

  const saveBtn = button("Salvar no backend", { variant: "primary", icon: "save", onClick: save, disabled: !state.dirty });

  mount(
    host,
    summary,
    panel({ kicker: "Curadoria", title: "Ordem dos destaques", trailing: saveBtn }, body),
  );
}

function featuredRow(uid, index) {
  const profile = state.profiles.get(uid) || { uid, nome: uid };
  return h(
    "article",
    { class: "list-card" },
    h("span", { class: "rank-badge" }, String(index + 1)),
    avatar(profile.foto, stringValue(profile.nome, uid)),
    h(
      "div",
      { class: "cell-stack" },
      h("strong", {}, stringValue(profile.nome, uid)),
      h("span", { class: "meta mono" }, uid),
    ),
    h(
      "div",
      { class: "row-actions" },
      iconButton("arrow_upward", { title: "Subir", onClick: () => move(uid, -1) }),
      iconButton("arrow_downward", { title: "Descer", onClick: () => move(uid, 1) }),
      iconButton("visibility", { title: "Abrir usuário", onClick: () => openUserDrawer(uid) }),
      iconButton("delete", { title: "Remover", onClick: () => remove(uid) }),
    ),
  );
}
