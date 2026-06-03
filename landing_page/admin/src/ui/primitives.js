// Reusable UI primitives. All data goes through h() children, so labels are
// escaped by construction (fixes the legacy unescaped-pill bug).
import { h, frag, icon } from "../core/dom.js";
import { initialOf, sanitizeKey, stringValue } from "../core/format.js";

export function button(label, opts = {}) {
  const { variant = "secondary", icon: ic, onClick, type = "button", disabled = false, title, dataset, block = false } = opts;
  return h(
    "button",
    { class: `btn btn-${variant}${block ? " btn-block" : ""}`, type, disabled, title, dataset, onClick },
    ic ? icon(ic) : null,
    label ? h("span", {}, label) : null,
  );
}

export function iconButton(iconName, opts = {}) {
  const { onClick, label, title, dataset } = opts;
  return h(
    "button",
    { class: "icon-btn", type: "button", "aria-label": label || title || "Ação", title: title || label, dataset, onClick },
    icon(iconName),
  );
}

/** Avatar that falls back to the name initial when the image fails to load. */
export function avatar(photoUrl, label, opts = {}) {
  const { round = true } = opts;
  const cls = "avatar" + (round ? " is-round" : "");
  const fallback = () => h("div", { class: cls + " avatar-fallback" }, initialOf(label));
  if (!photoUrl) return fallback();
  const img = h("img", { class: cls, src: photoUrl, alt: label || "Avatar", loading: "lazy" });
  img.addEventListener("error", () => img.replaceWith(fallback()));
  return img;
}

export function badge(label, variant) {
  return h("span", { class: `badge badge-${sanitizeKey(variant || label)}` }, label);
}

export function pill(label, variant) {
  return h("span", { class: "pill" + (variant ? ` pill-${sanitizeKey(variant)}` : "") }, label);
}

export const mono = (value) => h("span", { class: "mono" }, value);

/** Distinct loading / empty / error states (error is announced + retryable). */
export function statePanel(kind, message, opts = {}) {
  const iconName = kind === "loading" ? "hourglass_top" : kind === "error" ? "error_outline" : opts.icon || "inbox";
  const children = [icon(iconName), h("p", {}, message)];
  if (kind === "error" && typeof opts.onRetry === "function") {
    children.push(button("Tentar de novo", { variant: "secondary", icon: "refresh", onClick: opts.onRetry }));
  }
  return h("div", { class: `state-panel is-${kind}`, role: kind === "error" ? "alert" : "status" }, ...children);
}

/** Section header with eyebrow, title, optional description and actions. */
export function sectionLead(eyebrow, title, description, actions) {
  return h(
    "header",
    { class: "section-lead" },
    h(
      "div",
      { class: "section-lead-copy" },
      eyebrow ? h("span", { class: "eyebrow" }, eyebrow) : null,
      h("h2", {}, title),
      description ? h("p", {}, description) : null,
    ),
    actions ? h("div", { class: "section-lead-actions" }, ...(Array.isArray(actions) ? actions : [actions])) : null,
  );
}

export function panel(opts, ...children) {
  const { kicker, title, trailing } = opts || {};
  const head =
    kicker || title || trailing
      ? h(
          "div",
          { class: "panel-head" },
          h("div", {}, kicker ? h("p", { class: "panel-kicker" }, kicker) : null, title ? h("h3", {}, title) : null),
          trailing || null,
        )
      : null;
  return h("article", { class: "panel" }, head, ...children);
}

/** Key/value grid. Container queries adapt columns to the panel width. */
export function kvGrid(pairs) {
  return h(
    "dl",
    { class: "kv-grid" },
    ...pairs
      .filter(Boolean)
      .map(([label, value]) => frag(h("dt", {}, label), h("dd", {}, value == null || value === "" ? "—" : value))),
  );
}

/** Kebab menu for low-frequency actions. Uses <details> for free a11y toggle. */
export function kebab(actions) {
  const items = (actions || []).filter(Boolean);
  if (!items.length) return null;
  const menu = h(
    "div",
    { class: "kebab-menu", role: "menu" },
    ...items.map((a) =>
      h(
        "button",
        {
          class: "kebab-item" + (a.variant === "danger" ? " is-danger" : ""),
          type: "button",
          role: "menuitem",
          onClick: (event) => {
            const details = event.currentTarget.closest("details");
            if (details) details.open = false;
            if (typeof a.onClick === "function") a.onClick(event);
          },
        },
        a.icon ? icon(a.icon) : null,
        h("span", {}, a.label),
      ),
    ),
  );
  return h(
    "details",
    { class: "kebab" },
    h("summary", { class: "icon-btn", "aria-label": "Mais ações", title: "Mais ações" }, icon("more_vert")),
    menu,
  );
}

/** A KPI tile: big value + label + optional trend hint. */
export function statTile(opts) {
  const { value, label, hint, iconName, tone } = opts;
  return h(
    "article",
    { class: "stat-tile" + (tone ? ` tone-${sanitizeKey(tone)}` : "") },
    iconName ? icon(iconName) : null,
    h("strong", {}, stringValue(value, "0")),
    h("span", { class: "stat-label" }, label),
    hint ? h("span", { class: "stat-hint" }, hint) : null,
  );
}
