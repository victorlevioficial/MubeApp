import '../constants/app_constants.dart' as app_constants;
import '../core/domain/professional_roles.dart';
import 'category_normalizer.dart';

const String professionalRemoteRecordingFieldKey = 'fazGravacaoRemota';
const String professionalRemoteRecordingLabel = 'Gravação remota';
const String professionalRemoteRecordingCheckboxLabel =
    'Realizo gravações remotas para projetos à distância';

List<String> profileStringList(dynamic value) {
  if (value is Iterable) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  if (value is String) {
    final normalized = value.trim();
    return normalized.isEmpty ? const [] : <String>[normalized];
  }

  return const [];
}

final Map<String, String> _genreDisplayLabels = _buildDisplayLookup(
  app_constants.genres,
);
final Map<String, String> _instrumentDisplayLabels = _buildDisplayLookup(
  app_constants.instruments,
);
final Map<String, String> _studioServiceDisplayLabels = _buildDisplayLookup(
  app_constants.studioServices,
);
final Map<String, String> _roleDisplayLabels = {
  ..._buildDisplayLookup(app_constants.productionRoles),
  ..._buildDisplayLookup(app_constants.stageTechRoles),
  ..._buildDisplayLookup(app_constants.audiovisualRoles),
  ..._buildDisplayLookup(app_constants.educationRoles),
  ..._buildDisplayLookup(app_constants.luthierRoles),
  ..._buildDisplayLookup(app_constants.performanceRoles),
  ..._buildPrefixedDisplayLookup(
    'audiovisual',
    professionalAudiovisualRoleLabels,
  ),
  ..._buildPrefixedDisplayLookup('education', professionalEducationRoleLabels),
  ..._buildPrefixedDisplayLookup('luthier', professionalLuthierRoleLabels),
  ..._buildPrefixedDisplayLookup(
    'performance',
    professionalPerformanceRoleLabels,
  ),
};

String genreDisplayLabel(String rawGenre) =>
    _displayLookupOrFallback(rawGenre, _genreDisplayLabels);

List<String> genreDisplayLabels(Iterable<String> rawGenres) {
  return rawGenres.map(genreDisplayLabel).toList(growable: false);
}

String instrumentDisplayLabel(String rawInstrument) =>
    _displayLookupOrFallback(rawInstrument, _instrumentDisplayLabels);

List<String> instrumentDisplayLabels(Iterable<String> rawInstruments) {
  return rawInstruments.map(instrumentDisplayLabel).toList(growable: false);
}

String professionalRoleDisplayLabel(String rawRole) =>
    _displayLookupOrFallback(rawRole, _roleDisplayLabels);

List<String> professionalRoleDisplayLabels(Iterable<String> rawRoles) {
  return rawRoles.map(professionalRoleDisplayLabel).toList(growable: false);
}

String studioServiceDisplayLabel(String rawService) =>
    _displayLookupOrFallback(rawService, _studioServiceDisplayLabels);

List<String> studioServiceDisplayLabels(Iterable<String> rawServices) {
  return rawServices.map(studioServiceDisplayLabel).toList(growable: false);
}

bool professionalOffersRemoteRecording(Map<String, dynamic>? professionalData) {
  if (professionalData == null) return false;

  final categories = profileStringList(professionalData['categorias']);
  final roles = profileStringList(professionalData['funcoes']);

  final resolvedCategories = CategoryNormalizer.resolveCategories(
    rawCategories: categories,
    rawRoles: roles,
  );

  if (!resolvedCategories.contains('production')) {
    return false;
  }

  final rawValue = professionalData[professionalRemoteRecordingFieldKey];
  if (rawValue is bool) return rawValue;
  if (rawValue is String) {
    final normalized = rawValue.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'sim';
  }
  if (rawValue is num) return rawValue != 0;
  return false;
}

Map<String, String> _buildDisplayLookup(Iterable<String> labels) {
  final lookup = <String, String>{};
  for (final label in labels) {
    final normalized = CategoryNormalizer.sanitize(label);
    if (normalized.isEmpty) continue;
    lookup[label] = label;
    lookup[normalized] = label;
  }
  return lookup;
}

Map<String, String> _buildPrefixedDisplayLookup(
  String prefix,
  Iterable<String> labels,
) {
  final lookup = <String, String>{};
  for (final label in labels) {
    final normalized = CategoryNormalizer.sanitize(label);
    if (normalized.isEmpty) continue;
    lookup[label] = label;
    lookup[normalized] = label;
    lookup['${prefix}_$normalized'] = label;
  }
  return lookup;
}

String _displayLookupOrFallback(String rawValue, Map<String, String> lookup) {
  final trimmed = rawValue.trim();
  if (trimmed.isEmpty) return rawValue;

  final directMatch = lookup[trimmed];
  if (directMatch != null) return directMatch;

  final normalized = CategoryNormalizer.sanitize(trimmed);
  final normalizedMatch = lookup[normalized];
  if (normalizedMatch != null) return normalizedMatch;

  return _humanizeStoredValue(trimmed);
}

String _humanizeStoredValue(String rawValue) {
  final normalized = rawValue.trim().replaceAll('_', ' ');
  if (normalized.isEmpty) return rawValue;

  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(_humanizeStoredToken)
      .join(' ');
}

String _humanizeStoredToken(String token) {
  final lower = token.toLowerCase();

  switch (lower) {
    case 'dj':
    case 'edm':
    case 'mc':
    case 'mpb':
    case 'pa':
    case 'rf':
    case 'vj':
      return lower.toUpperCase();
    default:
      return token[0].toUpperCase() + token.substring(1).toLowerCase();
  }
}
