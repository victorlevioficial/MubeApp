part of 'package:mube/src/app.dart';

extension _MubeAppUpdateNoticePrompt on _MubeAppState {
  Future<void> _maybeShowAppUpdateNotice() async {
    if (!mounted || !_appUpdateNoticeCoordinator.canEvaluate) {
      return;
    }

    final currentPath = _currentAppPath;
    if (currentPath == RoutePaths.splash) {
      return;
    }

    _appUpdateNoticeCoordinator.startEvaluation();
    final notice = await (() async {
      try {
        return await ref.read(appUpdateNoticeProvider.future);
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Failed to evaluate app update notice',
          error,
          stackTrace,
        );
        return null;
      }
    })();

    if (!mounted) {
      _appUpdateNoticeCoordinator.finishEvaluation(keepPending: false);
      return;
    }

    if (notice == null) {
      _appUpdateNoticeCoordinator.finishEvaluation(keepPending: false);
      _resumeDeferredSessionDialogs();
      return;
    }

    _appUpdateNoticeCoordinator.finishEvaluation(keepPending: false);
    _appUpdateNoticeCoordinator.beginDisplay();
  }
}
