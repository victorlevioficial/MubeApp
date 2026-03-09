import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/mixins/pagination_mixin.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../favorites/domain/favorite_controller.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../data/featured_profiles_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/spotlight_rotation.dart';
import 'controllers/featured_profiles_controller.dart';
import 'controllers/feed_main_controller.dart';
import 'controllers/feed_sections_controller.dart';
import 'feed_state.dart';

export 'feed_state.dart';

part 'feed_controller.g.dart';

/// Constants for feed data fetching.
abstract final class FeedDataConstants {
  static const int sectionLimit = 10;
  static const int mainFeedBatchSize = 20;
}

@Riverpod(keepAlive: true)
class FeedController extends _$FeedController {
  final FeedMainRuntime _mainRuntime = FeedMainRuntime();
  List<FeedItem> _manualFeaturedItems = [];
  List<FeedItem> _spotlightItems = [];
  bool _blockedUsersListenerRegistered = false;
  Timer? _favoritesSyncTimer;
  Future<void>? _featuredProfilesLoad;
  Future<void>? _activeLoadAllData;
  Future<void>? _activeRefresh;

  FeedSectionsController? _sectionsController;
  FeedMainController? _mainController;
  FeaturedProfilesController? _featuredProfilesController;

  FeedState _withSpotlightItems(FeedState currentState) {
    _spotlightItems = SpotlightRotation.build(
      priorityItems: _manualFeaturedItems,
      candidateItems: _mainRuntime.allSortedUsers,
    );
    return currentState.copyWithFeed(featuredItems: _spotlightItems);
  }

  void _ensureControllers() {
    final feedRepository = ref.read(feedRepositoryProvider);
    _sectionsController ??= const FeedSectionsController();
    _mainController ??= FeedMainController(feedRepository: feedRepository);
  }

  FeaturedProfilesController _getFeaturedProfilesController() {
    return _featuredProfilesController ??= FeaturedProfilesController(
      repository: ref.read(featuredProfilesRepositoryProvider),
    );
  }

  void _registerBlockedUsersListener() {
    if (_blockedUsersListenerRegistered) return;
    _blockedUsersListenerRegistered = true;
    ref.listen<AsyncValue<List<String>>>(blockedUsersProvider, (
      previous,
      next,
    ) {
      if (previous == null) return;
      if (previous.asData?.value == next.asData?.value) return;
      if (!next.hasValue) return;
      unawaited(loadAllData());
    });
  }

  @override
  FutureOr<FeedState> build() {
    _ensureControllers();
    _registerBlockedUsersListener();
    ref.onDispose(() {
      _favoritesSyncTimer?.cancel();
    });
    // Data is loaded manually via loadAllData().
    return const FeedState();
  }

  /// Initial full load for feed screen.
  Future<void> loadAllData() async {
    final existingLoad = _activeLoadAllData;
    if (existingLoad != null) {
      AppPerformanceTracker.mark(
        'feed.load_all_data.reused',
        data: {'reason': 'already_in_progress'},
      );
      await existingLoad;
      return;
    }

    final loadFuture = _loadData(showFullSkeleton: true);
    _activeLoadAllData = loadFuture;
    try {
      await loadFuture;
    } finally {
      if (identical(_activeLoadAllData, loadFuture)) {
        _activeLoadAllData = null;
      }
    }
  }

