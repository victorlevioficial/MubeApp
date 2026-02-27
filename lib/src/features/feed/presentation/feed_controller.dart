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

/// Constants for feed data fetching
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

  /// Atualiza o state sempre injetando os featured mais recentes
  /// para evitar race condition entre chamadas concorrentes.
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

  /// Carrega todos os dados do feed (seções + feed principal).
  Future<void> loadAllData() async {
    _ensureControllers();

    final currentState = state.value ?? const FeedState();
    state = AsyncValue.data(currentState.copyWithFeed(isInitialLoading: true));
    // Sync de favoritos com pequeno atraso para evitar competir com first paint.
    unawaited(_loadFavoritesDeferred());

    // Busca os perfis em destaque do painel admin concorrentemente.
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
        'FeedController: featured profiles indisponíveis no ambiente atual',
        error,
        stack,
      );
    }

    try {
      final requestToken = ++_sectionsRequestToken;
      final user = await _resolveCurrentUserProfile();
      if (!ref.mounted) return;
      if (user != null) {
        _mainRuntime.userLat = user.location?['lat'];
        _mainRuntime.userLong = user.location?['lng'];
      }

      // Prioriza o feed principal e libera a UI.
      await _fetchMainFeed(reset: true);
      if (!ref.mounted) return;
      final afterMainState = state.value ?? const FeedState();
      if (afterMainState.isInitialLoading) {
        state = AsyncValue.data(
          afterMainState.copyWithFeed(isInitialLoading: false),
        );
      }

      if (user != null) {
        // Sem atraso artificial para evitar que "Em Destaque" apareça tarde.
        _loadSectionsInBackground(user, requestToken);
      }
    } catch (e, stack) {
      AppLogger.error('Feed: erro ao carregar dados iniciais', e, stack);
      if (!ref.mounted) return;
      final latest = state.value ?? currentState;
      state = AsyncValue.data(
        latest.copyWithFeed(
          isInitialLoading: false,
          status: PaginationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _loadFavoritesDeferred() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!ref.mounted) return;
      await ref.read(favoriteControllerProvider.notifier).loadFavorites();
    } catch (e, stack) {
      AppLogger.error('Feed: erro no sync diferido de favoritos', e, stack);
    }
  }

  void _loadSectionsInBackground(AppUser user, int requestToken) {
    unawaited(_loadSections(user: user, requestToken: requestToken));
  }

  Future<void> _loadSections({
    required AppUser user,
    required int requestToken,
  }) async {
    try {
      final sections = await _fetchSections(user: user);
      if (!ref.mounted) return;
      if (requestToken != _sectionsRequestToken) return;
      _emitState((s) => s.copyWithFeed(sectionItems: sections));
    } catch (error, stack) {
      AppLogger.error('Feed: erro ao carregar secoes', error, stack);
    }
  }

  Future<Map<FeedSectionType, List<FeedItem>>> _fetchSections({
    required AppUser user,
  }) async {
    _ensureControllers();
    final blockedIds = await _resolveBlockedIds(user: user);
    return _sectionsController!.fetchSections(
      user: user,
      blockedIds: blockedIds,
      userLat: _mainRuntime.userLat,
      userLong: _mainRuntime.userLong,
      sectionLimit: FeedDataConstants.sectionLimit,
    );
  }

  /// Busca o feed principal com paginação.
  Future<void> _fetchMainFeed({bool reset = false}) async {
    _ensureControllers();
    final currentState = state.value ?? const FeedState();

    // Verificações de proteção usando o padrão PaginationState.
    if (currentState.status == PaginationStatus.loading) {
      AppLogger.debug('Feed: Primeira carga em andamento, ignorando');
      return;
    }
    if (currentState.status == PaginationStatus.loadingMore && !reset) {
      AppLogger.debug('Feed: Já está carregando mais itens');
      return;
    }
    if (!reset && !currentState.hasMore) {
      AppLogger.debug('Feed: Não tem mais dados para carregar');
      return;
    }

    // Atualiza estado para loading.
    state = AsyncValue.data(
      currentState.copyWithFeed(
        status: reset ? PaginationStatus.loading : PaginationStatus.loadingMore,
        currentPage: reset ? 0 : currentState.currentPage,
        hasMore: reset ? true : currentState.hasMore,
        items: reset ? [] : currentState.items,
        clearError: true,
      ),
    );

    final user = await _resolveCurrentUserProfile();
    if (!ref.mounted) return;
    if (user == null) {
      state = AsyncValue.data(
        currentState.copyWithFeed(
          status: PaginationStatus.error,
          errorMessage: 'Usuário não autenticado',
        ),
      );
      return;
    }

    final blockedIds = await _resolveBlockedIds(user: user);
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
    state = AsyncValue.data(nextState);
  }

  /// Carrega mais itens no feed principal.
  Future<void> loadMoreMainFeed() async {
    await _fetchMainFeed(reset: false);
  }

  /// Atualiza o filtro e recarrega o feed.
  Future<void> onFilterChanged(String filter) async {
    final currentState = state.value;
    if (currentState == null || currentState.currentFilter == filter) return;

    state = AsyncValue.data(currentState.copyWithFeed(currentFilter: filter));
    await _fetchMainFeed(reset: true);
  }

  /// Atualiza o contador de likes de um item.
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

  /// Recarrega o feed (pull-to-refresh).
  Future<void> refresh() async {
    await loadAllData();
  }

  /// Verifica se pode carregar mais itens.
  bool get canLoadMore {
    final currentState = state.value;
    if (currentState == null) return false;
    return currentState.hasMore && !currentState.isLoading;
  }

  /// Verifica se está carregando mais itens.
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
        // fallback com dados já disponíveis
      }
    }
    return blocked.toList();
  }
}
