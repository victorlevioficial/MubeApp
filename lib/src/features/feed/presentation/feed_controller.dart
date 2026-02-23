import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/typedefs.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../favorites/domain/favorite_controller.dart';
import '../data/feed_items_provider.dart';
import '../data/feed_repository.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';

part 'feed_controller.g.dart';

/// Constants for feed data fetching
abstract final class FeedDataConstants {
  static const double nearbyRadiusKm = 50.0;
  static const int sectionLimit = 10;
  static const int mainFeedBatchSize = 20;
}

// --- State Class (com PaginationState) ---

/// Estado específico do feed, estendendo [PaginationState].
@immutable
class FeedState extends PaginationState<FeedItem> {
  /// Itens das seções horizontais (destaques).
  final Map<FeedSectionType, List<FeedItem>> sectionItems;

  /// Filtro atual aplicado ao feed.
  final String currentFilter;

  /// Indica se está carregando a inicialização completa.
  @override
  final bool isInitialLoading;

  const FeedState({
    this.sectionItems = const {},
    this.currentFilter = 'Todos',
    this.isInitialLoading = true,
    super.items = const [],
    super.status = PaginationStatus.initial,
    super.errorMessage,
    super.lastDocument,
    super.hasMore = true,
    super.currentPage = 0,
    super.pageSize = 20,
  });

  FeedState copyWithFeed({
    Map<FeedSectionType, List<FeedItem>>? sectionItems,
    String? currentFilter,
    bool? isInitialLoading,
    List<FeedItem>? items,
    PaginationStatus? status,
    String? errorMessage,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    int? currentPage,
    int? pageSize,
    bool clearError = false,
    bool clearLastDocument = false,
  }) {
    return FeedState(
      sectionItems: sectionItems ?? this.sectionItems,
      currentFilter: currentFilter ?? this.currentFilter,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedState &&
        mapEquals(other.sectionItems, sectionItems) &&
        other.currentFilter == currentFilter &&
        other.isInitialLoading == isInitialLoading &&
        listEquals(other.items, items) &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.lastDocument == lastDocument &&
        other.hasMore == hasMore &&
        other.currentPage == currentPage &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
    sectionItems,
    currentFilter,
    isInitialLoading,
    items,
    status,
    errorMessage,
    lastDocument,
    hasMore,
    currentPage,
    pageSize,
  );
}

// --- Controller (Riverpod Generator) ---

@Riverpod(keepAlive: true)
class FeedController extends _$FeedController {
  List<FeedItem> _allSortedUsers = [];
  double? _userLat;
  double? _userLong;
  bool _remoteHasMore = true;
  bool _geoFetchCompleted = false;
  DocumentSnapshot? _lastMainFeedDocument;

  @override
  FutureOr<FeedState> build() {
    // Data is loaded manually via loadAllData().
    // Watching providers here would cause unnecessary rebuilds.
    return const FeedState();
  }

  /// Carrega todos os dados do feed (seções + feed principal).
  Future<void> loadAllData() async {
    final currentState = state.value ?? const FeedState();
    state = AsyncValue.data(currentState.copyWithFeed(isInitialLoading: true));
    // Sync de favoritos com pequeno atraso para evitar competir com first paint.
    unawaited(_loadFavoritesDeferred());
    try {
      // Set user location from auth profile
      final user = await _resolveCurrentUserProfile();
      if (user != null) {
        _userLat = user.location?['lat'];
        _userLong = user.location?['lng'];
      }
      // Prioriza o feed principal; secoes carregam depois.
      await _fetchMainFeed(reset: true);
      final afterMainState = state.value ?? const FeedState();
      if (afterMainState.isInitialLoading) {
        state = AsyncValue.data(
          afterMainState.copyWithFeed(isInitialLoading: false),
        );
      }
      unawaited(_loadSectionsDeferred());
    } catch (e, stack) {
      AppLogger.error('Feed: erro ao carregar dados iniciais', e, stack);
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
      await ref.read(favoriteControllerProvider.notifier).loadFavorites();
    } catch (e, stack) {
      AppLogger.error('Feed: erro no sync diferido de favoritos', e, stack);
    }
  }

