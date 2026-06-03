// App shell: collapsible sidebar (off-canvas on mobile) + topbar + content slot.
// Navigation is grouped; the active item exposes aria-current=page.
import { h, icon } from "../core/dom.js";
import { button } from "./primitives.js";

export function createShell({ nav, sections, adminEmail, onNavigate, onLogout, onRefresh }) {
  const navButtons = new Map();

  const navEl = h(
    "nav",
    { class: "sidebar-nav", "aria-label": "Navegação principal" },
    ...nav.map((groupDef) =>
      h(
        "div",
        { class: "nav-group" },
        h("p", { class: "nav-group-label" }, groupDef.group),
        ...groupDef.items.map((id) => {
          const meta = sections[id];
          const btn = h(
            "button",
            { class: "nav-item", type: "button", onClick: () => onNavigate(id) },
            icon(meta.icon || "circle"),
            h("span", {}, meta.title),
            meta.isNew ? h("span", { class: "nav-tag" }, "novo") : null,
          );
          navButtons.set(id, btn);
          return btn;
        }),
      ),
    ),
  );

  const sidebar = h(
    "aside",
    { class: "sidebar" },
    h(
      "div",
      { class: "sidebar-brand" },
      h("div", { class: "brand-badge" }, icon("graphic_eq")),
      h("div", {}, h("p", { class: "brand-kicker" }, "Mube"), h("strong", {}, "Admin")),
    ),
    navEl,
    h(
      "div",
      { class: "sidebar-foot" },
      h("div", { class: "admin-chip" }, icon("verified_user"), h("span", { class: "admin-email" }, adminEmail || "")),
      button("Sair", { variant: "ghost", icon: "logout", block: true, onClick: onLogout }),
    ),
  );

  const scrim = h("div", { class: "sidebar-scrim", onClick: closeSidebar });

  const pageKicker = h("p", { class: "page-kicker" }, "");
  const pageTitle = h("h1", { class: "page-title" }, "");
  const menuBtn = h(
    "button",
    { class: "icon-btn menu-btn", type: "button", "aria-label": "Abrir menu", onClick: openSidebar },
    icon("menu"),
  );

  const topbar = h(
    "header",
    { class: "topbar" },
    h("div", { class: "topbar-main" }, menuBtn, h("div", {}, pageKicker, pageTitle)),
    h(
      "div",
      { class: "topbar-actions" },
      button("Atualizar", { variant: "secondary", icon: "refresh", onClick: onRefresh }),
    ),
  );

  const content = h("main", { class: "content", id: "section-content", tabindex: "-1" });
  const shellMain = h("div", { class: "shell-main" }, topbar, content);
  const el = h("div", { class: "admin-shell" }, scrim, sidebar, shellMain);

  function openSidebar() {
    el.classList.add("sidebar-open");
  }
  function closeSidebar() {
    el.classList.remove("sidebar-open");
  }

  function setActive(id) {
    navButtons.forEach((btn, key) => {
      const active = key === id;
      btn.classList.toggle("is-active", active);
      if (active) btn.setAttribute("aria-current", "page");
      else btn.removeAttribute("aria-current");
    });
    const meta = sections[id];
    if (meta) {
      pageTitle.textContent = meta.title;
      pageKicker.textContent = meta.kicker || "";
    }
    closeSidebar();
  }

  return { el, content, setActive, closeSidebar };
}