  Future<void> _loadData({required bool showFullSkeleton}) async {
    final loadStopwatch = AppPerformanceTracker.startSpan(
      'feed.load_all_data',
      data: {'full_skeleton': showFullSkeleton},
    );
    _ensureControllers();

    final currentState = state.value ?? const FeedState();
    state = AsyncValue.data(
      currentState.copyWithFeed(
        isInitialLoading: showFullSkeleton,
        clearError: true,
      ),
    );

    // Keep favorite sync away from first paint.
    _scheduleFavoritesSync();
    _loadFeaturedProfilesInBackground();

    try {
      final user = await _resolveCurrentUserProfile();
      if (!ref.mounted) return;

      if (user != null) {
        _mainRuntime.userLat = (user.location?['lat'] as num?)?.toDouble();
        _mainRuntime.userLong = (user.location?['lng'] as num?)?.toDouble();
      }

      List<String>? blockedIds;
      if (user != null) {
        blockedIds = await _resolveBlockedIds(user: user);
        if (!ref.mounted) return;
      }

      await _fetchMainFeed(
        reset: true,
        preserveExistingItems: !showFullSkeleton,
        userOverride: user,
        blockedIdsOverride: blockedIds,
      );
      if (!ref.mounted) return;

      if (showFullSkeleton) {
        final latestState = state.value ?? currentState;
        state = AsyncValue.data(
          latestState.copyWithFeed(isInitialLoading: false),
        );
      }
      final latestState = state.value ?? const FeedState();
      AppPerformanceTracker.finishSpan(
        'feed.load_all_data',
        loadStopwatch,
        data: {
          'items': latestState.items.length,
          'sections': latestState.sectionItems.length,
          'status': latestState.status.name,
        },
      );
    } catch (error, stack) {
      AppLogger.error('Feed: erro ao carregar dados iniciais', error, stack);
      AppPerformanceTracker.finishSpan(
        'feed.load_all_data',
        loadStopwatch,
        data: {'status': 'error', 'error_type': error.runtimeType.toString()},
      );
      if (!ref.mounted) return;
      final latestState = state.value ?? currentState;
      state = AsyncValue.data(
        latestState.copyWithFeed(
          isInitialLoading: false,
          status: PaginationStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _loadFeaturedProfilesInBackground() {
    _featuredProfilesLoad ??= _loadFeaturedProfiles();
  }

  Future<void> _loadFeaturedProfiles() async {
    final featuredStopwatch = AppPerformanceTracker.startSpan(
      'feed.featured_profiles',
    );
    var featuredStatus = 'done';
    try {
      if (Firebase.apps.isEmpty) {
        featuredStatus = 'skipped';
        return;
      }

      final featured = await _getFeaturedProfilesController()
          .loadFeaturedProfiles();
      if (!ref.mounted) return;
      _manualFeaturedItems = featured;
      AppLogger.debug(
        'FeedController: featured profiles carregados: ${featured.length}',
      );
      final currentState = state.value ?? const FeedState();
      state = AsyncValue.data(_withSpotlightItems(currentState));
      AppLogger.debug(
        'FeedController: state atualizado com ${_spotlightItems.length} destaques',
      );
    } catch (error, stack) {
      featuredStatus = 'error';
      AppLogger.error(
        'FeedController: featured profiles indisponiveis no ambiente atual',
        error,
        stack,
      );
    } finally {
      AppPerformanceTracker.finishSpan(
        'feed.featured_profiles',
        featuredStopwatch,
        data: {'status': featuredStatus, 'items': _spotlightItems.length},
      );
      _featuredProfilesLoad = null;
    }
  }

  void _scheduleFavoritesSync() {
    _favoritesSyncTimer?.cancel();
    _favoritesSyncTimer = Timer(const Duration(milliseconds: 900), () async {
      try {
        if (!ref.mounted) return;
        await ref.read(favoriteControllerProvider.notifier).loadFavorites();
      } catch (error, stack) {
        AppLogger.error(
          'Feed: erro no sync diferido de favoritos',
          error,
          stack,
        );
      }
    });
  }

  /// Fetches the main feed with pagination support.
  Future<void> _fetchMainFeed({
    bool reset = false,
    bool preserveExistingItems = false,
    bool invalidatePool = true,
    AppUser? userOverride,
    List<String>? blockedIdsOverride,
  }) async {
    _ensureControllers();
    final currentState = state.value ?? const FeedState();

    // Protection checks following PaginationState semantics.
    if (!reset && currentState.status == PaginationStatus.loading) {
      AppLogger.debug('Feed: primeira carga em andamento, ignorando');
      return;
    }
    if (!reset && currentState.status == PaginationStatus.loadingMore) {
      AppLogger.debug('Feed: ja esta carregando mais itens');
      return;
    }
    if (!reset && !currentState.hasMore) {
      AppLogger.debug('Feed: nao tem mais dados para carregar');
      return;
    }

    state = AsyncValue.data(
      currentState.copyWithFeed(
        status: reset ? PaginationStatus.loading : PaginationStatus.loadingMore,
        currentPage: reset ? 0 : currentState.currentPage,
        hasMore: reset ? true : currentState.hasMore,
        items: reset && !preserveExistingItems ? [] : currentState.items,
        clearError: true,
      ),
    );

    final user = userOverride ?? await _resolveCurrentUserProfile();
    if (!ref.mounted) return;
    if (user == null) {
      state = AsyncValue.data(
        currentState.copyWithFeed(
          status: PaginationStatus.error,
          errorMessage: 'Usuario nao autenticado',
        ),
      );
      return;
    }

    final blockedIds =
        blockedIdsOverride ?? await _resolveBlockedIds(user: user);
    if (!ref.mounted) return;

    final nextState = await _mainController!.fetchMainFeed(
      currentState: currentState,
      user: user,
      blockedIds: blockedIds,
      runtime: _mainRuntime,
      reset: reset,
      invalidatePool: invalidatePool,
      batchSize: FeedDataConstants.mainFeedBatchSize,
    );

    if (!ref.mounted) return;
    final latestState = state.value;
    final sections = _sectionsController!.buildSections(
      allItems: _mainRuntime.allSortedUsers,
      sectionLimit: FeedDataConstants.sectionLimit,
    );
    final mergedState = _withSpotlightItems(
      nextState.copyWithFeed(
        sectionItems: sections,
        isInitialLoading:
            latestState?.isInitialLoading ?? nextState.isInitialLoading,
      ),
    );
    state = AsyncValue.data(mergedState);
  }

  /// Loads more items for the main feed.
  Future<void> loadMoreMainFeed() async {
    await _fetchMainFeed(reset: false);
  }

  /// Updates filter and reloads main feed.
  Future<void> onFilterChanged(String filter) async {
    final currentState = state.value;
    if (currentState == null || currentState.currentFilter == filter) return;

    state = AsyncValue.data(currentState.copyWithFeed(currentFilter: filter));
    await _fetchMainFeed(reset: true, invalidatePool: false);
  }

  /// Updates like count for a specific item.
  void updateLikeCount(String targetId, {required bool isLiked}) {
    final currentState = state.value;
    if (currentState == null) return;

    FeedItem updateItem(FeedItem item) {
      if (item.uid == targetId) {
        final newCount = isLiked
            ? item.likeCount + 1
            : (item.likeCount - 1).clamp(0, 9999);
        return item.copyWith(likeCount: newCount);
      }
      return item;
    }

    final newMainItems = currentState.items.map(updateItem).toList();
    final newSectionItems = currentState.sectionItems.map((key, value) {
      return MapEntry(key, value.map(updateItem).toList());
    });
    final newSpotlightItems = currentState.featuredItems
        .map(updateItem)
        .toList();

    state = AsyncValue.data(
      currentState.copyWithFeed(
        items: newMainItems,
        sectionItems: newSectionItems,
        featuredItems: newSpotlightItems,
      ),
    );
  }

  /// Pull-to-refresh keeps current UI and reloads data.
  Future<void> refresh() async {
    final existingRefresh = _activeRefresh;
    if (existingRefresh != null) {
      AppPerformanceTracker.mark(
        'feed.refresh.reused',
        data: {'reason': 'already_in_progress'},
      );
      await existingRefresh;
      return;
    }

    final refreshFuture = _loadData(showFullSkeleton: false);
    _activeRefresh = refreshFuture;
    try {
      await refreshFuture;
    } finally {
      if (identical(_activeRefresh, refreshFuture)) {
        _activeRefresh = null;
      }
    }
  }

  /// Whether pagination can request more items.
  bool get canLoadMore {
    final currentState = state.value;
    if (currentState == null) return false;
    return currentState.hasMore && !currentState.isLoading;
  }

  /// Whether pagination is loading more data now.
  bool get isLoadingMore {
    final currentState = state.value;
    if (currentState == null) return false;
    return currentState.isLoadingMore;
  }

  Future<AppUser?> _resolveCurrentUserProfile({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final profileResolveStopwatch = AppPerformanceTracker.startSpan(
      'feed.resolve_current_user_profile',
    );
    if (!ref.mounted) return null;
    final immediate = ref.read(currentUserProfileProvider).value;
    if (immediate != null) {
      AppPerformanceTracker.finishSpan(
        'feed.resolve_current_user_profile',
        profileResolveStopwatch,
        data: {'source': 'cached', 'has_profile': true},
      );
      return immediate;
    }

    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      AppPerformanceTracker.finishSpan(
        'feed.resolve_current_user_profile',
        profileResolveStopwatch,
        data: {'source': 'missing_auth', 'has_profile': false},
      );
      return null;
    }

    try {
      final profile = await ref
          .read(authRepositoryProvider)
          .watchUser(uid)
          .where((user) => user != null)
          .cast<AppUser>()
          .first
          .timeout(timeout);
      AppPerformanceTracker.finishSpan(
        'feed.resolve_current_user_profile',
        profileResolveStopwatch,
        data: {'source': 'stream', 'has_profile': true},
      );
      return profile;
    } catch (_) {
      final fallback = ref.read(currentUserProfileProvider).value;
      AppPerformanceTracker.finishSpan(
        'feed.resolve_current_user_profile',
        profileResolveStopwatch,
        data: {'source': 'fallback', 'has_profile': fallback != null},
      );
      return fallback;
    }
  }

  Future<List<String>> _resolveBlockedIds({
    required AppUser user,
    Duration timeout = const Duration(milliseconds: 350),
  }) async {
    final blocked = <String>{...user.blockedUsers};
    if (!ref.mounted) return blocked.toList();

    final blockedState = ref.read(blockedUsersProvider);
    final immediate = blockedState.value;
    if (immediate != null) {
      blocked.addAll(immediate);
    } else if (blockedState.isLoading) {
      try {
        final streamed = await ref
            .read(blockedUsersProvider.future)
            .timeout(timeout);
        blocked.addAll(streamed);
      } catch (_) {
        // Fall back to currently available data.
      }
    }

    return blocked.toList();
  }
}
