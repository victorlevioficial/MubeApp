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
  // A completer to signal when the initial favorite list has been loaded.
  final Completer<void> _initialLoadCompleter = Completer<void>();

  @override
  FavoriteState build() {
    final authState = ref.watch(authStateChangesProvider);

    // When a user logs in, trigger the initial load.
    if (authState.hasValue && authState.value != null) {
      Future.microtask(() => loadFavorites());
    } else {
      // If the user logs out, complete the future if it's not already.
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
    }

    return const FavoriteState();
  }

  /// Allows other providers to wait until the initial set of favorites is loaded.
  Future<void> waitForInitialLoad() => _initialLoadCompleter.future;

  /// Loads the initial list of favorites from the repository.
  Future<void> loadFavorites() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) {
      if (!_initialLoadCompleter.isCompleted) _initialLoadCompleter.complete();
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
      // Signal that the initial load is complete, regardless of success or failure.
      if (!_initialLoadCompleter.isCompleted) {
        _initialLoadCompleter.complete();
      }
    }
  }

  bool isLiked(String targetId) {
    return state.localFavorites.contains(targetId);
  }

  /// Toggles the favorite status of an item using an optimistic UI approach.
  void toggle(String targetId) {
    final isCurrentlyLiked = state.localFavorites.contains(targetId);
    final newStatus = !isCurrentlyLiked;

    final newLocal = Set<String>.from(state.localFavorites);
    if (newStatus) {
      newLocal.add(targetId);
    } else {
      newLocal.remove(targetId);
    }
    state = state.copyWith(localFavorites: newLocal);

    _syncToggleWithServer(targetId, newStatus);
  }

  /// Synchronizes the new favorite status with the server and handles rollbacks.
  Future<void> _syncToggleWithServer(String targetId, bool newStatus) async {
    final repo = ref.read(favoriteRepositoryProvider);

    try {
      if (newStatus) {
        await repo.addFavorite(targetId);
      } else {
        await repo.removeFavorite(targetId);
      }

      final newServer = Set<String>.from(state.serverFavorites);
      if (newStatus) {
        newServer.add(targetId);
      } else {
        newServer.remove(targetId);
      }
      state = state.copyWith(serverFavorites: newServer);

      ref
          .read(feedControllerProvider.notifier)
          .updateLikeCount(targetId, isLiked: newStatus);
    } catch (e) {
      // Rollback optimistic UI on failure
      final originalServerStatus = state.serverFavorites.contains(targetId);
      final currentLocalStatus = state.localFavorites.contains(targetId);

      if (originalServerStatus != currentLocalStatus) {
        final newLocal = Set<String>.from(state.localFavorites);
        if (originalServerStatus) {
          newLocal.add(targetId);
        } else {
          newLocal.remove(targetId);
        }
        state = state.copyWith(localFavorites: newLocal);
      }

      AppLogger.error('Erro ao sincronizar favorito: $targetId', e);
    }
  }
}
