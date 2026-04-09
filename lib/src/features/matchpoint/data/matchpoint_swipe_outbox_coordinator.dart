import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/connectivity_provider.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import 'matchpoint_swipe_command_repository.dart';

class MatchpointSwipeOutboxCoordinator {
  final Ref _ref;
  Timer? _flushTimer;
  bool _isFlushing = false;

  MatchpointSwipeOutboxCoordinator(this._ref);

  void dispose() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void cancelScheduledFlush({String reason = 'unspecified'}) {
    if (_flushTimer == null) return;
    _flushTimer?.cancel();
    _flushTimer = null;
    AppLogger.info('MatchPoint outbox flush canceled: reason=$reason');
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

    if (!_ref.read(isOnlineProvider)) {
      AppLogger.info(
        'MatchPoint outbox flush skipped: offline reason=$reason uid=${currentUser.uid}',
      );
      return;
    }

    _isFlushing = true;
    try {
      AppLogger.info(
        'MatchPoint outbox flush started: reason=$reason uid=${currentUser.uid}',
      );
      await _ref
          .read(matchpointSwipeCommandRepositoryProvider)
          .flushPending(userId: currentUser.uid);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'MatchPoint outbox flush failed',
        error,
        stackTrace,
        false,
      );
    } finally {
      _isFlushing = false;
    }
  }
}

final matchpointSwipeOutboxCoordinatorProvider =
    Provider<MatchpointSwipeOutboxCoordinator>((ref) {
      final coordinator = MatchpointSwipeOutboxCoordinator(ref);
      ref.onDispose(coordinator.dispose);
      return coordinator;
    });
