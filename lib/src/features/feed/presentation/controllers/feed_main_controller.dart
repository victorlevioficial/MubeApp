import '../../../../core/mixins/pagination_mixin.dart';
import '../../../../utils/app_performance_tracker.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/feed_repository.dart';
import '../../domain/feed_discovery.dart';
import '../../domain/feed_item.dart';
import '../feed_state.dart';

/// Runtime cache for the fully sorted discovery pool.
class FeedMainRuntime {
  List<FeedItem> allSortedUsers = [];
  bool hasLoadedPool = false;
  double? userLat;
  double? userLong;
}

/// Controller responsible for deterministic main feed pagination.
class FeedMainController {
  final FeedRepository _feedRepository;

  const FeedMainController({required FeedRepository feedRepository})
    : _feedRepository = feedRepository;

  Future<FeedState> fetchMainFeed({
    required FeedState currentState,
    required AppUser user,
    required List<String> blockedIds,
    required FeedMainRuntime runtime,
    required bool reset,
    required bool invalidatePool,
    required int batchSize,
  }) async {
    final mainFeedStopwatch = AppPerformanceTracker.startSpan(
      'feed.main_fetch',
      data: {'reset': reset, 'filter': currentState.currentFilter},
    );

    if (reset && invalidatePool) {
      runtime.allSortedUsers = [];
      runtime.hasLoadedPool = false;
    }

    try {
      if (!runtime.hasLoadedPool) {
        final poolResult = await _feedRepository.getDiscoverFeedPoolSorted(
          currentUserId: user.uid,
          userLat: runtime.userLat,
          userLong: runtime.userLong,
          excludedIds: blockedIds,
        );

        String? failureMessage;
        poolResult.fold((error) => failureMessage = error.message, (_) => null);
        if (failureMessage != null) {
          AppPerformanceTracker.finishSpan(
            'feed.main_fetch',
            mainFeedStopwatch,
            data: {'status': 'error', 'source': 'discover_pool'},
          );
          return currentState.copyWithFeed(
            status: PaginationStatus.error,
            errorMessage: failureMessage,
          );
        }

        runtime.allSortedUsers = poolResult.getOrElse((_) => const []);
        runtime.hasLoadedPool = true;
        AppPerformanceTracker.mark(
          'feed.main_pool.ready',
          data: {
            'pool_items': runtime.allSortedUsers.length,
            ..._diagnosticCounts(runtime.allSortedUsers, prefix: 'pool'),
          },
        );
      }

      final filteredItems = _applyCurrentFilter(
        runtime.allSortedUsers,
        currentState.currentFilter,
      );
      final page = reset ? 0 : currentState.currentPage;
      final startIndex = page * batchSize;

      if (startIndex >= filteredItems.length) {
        final baseState = reset
            ? currentState.copyWithFeed(items: [], currentPage: 0)
            : currentState;
        AppPerformanceTracker.finishSpan(
          'feed.main_fetch',
          mainFeedStopwatch,
          data: {
            'status': 'no_more_data',
            'items': baseState.items.length,
            'pool_items': runtime.allSortedUsers.length,
            'filtered_items': filteredItems.length,
            ..._diagnosticCounts(filteredItems, prefix: 'filtered'),
          },
        );
        return baseState.copyWithFeed(
          status: PaginationStatus.noMoreData,
          hasMore: false,
        );
      }

      final endIndex = (startIndex + batchSize).clamp(0, filteredItems.length);
      final nextSlice = filteredItems.sublist(startIndex, endIndex);
      final pagedItems = reset
          ? nextSlice
          : [...currentState.items, ...nextSlice];
      final hasMore = endIndex < filteredItems.length;

      AppPerformanceTracker.finishSpan(
        'feed.main_fetch',
        mainFeedStopwatch,
        data: {
          'status': hasMore ? 'loaded' : 'no_more_data',
          'items': pagedItems.length,
          'batch_items': nextSlice.length,
          'pool_items': runtime.allSortedUsers.length,
          'filtered_items': filteredItems.length,
          ..._diagnosticCounts(filteredItems, prefix: 'filtered'),
        },
      );

      return currentState.copyWithFeed(
        items: pagedItems,
        status: hasMore ? PaginationStatus.loaded : PaginationStatus.noMoreData,
        currentPage: page + 1,
        hasMore: hasMore,
      );
    } catch (error) {
      AppPerformanceTracker.finishSpan(
        'feed.main_fetch',
        mainFeedStopwatch,
        data: {'status': 'error', 'error_type': error.runtimeType.toString()},
      );
      return currentState.copyWithFeed(
        status: PaginationStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  List<FeedItem> _applyCurrentFilter(
    List<FeedItem> items,
    String currentFilter,
  ) {
    final filter = switch (currentFilter) {
      'Profissionais' => FeedDiscoveryFilter.professionals,
      'Bandas' => FeedDiscoveryFilter.bands,
      'Estúdios' => FeedDiscoveryFilter.studios,
      _ => FeedDiscoveryFilter.all,
    };

    return items
        .where((item) => FeedDiscovery.matchesFilter(item, filter))
        .toList(growable: false);
  }

  Map<String, Object> _diagnosticCounts(
    List<FeedItem> items, {
    required String prefix,
  }) {
    var professionals = 0;
    var artists = 0;
    var technicians = 0;
    var bands = 0;
    var studios = 0;
    var withoutDistance = 0;

    for (final item in items) {
      if (item.distanceKm == null) withoutDistance++;
      switch (item.tipoPerfil) {
        case 'profissional':
          professionals++;
          if (FeedDiscovery.isPureTechnician(item)) {
            technicians++;
          } else {
            artists++;
          }
          break;
        case 'banda':
          bands++;
          break;
        case 'estudio':
          studios++;
          break;
      }
    }

    return {
      '${prefix}_professionals': professionals,
      '${prefix}_artists': artists,
      '${prefix}_technicians': technicians,
      '${prefix}_bands': bands,
      '${prefix}_studios': studios,
      '${prefix}_without_distance': withoutDistance,
    };
  }
}
