// Canonical taxonomy for professional roles used across the UI (onboarding
// flow, edit-profile form, edit-profile controller) and by
// `professional_profile_utils.dart`.
//
// Note: the lists in `app_constants.{audiovisualRoles, educationRoles,
// luthierRoles, performanceRoles}` are LEGACY — preserved so
// `CategoryNormalizer` can still recognize older role IDs persisted in
// Firestore (dados antigos de cadastros antigos). The
// `professional<X>RoleLabels` lists defined in this module are the canonical
// source for the current UI and are intentionally NOT equal to the legacy
// lists in `app_constants.dart`.
import '../../constants/app_constants.dart' as app_constants;
import '../../utils/identifier_sanitizer.dart';

/// A single selectable professional role (id + label) within a section.
class ProfessionalRoleOption {
  final String id;
  final String label;

  const ProfessionalRoleOption({required this.id, required this.label});
}

/// A group of roles belonging to a given professional category.
class ProfessionalRoleSection {
  final String categoryId;
  final String title;
  final String subtitle;
  final List<ProfessionalRoleOption> options;

  const ProfessionalRoleSection({
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.options,
  });

  Map<String, String> get labelById => {
    for (final option in options) option.id: option.label,
  };
}

/// Canonical labels for the `audiovisual` category (UI source of truth).
const List<String> professionalAudiovisualRoleLabels = [
  'Direção de Vídeo',
  'Captação de Vídeo',
  'Edição de Vídeo',
  'Motion Design',
  'Operação de Câmera',
  'Streaming ao Vivo',
];

/// Canonical labels for the `education` category (UI source of truth).
const List<String> professionalEducationRoleLabels = [
  'Professor(a)',
  'Mentor(a)',
  'Oficineiro(a)',
  'Palestrante',
  'Coach Artístico',
  'Consultor(a)',
];

/// Canonical labels for the `luthier` category (UI source of truth).
const List<String> professionalLuthierRoleLabels = [
  'Ajuste e Regulagem',
  'Reparo',
  'Construção de Instrumentos',
  'Elétrica e Eletrônica',
  'Customização',
  'Encordoamento e Manutenção',
];

/// Canonical labels for the `performance` category (UI source of truth).
const List<String> professionalPerformanceRoleLabels = [
  'Performer',
  'Artista de Palco',
  'Intervenção Cênica',
  'Dança',
  'Live Act',
  'VJ / Visuals',
];

/// Categories whose genres input should be hidden from the UI.
const Set<String> professionalGenreHiddenCategories = {
  'audiovisual',
  'education',
  'luthier',
};

/// Categories that render a role-selector section (and require at least one
/// role to be selected for validation to pass).
const Set<String> professionalRoleCategoriesWithSelectors = {
  'production',
  'stage_tech',
  'audiovisual',
  'education',
  'luthier',
  'performance',
};

/// Ordered list of role sections used by the UI (onboarding and edit profile).
final List<ProfessionalRoleSection> professionalRoleSections = [
  ProfessionalRoleSection(
    categoryId: 'production',
    title: 'Produção Musical *',
    subtitle: 'Quais funções de produção você desempenha?',
    options: _buildPlainRoleOptions(app_constants.productionRoles),
  ),
  ProfessionalRoleSection(
    categoryId: 'stage_tech',
    title: 'Técnica de Palco *',
    subtitle: 'Quais funções técnicas de palco você desempenha?',
    options: _buildPlainRoleOptions(app_constants.stageTechRoles),
  ),
  ProfessionalRoleSection(
    categoryId: 'audiovisual',
    title: 'Audiovisual *',
    subtitle: 'Selecione suas funções em vídeo e conteúdo visual',
    options: _buildPrefixedRoleOptions(
      'audiovisual',
      professionalAudiovisualRoleLabels,
    ),
  ),
  ProfessionalRoleSection(
    categoryId: 'education',
    title: 'Educação *',
    subtitle: 'Selecione suas funções ligadas a ensino e mentoria',
    options: _buildPrefixedRoleOptions(
      'education',
      professionalEducationRoleLabels,
    ),
  ),
  ProfessionalRoleSection(
    categoryId: 'luthier',
    title: 'Luthier *',
    subtitle: 'Selecione suas funções de construção e manutenção',
    options: _buildPrefixedRoleOptions(
      'luthier',
      professionalLuthierRoleLabels,
    ),
  ),
  ProfessionalRoleSection(
    categoryId: 'performance',
    title: 'Performance *',
    subtitle: 'Selecione suas funções de presença cênica e live acts',
    options: _buildPrefixedRoleOptions(
      'performance',
      professionalPerformanceRoleLabels,
    ),
  ),
];

/// Quick lookup of a section by its `categoryId`.
final Map<String, ProfessionalRoleSection> professionalRoleSectionByCategoryId =
    {
      for (final section in professionalRoleSections)
        section.categoryId: section,
    };

/// Lookup from label|sanitized label|id to canonical role id.
final Map<String, String> professionalRoleIdLookup = _buildRoleIdLookup();

/// Lookup from role id to the `categoryId` it belongs to.
final Map<String, String> professionalRoleCategoryById =
    _buildRoleCategoryById();

