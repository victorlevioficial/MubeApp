import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
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

    try {
      final serverFavorites = await ref
          .read(favoriteRepositoryProvider)
          .loadFavorites();

      state = state.copyWith(
        localFavorites: Set<String>.from(serverFavorites),
        serverFavorites: serverFavorites,
        isSyncing: false,
      );
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
    unawaited(_processSyncQueue(targetId));
  }

  Future<void> _processSyncQueue(String targetId) async {
    if (_syncInProgress.contains(targetId)) return;

    _syncInProgress.add(targetId);
    final repo = ref.read(favoriteRepositoryProvider);

    try {
      while (true) {
        final desiredStatus = _pendingDesiredStatus[targetId];
        if (desiredStatus == null) break;

        final serverStatus = state.serverFavorites.contains(targetId);
        if (desiredStatus == serverStatus) {
          _pendingDesiredStatus.remove(targetId);
          continue;
        }

        try {
          if (desiredStatus) {
            await repo.addFavorite(targetId);
          } else {
            await repo.removeFavorite(targetId);
          }

          _setServerFavorite(targetId, desiredStatus);

          if (_pendingDesiredStatus[targetId] == desiredStatus) {
            _pendingDesiredStatus.remove(targetId);
          }
        } catch (e, stackTrace) {
          final latestDesired = _pendingDesiredStatus[targetId];
          final currentServerStatus = state.serverFavorites.contains(targetId);

          // Only rollback when this failing request is still the latest intent.
          if (latestDesired == desiredStatus) {
            _pendingDesiredStatus.remove(targetId);

            if (desiredStatus != currentServerStatus) {
              _applyLikeCountDelta(targetId, isLiked: currentServerStatus);
            }

            final currentLocalStatus = state.localFavorites.contains(targetId);
            if (currentLocalStatus != currentServerStatus) {
              _setLocalFavorite(targetId, currentServerStatus);
              ref
                  .read(feedControllerProvider.notifier)
                  .updateLikeCount(targetId, isLiked: currentServerStatus);
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

      // Handle edge-case where a new toggle was queued exactly while leaving loop.
      final pendingStatus = _pendingDesiredStatus[targetId];
      if (pendingStatus != null &&
          pendingStatus != state.serverFavorites.contains(targetId)) {
        unawaited(_processSyncQueue(targetId));
      }
    }
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
