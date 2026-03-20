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

    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      _appUpdateNoticeCoordinator.finishEvaluation(keepPending: true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_maybeShowAppUpdateNotice());
      });
      return;
    }

    _appUpdateNoticeCoordinator.finishEvaluation(keepPending: false);
    _appUpdateNoticeCoordinator.beginDisplay();
    final shouldOpenStore = await AppUpdateNoticeDialog.show(
      dialogContext,
      notice: notice,
    );
    _appUpdateNoticeCoordinator.endDisplay();

    if (!mounted) return;

    if (shouldOpenStore == true && notice.storeUri != null) {
      final opened = await ref.read(appUpdateLauncherProvider)(
        notice.storeUri!,
      );
      if (!mounted) return;
      if (!opened) {
        final currentContext = rootNavigatorKey.currentContext;
        if (currentContext != null && currentContext.mounted) {
          AppSnackBar.error(currentContext, 'Nao foi possivel abrir a loja.');
        }
      }
    }

    _resumeDeferredSessionDialogs();
  }
}
