import '../../../../constants/firestore_constants.dart';
import '../../../../core/typedefs.dart';
import '../../../../utils/app_performance_tracker.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/feed_repository.dart';
import '../../domain/feed_item.dart';
import '../../domain/feed_section.dart';

/// Controller especializado nas seções horizontais do feed.
class FeedSectionsController {
  final FeedRepository _feedRepository;

  const FeedSectionsController({required FeedRepository feedRepository})
    : _feedRepository = feedRepository;

  Future<Map<FeedSectionType, List<FeedItem>>> fetchSections({
    required AppUser user,
    required List<String> blockedIds,
    required double? userLat,
    required double? userLong,
    required int sectionLimit,
  }) async {
    final sectionsStopwatch = AppPerformanceTracker.startSpan(
      'feed.sections_fetch',
    );
    final items = <FeedSectionType, List<FeedItem>>{};

    Future<List<FeedItem>> fetchOrEmpty(
      FutureResult<List<FeedItem>> call,
    ) async {
      final result = await call;
      return result.getOrElse((_) => []);
    }

    if (userLat != null && userLong != null) {
      final results = await Future.wait<List<FeedItem>>([
        fetchOrEmpty(
          _feedRepository.getTechnicians(
            currentUserId: user.uid,
            excludedIds: blockedIds,
            userLat: userLat,
            userLong: userLong,
            limit: sectionLimit,
          ),
        ),
        fetchOrEmpty(
          _feedRepository.getAllUsersSortedByDistance(
            currentUserId: user.uid,
            userLat: userLat,
            userLong: userLong,
            filterType: ProfileType.band,
            userGeohash: user.geohash,
            excludedIds: blockedIds,
            limit: sectionLimit * 3,
          ),
        ),
        fetchOrEmpty(
          _feedRepository.getAllUsersSortedByDistance(
            currentUserId: user.uid,
            userLat: userLat,
            userLong: userLong,
            filterType: ProfileType.studio,
            userGeohash: user.geohash,
            excludedIds: blockedIds,
            limit: sectionLimit * 3,
          ),
        ),
      ]);
      items[FeedSectionType.technicians] = results[0];
      items[FeedSectionType.bands] = results[1].take(sectionLimit).toList();
      items[FeedSectionType.studios] = results[2].take(sectionLimit).toList();
    } else {
      final results = await Future.wait<List<FeedItem>>([
        fetchOrEmpty(
          _feedRepository.getTechnicians(
            currentUserId: user.uid,
            excludedIds: blockedIds,
            userLat: userLat,
            userLong: userLong,
            limit: sectionLimit,
          ),
        ),
        fetchOrEmpty(
          _feedRepository.getUsersByType(
            type: ProfileType.band,
            currentUserId: user.uid,
            excludedIds: blockedIds,
            userLat: userLat,
            userLong: userLong,
            limit: sectionLimit,
          ),
        ),
        fetchOrEmpty(
          _feedRepository.getUsersByType(
            type: ProfileType.studio,
            currentUserId: user.uid,
            excludedIds: blockedIds,
            userLat: userLat,
            userLong: userLong,
            limit: sectionLimit,
          ),
        ),
      ]);
      items[FeedSectionType.technicians] = results[0];
      items[FeedSectionType.bands] = results[1];
      items[FeedSectionType.studios] = results[2];
    }

    AppPerformanceTracker.finishSpan(
      'feed.sections_fetch',
      sectionsStopwatch,
      data: {
        'technicians': items[FeedSectionType.technicians]?.length ?? 0,
        'bands': items[FeedSectionType.bands]?.length ?? 0,
        'studios': items[FeedSectionType.studios]?.length ?? 0,
      },
    );
    return items;
  }
}
