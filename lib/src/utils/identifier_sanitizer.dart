import 'package:diacritic/diacritic.dart';

/// Lower-cases [value], strips diacritics and collapses any non
/// alphanumeric run into single underscores. Used to derive stable
/// identifiers from human-readable labels (role/category/genre names).
///
/// Lives in `utils/` as a neutral helper so both `CategoryNormalizer`
/// and `core/domain/professional_roles.dart` can depend on it without
/// creating an import cycle.
String sanitizeIdentifier(String value) {
  return removeDiacritics(value)
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}
