// Entry point: wires auth, builds the shell on login, and routes sections by
// URL hash. A failure in one section can never blank the whole panel — the
// activate() try/catch renders an error state in the content slot instead.
import { onAuth, ensureAdminAccess, signIn, signOutAdmin } from "./core/backend.js";
import { h, mount, icon } from "./core/dom.js";
import { getErrorMessage } from "./core/format.js";
import { createShell } from "./ui/Shell.js";
import { NAV, SECTIONS } from "./sections/index.js";
import { statePanel, button } from "./ui/primitives.js";
import { closeDrawer } from "./ui/Drawer.js";

const appRoot = document.getElementById("app");
let shell = null;
let activeSection = "dashboard";

function sectionFromHash() {
  const hash = (location.hash || "").replace(/^#/, "").trim();
  return SECTIONS[hash] ? hash : "dashboard";
}

function navigate(id) {
  if (!SECTIONS[id]) id = "dashboard";
  if (location.hash !== `#${id}`) {
    location.hash = id; // hashchange listener calls activate()
  } else {
    activate(id);
  }
}

async function activate(id, opts = {}) {
  if (!shell) return;
  if (!SECTIONS[id]) id = "dashboard";
  activeSection = id;
  shell.setActive(id);
  closeDrawer();
  try {
    await SECTIONS[id].mount(shell.content, { navigate, force: opts.force === true });
  } catch (error) {
    mount(shell.content, statePanel("error", getErrorMessage(error), { onRetry: () => activate(id, { force: true }) }));
  }
}

function buildShell(user) {
  shell = createShell({
    nav: NAV,
    sections: SECTIONS,
    adminEmail: user.email || "",
    onNavigate: navigate,
    onLogout: () => signOutAdmin().catch(() => null),
    onRefresh: () => activate(activeSection, { force: true }),
  });
  mount(appRoot, shell.el);
  activate(sectionFromHash(), { force: true });
}

function renderBoot(message) {
  mount(appRoot, h("div", { class: "boot-screen" }, statePanel("loading", message || "Carregando…")));
}

function renderLogin(message) {
  const email = h("input", { type: "email", placeholder: "voce@empresa.com", autocomplete: "username", required: true });
  const password = h("input", { type: "password", placeholder: "Sua senha", autocomplete: "current-password", required: true });
  const error = h("p", { class: "login-error" + (message ? "" : " is-hidden") }, message || "");
  const submit = button("Entrar", { variant: "primary", type: "submit", block: true });

  const form = h(
    "form",
    {
      class: "login-form",
      onSubmit: async (event) => {
        event.preventDefault();
        error.classList.add("is-hidden");
        submit.disabled = true;
        try {
          await signIn(email.value.trim(), password.value);
          // onAuth takes over from here.
        } catch (err) {
          error.textContent = getErrorMessage(err);
          error.classList.remove("is-hidden");
          submit.disabled = false;
        }
      },
    },
    h("label", { class: "field" }, h("span", {}, "Email"), email),
    h("label", { class: "field" }, h("span", {}, "Senha"), password),
    submit,
    error,
  );

  mount(
    appRoot,
    h(
      "div",
      { class: "login-screen" },
      h(
        "div",
        { class: "login-card" },
        h(
          "div",
          { class: "brand-lockup" },
          h("div", { class: "brand-badge" }, icon("graphic_eq")),
          h("div", {}, h("p", { class: "brand-kicker" }, "Acesso administrativo"), h("h2", {}, "Mube Admin")),
        ),
        form,
      ),
    ),
  );
}

async function onUser(user) {
  if (!user) {
    shell = null;
    renderLogin();
    return;
  }
  renderBoot("Validando acesso…");
  try {
    await ensureAdminAccess(user);
    buildShell(user);
  } catch (error) {
    await signOutAdmin().catch(() => null);
    renderLogin(getErrorMessage(error));
  }
}

window.addEventListener("hashchange", () => {
  if (!shell) return;
  const id = sectionFromHash();
  if (id !== activeSection) activate(id);
});

onAuth(onUser);
