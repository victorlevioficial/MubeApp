import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/favorites/data/favorite_repository.dart';
import '../../features/gigs/data/gig_repository.dart';
import '../../utils/app_logger.dart';
import '../errors/firestore_resilience.dart';
import '../providers/connectivity_provider.dart';
import 'offline_mutation_queue.dart';

class OfflineMutationCoordinator {
  OfflineMutationCoordinator(this._ref);

  final Ref _ref;

  Timer? _flushTimer;
  bool _isFlushing = false;

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void cancelScheduledFlush({String reason = 'unspecified'}) {
    if (_flushTimer == null) return;
    _flushTimer?.cancel();
    _flushTimer = null;
    AppLogger.info('Offline mutation flush canceled: reason=$reason');
  }

  void scheduleFlush({
    Duration delay = const Duration(seconds: 8),
    String reason = 'unspecified',
  }) {
    _flushTimer?.cancel();
    _flushTimer = Timer(delay, () {
      unawaited(flushNow(reason: reason));
    });
  }

  Future<void> flushNow({String reason = 'unspecified'}) async {
    if (_isFlushing || !_ref.mounted) return;

    final currentUser = _ref.read(authRepositoryProvider).currentUser;
    if (currentUser == null || currentUser.uid.isEmpty) {
      return;
    }

    await _ref
        .read(offlineMutationStoreProvider.notifier)
        .ensureUserLoaded(currentUser.uid);
    if (!_ref.mounted) return;

    final store = _ref.read(offlineMutationStoreProvider.notifier);
    if (store.entries.isEmpty) {
      return;
    }

    if (!_ref.read(isOnlineProvider)) {
      AppLogger.info(
        'Offline mutation flush skipped: offline reason=$reason uid=${currentUser.uid}',
      );
      return;
    }

    _isFlushing = true;
    try {
      AppLogger.info(
        'Offline mutation flush started: reason=$reason uid=${currentUser.uid} entries=${store.entries.length}',
      );

      for (final entry in store.entries) {
        if (!_ref.mounted) return;

        try {
          switch (entry.type) {
            case OfflineMutationType.favoriteAdd:
              await _flushFavoriteMutation(entry, isFavorite: true);
            case OfflineMutationType.favoriteRemove:
              await _flushFavoriteMutation(entry, isFavorite: false);
            case OfflineMutationType.gigApply:
              await _flushGigApplyMutation(entry);
          }

          await store.removeScopeKey(entry.scopeKey);
        } catch (error, stackTrace) {
          if (_isRecoverable(error)) {
            await store.markRetry(entry.scopeKey);
            AppLogger.warning(
              'Offline mutation flush will retry later: scope=${entry.scopeKey}',
              error,
              stackTrace,
              false,
            );
            break;
          }

          await store.removeScopeKey(entry.scopeKey);
          AppLogger.error(
            'Offline mutation dropped after permanent failure: scope=${entry.scopeKey}',
            error,
            stackTrace,
          );
        }
      }
    } finally {
      _isFlushing = false;
    }
  }

  Future<void> _flushFavoriteMutation(
    OfflineMutation entry, {
    required bool isFavorite,
  }) async {
    final targetId = entry.favoriteTargetId?.trim() ?? '';
    if (targetId.isEmpty) {
      return;
    }

    final repository = _ref.read(favoriteRepositoryProvider);
    if (isFavorite) {
      await repository.addFavorite(targetId);
      return;
    }

    await repository.removeFavorite(targetId);
  }

  Future<void> _flushGigApplyMutation(OfflineMutation entry) async {
    final gigId = entry.gigId?.trim() ?? '';
    final message = entry.gigMessage?.trim() ?? '';
    if (gigId.isEmpty || message.isEmpty) {
      return;
    }

    try {
      await _ref.read(gigRepositoryProvider).applyToGig(gigId, message);
    } on GigApplicationAlreadyExistsException {
      // Treat replay after a successful remote write as convergent success.
      return;
    }
  }

  bool _isRecoverable(Object error) {
    if (!_ref.read(isOnlineProvider)) {
      return true;
    }

    return isRecoverableFirestoreError(error);
  }
}

final offlineMutationCoordinatorProvider = Provider<OfflineMutationCoordinator>(
  (ref) {
    final coordinator = OfflineMutationCoordinator(ref);

    ref.read(offlineMutationStoreProvider);

    ref.listen<AsyncValue<ConnectivityStatus>>(connectivityProvider, (
      previous,
      next,
    ) {
      final previousStatus = previous?.value;
      final nextStatus = next.value;
      if (previousStatus == ConnectivityStatus.offline &&
          nextStatus == ConnectivityStatus.online) {
        coordinator.scheduleFlush(
          delay: const Duration(milliseconds: 600),
          reason: 'connectivity_restored',
        );
      }

      if (nextStatus == ConnectivityStatus.offline) {
        coordinator.cancelScheduledFlush(reason: 'connectivity_lost');
      }
    });

    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      next.whenData((user) {
        if (user == null) {
          coordinator.cancelScheduledFlush(reason: 'auth_logged_out');
          return;
        }

        coordinator.scheduleFlush(
          delay: const Duration(milliseconds: 350),
          reason: 'auth_logged_in',
        );
      });
    });

    ref.onDispose(coordinator.dispose);
    return coordinator;
  },
);
