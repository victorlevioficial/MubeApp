part of 'package:mube/src/app.dart';

extension _MubeAppBandReminderPrompt on _MubeAppState {
  Future<void> _maybeShowBandMembersReminder(AppUser? profile) async {
    if (!mounted ||
        _appUpdateNoticeCoordinator.blocksOtherPrompts ||
        !_bandMembersReminderCoordinator.canPresent) {
      return;
    }

    final currentPath = _currentAppPath;
    if (_shouldWaitForBandMembersReminderRoute(currentPath)) {
      return;
    }

    if (profile == null) {
      return;
    }

    if (!profile.isCadastroConcluido) {
      _bandMembersReminderCoordinator.skipForSession(
        reason: 'registration_incomplete',
        currentPath: currentPath,
      );
      return;
    }

    if (profile.tipoPerfil != AppUserType.band) {
      _bandMembersReminderCoordinator.skipForSession(
        reason: 'not_a_band',
        currentPath: currentPath,
      );
      return;
    }

    if (isBandEligibleForActivation(profile.members.length)) {
      _bandMembersReminderCoordinator.skipForSession(
        reason: 'minimum_members_met',
        currentPath: currentPath,
      );
      return;
    }

    if (!_canShowBandMembersReminderOnPath(currentPath)) {
      _bandMembersReminderCoordinator.skipForSession(
        reason: 'path_not_supported',
        currentPath: currentPath,
      );
      return;
    }

    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_maybeShowBandMembersReminder(_currentPromptProfile));
      });
      return;
    }

    _bandMembersReminderCoordinator.beginDisplay();

    final shouldOpenManageMembers = await BandFormationReminderDialog.show(
      context: dialogContext,
      bandName: profile.appDisplayName,
      acceptedMembers: profile.members.length,
    );

    _bandMembersReminderCoordinator.endDisplay();
    if (!mounted || !shouldOpenManageMembers) return;

    final activePath = _currentAppPath;
    if (activePath != RoutePaths.manageMembers) {
      unawaited(_goRouter.push(RoutePaths.manageMembers));
    }
  }
}
