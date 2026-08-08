export const GIG_SEARCH_SCHEMA_VERSION = 1;
const MAX_GIG_SEARCH_CHARACTERS = 2500;

function firstNonEmptyString(values: unknown[]): string {
  for (const value of values) {
    if (typeof value === "string" && value.trim().length > 0) {
      return value.trim();
    }
  }
  return "";
}

function asRecord(value: unknown): Record<string, unknown> {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value) ? value as Record<string, unknown> : {};
}

export function normalizeGigSearchText(value: string): string {
  return value
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

export function buildGigSearchGrams(
  data: Record<string, unknown>
): string[] {
  const location = asRecord(data.location);
  const source = normalizeGigSearchText([
    firstNonEmptyString([data.title]),
    firstNonEmptyString([data.description]),
    firstNonEmptyString([location.label]),
  ].join(" ")).slice(0, MAX_GIG_SEARCH_CHARACTERS);
  const grams = new Set<string>();
  for (let size = 1; size <= 3; size += 1) {
    if (source.length < size) break;
    for (let index = 0; index <= source.length - size; index += 1) {
      grams.add(source.slice(index, index + size));
    }
  }
  return [...grams].sort();
}
