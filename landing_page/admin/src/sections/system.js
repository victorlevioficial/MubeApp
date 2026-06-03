// System: app config snapshots, transcode jobs, and raw Firestore/Storage
// explorers. Read-only inspection surfaces (parity with the legacy panel).
import { h, mount } from "../core/dom.js";
import { callFunction } from "../core/backend.js";
import { asArray, asObject, stringValue, toInteger, formatNumber, formatDateTime, prettyJson, getErrorMessage } from "../core/format.js";
import { sectionLead, panel, statePanel, button, badge, statTile } from "../ui/primitives.js";
import { openDrawer } from "../ui/Drawer.js";
import { handleError } from "../ui/toast.js";
import { openUserDrawer } from "./users.js";

const FS_LIMITS = [["10", "10"], ["25", "25"], ["50", "50"]];
const STORAGE_LIMITS = [["20", "20"], ["50", "50"], ["100", "100"]];

let cache = null;
let host = null;

export async function mountSystem(container, ctx = {}) {
  host = h("div", { class: "section-body" });
  mount(container, lead(), host);
  if (cache && !ctx.force) {
    render();
    return;
  }
  await load();
}

function lead() {
  return sectionLead("Infra e configuração", "Sistema", "Config do app, jobs de transcode e exploradores técnicos.");
}

async function load() {
  if (!host) return;
  mount(host, statePanel("loading", "Carregando dados de sistema…"));
  try {
    cache = await callFunction("getSystemAdminData", { limit: 40 });
    render();
  } catch (error) {
    mount(host, statePanel("error", getErrorMessage(error), { onRetry: load }));
  }
}

function render() {
  const data = asObject(cache);
  const config = asObject(data.config);
  const rootCollections = asArray(data.rootCollections);
  const jobs = asArray(data.transcodeJobs);

  const summary = h(
    "div",
    { class: "kpi-strip" },
    statTile({ iconName: "dataset", label: "Collections raiz", value: formatNumber(rootCollections.length) }),
    statTile({ iconName: "video_settings", label: "Jobs de transcode", value: formatNumber(jobs.length), tone: jobs.length > 0 ? "info" : "ok" }),
  );

  const configPanel = panel(
    { kicker: "Configuração", title: "Documentos de config" },
    h(
      "div",
      { class: "card-list" },
      configCard("Config app_data", asObject(config.appData)),
      configCard("Config featuredProfiles", asObject(config.featuredProfiles)),
      configCard("Config admin", asObject(config.admin)),
      h(
        "article",
        { class: "list-card" },
        h(
          "div",
          { class: "cell-stack" },
          h("strong", {}, "Collections raiz"),
          h("span", { class: "meta" }, rootCollections.map((c) => stringValue(c.path)).join(", ") || "Nenhuma collection retornada."),
        ),
      ),
    ),
  );

  const jobsPanel = panel(
    { kicker: "Pipeline de vídeo", title: "Jobs de transcode" },
    jobs.length ? h("div", { class: "card-list" }, ...jobs.map(transcodeCard)) : statePanel("empty", "Nenhum job de transcode retornado.", { icon: "video_library" }),
  );

  mount(
    host,
    summary,
    configPanel,
    jobsPanel,
    explorerPanel({
      title: "Explorador Firestore",
      kicker: "Inspeção",
      placeholder: "Ex.: users/UID ou conversations",
      limits: FS_LIMITS,
      onInspect: (path, limit) => callFunction("inspectFirestorePath", { path, limit }),
    }),
    explorerPanel({
      title: "Explorador Storage",
      kicker: "Inspeção",
      placeholder: "Ex.: profile_videos/UID",
      limits: STORAGE_LIMITS,
      onInspect: (prefix, limit) => callFunction("inspectStoragePrefix", { prefix, limit }),
    }),
  );
}

function configCard(title, snapshot) {
  const exists = snapshot.exists === true;
  return h(
    "article",
    { class: "list-card" },
    h(
      "div",
      { class: "cell-stack" },
      h("strong", {}, title),
      h("span", { class: "meta mono" }, stringValue(snapshot.path, "Sem path")),
    ),
    badge(exists ? "Disponível" : "Ausente", exists ? "processed" : "pending"),
    button("JSON", { variant: "ghost", icon: "data_object", onClick: () => openJson(title, stringValue(snapshot.path), snapshot) }),
  );
}

function transcodeCard(job) {
  const jobData = asObject(job.data);
  const uid = stringValue(jobData.userId);
  return h(
    "article",
    { class: "list-card list-card-col" },
    h(
      "div",
      { class: "list-card-head" },
      h(
        "div",
        { class: "cell-stack" },
        h("strong", {}, stringValue(job.id, "Job")),
        h("span", { class: "meta mono" }, stringValue(job.path, "Sem path")),
      ),
      badge(stringValue(jobData.status, "pending"), stringValue(jobData.status, "pending")),
    ),
    h(
      "div",
      { class: "row-actions" },
      h("span", { class: "meta" }, `Atualizado ${formatDateTime(jobData.updatedAt || jobData.updated_at)}`),
      uid ? button("Usuário", { variant: "ghost", icon: "person", onClick: () => openUserDrawer(uid) }) : null,
      button("JSON", { variant: "ghost", icon: "data_object", onClick: () => openJson(stringValue(job.id, "Transcode job"), stringValue(job.path), job) }),
    ),
  );
}

function explorerPanel({ title, kicker, placeholder, limits, onInspect }) {
  const input = h("input", {
    type: "text",
    placeholder,
    onKeydown: (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        run();
      }
    },
  });
  const limitSel = h("select", {}, ...limits.map(([value, label]) => h("option", { value }, label)));
  const resultHost = h("div", { class: "explorer-result" }, statePanel("empty", "Use o explorador para inspecionar caminhos.", { icon: "saved_search" }));

  const runBtn = button("Inspecionar", { variant: "secondary", icon: "travel_explore", onClick: run });

  async function run() {
    runBtn.disabled = true;
    mount(resultHost, statePanel("loading", "Inspecionando…"));
    try {
      const payload = await onInspect(input.value.trim(), Math.min(toInteger(limitSel.value, 10), 100));
      mount(
        resultHost,
        h("div", { class: "drawer-actions" }, button("Abrir JSON completo", { variant: "secondary", icon: "data_object", onClick: () => openJson(title, input.value.trim() || "(raiz)", payload) })),
        h("pre", { class: "code-block" }, prettyJson(payload)),
      );
    } catch (error) {
      mount(resultHost, statePanel("error", getErrorMessage(error), { onRetry: run }));
      handleError(error);
    } finally {
      runBtn.disabled = false;
    }
  }

  return panel(
    { kicker, title },
    h(
      "div",
      { class: "filter-bar" },
      h("label", { class: "field field-grow" }, h("span", {}, "Caminho"), input),
      h("label", { class: "field" }, h("span", {}, "Limite"), limitSel),
      runBtn,
    ),
    resultHost,
  );
}

function openJson(title, subtitle, data) {
  openDrawer({
    kicker: "Sistema",
    title,
    subtitle,
    content: h("pre", { class: "code-block" }, prettyJson(data)),
  });
}
