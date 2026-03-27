import 'package:diacritic/diacritic.dart';

import '../constants/app_constants.dart';

abstract final class CategoryNormalizer {
  static final Map<String, String> _categoryAliases = <String, String>{
    'singer': 'singer',
    'cantor': 'singer',
    'cantora': 'singer',
    'cantor_a': 'singer',
    'vocalista': 'singer',
    'instrumentalist': 'instrumentalist',
    'instrumentista': 'instrumentalist',
    'dj': 'dj',
    'production': 'production',
    'producao_musical': 'production',
    'produtor': 'production',
    'produtor_musical': 'production',
    'stage_tech': 'stage_tech',
    'tecnica_de_palco': 'stage_tech',
    'tecnico_de_palco': 'stage_tech',
    'crew': 'crew',
    'equipe_tecnica': 'crew',
    'equipe_tecnico': 'crew',
    'tecnico': 'crew',
    'tecnica': 'crew',
    'audiovisual': 'audiovisual',
    'audio_visual': 'audiovisual',
    'education': 'education',
    'educacao': 'education',
    'luthier': 'luthier',
    'performance': 'performance',
    'performer': 'performance',
  };

  static final Map<String, String> _productionRoleAliases = _buildRoleAliases(
    productionRoles,
    legacyAliases: const {
      'produtor': 'produtor',
      'diretor_musical': 'diretor_musical',
    },
  );
  static final Map<String, String> _stageTechRoleAliases = _buildRoleAliases(
    stageTechRoles,
    legacyAliases: const {'backline_tech': 'backline_tech'},
  );
  static final Map<String, String> _audiovisualRoleAliases = _buildRoleAliases(
    audiovisualRoles,
  );
  static final Map<String, String> _educationRoleAliases = _buildRoleAliases(
    educationRoles,
  );
  static final Map<String, String> _luthierRoleAliases = _buildRoleAliases(
    luthierRoles,
  );
  static final Map<String, String> _performanceRoleAliases = _buildRoleAliases(
    performanceRoles,
  );

  static const Set<String> _newGenreOptionalCategories = <String>{
    'audiovisual',
    'education',
    'luthier',
  };
  static const Set<String> _legacyHomeMatchpointCategories = <String>{
    'singer',
    'instrumentalist',
    'dj',
    'production',
    'stage_tech',
    'crew',
  };

  static String sanitize(String value) {
    return removeDiacritics(value)
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String normalizeCategoryId(String raw) {
    final sanitized = sanitize(raw);
    if (sanitized.isEmpty) return '';
    return _categoryAliases[sanitized] ?? sanitized;
  }

  static String normalizeRoleId(String raw) {
    final sanitized = sanitize(raw);
    if (sanitized.isEmpty) return '';

    return _productionRoleAliases[sanitized] ??
        _stageTechRoleAliases[sanitized] ??
        _audiovisualRoleAliases[sanitized] ??
        _educationRoleAliases[sanitized] ??
        _luthierRoleAliases[sanitized] ??
        _performanceRoleAliases[sanitized] ??
        sanitized;
  }

  static List<String> resolveCategories({
    required List<String> rawCategories,
    required List<String> rawRoles,
  }) {
    final normalizedCategories = rawCategories
        .map(normalizeCategoryId)
        .where((item) => item.isNotEmpty)
        .toSet();
    final normalizedRoles = rawRoles
        .map(normalizeRoleId)
        .where((item) => item.isNotEmpty)
        .toSet();

    final resolved = <String>{};
    for (final category in normalizedCategories) {
      switch (category) {
        case 'singer':
        case 'instrumentalist':
        case 'dj':
        case 'production':
        case 'stage_tech':
          resolved.add(category);
          break;
        case 'crew':
          final hasProduction = normalizedRoles.any(isProductionRoleId);
          final hasStageTech = normalizedRoles.any(isStageTechRoleId);
          if (hasProduction) resolved.add('production');
          if (hasStageTech) resolved.add('stage_tech');
          if (!hasProduction && !hasStageTech) {
            resolved.add('crew');
          }
          break;
        default:
          resolved.add(category);
      }
    }

    return resolved.toList(growable: false);
  }

  static bool isProductionRoleId(String roleId) =>
      _productionRoleAliases.containsValue(roleId);

  static bool isStageTechRoleId(String roleId) =>
      _stageTechRoleAliases.containsValue(roleId);

  static bool isProductionRole(String rawRole) =>
      isProductionRoleId(normalizeRoleId(rawRole));

  static bool isStageTechRole(String rawRole) =>
      isStageTechRoleId(normalizeRoleId(rawRole));

  static List<String> filterProductionRoles(List<String> rawRoles) {
    return rawRoles.where(isProductionRole).toList(growable: false);
  }

  static List<String> filterStageTechRoles(List<String> rawRoles) {
    return rawRoles.where(isStageTechRole).toList(growable: false);
  }

  static bool isPureTechnician({
    required List<String> rawCategories,
    required List<String> rawRoles,
  }) {
    final resolved = resolveCategories(
      rawCategories: rawCategories,
      rawRoles: rawRoles,
    ).toSet();

    final hasStageTech = resolved.contains('stage_tech');
    final hasMusician =
        resolved.contains('singer') ||
        resolved.contains('instrumentalist') ||
        resolved.contains('dj') ||
        resolved.contains('production');

    return hasStageTech && !hasMusician;
  }

  static bool shouldRequireGenres({
    required List<String> rawCategories,
    required List<String> rawRoles,
  }) {
    final resolved = resolveCategories(
      rawCategories: rawCategories,
      rawRoles: rawRoles,
    ).toSet();

    if (resolved.isEmpty) return true;
    return !resolved.every(_newGenreOptionalCategories.contains);
  }

  static bool isEligibleForHomeAndMatchpoint({
    required List<String> rawCategories,
    required List<String> rawRoles,
  }) {
    final resolved = resolveCategories(
      rawCategories: rawCategories,
      rawRoles: rawRoles,
    ).toSet();

    if (resolved.isEmpty) return false;

    if (resolved.any(_legacyHomeMatchpointCategories.contains)) {
      return true;
    }

    return false;
  }

  static Map<String, String> _buildRoleAliases(
    List<String> labels, {
    Map<String, String> legacyAliases = const {},
  }) {
    return {
      for (final label in labels) sanitize(label): sanitize(label),
      ...legacyAliases,
    };
  }
}