  Future<void> _loadSectionsDeferred() async {
    try {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final sections = await _fetchSections();
      final latestState = state.value ?? const FeedState();
      state = AsyncValue.data(
        latestState.copyWithFeed(
          sectionItems: sections,
          isInitialLoading: false,
        ),
      );
    } catch (error, stack) {
      AppLogger.error('Feed: erro ao carregar secoes', error, stack);
    }
  }

  // Loads horizontal feed sections in the background.
  Future<Map<FeedSectionType, List<FeedItem>>> _fetchSections() async {
    final user = await _resolveCurrentUserProfile();
    if (user == null) return {};

    final feedRepo = ref.read(feedRepositoryProvider);
    final items = <FeedSectionType, List<FeedItem>>{};

    Future<List<FeedItem>> fetchOrEmpty(
      FutureResult<List<FeedItem>> call,
    ) async {
      final result = await call;
      return result.getOrElse((l) => []);
    }

    if (_userLat != null && _userLong != null) {
      final results = await Future.wait<List<FeedItem>>([
        fetchOrEmpty(
          feedRepo.getTechnicians(
            currentUserId: user.uid,
            userLat: _userLat,
            userLong: _userLong,
            limit: FeedDataConstants.sectionLimit,
          ),
        ),
        fetchOrEmpty(
          feedRepo.getAllUsersSortedByDistance(
            currentUserId: user.uid,
            userLat: _userLat!,
            userLong: _userLong!,
            filterType: ProfileType.band,
            userGeohash: user.geohash,
          ),
        ),
        fetchOrEmpty(
          feedRepo.getAllUsersSortedByDistance(
            currentUserId: user.uid,
            userLat: _userLat!,
            userLong: _userLong!,
            filterType: ProfileType.studio,
            userGeohash: user.geohash,
          ),
        ),
      ]);
      items[FeedSectionType.technicians] = results[0];
      items[FeedSectionType.bands] = results[1]
          .take(FeedDataConstants.sectionLimit)
          .toList();
      items[FeedSectionType.studios] = results[2]
          .take(FeedDataConstants.sectionLimit)
          .toList();
    } else {
      final results = await Future.wait<List<FeedItem>>([
        fetchOrEmpty(
          feedRepo.getTechnicians(
            currentUserId: user.uid,
            userLat: _userLat,
            userLong: _userLong,
            limit: FeedDataConstants.sectionLimit,
          ),
        ),
        fetchOrEmpty(
          feedRepo.getUsersByType(
            type: ProfileType.band,
            currentUserId: user.uid,
            userLat: _userLat,
            userLong: _userLong,
            limit: FeedDataConstants.sectionLimit,
          ),
        ),
        fetchOrEmpty(
          feedRepo.getUsersByType(
            type: ProfileType.studio,
            currentUserId: user.uid,
            userLat: _userLat,
            userLong: _userLong,
            limit: FeedDataConstants.sectionLimit,
          ),
        ),
      ]);
      items[FeedSectionType.technicians] = results[0];
      items[FeedSectionType.bands] = results[1];
      items[FeedSectionType.studios] = results[2];
    }
    final allItems = items.values.expand((list) => list).toList();
    ref.read(feedItemsProvider.notifier).loadItems(allItems);
    // Precache is handled by FeedImagePrecacheService in the UI layer

    return items;
  }

