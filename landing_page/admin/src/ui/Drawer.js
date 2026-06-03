// Accessible detail drawer (side panel on desktop, bottom-sheet on mobile).
// role=dialog + aria-modal + focus trap + Escape/scrim to close. A single
// reusable instance; contents are replaced per open() and cleared on close.
import { h, mount, clear, icon } from "../core/dom.js";

const FOCUSABLE = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])';

let root = null;
let panel = null;
let kickerEl;
let titleEl;
let subtitleEl;
let bodyEl;
let lastFocused = null;
let keyHandler = null;

function build() {
  if (root) return;
  kickerEl = h("p", { class: "drawer-kicker" });
  titleEl = h("h2", { id: "drawer-title" });
  subtitleEl = h("p", { class: "drawer-subtitle" });
  bodyEl = h("div", { class: "drawer-body" });

  panel = h(
    "aside",
    { class: "drawer-panel", role: "dialog", "aria-modal": "true", "aria-labelledby": "drawer-title" },
    h(
      "header",
      { class: "drawer-header" },
      h("div", { class: "drawer-heading" }, kickerEl, titleEl, subtitleEl),
      h("button", { class: "icon-btn", type: "button", "aria-label": "Fechar", onClick: closeDrawer }, icon("close")),
    ),
    bodyEl,
  );

  root = h(
    "div",
    { class: "drawer-root is-hidden" },
    h("div", { class: "drawer-scrim", onClick: closeDrawer }),
    panel,
  );
  document.body.appendChild(root);
}

/**
 * @param {object} opts
 * @param {string} opts.kicker
 * @param {string} opts.title
 * @param {string} [opts.subtitle]
 * @param {Node} [opts.content] - used when `tabs` is not provided
 * @param {Array<{label:string, content:Node|(()=>Node)}>} [opts.tabs]
 */
export function openDrawer(opts = {}) {
  build();
  lastFocused = document.activeElement;
  kickerEl.textContent = opts.kicker || "Detalhes";
  titleEl.textContent = opts.title || "";
  subtitleEl.textContent = opts.subtitle || "";
  subtitleEl.style.display = opts.subtitle ? "" : "none";

  if (opts.tabs && opts.tabs.length) {
    mount(bodyEl, renderTabs(opts.tabs));
  } else {
    mount(bodyEl, opts.content || h("div"));
  }

  root.classList.remove("is-hidden");
  document.body.classList.add("no-scroll");

  keyHandler = (event) => {
    if (event.key === "Escape") closeDrawer();
    else if (event.key === "Tab") trapFocus(event);
  };
  document.addEventListener("keydown", keyHandler);

  requestAnimationFrame(() => {
    const first = panel.querySelector(FOCUSABLE);
    if (first) first.focus();
  });
}

export function closeDrawer() {
  if (!root || root.classList.contains("is-hidden")) return;
  root.classList.add("is-hidden");
  document.body.classList.remove("no-scroll");
  if (keyHandler) document.removeEventListener("keydown", keyHandler);
  keyHandler = null;
  clear(bodyEl);
  if (lastFocused && typeof lastFocused.focus === "function") lastFocused.focus();
}

function trapFocus(event) {
  const focusables = panel.querySelectorAll(FOCUSABLE);
  if (!focusables.length) return;
  const first = focusables[0];
  const last = focusables[focusables.length - 1];
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}

function renderTabs(tabs) {
  const host = h("div", { class: "tab-panel" });
  const buttons = [];

  function activate(index) {
    buttons.forEach((b, i) => {
      const active = i === index;
      b.classList.toggle("is-active", active);
      b.setAttribute("aria-selected", active ? "true" : "false");
    });
    const content = tabs[index].content;
    mount(host, typeof content === "function" ? content() : content);
  }

  const tablist = h(
    "div",
    { class: "tablist", role: "tablist" },
    ...tabs.map((tab, i) => {
      const b = h("button", { class: "tab", type: "button", role: "tab", onClick: () => activate(i) }, tab.label);
      buttons.push(b);
      return b;
    }),
  );

  const wrap = h("div", { class: "tabs" }, tablist, host);
  activate(0);
  return wrap;
}