// ---------------------------------------------------------------------------
// Reconciled aliases — single source of truth for `CategoryNormalizer`.
//
// Before PR 8, `CategoryNormalizer` kept six private maps built locally from
// `app_constants.{audiovisual,education,luthier,performance,production,
// stageTech}Roles`. That duplicated the taxonomy: any new role added to
// `professional_roles.dart` had to be mirrored manually inside the
// normalizer to be recognized. The structures below centralise the
// canonical IDs (production / stage_tech) and the legacy IDs preserved in
// `app_constants` for older Firestore documents — `CategoryNormalizer`
// consumes them directly.
// ---------------------------------------------------------------------------

/// Canonical IDs that identify a Production role. Includes every
/// label in `app_constants.productionRoles` (sanitized) plus the historical
/// aliases that older clients persisted directly.
final Set<String> professionalProductionRoleIds = {
  for (final label in app_constants.productionRoles) sanitizeIdentifier(label),
  'produtor',
  'diretor_musical',
};

/// Canonical IDs that identify a Stage-Tech role. Mirrors
/// [professionalProductionRoleIds] for `app_constants.stageTechRoles`.
final Set<String> professionalStageTechRoleIds = {
  for (final label in app_constants.stageTechRoles) sanitizeIdentifier(label),
  'backline_tech',
};

/// Sanitized lookup of role IDs → canonical role ID. Combines:
/// - production / stage_tech IDs (non-prefixed) from `app_constants`;
/// - legacy audiovisual / education / luthier / performance IDs preserved
///   in `app_constants` for older Firestore documents;
/// - manual historical aliases ('produtor', 'diretor_musical',
///   'backline_tech').
///
/// The current UI labels (audiovisual_*, education_*, luthier_*,
/// performance_*) are NOT included here on purpose: those ids are emitted
/// pre-prefixed by the role pickers, and `normalizeRoleId` already returns
/// any sanitized input unchanged when no alias matches.
final Map<String, String> professionalRoleAliasLookup = _buildRoleAliasLookup();

Map<String, String> _buildRoleAliasLookup() {
  final lookup = <String, String>{};

  void addIdentity(Iterable<String> labels) {
    for (final label in labels) {
      final id = sanitizeIdentifier(label);
      if (id.isEmpty) continue;
      lookup[id] = id;
    }
  }

  addIdentity(app_constants.productionRoles);
  addIdentity(app_constants.stageTechRoles);
  addIdentity(app_constants.audiovisualRoles);
  addIdentity(app_constants.educationRoles);
  addIdentity(app_constants.luthierRoles);
  addIdentity(app_constants.performanceRoles);

  // Manual aliases that older clients used but never appeared in the
  // canonical label lists.
  lookup['produtor'] = 'produtor';
  lookup['diretor_musical'] = 'diretor_musical';
  lookup['backline_tech'] = 'backline_tech';

  return lookup;
}

List<ProfessionalRoleOption> _buildPlainRoleOptions(List<String> labels) {
  return labels
      .map(
        (label) =>
            ProfessionalRoleOption(id: sanitizeIdentifier(label), label: label),
      )
      .toList(growable: false);
}

List<ProfessionalRoleOption> _buildPrefixedRoleOptions(
  String prefix,
  List<String> labels,
) {
  return labels
      .map(
        (label) => ProfessionalRoleOption(
          id: '${prefix}_${sanitizeIdentifier(label)}',
          label: label,
        ),
      )
      .toList(growable: false);
}

String _professionalRoleId(String label, {String? prefix}) {
  final normalized = sanitizeIdentifier(label);
  return prefix == null ? normalized : '${prefix}_$normalized';
}

Map<String, String> _buildRoleIdLookup() {
  final lookup = <String, String>{};

  void addRoles(String categoryId, List<String> labels, {String? prefix}) {
    for (final label in labels) {
      final roleId = _professionalRoleId(label, prefix: prefix);
      lookup[roleId] = roleId;
      lookup[label] = roleId;
      lookup[sanitizeIdentifier(label)] = roleId;
    }
  }

  addRoles('production', app_constants.productionRoles);
  addRoles('stage_tech', app_constants.stageTechRoles);
  addRoles(
    'audiovisual',
    professionalAudiovisualRoleLabels,
    prefix: 'audiovisual',
  );
  addRoles('education', professionalEducationRoleLabels, prefix: 'education');
  addRoles('luthier', professionalLuthierRoleLabels, prefix: 'luthier');
  addRoles(
    'performance',
    professionalPerformanceRoleLabels,
    prefix: 'performance',
  );

  return lookup;
}

Map<String, String> _buildRoleCategoryById() {
  final map = <String, String>{};

  void addRoles(String categoryId, List<String> labels, {String? prefix}) {
    for (final label in labels) {
      final roleId = _professionalRoleId(label, prefix: prefix);
      map[roleId] = categoryId;
    }
  }

  addRoles('production', app_constants.productionRoles);
  addRoles('stage_tech', app_constants.stageTechRoles);
  addRoles(
    'audiovisual',
    professionalAudiovisualRoleLabels,
    prefix: 'audiovisual',
  );
  addRoles('education', professionalEducationRoleLabels, prefix: 'education');
  addRoles('luthier', professionalLuthierRoleLabels, prefix: 'luthier');
  addRoles(
    'performance',
    professionalPerformanceRoleLabels,
    prefix: 'performance',
  );

  return map;
}
