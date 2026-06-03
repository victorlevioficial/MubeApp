// Accessible toast: role=status + aria-live so screen readers announce it.
import { h, clear } from "../core/dom.js";
import { getErrorMessage } from "../core/format.js";

let toastEl = null;
let timer = null;

function ensureToast() {
  if (toastEl) return toastEl;
  toastEl = h("div", { class: "toast is-hidden", role: "status", "aria-live": "polite" });
  document.body.appendChild(toastEl);
  return toastEl;
}

export function showToast(message, kind = "success") {
  const el = ensureToast();
  clearTimeout(timer);
  clear(el);
  el.appendChild(document.createTextNode(message));
  el.className = `toast is-${kind}`;
  // Force reflow so the enter transition replays on repeated toasts.
  void el.offsetWidth;
  el.classList.add("is-visible");
  timer = window.setTimeout(() => {
    el.classList.remove("is-visible");
    el.classList.add("is-hidden");
  }, 3600);
}

/** Standard error sink: log for ops, surface a friendly message to the user. */
export function handleError(error) {
  console.error("[Mube Admin]", error);
  showToast(getErrorMessage(error), "error");
}
