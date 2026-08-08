import {
  buildGigSearchGrams,
  GIG_SEARCH_SCHEMA_VERSION,
  normalizeGigSearchText,
} from "../src/gig_search_index";

describe("gig search index", () => {
  test("normalizes Brazilian accents and punctuation", () => {
    expect(normalizeGigSearchText(" São José / MÚSICA! "))
      .toBe("sao jose musica");
  });

  test("indexes title, description and location with stable grams", () => {
    const grams = buildGigSearchGrams({
      title: "Sax",
      description: "Jazz",
      location: {label: "Niterói"},
    });

    expect(grams).toEqual(expect.arrayContaining([
      "s",
      "sa",
      "sax",
      "j",
      "ja",
      "jaz",
      "nit",
    ]));
    expect(grams).toEqual([...new Set(grams)].sort());
    expect(GIG_SEARCH_SCHEMA_VERSION).toBe(1);
  });

  test("caps indexed text to keep Firestore index entries bounded", () => {
    const uniqueTrigrams = buildGigSearchGrams({
      title: "a".repeat(3000),
      description: "ignored after the cap",
    });

    expect(uniqueTrigrams).toEqual(["a", "aa", "aaa"]);
  });
});
