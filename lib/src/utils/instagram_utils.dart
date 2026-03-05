const String instagramLabelOptional = 'Instagram (opcional)';
const String instagramHint = '@seu_instagram';

/// Normalizes Instagram input to a canonical handle format.
///
/// Examples:
/// - `instagram.com/user` -> `@user`
/// - `@user.name` -> `@user.name`
/// - ` https://www.instagram.com/user/?hl=pt ` -> `@user`
String normalizeInstagramHandle(String? value) {
  var normalized = (value ?? '').trim();
  if (normalized.isEmpty) return '';

  normalized = normalized.replaceAll(RegExp(r'\s+'), '');
  normalized = normalized.replaceFirst(
    RegExp(r'^(https?:\/\/)?(www\.)?instagram\.com\/', caseSensitive: false),
    '',
  );
  normalized = normalized.replaceFirst(RegExp(r'^@+'), '');

  // Keep only the first path segment and remove URL fragments.
  normalized = normalized.split('/').first;
  normalized = normalized.split('?').first;
  normalized = normalized.split('#').first;

  final cleaned = normalized.replaceAll(RegExp(r'[^A-Za-z0-9._]'), '');
  if (cleaned.isEmpty) return '';
  return '@$cleaned';
}
