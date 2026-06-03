// Responsive data list. One DOM, two layouts driven purely by CSS:
//   >=768px : aligned columns (grid) with a visible header row, like a table
//   <768px  : each row collapses into a stacked card; cells show their label
//             via data-label (CSS ::before). No fixed min-width, so it never
//             overflows the viewport on a phone (the legacy table bug).
// ARIA roles (table/row/columnheader/cell) keep it semantic for screen readers.
import { h } from "../core/dom.js";
import { stringValue } from "../core/format.js";
import { statePanel } from "./primitives.js";

function gridStyle(columns) {
  return { "grid-template-columns": columns.map((c) => c.width || "minmax(0, 1fr)").join(" ") };
}

/**
 * @param {object} opts
 * @param {Array<{key?:string,label:string,render?:(row)=>(Node|string),width?:string}>} opts.columns
 * @param {Array<object>} opts.rows
 * @param {(row)=>void} [opts.onRowClick]
 * @param {string} [opts.emptyMessage]
 */
export function dataList(opts) {
  const { columns, rows, onRowClick, emptyMessage = "Nada por aqui ainda." } = opts;
  if (!rows || !rows.length) return statePanel("empty", emptyMessage);

  const header = h(
    "div",
    { class: "dl-row dl-head", role: "row", style: gridStyle(columns) },
    ...columns.map((c) => h("div", { class: "dl-cell", role: "columnheader" }, c.label)),
  );

  const body = rows.map((row) => {
    const cells = columns.map((c) =>
      h(
        "div",
        { class: "dl-cell", role: "cell", dataset: { label: c.label } },
        c.render ? c.render(row) : stringValue(row[c.key], "—"),
      ),
    );
    return h(
      "div",
      {
        class: "dl-row" + (onRowClick ? " is-clickable" : ""),
        role: "row",
        style: gridStyle(columns),
        tabindex: onRowClick ? "0" : null,
        onClick: onRowClick ? () => onRowClick(row) : null,
        onKeydown: onRowClick
          ? (event) => {
              if (event.key === "Enter" || event.key === " ") {
                event.preventDefault();
                onRowClick(row);
              }
            }
          : null,
      },
      ...cells,
    );
  });

  return h("div", { class: "data-list", role: "table" }, header, ...body);
}
