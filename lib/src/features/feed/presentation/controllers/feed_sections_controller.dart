import '../../../../utils/app_performance_tracker.dart';
import '../../domain/feed_discovery.dart';
import '../../domain/feed_item.dart';
import '../../domain/feed_section.dart';

/// Builds home sections from the already-sorted discovery pool.
class FeedSectionsController {
  const FeedSectionsController();

  Map<FeedSectionType, List<FeedItem>> buildSections({
    required List<FeedItem> allItems,
    required int sectionLimit,
  }) {
    final sections = {
      FeedSectionType.technicians: _takeFiltered(
        allItems,
        FeedDiscoveryFilter.technicians,
        sectionLimit,
      ),
      FeedSectionType.bands: _takeFiltered(
        allItems,
        FeedDiscoveryFilter.bands,
        sectionLimit,
      ),
      FeedSectionType.studios: _takeFiltered(
        allItems,
        FeedDiscoveryFilter.studios,
        sectionLimit,
      ),
    };
    AppPerformanceTracker.mark(
      'feed.sections.built',
      data: {
        'source_items': allItems.length,
        'technicians': sections[FeedSectionType.technicians]?.length ?? 0,
        'bands': sections[FeedSectionType.bands]?.length ?? 0,
        'studios': sections[FeedSectionType.studios]?.length ?? 0,
      },
    );
    return sections;
  }

  List<FeedItem> _takeFiltered(
    List<FeedItem> allItems,
    FeedDiscoveryFilter filter,
    int limit,
  ) {
    return allItems
        .where((item) => FeedDiscovery.matchesFilter(item, filter))
        .take(limit)
        .toList(growable: false);
  }
}
