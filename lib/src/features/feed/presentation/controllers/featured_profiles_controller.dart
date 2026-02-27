import '../../../../utils/app_logger.dart';
import '../../data/featured_profiles_repository.dart';
import '../../domain/feed_item.dart';

/// Controller dedicado para carregar perfis em destaque configurados no admin.
class FeaturedProfilesController {
  final FeaturedProfilesRepository _repository;

  const FeaturedProfilesController({
    required FeaturedProfilesRepository repository,
  }) : _repository = repository;

  Future<List<FeedItem>> loadFeaturedProfiles() async {
    try {
      return await _repository.getFeaturedProfiles();
    } catch (error, stack) {
      AppLogger.error(
        'FeaturedProfilesController: erro ao carregar destaques',
        error,
        stack,
      );
      return const [];
    }
  }
}
