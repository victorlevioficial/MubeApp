import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/firestore_resilience.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/services/analytics/analytics_provider.dart';
import '../../../core/services/offline_mutation_coordinator.dart';
import '../../../core/services/offline_mutation_queue.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../chat/data/chat_repository.dart';
import '../../feed/presentation/feed_controller.dart';
import '../data/favorite_repository.dart';
import 'favorite_state.dart';

part 'favorite_controller.g.dart';

@Riverpod(keepAlive: true)
class FavoriteController extends _$FavoriteController {
  // Signals when initial favorites are loaded at least once after login.
  final Completer<void> _initialLoadCompleter = Completer<void>();

  // Latest desired like status per target id (last interaction wins).
  final Map<String, bool> _pendingDesiredStatus = <String, bool>{};

  // Tracks per-target sync currently in flight.
  final Set<String> _syncInProgress = <String>{};

  // Tracks targets whose counts were changed locally in this session.
  final Set<String> _locallyAdjustedCountTargets = <String>{};

  @override
  FavoriteState build() {
    final authState = ref.watch(authStateChangesProvider);
    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityProvider, (
      previous,
      next,
    ) {
      if (previous?.value != ConnectivityStatus.offline ||
          next.value != ConnectivityStatus.online) {
        return;
      }

      for (final targetId in List<String>.from(_pendingDesiredStatus.keys)) {
        unawaited(_processSyncQueue(targetId));
      }
    });

    if (authState.hasValue && authState.value != null) {
      Future.microtask(loadFavorites);
    } else {
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
    }

