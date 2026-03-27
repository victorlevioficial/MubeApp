import '../../../constants/firestore_constants.dart';
import '../../../utils/category_normalizer.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';

const Set<String> _supportOnlyProfessionalCategoryIds = <String>{
  'audiovisual',
  'audio_visual',
  'educacao',
  'education',
  'luthier',
  'luthieria',
  'performance',
};

const Set<String> _artisticallyEligibleCategoryIds = <String>{
  'singer',
  'instrumentalist',
  'dj',
  'production',
};

/// Returns `true` when the category set is only made of the new support
/// subcategories and does not include any artistically eligible signal.
bool isSupportOnlyCategoryIds(Iterable<String> categoryIds) {
  final normalized = _normalizeCategoryIds(categoryIds);
  if (normalized.isEmpty) return false;
  return normalized.every(_supportOnlyProfessionalCategoryIds.contains);
}

/// Returns `true` when a professional profile still has an artistic signal.
///
/// This keeps legacy behavior intact for singers, instrumentalists, DJs and
/// production profiles while excluding the new support-only subcategories.
bool isArtisticallyEligibleCategoryIds(Iterable<String> categoryIds) {
  final normalized = _normalizeCategoryIds(categoryIds);
  return normalized.any(_artisticallyEligibleCategoryIds.contains);
}

bool isSupportOnlyProfessionalCategories({
  required Iterable<String> rawCategories,
  required Iterable<String> rawRoles,
}) {
  final resolved = _resolveProfessionalCategories(
    rawCategories: rawCategories,
    rawRoles: rawRoles,
  );
  return isSupportOnlyCategoryIds(resolved);
}

bool isArtisticallyEligibleProfessionalCategories({
  required Iterable<String> rawCategories,
  required Iterable<String> rawRoles,
}) {
  final resolved = _resolveProfessionalCategories(
    rawCategories: rawCategories,
    rawRoles: rawRoles,
  );
  return isArtisticallyEligibleCategoryIds(resolved);
}

/// MatchPoint is available for bands and for professional profiles that are
/// not support-only.
bool isMatchpointAvailableForType(
  AppUserType? userType, {
  required Iterable<String> rawCategories,
  required Iterable<String> rawRoles,
}) {
  return isMatchpointAvailableForProfileType(
    userType?.id,
    rawCategories: rawCategories,
    rawRoles: rawRoles,
  );
}

/// String-based variant used by Firestore-backed code paths.
bool isMatchpointAvailableForProfileType(
  String? profileType, {
  required Iterable<String> rawCategories,
  required Iterable<String> rawRoles,
}) {
  if (profileType == ProfileType.band) return true;
  if (profileType != ProfileType.professional) return false;

  return !isSupportOnlyProfessionalCategories(
    rawCategories: rawCategories,
    rawRoles: rawRoles,
  );
}

bool isMatchpointAvailableForUser(AppUser? user) {
  if (user == null) return false;

  final professional = user.dadosProfissional;
  final rawCategories = <String>[];
  final rawRoles = <String>[];

  final categories = professional?['categorias'] as List?;
  if (categories != null) {
    rawCategories.addAll(categories.whereType<String>());
  }

  final legacyCategory = professional?['categoria'];
  if (legacyCategory is String && legacyCategory.isNotEmpty) {
    rawCategories.add(legacyCategory);
  }

  final roles = professional?['funcoes'] as List?;
  if (roles != null) {
    rawRoles.addAll(roles.whereType<String>());
  }

  return isMatchpointAvailableForType(
    user.tipoPerfil,
    rawCategories: rawCategories,
    rawRoles: rawRoles,
  );
}

Set<String> _resolveProfessionalCategories({
  required Iterable<String> rawCategories,
  required Iterable<String> rawRoles,
}) {
  return CategoryNormalizer.resolveCategories(
    rawCategories: rawCategories.toList(growable: false),
    rawRoles: rawRoles.toList(growable: false),
  ).map(CategoryNormalizer.normalizeCategoryId).toSet();
}

Set<String> _normalizeCategoryIds(Iterable<String> categoryIds) {
  return categoryIds
      .map(CategoryNormalizer.normalizeCategoryId)
      .where((id) => id.isNotEmpty)
      .toSet();
}
