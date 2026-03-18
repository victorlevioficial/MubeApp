import '../../utils/app_logger.dart';

/// Tracks per-session prompt state that can temporarily block other dialogs.
class SessionPromptCoordinator {
  SessionPromptCoordinator({bool pendingInitially = false})
    : _hasPendingEvaluation = pendingInitially;

  bool _hasPendingEvaluation;
  bool _hasShownForSession = false;
  bool _isEvaluating = false;
  bool _isVisible = false;

  bool get canEvaluate =>
      _hasPendingEvaluation &&
      !_hasShownForSession &&
      !_isEvaluating &&
      !_isVisible;

  bool get blocksOtherPrompts =>
      _hasPendingEvaluation || _isEvaluating || _isVisible;

  void startEvaluation() {
    _isEvaluating = true;
  }

  void finishEvaluation({required bool keepPending}) {
    _isEvaluating = false;
    _hasPendingEvaluation = keepPending;
  }

  void beginDisplay() {
    _hasPendingEvaluation = false;
    _hasShownForSession = true;
    _isVisible = true;
  }

  void endDisplay() {
    _isVisible = false;
  }
}

/// Tracks prompt state that resets whenever the authenticated user changes.
class UserScopedSessionPromptCoordinator {
  UserScopedSessionPromptCoordinator({required this.logLabel});

  final String logLabel;

  String? _userId;
  bool _hasPendingEvaluation = false;
  bool _hasShownForSession = false;
  bool _isVisible = false;

  bool get canPresent =>
      _hasPendingEvaluation && !_hasShownForSession && !_isVisible;

  bool handleAuthUser(String? userId) {
    if (userId == null) {
      _userId = null;
      _hasPendingEvaluation = false;
      _hasShownForSession = false;
      _isVisible = false;
      return false;
    }

    if (_userId == userId) {
      return false;
    }

    _userId = userId;
    _hasPendingEvaluation = true;
    _hasShownForSession = false;
    _isVisible = false;
    return true;
  }

  void beginDisplay() {
    _hasPendingEvaluation = false;
    _hasShownForSession = true;
    _isVisible = true;
  }

  void endDisplay() {
    _isVisible = false;
  }

  void skipForSession({required String reason, required String currentPath}) {
    _hasPendingEvaluation = false;
    AppLogger.debug('[$logLabel] Skipped for session: $reason ($currentPath)');
  }
}
