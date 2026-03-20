part of 'package:mube/src/app.dart';

extension _MubeAppPromptDispatch on _MubeAppState {
  void _handleRouterStateChanged() {
    final currentPath = _currentAppPath;
    if (!_hasReleasedInitialRoute) {
      if (currentPath == RoutePaths.splash) return;

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
