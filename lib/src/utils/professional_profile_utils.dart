import 'category_normalizer.dart';

const String professionalRemoteRecordingFieldKey = 'fazGravacaoRemota';
const String professionalRemoteRecordingLabel = 'Gravação remota';
const String professionalRemoteRecordingCheckboxLabel =
    'Realizo gravações remotas para projetos à distância';

bool professionalOffersRemoteRecording(Map<String, dynamic>? professionalData) {
  if (professionalData == null) return false;

  final categories =
      (professionalData['categorias'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false);
  final roles = (professionalData['funcoes'] as List<dynamic>? ?? const [])
      .map((item) => item.toString())
      .toList(growable: false);

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
