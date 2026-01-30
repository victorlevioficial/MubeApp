import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/app_config_repository.dart';
import '../domain/app_config.dart';

part 'app_config_provider.g.dart';

/// Provider que carrega e disponibiliza as configurações do app
@Riverpod(keepAlive: true)
Future<AppConfig> appConfig(Ref ref) async {
  final repository = ref.watch(appConfigRepositoryProvider);
  return repository.fetchConfig();
}

/// Helpers para acesso direto às listas (retorna labels como strings para compatibilidade)
@riverpod
List<String> genreLabels(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.maybeWhen(
    data: (c) => c.genres.map((g) => g.label).toList(),
    orElse: () => [],
  );
}

@riverpod
List<String> instrumentLabels(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.maybeWhen(
    data: (c) => c.instruments.map((i) => i.label).toList(),
    orElse: () => [],
  );
}

@riverpod
List<String> crewRoleLabels(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.maybeWhen(
    data: (c) => c.crewRoles.map((r) => r.label).toList(),
    orElse: () => [],
  );
}

@riverpod
List<String> studioServiceLabels(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return config.maybeWhen(
    data: (c) => c.studioServices.map((s) => s.label).toList(),
    orElse: () => [],
  );
}

/// Helper para matching inteligente (verifica aliases)
@riverpod
bool canMatch(
  Ref ref, {
  required String userTag,
  required String targetTag,
  required String type,
}) {
  if (userTag == targetTag) return true;

  final config = ref.watch(appConfigProvider);
  return config.maybeWhen(
    data: (c) {
      List<ConfigItem> list;
      if (type == 'genre') {
        list = c.genres;
      } else if (type == 'instrument') {
        list = c.instruments;
      } else {
        return false;
      }

      final userItem = list.firstWhere(
        (g) => g.label == userTag || g.id == userTag,
        orElse: () => const ConfigItem(id: '', label: ''),
      );
      final targetItem = list.firstWhere(
        (g) => g.label == targetTag || g.id == targetTag,
        orElse: () => const ConfigItem(id: '', label: ''),
      );

      // Se não achou items, não tem match
      if (userItem.id.isEmpty || targetItem.id.isEmpty) return false;

      // Check aliases bidirectional
      if (userItem.aliases.contains(targetItem.id)) return true;
      if (targetItem.aliases.contains(userItem.id)) return true;

      return false;
    },
    orElse: () => false,
  );
}
