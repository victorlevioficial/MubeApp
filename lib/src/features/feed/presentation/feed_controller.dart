import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/mixins/pagination_mixin.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../favorites/domain/favorite_controller.dart';
import '../../moderation/data/blocked_users_provider.dart';
import '../data/featured_profiles_repository.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';
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
  List<FeedItem> _featuredItems = [];
  int _sectionsRequestToken = 0;

  FeedSectionsController? _sectionsController;
  FeedMainController? _mainController;
  FeaturedProfilesController? _featuredProfilesController;

  /// Always inject the latest featured list to avoid race conditions.
  void _emitState(FeedState Function(FeedState current) updater) {
    final current = state.value ?? const FeedState();
    final updated = updater(current);
    state = AsyncValue.data(
      updated.featuredItems.isNotEmpty
          ? updated
          : updated.copyWithFeed(featuredItems: _featuredItems),
    );
  }

  void _ensureControllers() {
    final feedRepository = ref.read(feedRepositoryProvider);
    _sectionsController ??= FeedSectionsController(
      feedRepository: feedRepository,
    );
    _mainController ??= FeedMainController(feedRepository: feedRepository);
  }

  FeaturedProfilesController _getFeaturedProfilesController() {
    return _featuredProfilesController ??= FeaturedProfilesController(
      repository: ref.read(featuredProfilesRepositoryProvider),
    );
  }

  @override
  FutureOr<FeedState> build() {
    _ensureControllers();
    // Data is loaded manually via loadAllData().
    return const FeedState();
  }

  /// Initial full load for feed screen.
  Future<void> loadAllData() async {
    await _loadData(showFullSkeleton: true);
  }

  Future<void> _loadData({required bool showFullSkeleton}) async {
    _ensureControllers();

    final currentState = state.value ?? const FeedState();
    state = AsyncValue.data(
      currentState.copyWithFeed(
        isInitialLoading: showFullSkeleton,
        clearError: true,
      ),
    );

    // Keep favorite sync away from first paint.
    unawaited(_loadFavoritesDeferred());
    _loadFeaturedProfilesInBackground();

    try {
      final requestToken = ++_sectionsRequestToken;
      final user = await _resolveCurrentUserProfile();
      if (!ref.mounted) return;

      if (user != null) {
        _mainRuntime.userLat = user.location?['lat'];
        _mainRuntime.userLong = user.location?['lng'];
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

      if (user != null) {
        unawaited(
          _loadSections(
            user: user,
            requestToken: requestToken,
            blockedIds: blockedIds,
          ),
        );
      }
    } catch (error, stack) {
      AppLogger.error('Feed: erro ao carregar dados iniciais', error, stack);
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
    try {
      unawaited(
        _getFeaturedProfilesController().loadFeaturedProfiles().then((
          featured,
        ) {
          if (!ref.mounted) return;
          AppLogger.debug(
            'FeedController: featured profiles carregados: ${featured.length}',
          );
          if (featured.isNotEmpty) {
            _featuredItems = featured;
            _emitState((s) => s.copyWithFeed(featuredItems: featured));
            AppLogger.debug(
              'FeedController: state atualizado com ${featured.length} destaques',
            );
          }
        }),
      );
    } catch (error, stack) {
      AppLogger.error(
        'FeedController: featured profiles indisponiveis no ambiente atual',
        error,
        stack,
      );
    }
  }

  Future<void> _loadFavoritesDeferred() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!ref.mounted) return;
      await ref.read(favoriteControllerProvider.notifier).loadFavorites();
    } catch (error, stack) {
      AppLogger.error('Feed: erro no sync diferido de favoritos', error, stack);
    }
  }

  Future<void> _loadSections({
    required AppUser user,
    required int requestToken,
    List<String>? blockedIds,
  }) async {
    try {
      final sections = await _fetchSections(user: user, blockedIds: blockedIds);
      if (!ref.mounted) return;
      if (requestToken != _sectionsRequestToken) return;
      _emitState((s) => s.copyWithFeed(sectionItems: sections));
    } catch (error, stack) {
      AppLogger.error('Feed: erro ao carregar secoes', error, stack);
    }
  }

  Future<Map<FeedSectionType, List<FeedItem>>> _fetchSections({
    required AppUser user,
    List<String>? blockedIds,
  }) async {
    _ensureControllers();
    final effectiveBlockedIds =
        blockedIds ?? await _resolveBlockedIds(user: user);
    return _sectionsController!.fetchSections(
      user: user,
      blockedIds: effectiveBlockedIds,
      userLat: _mainRuntime.userLat,
      userLong: _mainRuntime.userLong,
      sectionLimit: FeedDataConstants.sectionLimit,
    );
  }

  /// Fetches the main feed with pagination support.
  Future<void> _fetchMainFeed({
    bool reset = false,
    bool preserveExistingItems = false,
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
      batchSize: FeedDataConstants.mainFeedBatchSize,
    );

    if (!ref.mounted) return;
    final latestState = state.value;
    final mergedState = nextState.copyWithFeed(
      sectionItems: latestState?.sectionItems ?? nextState.sectionItems,
      featuredItems: latestState?.featuredItems ?? nextState.featuredItems,
      isInitialLoading:
          latestState?.isInitialLoading ?? nextState.isInitialLoading,
    );
    _emitState((_) => mergedState);
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
    await _fetchMainFeed(reset: true);
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

    state = AsyncValue.data(
      currentState.copyWithFeed(
        items: newMainItems,
        sectionItems: newSectionItems,
      ),
    );
  }

  /// Pull-to-refresh keeps current UI and reloads data.
  Future<void> refresh() async {
    await _loadData(showFullSkeleton: false);
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
    if (!ref.mounted) return null;
    final immediate = ref.read(currentUserProfileProvider).value;
    if (immediate != null) return immediate;

    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return null;

    try {
      return await ref
          .read(authRepositoryProvider)
          .watchUser(uid)
          .where((user) => user != null)
          .cast<AppUser>()
          .first
          .timeout(timeout);
    } catch (_) {
      return ref.read(currentUserProfileProvider).value;
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
