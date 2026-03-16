// ignore_for_file: directives_ordering

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/error_message_resolver.dart';
import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/typedefs.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../favorites/domain/favorite_controller.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../data/featured_profiles_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
import '../domain/paginated_feed_response.dart';
import '../domain/spotlight_rotation.dart';
import 'controllers/feed_main_controller.dart';
import 'controllers/featured_profiles_controller.dart';
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
  List<FeedItem> _manualFeaturedItems = [];
  List<FeedItem> _spotlightItems = [];
  bool _blockedUsersListenerRegistered = false;
  Timer? _favoritesSyncTimer;
  Future<void>? _featuredProfilesLoad;
  Future<void>? _activeLoadAllData;
  Future<void>? _activeRefresh;

  FeaturedProfilesController? _featuredProfilesController;
  FeedMainController? _mainFeedController;
  final FeedMainRuntime _mainFeedRuntime = FeedMainRuntime();
  String? _mainFeedPoolUserId;
  String _mainFeedPoolBlockedKey = '';

  FeedState _withSpotlightItems(FeedState currentState) {
    _spotlightItems = SpotlightRotation.build(
      priorityItems: _manualFeaturedItems,
      candidateItems: _buildSpotlightCandidates(currentState),
    );
    return currentState.copyWithFeed(featuredItems: _spotlightItems);
  }

  List<FeedItem> _buildSpotlightCandidates(FeedState currentState) {
    final uniqueItems = <String, FeedItem>{};
    for (final item in currentState.items) {
      uniqueItems[item.uid] = item;
    }
    for (final items in currentState.sectionItems.values) {
      for (final item in items) {
        uniqueItems[item.uid] = item;
      }
    }
    return uniqueItems.values.toList(growable: false);
  }

  FeaturedProfilesController _getFeaturedProfilesController() {
    return _featuredProfilesController ??= FeaturedProfilesController(
      repository: ref.read(featuredProfilesRepositoryProvider),
    );
  }

  FeedMainController _getMainFeedController() {
    return _mainFeedController ??= FeedMainController(
      feedRepository: ref.read(feedRepositoryProvider),
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
    _registerBlockedUsersListener();
    ref.onDispose(() {
      _favoritesSyncTimer?.cancel();
    });
    return const FeedState();
  }

  Future<void> ensureLoaded() async {
    final currentState = state.value;
    if (currentState == null) {
      await loadAllData();
      return;
    }

    final hasAnyContent =
        currentState.items.isNotEmpty ||
        currentState.sectionItems.values.any((items) => items.isNotEmpty) ||
        currentState.featuredItems.isNotEmpty;
    if (hasAnyContent || currentState.status != PaginationStatus.initial) {
      return;
    }

    await loadAllData();
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

    final currentState = state.value ?? const FeedState();
    state = AsyncValue.data(
      currentState.copyWithFeed(
        isInitialLoading: showFullSkeleton,
        status: currentState.items.isEmpty || showFullSkeleton
            ? PaginationStatus.loading
            : currentState.status,
        clearError: true,
        clearLastDocument: true,
      ),
    );

    _scheduleFavoritesSync();
    _loadFeaturedProfilesInBackground();

    try {
      final user = await _resolveCurrentUserProfile();
      if (!ref.mounted) return;

      if (user == null) {
        state = AsyncValue.data(
          currentState.copyWithFeed(
            isInitialLoading: false,
            status: PaginationStatus.error,
            errorMessage: 'Usuario nao autenticado',
            clearLastDocument: true,
            hasMore: false,
          ),
        );
        return;
      }

      final blockedIds = await _resolveBlockedIds(user: user);
      if (!ref.mounted) return;

      final sectionsFuture = _loadHomeSections(
        user: user,
        blockedIds: blockedIds,
      );
      final mainFeedState = await _fetchMainFeedState(
        currentState: currentState,
        user: user,
        blockedIds: blockedIds,
        reset: true,
        forceInvalidatePool: true,
      );
      final sections = await sectionsFuture;
      if (!ref.mounted) return;

      if (mainFeedState.status == PaginationStatus.error) {
        state = AsyncValue.data(
          currentState.copyWithFeed(
            sectionItems: sections,
            isInitialLoading: false,
            status: PaginationStatus.error,
            errorMessage: mainFeedState.errorMessage,
            clearLastDocument: true,
            hasMore: false,
          ),
        );
        AppPerformanceTracker.finishSpan(
          'feed.load_all_data',
          loadStopwatch,
          data: {
            'status': 'error',
            'error_message': mainFeedState.errorMessage,
          },
        );
        return;
      }

      final nextState = _withSpotlightItems(
        currentState.copyWithFeed(
          sectionItems: sections,
          items: mainFeedState.items,
          status: mainFeedState.status,
          currentPage: mainFeedState.currentPage,
          hasMore: mainFeedState.hasMore,
          isInitialLoading: false,
          clearError: true,
          clearLastDocument: true,
        ),
      );
      state = AsyncValue.data(nextState);
      AppPerformanceTracker.finishSpan(
        'feed.load_all_data',
        loadStopwatch,
        data: {
          'items': nextState.items.length,
          'sections': nextState.sectionItems.length,
          'status': nextState.status.name,
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
          errorMessage: resolveErrorMessage(error),
        ),
      );
    }
  }

  Future<Map<FeedSectionType, List<FeedItem>>> _loadHomeSections({
    required AppUser user,
    required List<String> blockedIds,
  }) async {
    final repository = ref.read(feedRepositoryProvider);
    final userLat = (user.location?['lat'] as num?)?.toDouble();
    final userLong = (user.location?['lng'] as num?)?.toDouble();

    final results = await Future.wait<_HomeSectionResult>([
      _loadSection(
        type: FeedSectionType.technicians,
        loader: () => repository.getTechnicians(
          currentUserId: user.uid,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: FeedDataConstants.sectionLimit,
        ),
      ),
      _loadSection(
        type: FeedSectionType.bands,
        loader: () => repository.getUsersByType(
          type: ProfileType.band,
          currentUserId: user.uid,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: FeedDataConstants.sectionLimit,
        ),
      ),
      _loadSection(
        type: FeedSectionType.studios,
        loader: () => repository.getUsersByType(
          type: ProfileType.studio,
          currentUserId: user.uid,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: FeedDataConstants.sectionLimit,
        ),
      ),
    ]);

    return {for (final result in results) result.type: result.items};
  }

  Future<_HomeSectionResult> _loadSection({
    required FeedSectionType type,
    required FutureResult<List<FeedItem>> Function() loader,
  }) async {
    try {
      final result = await loader();
      return result.fold((failure) {
        AppLogger.warning(
          'Feed: falha ao carregar seção ${type.name}',
          failure,
        );
        return _HomeSectionResult(type: type, items: const []);
      }, (items) => _HomeSectionResult(type: type, items: items));
    } catch (error, stack) {
      AppLogger.warning(
        'Feed: erro ao carregar seção ${type.name}',
        error,
        stack,
      );
      return _HomeSectionResult(type: type, items: const []);
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

  Future<FeedState> _fetchMainFeedState({
    required FeedState currentState,
    required AppUser user,
    required List<String> blockedIds,
    required bool reset,
    required bool forceInvalidatePool,
  }) async {
    final userLat = (user.location?['lat'] as num?)?.toDouble();
    final userLong = (user.location?['lng'] as num?)?.toDouble();
    final nextBlockedKey = _buildBlockedIdsKey(blockedIds);
    final shouldInvalidatePool =
        forceInvalidatePool ||
        !_mainFeedRuntime.hasLoadedPool ||
        _mainFeedPoolUserId != user.uid ||
        _mainFeedRuntime.userLat != userLat ||
        _mainFeedRuntime.userLong != userLong ||
        _mainFeedPoolBlockedKey != nextBlockedKey;

    _mainFeedPoolUserId = user.uid;
    _mainFeedPoolBlockedKey = nextBlockedKey;
    _mainFeedRuntime.userLat = userLat;
    _mainFeedRuntime.userLong = userLong;

    final nextState = await _getMainFeedController().fetchMainFeed(
      currentState: currentState,
      user: user,
      blockedIds: blockedIds,
      runtime: _mainFeedRuntime,
      reset: reset,
      invalidatePool: shouldInvalidatePool,
      batchSize: FeedDataConstants.mainFeedBatchSize,
    );

    return nextState.copyWithFeed(clearLastDocument: true);
  }

  String _buildBlockedIdsKey(List<String> blockedIds) {
    if (blockedIds.isEmpty) return '';
    final sortedIds = [...blockedIds]..sort();
    return sortedIds.join('|');
  }

  // ignore: unused_element
  FutureResult<PaginatedFeedResponse> _loadMainPage({
    required AppUser user,
    required List<String> blockedIds,
    required String filter,
    required DocumentSnapshot? startAfter,
    required int limit,
  }) {
    final repository = ref.read(feedRepositoryProvider);
    final userLat = (user.location?['lat'] as num?)?.toDouble();
    final userLong = (user.location?['lng'] as num?)?.toDouble();

    switch (filter) {
      case 'Profissionais':
        return repository.getUsersByTypePaginated(
          type: ProfileType.professional,
          currentUserId: user.uid,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: limit,
          startAfter: startAfter,
        );
      case 'Bandas':
        return repository.getUsersByTypePaginated(
          type: ProfileType.band,
          currentUserId: user.uid,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: limit,
          startAfter: startAfter,
        );
      case 'Estúdios':
        return repository.getUsersByTypePaginated(
          type: ProfileType.studio,
          currentUserId: user.uid,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: limit,
          startAfter: startAfter,
        );
      default:
        return repository.getMainFeedPaginated(
          currentUserId: user.uid,
          excludedIds: blockedIds,
          userLat: userLat,
          userLong: userLong,
          limit: limit,
          startAfter: startAfter,
        );
    }
  }

  /// Loads more items for the main feed.
  Future<void> loadMoreMainFeed() async {
    final currentState = state.value ?? const FeedState();
    if (currentState.status == PaginationStatus.loading ||
        currentState.status == PaginationStatus.loadingMore ||
        !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(
      currentState.copyWithFeed(
        status: PaginationStatus.loadingMore,
        clearError: true,
      ),
    );

    final user = await _resolveCurrentUserProfile();
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

    final blockedIds = await _resolveBlockedIds(user: user);
    if (!ref.mounted) return;

    final nextState = await _fetchMainFeedState(
      currentState: currentState,
      user: user,
      blockedIds: blockedIds,
      reset: false,
      forceInvalidatePool: false,
    );
    if (!ref.mounted) return;

    state = AsyncValue.data(
      _withSpotlightItems(
        nextState.copyWithFeed(
          sectionItems: currentState.sectionItems,
          featuredItems: currentState.featuredItems,
          isInitialLoading: false,
        ),
      ),
    );
  }

  // ignore: unused_element
  List<FeedItem> _mergeUniqueItems(
    List<FeedItem> existingItems,
    List<FeedItem> incomingItems,
  ) {
    final merged = <FeedItem>[];
    final seenIds = <String>{};
    for (final item in existingItems) {
      if (seenIds.add(item.uid)) {
        merged.add(item);
      }
    }
    for (final item in incomingItems) {
      if (seenIds.add(item.uid)) {
        merged.add(item);
      }
    }
    return merged;
  }

  /// Updates filter and reloads main feed.
  Future<void> onFilterChanged(String filter) async {
    final currentState = state.value;
    if (currentState == null || currentState.currentFilter == filter) return;

    state = AsyncValue.data(
      currentState.copyWithFeed(
        currentFilter: filter,
        items: const [],
        status: PaginationStatus.loading,
        hasMore: true,
        currentPage: 0,
        clearError: true,
        clearLastDocument: true,
      ),
    );

    final user = await _resolveCurrentUserProfile();
    if (!ref.mounted) return;
    if (user == null) {
      state = AsyncValue.data(
        currentState.copyWithFeed(
          currentFilter: filter,
          items: const [],
          status: PaginationStatus.error,
          errorMessage: 'Usuario nao autenticado',
          hasMore: false,
          clearLastDocument: true,
        ),
      );
      return;
    }

    final blockedIds = await _resolveBlockedIds(user: user);
    if (!ref.mounted) return;

    final baseState = currentState.copyWithFeed(
      currentFilter: filter,
      items: const [],
      status: PaginationStatus.loading,
      hasMore: true,
      currentPage: 0,
      clearError: true,
      clearLastDocument: true,
    );
    final nextState = await _fetchMainFeedState(
      currentState: baseState,
      user: user,
      blockedIds: blockedIds,
      reset: true,
      forceInvalidatePool: false,
    );
    if (!ref.mounted) return;

    state = AsyncValue.data(
      _withSpotlightItems(
        nextState.copyWithFeed(
          sectionItems: currentState.sectionItems,
          featuredItems: currentState.featuredItems,
          isInitialLoading: false,
        ),
      ),
    );
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
    return currentState.hasMore &&
        currentState.status != PaginationStatus.loading &&
        currentState.status != PaginationStatus.loadingMore;
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

class _HomeSectionResult {
  const _HomeSectionResult({required this.type, required this.items});

  final FeedSectionType type;
  final List<FeedItem> items;
}
