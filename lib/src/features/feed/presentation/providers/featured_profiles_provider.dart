import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/featured_profiles_repository.dart';
import '../../domain/feed_item.dart';

part 'featured_profiles_provider.g.dart';

/// Provider que carrega os perfis em destaque do admin.
///
/// Substitui o antigo `FeaturedProfilesController` por um provider Riverpod
/// gerenciado, permitindo testes e reuso sem instanciacao manual.
@Riverpod(keepAlive: true)
Future<List<FeedItem>> featuredProfiles(Ref ref) {
  final repository = ref.watch(featuredProfilesRepositoryProvider);
  return repository.getFeaturedProfiles();
}