    return const FavoriteState();
  }

  Future<void> waitForInitialLoad() => _initialLoadCompleter.future;

  Future<void> loadFavorites() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
      return;
    }

    state = state.copyWith(isSyncing: true);
    final store = ref.read(offlineMutationStoreProvider.notifier);

    try {
      await store.ensureUserLoaded(user.uid);
      final serverFavorites = await ref
          .read(favoriteRepositoryProvider)
          .loadFavorites();
      final pendingDesiredStatus = store.favoriteDesiredStatusByTarget();
      for (final entry in pendingDesiredStatus.entries) {
        if (entry.value == serverFavorites.contains(entry.key)) {
          _pendingDesiredStatus.remove(entry.key);
          unawaited(_clearPersistedFavoriteIntent(entry.key));
          continue;
        }

        _pendingDesiredStatus[entry.key] = entry.value;
      }

      final localFavorites = Set<String>.from(serverFavorites);
      pendingDesiredStatus.forEach((targetId, isFavorite) {
        if (isFavorite) {
          localFavorites.add(targetId);
        } else {
          localFavorites.remove(targetId);
        }
      });

      state = state.copyWith(
        localFavorites: localFavorites,
        serverFavorites: serverFavorites,
        isSyncing: false,
      );

      if (ref.read(isOnlineProvider)) {
        for (final targetId in List<String>.from(_pendingDesiredStatus.keys)) {
          unawaited(_processSyncQueue(targetId));
        }
      }
    } catch (e, stackTrace) {
      state = state.copyWith(isSyncing: false);
      AppLogger.error('Erro ao carregar favoritos', e, stackTrace);
    } finally {
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
    }
  }

  bool isLiked(String targetId) {
    return state.localFavorites.contains(targetId);
  }

  /// Seeds/refreshes displayed like count for a target.
  ///
  /// We only refresh an existing value if it was never locally adjusted in this
  /// session, preventing stale backend reads from overwriting optimistic counts.
  void ensureLikeCount(String targetId, int countFromServer) {
    final sanitized = countFromServer < 0 ? 0 : countFromServer;
    final current = state.likeCounts[targetId];

    if (current == null) {
      _setLikeCount(targetId, sanitized);
      return;
    }

    if (!_locallyAdjustedCountTargets.contains(targetId) &&
        current != sanitized) {
      _setLikeCount(targetId, sanitized);
    }
  }

  /// Optimistic toggle with per-target serialization.
  ///
  /// Behavior:
  /// - local state updates instantly
  /// - rapid taps are coalesced (last intent wins)
  /// - server sync runs sequentially per target
  void toggle(String targetId) {
    final isCurrentlyLiked = state.localFavorites.contains(targetId);
    final newStatus = !isCurrentlyLiked;

    _locallyAdjustedCountTargets.add(targetId);
    _setLocalFavorite(targetId, newStatus);
    _applyLikeCountDelta(targetId, isLiked: newStatus);

    // Update count optimistically in feed surfaces.
    ref
        .read(feedControllerProvider.notifier)
        .updateLikeCount(targetId, isLiked: newStatus);

    _pendingDesiredStatus[targetId] = newStatus;
    unawaited(_persistFavoriteIntent(targetId, newStatus));
    unawaited(_processSyncQueue(targetId));
  }

  Future<void> _processSyncQueue(String targetId) async {
    if (_syncInProgress.contains(targetId)) return;

    _syncInProgress.add(targetId);
    final repo = ref.read(favoriteRepositoryProvider);

    try {
      while (true) {
        if (!ref.mounted) return;

        final desiredStatus = _pendingDesiredStatus[targetId];
        if (desiredStatus == null) break;

        final serverStatus = state.serverFavorites.contains(targetId);
        if (desiredStatus == serverStatus) {
          _pendingDesiredStatus.remove(targetId);
          continue;
        }

        if (!ref.read(isOnlineProvider)) {
          ref
              .read(offlineMutationCoordinatorProvider)
              .scheduleFlush(reason: 'favorite_sync_offline');
          break;
        }

        try {
          if (desiredStatus) {
            await repo.addFavorite(targetId);
          } else {
            await repo.removeFavorite(targetId);
          }
          if (!ref.mounted) return;

          // Analytics: fire-and-forget after successful remote sync.
          unawaited(
            ref
                .read(analyticsServiceProvider)
                .logEvent(
                  name: 'favorite_toggled',
                  parameters: {
                    'target_id': targetId,
                    'action': desiredStatus ? 'add' : 'remove',
                  },
                )
                .catchError((_) {}),
          );

          _setServerFavorite(targetId, desiredStatus);
          await _clearPersistedFavoriteIntent(targetId);
          if (!ref.mounted) return;

          if (desiredStatus) {
            final currentUserId = ref
                .read(authRepositoryProvider)
                .currentUser
                ?.uid;
            if (currentUserId != null && currentUserId.isNotEmpty) {
              try {
                final reevaluateResult = await ref
                    .read(chatRepositoryProvider)
                    .reevaluateConversationAccessByUsers(
                      userAId: currentUserId,
                      userBId: targetId,
                      trigger: 'favorite_added',
                    );
                reevaluateResult.fold(
                  (failure) => AppLogger.warning(
                    'Falha ao promover conversa apos favorito',
                    failure.message,
                  ),
                  (_) {},
                );
              } catch (e, stackTrace) {
                AppLogger.warning(
                  'Promocao de conversa apos favorito indisponivel neste contexto',
                  '$e\n$stackTrace',
                );
              }
            }
          }

          if (_pendingDesiredStatus[targetId] == desiredStatus) {
            _pendingDesiredStatus.remove(targetId);
          }
        } catch (e, stackTrace) {
          if (!ref.mounted) return;

          final latestDesired = _pendingDesiredStatus[targetId];
          final currentServerStatus = state.serverFavorites.contains(targetId);
          final shouldPreservePendingChange =
              latestDesired == desiredStatus &&
              _shouldPreservePendingFavoriteChange(e);

          // Only rollback when this failing request is still the latest intent.
          if (latestDesired == desiredStatus) {
            _pendingDesiredStatus.remove(targetId);

            if (shouldPreservePendingChange) {
              ref
                  .read(offlineMutationCoordinatorProvider)
                  .scheduleFlush(reason: 'favorite_sync_retry');
            } else {
              await _clearPersistedFavoriteIntent(targetId);
              if (!ref.mounted) return;

              if (desiredStatus != currentServerStatus) {
                _applyLikeCountDelta(targetId, isLiked: currentServerStatus);
              }

              final currentLocalStatus = state.localFavorites.contains(
                targetId,
              );
              if (currentLocalStatus != currentServerStatus) {
                _setLocalFavorite(targetId, currentServerStatus);
                ref
                    .read(feedControllerProvider.notifier)
                    .updateLikeCount(targetId, isLiked: currentServerStatus);
              }
            }
          }

          AppLogger.error(
            'Erro ao sincronizar favorito: $targetId',
            e,
            stackTrace,
          );
        }
      }
    } finally {
      _syncInProgress.remove(targetId);
      if (ref.mounted) {
        // Handle edge-case where a new toggle was queued exactly while leaving loop.
        final pendingStatus = _pendingDesiredStatus[targetId];
        if (pendingStatus != null &&
            ref.read(isOnlineProvider) &&
            pendingStatus != state.serverFavorites.contains(targetId)) {
          unawaited(_processSyncQueue(targetId));
        }
      }
    }
  }

  Future<void> _persistFavoriteIntent(
    String targetId,
    bool desiredStatus,
  ) async {
    final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
    final store = ref.read(offlineMutationStoreProvider.notifier);
    await store.ensureUserLoaded(currentUserId);
    await store.upsertFavoriteDesiredState(
      targetId: targetId,
      isFavorite: desiredStatus,
    );
  }

  Future<void> _clearPersistedFavoriteIntent(String targetId) async {
    await ref
        .read(offlineMutationStoreProvider.notifier)
        .removeScopeKey(favoriteMutationScopeKey(targetId));
  }

  bool _shouldPreservePendingFavoriteChange(Object error) {
    if (!ref.read(isOnlineProvider)) {
      return true;
    }

    return isRecoverableFirestoreError(error);
  }

  void _applyLikeCountDelta(String targetId, {required bool isLiked}) {
    final current = state.likeCounts[targetId] ?? 0;
    final next = isLiked ? current + 1 : (current - 1).clamp(0, 1 << 30);
    _setLikeCount(targetId, next.toInt());
  }

  void _setLikeCount(String targetId, int count) {
    final next = Map<String, int>.from(state.likeCounts);
    next[targetId] = count < 0 ? 0 : count;
    state = state.copyWith(likeCounts: next);
  }

  void _setLocalFavorite(String targetId, bool isLiked) {
    final next = Set<String>.from(state.localFavorites);
    if (isLiked) {
      next.add(targetId);
    } else {
      next.remove(targetId);
    }
    state = state.copyWith(localFavorites: next);
  }

  void _setServerFavorite(String targetId, bool isLiked) {
    final next = Set<String>.from(state.serverFavorites);
    if (isLiked) {
      next.add(targetId);
    } else {
      next.remove(targetId);
    }
    state = state.copyWith(serverFavorites: next);
  }
}
