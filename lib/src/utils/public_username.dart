import 'package:diacritic/diacritic.dart';

const int minPublicUsernameLength = 3;
const int maxPublicUsernameLength = 24;

final RegExp _publicUsernamePattern = RegExp(
  r'^[a-z0-9](?:[a-z0-9._]{1,22}[a-z0-9])$',
);

String normalizePublicUsername(String raw) {
  var normalized = removeDiacritics(raw.trim().toLowerCase());

  if (normalized.startsWith('@')) {
    normalized = normalized.substring(1);
  }

  normalized = normalized
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll(RegExp(r'[^a-z0-9._]'), '');

  return normalized;
}

String? normalizedPublicUsernameOrNull(String? raw) {
  if (raw == null) return null;
  final normalized = normalizePublicUsername(raw);
  return normalized.isEmpty ? null : normalized;
}

bool isValidPublicUsername(String raw) {
  final normalized = normalizePublicUsername(raw);
  if (normalized.length < minPublicUsernameLength ||
      normalized.length > maxPublicUsernameLength) {
    return false;
  }

  return _publicUsernamePattern.hasMatch(normalized);
}

String? validatePublicUsername(String? raw, {bool allowEmpty = true}) {
  final normalized = normalizedPublicUsernameOrNull(raw);
  if (normalized == null) {
    return allowEmpty ? null : 'Escolha um @usuario.';
  }

  if (normalized.length < minPublicUsernameLength) {
    return 'Use pelo menos 3 caracteres.';
  }

  if (normalized.length > maxPublicUsernameLength) {
    return 'Use no maximo 24 caracteres.';
  }

  if (!_publicUsernamePattern.hasMatch(normalized)) {
    return 'Use apenas letras, numeros, "." ou "_" e evite simbolos no inicio ou fim.';
  }

  return null;
}

String publicUsernameHandle(String username) =>
    '@${normalizePublicUsername(username)}';
