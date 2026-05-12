part of 'package:mube/src/app.dart';

extension _MubeAppPushNavigation on _MubeAppState {
  void _setupPushListeners() {
    final eventBus = PushNotificationEventBus.instance;

    // Badge count now comes from Firestore stream automatically.
    // We only need to handle navigation when user taps a notification.
    _onMessageOpenedSub = eventBus.onNavigation.listen((intent) {
      if (!mounted) return;
      _pendingPushNavigationIntent = intent;
      _dispatchPendingPushNavigationIfPossible();
    });
  }

  bool _dispatchPendingPushNavigationIfPossible() {
    if (!mounted || _isPushNavigationDispatchScheduled) return false;

    final pendingIntent = _pendingPushNavigationIntent;
    final targetPath = _resolvePushNavigationTarget(pendingIntent);
    if (pendingIntent == null || targetPath == null) {
      _pendingPushNavigationIntent = null;
      return false;
    }

    final currentPath = _goRouter.routerDelegate.currentConfiguration.uri.path;
    if (_shouldDeferPushNavigation(currentPath)) {
      return false;
    }

    if (currentPath == targetPath) {
      _pendingPushNavigationIntent = null;
      return false;
    }

    _isPushNavigationDispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPushNavigationDispatchScheduled = false;
      if (!mounted) return;

      final latestIntent = _pendingPushNavigationIntent;
      final latestTargetPath = _resolvePushNavigationTarget(latestIntent);
      if (latestIntent == null || latestTargetPath == null) {
        _pendingPushNavigationIntent = null;
        return;
      }

      final activePath = _goRouter.routerDelegate.currentConfiguration.uri.path;
      if (_shouldDeferPushNavigation(activePath)) {
        return;
      }

      if (activePath == latestTargetPath) {
        _pendingPushNavigationIntent = null;
        return;
      }

      _pendingPushNavigationIntent = null;
      AppLogger.debug(
        '[PushNavigation] Navigating to $latestTargetPath from $activePath',
      );
      unawaited(_goRouter.push(latestTargetPath, extra: latestIntent.extra));
    });

    return true;
  }

  String? _resolvePushNavigationTarget(PushNavigationIntent? intent) {
    if (intent == null) return null;

    final route = intent.route?.trim();
    if (route != null && route.isNotEmpty) {
      return route;
    }

    final conversationId = intent.conversationId?.trim();
    if (conversationId != null && conversationId.isNotEmpty) {
      return RoutePaths.conversationById(conversationId);
    }

    return null;
  }

  bool _shouldDeferPushNavigation(String currentPath) {
    if (currentPath == RoutePaths.splash ||
        currentPath == RoutePaths.login ||
        currentPath == RoutePaths.register ||
        currentPath == RoutePaths.forgotPassword ||
        currentPath == RoutePaths.emailVerification) {
      return true;
    }

    return currentPath.startsWith(RoutePaths.onboarding);
  }
}
