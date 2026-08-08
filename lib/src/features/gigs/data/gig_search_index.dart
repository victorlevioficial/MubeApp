const int gigSearchSchemaVersion = 1;
const int _maxIndexedSearchCharacters = 2500;

String normalizeGigSearchText(String value) {
  const replacements = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };

  final lower = value.trim().toLowerCase();
  final folded = lower.split('').map((character) {
    return replacements[character] ?? character;
  }).join();
  return folded
      .replaceAll(RegExp('[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String buildGigSearchText({
  required String title,
  required String description,
  Map<String, dynamic>? location,
}) {
  final normalized = normalizeGigSearchText(
    [title, description, location?['label']?.toString() ?? ''].join(' '),
  );
  if (normalized.length <= _maxIndexedSearchCharacters) return normalized;
  return normalized.substring(0, _maxIndexedSearchCharacters);
}

List<String> buildGigSearchGrams({
  required String title,
  required String description,
  Map<String, dynamic>? location,
}) {
  final source = buildGigSearchText(
    title: title,
    description: description,
    location: location,
  );
  final grams = <String>{};
  for (var size = 1; size <= 3; size++) {
    if (source.length < size) break;
    for (var index = 0; index <= source.length - size; index++) {
      grams.add(source.substring(index, index + size));
    }
  }
  final result = grams.toList(growable: false)..sort();
  return result;
}

String gigSearchLookupGram(String term) {
  final normalized = normalizeGigSearchText(term);
  if (normalized.isEmpty) return '';
  return normalized.substring(0, normalized.length < 3 ? normalized.length : 3);
}
