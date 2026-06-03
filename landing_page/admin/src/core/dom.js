// Safe-by-construction DOM rendering for the admin panel.
//
// We never assign data into innerHTML. `h()` builds real DOM nodes and any
// string passed as a child becomes a TextNode, so the browser escapes it for
// us. This removes the entire class of HTML-escaping bugs that the legacy
// panel had (inconsistent escapeHtml / unescaped pill labels).

/**
 * Hyperscript element factory.
 * @param {string} tag
 * @param {object|null} props - class, style(object), dataset(object),
 *   on<Event> handlers, ref(fn), aria-*, boolean/string attributes.
 * @param {...*} children - Nodes, strings, numbers, arrays, or null/false (skipped).
 */
export function h(tag, props, ...children) {
  const node = document.createElement(tag);
  applyProps(node, props || {});
  append(node, children);
  return node;
}

function applyProps(node, props) {
  for (const key in props) {
    if (!Object.prototype.hasOwnProperty.call(props, key)) continue;
    const value = props[key];
    if (value == null || value === false) continue;

    if (key === "class" || key === "className") {
      node.className = value;
    } else if (key === "style" && typeof value === "object") {
      Object.assign(node.style, value);
    } else if (key === "dataset" && typeof value === "object") {
      Object.assign(node.dataset, value);
    } else if (key === "ref" && typeof value === "function") {
      value(node);
    } else if (key.startsWith("on") && typeof value === "function") {
      node.addEventListener(key.slice(2).toLowerCase(), value);
    } else if (value === true) {
      node.setAttribute(key, "");
    } else {
      node.setAttribute(key, String(value));
    }
  }
}

/** Append a (possibly nested) list of children to a node, skipping nullish. */
export function append(node, children) {
  for (const child of children.flat(Infinity)) {
    if (child == null || child === false || child === true) continue;
    node.appendChild(child instanceof Node ? child : document.createTextNode(String(child)));
  }
  return node;
}

/** Build a DocumentFragment from children. */
export function frag(...children) {
  return append(document.createDocumentFragment(), children);
}

/** Remove all children from a node. */
export function clear(node) {
  while (node.firstChild) node.removeChild(node.firstChild);
  return node;
}

/** Replace a node's contents with the given children. */
export function mount(parent, ...children) {
  clear(parent);
  return append(parent, children);
}

/** Material Icons Round glyph. The ligature text is safe as textContent. */
export function icon(name) {
  return h("span", { class: "material-icons-round", "aria-hidden": "true" }, name);
}
