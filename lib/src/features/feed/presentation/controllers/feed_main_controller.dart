import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../constants/firestore_constants.dart';
import '../../../../core/mixins/pagination_mixin.dart';
import '../../../../utils/app_logger.dart';
import '../../../auth/domain/app_user.dart';
import '../../data/feed_repository.dart';
import '../../domain/feed_item.dart';
import '../feed_state.dart';

/// Estado operacional do feed principal que não pertence ao estado de UI.
class FeedMainRuntime {
  List<FeedItem> allSortedUsers = [];
  bool remoteHasMore = true;
  bool geoFetchCompleted = false;
  DocumentSnapshot? lastMainFeedDocument;
  double? userLat;
  double? userLong;
}

/// Controller especializado na paginação e carga do feed principal.
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
    required int batchSize,
  }) async {
    if (reset) {
      runtime.remoteHasMore = true;
      runtime.geoFetchCompleted = false;
      runtime.lastMainFeedDocument = null;
    }

    try {
      final localRemaining =
          runtime.allSortedUsers.length -
          (currentState.currentPage * currentState.pageSize);
      final canTryRemote = runtime.remoteHasMore;
      final shouldFetchFromFirestore =
          reset || (localRemaining <= 0 && canTryRemote);

      AppLogger.debug(
        'Feed Debug: localRemaining=$localRemaining, '
        'shouldFetch=$shouldFetchFromFirestore, reset=$reset, '
        'total=${runtime.allSortedUsers.length}',
      );

      if (shouldFetchFromFirestore) {
        final filterType = _resolveFilterType(currentState.currentFilter);
        final isNearbyFilter = currentState.currentFilter == 'Perto de mim';
        var shouldFetchCursor = false;

        if (runtime.userLat != null && runtime.userLong != null) {
          if (!runtime.geoFetchCompleted) {
            var fallbackToCursor = false;
            var shouldReturnError = false;
            String? errorMessage;

            AppLogger.debug('Feed: Buscando usuários do Firestore...');
            final result = await _feedRepository.getNearbyUsersOptimized(
              currentUserId: user.uid,
              userLat: runtime.userLat!,
              userLong: runtime.userLong!,
              filterType: filterType,
              excludedIds: blockedIds,
              targetResults: batchSize,
            );

            result.fold(
              (failure) {
                AppLogger.error('Feed: Erro ao buscar usuários', failure);
                if (reset) {
                  shouldReturnError = true;
                  errorMessage = failure.message;
                  runtime.allSortedUsers = [];
                }
              },
              (success) {
                AppLogger.debug(
                  'Feed: ${success.length} usuários retornados do Firestore',
                );
                if (reset) {
                  runtime.allSortedUsers = success;
                  fallbackToCursor = success.isEmpty;
                } else {
                  final existingIds = runtime.allSortedUsers
                      .map((u) => u.uid)
                      .toSet();
                  final newUsers = success
                      .where((u) => !existingIds.contains(u.uid))
                      .toList();
                  AppLogger.debug(
                    'Feed: ${newUsers.length} usuários são novos',
                  );

                  if (newUsers.isEmpty) {
                    AppLogger.debug('Feed: Nenhum usuário novo encontrado');
                    fallbackToCursor = true;
                  } else {
                    runtime.allSortedUsers.addAll(newUsers);
                    runtime.allSortedUsers.sort(
                      (a, b) =>
                          (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
                    );
                  }
                }

                runtime.geoFetchCompleted = true;

                if (fallbackToCursor) {
                  if (isNearbyFilter) {
                    runtime.remoteHasMore = false;
                  } else {
                    shouldFetchCursor = true;
                  }
                }
              },
            );

            if (shouldReturnError) {
              return currentState.copyWithFeed(
                status: PaginationStatus.error,
                errorMessage: errorMessage ?? 'Erro ao buscar usuários',
              );
            }
          } else {
            if (isNearbyFilter) {
              runtime.remoteHasMore = false;
            } else {
              shouldFetchCursor = true;
            }
          }
        } else {
          if (isNearbyFilter) {
            runtime.remoteHasMore = false;
          } else {
            shouldFetchCursor = true;
          }
        }

        if (shouldFetchCursor) {
          await _fetchMainFeedPage(
            userId: user.uid,
            filterType: filterType,
            reset: reset,
            blockedIds: blockedIds,
            runtime: runtime,
            limit: batchSize,
          );
        }
      } else {
        AppLogger.debug(
          'Feed: Usando paginação local, $localRemaining usuários restantes',
        );
      }

      if (blockedIds.isNotEmpty) {
        runtime.allSortedUsers.removeWhere(
          (item) => blockedIds.contains(item.uid),
        );
      }

      final page = reset ? 0 : currentState.currentPage;
      final startIndex = page * currentState.pageSize;
      if (startIndex >= runtime.allSortedUsers.length) {
        final hasMore = runtime.remoteHasMore;
        final baseState = reset
            ? currentState.copyWithFeed(items: [], currentPage: 0)
            : currentState;

        return baseState.copyWithFeed(
          status: hasMore
              ? PaginationStatus.loaded
              : PaginationStatus.noMoreData,
          hasMore: hasMore,
        );
      }

      final endIndex = (startIndex + currentState.pageSize).clamp(
        0,
        runtime.allSortedUsers.length,
      );

      final newItems = runtime.allSortedUsers.sublist(startIndex, endIndex);
      final allItems = reset ? newItems : [...currentState.items, ...newItems];

      final hasMoreLocal = endIndex < runtime.allSortedUsers.length;
      final hasMore = hasMoreLocal || runtime.remoteHasMore;

      AppLogger.debug(
        'Feed: endIndex=$endIndex, total=${runtime.allSortedUsers.length}, hasMore=$hasMore',
      );

      return currentState.copyWithFeed(
        items: allItems,
        status: hasMore ? PaginationStatus.loaded : PaginationStatus.noMoreData,
        currentPage: page + 1,
        hasMore: hasMore,
      );
    } catch (error) {
      return currentState.copyWithFeed(
        status: PaginationStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> _fetchMainFeedPage({
    required String userId,
    required String? filterType,
    required bool reset,
    required List<String> blockedIds,
    required FeedMainRuntime runtime,
    required int limit,
  }) async {
    final result = await _feedRepository.getMainFeedPaginated(
      currentUserId: userId,
      filterType: filterType,
      userLat: runtime.userLat,
      userLong: runtime.userLong,
      limit: limit,
      startAfter: runtime.lastMainFeedDocument,
    );

    result.fold(
      (failure) {
        AppLogger.error('Feed: Erro ao buscar página', failure);
        // Mantém o comportamento anterior: marca fim remoto e deixa paginação
        // local decidir o estado final.
        runtime.remoteHasMore = false;
        if (reset) {
          AppLogger.debug(
            'Feed: falha em cursor durante reset, mantendo fallback local',
          );
        }
      },
      (response) {
        runtime.lastMainFeedDocument = response.lastDocument;
        runtime.remoteHasMore = response.hasMore;

        final remoteItems = blockedIds.isEmpty
            ? response.items
            : response.items
                  .where((item) => !blockedIds.contains(item.uid))
                  .toList();

        final existingIds = runtime.allSortedUsers.map((u) => u.uid).toSet();
        final newUsers = remoteItems
            .where((u) => !existingIds.contains(u.uid))
            .toList();

        if (newUsers.isNotEmpty) {
          runtime.allSortedUsers.addAll(newUsers);
        }
      },
    );
  }

  String? _resolveFilterType(String currentFilter) {
    switch (currentFilter) {
      case 'Profissionais':
        return ProfileType.professional;
      case 'Bandas':
        return ProfileType.band;
      case 'Estúdios':
        return ProfileType.studio;
      default:
        return null;
    }
  }
}
