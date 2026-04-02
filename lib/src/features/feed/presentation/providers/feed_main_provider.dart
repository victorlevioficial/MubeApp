import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/error_message_resolver.dart';
import '../../../../core/mixins/pagination_mixin.dart';
import '../../../../utils/app_performance_tracker.dart';
import '../../../auth/domain/app_user.dart';
import '../../../matchpoint/domain/matchpoint_availability.dart';
import '../../data/feed_repository.dart';
import '../../domain/feed_discovery.dart';
import '../../domain/feed_item.dart';
import '../feed_state.dart';

part 'feed_main_provider.g.dart';

/// Provider que gerencia o feed principal com paginação determinística.
///
/// Substitui o antigo `FeedMainController` + `FeedMainRuntime` por um
/// Notifier Riverpod gerenciado, permitindo testes e reuso sem
/// instanciação manual.
@Riverpod(keepAlive: true)
class FeedMain extends _$FeedMain {
  static const int _initialPoolPages = 2;

  final List<FeedItem> _allSortedUsers = [];
  bool _hasLoadedPool = false;
  bool _isPoolExhaustive = false;
  int _loadedPoolTarget = 0;
  double? _userLat;
  double? _userLong;
  String? _poolUserId;
  String _poolBlockedKey = '';

  @override
  FeedState build() {
    return const FeedState();
  }

  Future<FeedState> fetch({
    required FeedState currentState,
    required AppUser user,
    required List<String> blockedIds,
    required bool reset,
    required bool forceInvalidatePool,
    required int batchSize,
  }) async {
    final mainFeedStopwatch = AppPerformanceTracker.startSpan(
      'feed.main_fetch',
      data: {'reset': reset, 'filter': currentState.currentFilter},
    );

    if (reset && forceInvalidatePool) {
      _allSortedUsers.clear();
      _hasLoadedPool = false;
      _isPoolExhaustive = false;
      _loadedPoolTarget = 0;
    }

    final nextUserLat = (user.location?['lat'] as num?)?.toDouble();
    final nextUserLong = (user.location?['lng'] as num?)?.toDouble();
    final nextBlockedKey = _buildBlockedIdsKey(blockedIds);
    final shouldInvalidatePool =
        forceInvalidatePool ||
        !_hasLoadedPool ||
        _poolUserId != user.uid ||
        _poolBlockedKey != nextBlockedKey ||
        _userLat != nextUserLat ||
        _userLong != nextUserLong;

    _poolUserId = user.uid;
    _poolBlockedKey = nextBlockedKey;
    _userLat = nextUserLat;
    _userLong = nextUserLong;

    if (shouldInvalidatePool) {
      _allSortedUsers.clear();
      _hasLoadedPool = false;
      _isPoolExhaustive = false;
      _loadedPoolTarget = 0;
    }

    try {
      var expandedPoolDuringFetch = false;
      if (!_hasLoadedPool) {
        final failureMessage = await _loadDiscoveryPool(
          user: user,
          blockedIds: blockedIds,
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
        _allSortedUsers,
        currentState.currentFilter,
      );
      final page = reset ? 0 : currentState.currentPage;
      final startIndex = page * batchSize;

      while (_shouldExpandPool(
        filteredLength: filteredItems.length,
        startIndex: startIndex,
        batchSize: batchSize,
      )) {
        expandedPoolDuringFetch = true;
        final nextTarget = _nextPoolTarget();
        final failureMessage = await _loadDiscoveryPool(
          user: user,
          blockedIds: blockedIds,
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
          _allSortedUsers,
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
            'pool_items': _allSortedUsers.length,
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
      final hasMore = endIndex < filteredItems.length || _canExpandPool();

      AppPerformanceTracker.finishSpan(
        'feed.main_fetch',
        mainFeedStopwatch,
        data: {
          'status': hasMore ? 'loaded' : 'no_more_data',
          'items': pagedItems.length,
          'batch_items': nextSlice.length,
          'pool_items': _allSortedUsers.length,
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

  int _nextPoolTarget() {
    if (!_canExpandPool()) {
      return _loadedPoolTarget;
    }

    final currentTarget = _loadedPoolTarget > 0
        ? _loadedPoolTarget
        : _initialPoolTarget(FeedDataConstants.mainFeedBatchSize);
    final doubledTarget = currentTarget * 2;
    return doubledTarget.clamp(
      currentTarget,
      FeedRepository.defaultDiscoverPoolTargetResults,
    );
  }

  bool _canExpandPool() {
    return !_isPoolExhaustive &&
        _loadedPoolTarget < FeedRepository.defaultDiscoverPoolTargetResults;
  }

  bool _shouldExpandPool({
    required int filteredLength,
    required int startIndex,
    required int batchSize,
  }) {
    if (!_canExpandPool()) return false;
    return (filteredLength - startIndex) < batchSize;
  }

  Future<String?> _loadDiscoveryPool({
    required AppUser user,
    required List<String> blockedIds,
    required int targetResults,
    required String markName,
    int? fastPartialThreshold,
  }) async {
    final repository = ref.read(feedRepositoryProvider);
    final poolResult = await repository.getDiscoverFeedPool(
      currentUserId: user.uid,
      userLat: _userLat,
      userLong: _userLong,
      excludedIds: blockedIds,
      targetResults: targetResults,
      fastPartialThreshold: fastPartialThreshold,
    );

    String? failureMessage;
    poolResult.fold((error) => failureMessage = error.message, (pool) {
      _allSortedUsers.clear();
      _allSortedUsers.addAll(_filterMainDiscoveryItems(pool.items));
      _hasLoadedPool = true;
      _isPoolExhaustive = pool.isExhaustive;
      _loadedPoolTarget = targetResults;
      AppPerformanceTracker.mark(
        markName,
        data: {
          'pool_items': _allSortedUsers.length,
          'target_results': targetResults,
          'is_exhaustive': _isPoolExhaustive,
          'can_expand_more': _canExpandPool(),
          ..._diagnosticCounts(_allSortedUsers, prefix: 'pool'),
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

  String _buildBlockedIdsKey(List<String> blockedIds) {
    if (blockedIds.isEmpty) return '';
    final sortedIds = [...blockedIds]..sort();
    return sortedIds.join('|');
  }
}

/// Constants for feed data fetching.
abstract final class FeedDataConstants {
  static const int sectionLimit = 10;
  static const int mainFeedBatchSize = 20;
}
