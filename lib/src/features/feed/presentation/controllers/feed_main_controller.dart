import '../../../../core/errors/error_message_resolver.dart';
import '../../../../core/mixins/pagination_mixin.dart';
import '../../../../utils/app_performance_tracker.dart';
import '../../../auth/domain/app_user.dart';
import '../../../matchpoint/domain/matchpoint_availability.dart';
import '../../data/feed_repository.dart';
import '../../domain/feed_discovery.dart';
import '../../domain/feed_item.dart';
import '../feed_state.dart';

/// Runtime cache for the fully sorted discovery pool.
class FeedMainRuntime {
  List<FeedItem> allSortedUsers = [];
  bool hasLoadedPool = false;
  bool isPoolExhaustive = false;
  int loadedPoolTarget = 0;
  double? userLat;
  double? userLong;
}

/// Controller responsible for deterministic main feed pagination.
class FeedMainController {
  static const int _initialPoolPages = 2;
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
      runtime.isPoolExhaustive = false;
      runtime.loadedPoolTarget = 0;
    }

    try {
      var expandedPoolDuringFetch = false;
      if (!runtime.hasLoadedPool) {
        final failureMessage = await _loadDiscoveryPoolIntoRuntime(
          user: user,
          blockedIds: blockedIds,
          runtime: runtime,
          targetResults: _initialPoolTarget(batchSize),
          fastPartialThreshold: batchSize,
          markName: 'feed.main_pool.ready',
        );

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
      }

      var filteredItems = _applyCurrentFilter(
        runtime.allSortedUsers,
        currentState.currentFilter,
      );
      final page = reset ? 0 : currentState.currentPage;
      final startIndex = page * batchSize;

      while (_shouldExpandPool(
        filteredLength: filteredItems.length,
        startIndex: startIndex,
        batchSize: batchSize,
        runtime: runtime,
      )) {
        expandedPoolDuringFetch = true;
        final nextTarget = _nextPoolTarget(runtime, batchSize);
        final failureMessage = await _loadDiscoveryPoolIntoRuntime(
          user: user,
          blockedIds: blockedIds,
          runtime: runtime,
          targetResults: nextTarget,
          markName: 'feed.main_pool.expanded',
        );
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
        filteredItems = _applyCurrentFilter(
          runtime.allSortedUsers,
          currentState.currentFilter,
        );
      }

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
          : expandedPoolDuringFetch
          ? filteredItems.sublist(0, endIndex)
          : [...currentState.items, ...nextSlice];
      final hasMore =
          endIndex < filteredItems.length || _canExpandPool(runtime);

      AppPerformanceTracker.finishSpan(
        'feed.main_fetch',
        mainFeedStopwatch,
        data: {
          'status': hasMore ? 'loaded' : 'no_more_data',
          'items': pagedItems.length,
          'batch_items': nextSlice.length,
          'pool_items': runtime.allSortedUsers.length,
          'filtered_items': filteredItems.length,
          'expanded_pool': expandedPoolDuringFetch,
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
        errorMessage: resolveErrorMessage(error),
      );
    }
  }

  int _initialPoolTarget(int batchSize) {
    final target = batchSize * _initialPoolPages;
    return target.clamp(
      batchSize,
      FeedRepository.defaultDiscoverPoolTargetResults,
    );
  }

  int _nextPoolTarget(FeedMainRuntime runtime, int batchSize) {
    if (!_canExpandPool(runtime)) {
      return runtime.loadedPoolTarget;
    }

    final currentTarget = runtime.loadedPoolTarget > 0
        ? runtime.loadedPoolTarget
        : _initialPoolTarget(batchSize);
    final doubledTarget = currentTarget * 2;
    return doubledTarget.clamp(
      currentTarget,
      FeedRepository.defaultDiscoverPoolTargetResults,
    );
  }

  bool _canExpandPool(FeedMainRuntime runtime) {
    return !runtime.isPoolExhaustive &&
        runtime.loadedPoolTarget <
            FeedRepository.defaultDiscoverPoolTargetResults;
  }

  bool _shouldExpandPool({
    required int filteredLength,
    required int startIndex,
    required int batchSize,
    required FeedMainRuntime runtime,
  }) {
    if (!_canExpandPool(runtime)) return false;
    return (filteredLength - startIndex) < batchSize;
  }

  Future<String?> _loadDiscoveryPoolIntoRuntime({
    required AppUser user,
    required List<String> blockedIds,
    required FeedMainRuntime runtime,
    required int targetResults,
    required String markName,
    int? fastPartialThreshold,
  }) async {
    final poolResult = await _feedRepository.getDiscoverFeedPool(
      currentUserId: user.uid,
      userLat: runtime.userLat,
      userLong: runtime.userLong,
      excludedIds: blockedIds,
      targetResults: targetResults,
      fastPartialThreshold: fastPartialThreshold,
    );

    String? failureMessage;
    poolResult.fold((error) => failureMessage = error.message, (pool) {
      runtime.allSortedUsers = _filterMainDiscoveryItems(pool.items);
      runtime.hasLoadedPool = true;
      runtime.isPoolExhaustive = pool.isExhaustive;
      runtime.loadedPoolTarget = targetResults;
      AppPerformanceTracker.mark(
        markName,
        data: {
          'pool_items': runtime.allSortedUsers.length,
          'target_results': targetResults,
          'is_exhaustive': runtime.isPoolExhaustive,
          'can_expand_more': _canExpandPool(runtime),
          ..._diagnosticCounts(runtime.allSortedUsers, prefix: 'pool'),
        },
      );
    });

    return failureMessage;
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

    final filteredItems = items
        .where((item) => FeedDiscovery.matchesFilter(item, filter))
        .toList(growable: false);

    if (filter == FeedDiscoveryFilter.bands ||
        filter == FeedDiscoveryFilter.studios) {
      return filteredItems;
    }

    return filteredItems
        .where(_isEligibleForMainDiscovery)
        .toList(growable: false);
  }

  List<FeedItem> _filterMainDiscoveryItems(List<FeedItem> items) {
    return items.where(_isEligibleForMainDiscovery).toList(growable: false);
  }

  bool _isEligibleForMainDiscovery(FeedItem item) {
    if (item.tipoPerfil != 'profissional') return true;
    return !isSupportOnlyCategoryIds(item.subCategories);
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