  /// Busca o feed principal com paginação.
  Future<void> _fetchMainFeed({bool reset = false}) async {
    final currentState = state.value ?? const FeedState();

    if (reset) {
      _remoteHasMore = true;
      _geoFetchCompleted = false;
      _lastMainFeedDocument = null;
    }

    // Verificações de proteção usando o padrão PaginationState
    // Se está carregando a primeira página (loading), não permitir nova chamada
    if (currentState.status == PaginationStatus.loading) {
      AppLogger.debug('Feed: Primeira carga em andamento, ignorando');
      return;
    }
    // Se está carregando mais (loadingMore) e tem itens, não permitir nova chamada
    if (currentState.status == PaginationStatus.loadingMore && !reset) {
      AppLogger.debug('Feed: Já está carregando mais itens');
      return;
    }
    if (!reset && !currentState.hasMore) {
      AppLogger.debug('Feed: Não tem mais dados para carregar');
      return;
    }

    // Atualiza estado para loading
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
    if (user == null) {
      state = AsyncValue.data(
        currentState.copyWithFeed(
          status: PaginationStatus.error,
          errorMessage: 'Usuário não autenticado',
        ),
      );
      return;
    }

    try {
      // Lógica simplificada:
      // 1. Primeira carga (reset): busca lote inicial no backend
      // 2. Scroll: paginação local
      // 3. Se acabou local e o backend ainda tem mais: busca novo lote
      // 4. Se buscou e não encontrou nada: noMoreData

      final localRemaining =
          _allSortedUsers.length -
          (currentState.currentPage * currentState.pageSize);
      final canTryRemote = _remoteHasMore;
      final shouldFetchFromFirestore =
          reset || (localRemaining <= 0 && canTryRemote);

      AppLogger.debug(
        'Feed Debug: localRemaining=$localRemaining, '
        'shouldFetch=$shouldFetchFromFirestore, reset=$reset, '
        'total=${_allSortedUsers.length}',
      );

      if (shouldFetchFromFirestore) {
        String? filterType;
        switch (currentState.currentFilter) {
          case 'Profissionais':
            filterType = ProfileType.professional;
            break;
          case 'Bandas':
            filterType = ProfileType.band;
            break;
          case 'Estúdios':
            filterType = ProfileType.studio;
            break;
        }

        final isNearbyFilter = currentState.currentFilter == 'Perto de mim';
        var shouldFetchCursor = false;

        if (_userLat != null && _userLong != null) {
          if (!_geoFetchCompleted) {
            var fallbackToCursor = false;
            AppLogger.debug('Feed: Buscando usuários do Firestore...');
            final result = await ref
                .read(feedRepositoryProvider)
                .getNearbyUsersOptimized(
                  currentUserId: user.uid,
                  userLat: _userLat!,
                  userLong: _userLong!,
                  filterType: filterType,
                  excludedIds: user.blockedUsers,
                  targetResults: FeedDataConstants.mainFeedBatchSize,
                );

            result.fold(
              (failure) {
                AppLogger.error('Feed: Erro ao buscar usuários', failure);
                if (reset) {
                  state = AsyncValue.data(
                    currentState.copyWithFeed(
                      status: PaginationStatus.error,
                      errorMessage: failure.message,
                    ),
                  );
                  _allSortedUsers = [];
                }
              },
              (success) {
                AppLogger.debug(
                  'Feed: ${success.length} usuários retornados do Firestore',
                );
                if (reset) {
                  // Substitui a lista
                  _allSortedUsers = success;
                  fallbackToCursor = success.isEmpty;
                } else {
                  // Adiciona novos usuários à lista existente
                  final existingIds = _allSortedUsers.map((u) => u.uid).toSet();
                  final newUsers = success
                      .where((u) => !existingIds.contains(u.uid))
                      .toList();
                  AppLogger.debug(
                    'Feed: ${newUsers.length} usuários são novos',
                  );

                  if (newUsers.isEmpty) {
                    // Não encontrou usuários novos, tentar cursor
                    AppLogger.debug('Feed: Nenhum usuário novo encontrado');
                    fallbackToCursor = true;
                  } else {
                    _allSortedUsers.addAll(newUsers);
                    _allSortedUsers.sort(
                      (a, b) =>
                          (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
                    );
                  }
                }

                _geoFetchCompleted = true;

                if (fallbackToCursor) {
                  if (isNearbyFilter) {
                    _remoteHasMore = false;
                  } else {
                    shouldFetchCursor = true;
                  }
                }
              },
            );

            if (state.value?.status == PaginationStatus.error) return;
          } else {
            if (isNearbyFilter) {
              _remoteHasMore = false;
            } else {
              shouldFetchCursor = true;
            }
          }
        } else {
          if (isNearbyFilter) {
            _remoteHasMore = false;
          } else {
            shouldFetchCursor = true;
          }
        }

        if (shouldFetchCursor) {
          await _fetchMainFeedPage(
            currentState: currentState,
            userId: user.uid,
            filterType: filterType,
            reset: reset,
          );
        }
      } else {
        AppLogger.debug(
          'Feed: Usando paginação local, $localRemaining usuários restantes',
        );
      }

      // Paginação local na lista ordenada
      final page = reset ? 0 : currentState.currentPage;
      final startIndex = page * currentState.pageSize;
      if (startIndex >= _allSortedUsers.length) {
        final hasMore = _remoteHasMore;
        final baseState = reset
            ? currentState.copyWithFeed(items: [], currentPage: 0)
            : currentState;

        state = AsyncValue.data(
          baseState.copyWithFeed(
            status: hasMore
                ? PaginationStatus.loaded
                : PaginationStatus.noMoreData,
            hasMore: hasMore,
          ),
        );
        return;
      }
      final endIndex = (startIndex + currentState.pageSize).clamp(
        0,
        _allSortedUsers.length,
      );

      final newItems = _allSortedUsers.sublist(startIndex, endIndex);

      ref.read(feedItemsProvider.notifier).loadItems(newItems);
      // Precache is handled by FeedImagePrecacheService in the UI layer

      final allItems = reset ? newItems : [...currentState.items, ...newItems];

      // Verifica se tem mais usuários para mostrar
      final hasMoreLocal = endIndex < _allSortedUsers.length;
      // Busca mais do Firestore enquanto o backend indicar que há mais dados.
      final canFetchMore = _remoteHasMore;
      final hasMore = hasMoreLocal || canFetchMore;

      AppLogger.debug(
        'Feed: endIndex=$endIndex, total=${_allSortedUsers.length}, hasMore=$hasMore',
      );

      state = AsyncValue.data(
        currentState.copyWithFeed(
          items: allItems,
          status: hasMore
              ? PaginationStatus.loaded
              : PaginationStatus.noMoreData,
          currentPage: page + 1,
          hasMore: hasMore,
        ),
      );
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWithFeed(
          status: PaginationStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _fetchMainFeedPage({
    required FeedState currentState,
    required String userId,
    required String? filterType,
    required bool reset,
  }) async {
    final result = await ref
        .read(feedRepositoryProvider)
        .getMainFeedPaginated(
          currentUserId: userId,
          filterType: filterType,
          userLat: _userLat,
          userLong: _userLong,
          limit: FeedDataConstants.mainFeedBatchSize,
          startAfter: _lastMainFeedDocument,
        );

    result.fold(
      (failure) {
        AppLogger.error('Feed: Erro ao buscar página', failure);
        if (reset) {
          state = AsyncValue.data(
            currentState.copyWithFeed(
              status: PaginationStatus.error,
              errorMessage: failure.message,
            ),
          );
        }
        _remoteHasMore = false;
      },
      (response) {
        _lastMainFeedDocument = response.lastDocument;
        _remoteHasMore = response.hasMore;

        final existingIds = _allSortedUsers.map((u) => u.uid).toSet();
        final newUsers = response.items
            .where((u) => !existingIds.contains(u.uid))
            .toList();

        if (newUsers.isNotEmpty) {
          _allSortedUsers.addAll(newUsers);
        }
      },
    );
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
}
