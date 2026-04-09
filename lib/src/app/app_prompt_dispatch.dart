part of 'package:mube/src/app.dart';

extension _MubeAppPromptDispatch on _MubeAppState {
  void _handleRouterStateChanged() {
    final currentPath = _currentAppPath;
    if (currentPath == RoutePaths.splash) return;

    final outboxCoordinator = ref.read(
      matchpointSwipeOutboxCoordinatorProvider,
    );
    if (_isMatchpointRoute(currentPath)) {
      outboxCoordinator.cancelScheduledFlush(
        reason: 'matchpoint_route_active:$currentPath',
      );
    } else {
      outboxCoordinator.scheduleFlush(reason: 'route_changed:$currentPath');
    }

    if (!_hasReleasedInitialRoute) {
      _hasReleasedInitialRoute = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onInitialRouteReady?.call();
      });
    }

    if (_dispatchPendingPushNavigationIfPossible()) {
      return;
    }

    unawaited(_maybeShowAppUpdateNotice());
    unawaited(_maybeShowBandMembersReminder(_currentPromptProfile));
    unawaited(_maybeShowGigReviewReminder(_currentPromptProfile));
    unawaited(_maybeShowStoreReviewPrompt());
  }

  void _resumeDeferredSessionDialogs() {
    unawaited(_maybeShowBandMembersReminder(_currentPromptProfile));
    unawaited(_maybeShowGigReviewReminder(_currentPromptProfile));
    unawaited(_maybeShowStoreReviewPrompt());
  }
}
