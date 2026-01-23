import 'package:diacritic/diacritic.dart';

/// Normalizes text for search purposes.
///
/// - Converts to lowercase
/// - Removes accents/diacritics
/// - Trims whitespace
/// - Collapses multiple spaces
///
/// Example: `normalizeText("João Silva ") -> "joao silva"`
String normalizeText(String? input) {
  if (input == null || input.isEmpty) return '';

  return removeDiacritics(
    input,
  ).toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// Normalizes a list of strings for search/comparison.
///
/// - Normalizes each item using [normalizeText]
/// - Removes empty strings
/// - Removes duplicates
///
/// Example: `normalizeList([" Rock ", "ROCK", "rock"]) -> ["rock"]`
List<String> normalizeList(List<String>? input) {
  if (input == null || input.isEmpty) return [];

  return input.map(normalizeText).where((s) => s.isNotEmpty).toSet().toList();
}

/// Checks if any item in [list] starts with [prefix].
///
/// Both are normalized before comparison.
bool listContainsPrefix(List<String> list, String prefix) {
  final normalizedPrefix = normalizeText(prefix);
  if (normalizedPrefix.isEmpty) return true;

  return list.any((item) => normalizeText(item).startsWith(normalizedPrefix));
}

/// Checks if [list] contains any of the [targets].
///
/// Both are normalized before comparison.
bool listContainsAny(List<String> list, List<String> targets) {
  if (targets.isEmpty) return true;

  final normalizedList = normalizeList(list);
  final normalizedTargets = normalizeList(targets);

  return normalizedTargets.any((t) => normalizedList.contains(t));
}
