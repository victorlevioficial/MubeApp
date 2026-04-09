part of 'package:mube/src/app.dart';

extension _MubeAppPromptGuards on _MubeAppState {
  String get _currentAppPath =>
      _goRouter.routerDelegate.currentConfiguration.uri.path;

  AppUser? get _currentPromptProfile =>
      ref.read(currentUserProfileProvider).value;

  bool _isMatchpointRoute(String currentPath) {
    return currentPath == RoutePaths.matchpoint ||
        currentPath.startsWith('${RoutePaths.matchpoint}/');
  }

  bool _shouldWaitForBandMembersReminderRoute(String currentPath) {
    return currentPath == RoutePaths.splash ||
        currentPath == RoutePaths.login ||
        currentPath == RoutePaths.register ||
        currentPath == RoutePaths.forgotPassword ||
        currentPath == RoutePaths.emailVerification ||
        currentPath == RoutePaths.notificationPermission;
  }

  bool _canShowBandMembersReminderOnPath(String currentPath) {
    if (currentPath.startsWith(RoutePaths.onboarding)) {
      return false;
    }

    return !RoutePaths.isPublic(currentPath);
  }
}
