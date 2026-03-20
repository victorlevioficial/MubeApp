part of 'package:mube/src/app.dart';

extension _MubeAppGigReviewPrompt on _MubeAppState {
  Future<void> _maybeShowGigReviewReminder(AppUser? profile) async {
    if (!mounted ||
        _appUpdateNoticeCoordinator.blocksOtherPrompts ||
        !_gigReviewReminderCoordinator.canPresent) {
      return;
    }

    final currentPath = _currentAppPath;
    if (_shouldWaitForBandMembersReminderRoute(currentPath) ||
        !_canShowBandMembersReminderOnPath(currentPath)) {
      return;
    }

    if (profile == null || !profile.isCadastroConcluido) {
      return;
    }

    final dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_maybeShowGigReviewReminder(_currentPromptProfile));
      });
      return;
    }

    final List<GigReviewOpportunity> opportunities = await (() async {
      try {
        return await ref.read(pendingGigReviewsProvider.future);
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Failed to load pending gig reviews for reminder',
          error,
          stackTrace,
        );
        return <GigReviewOpportunity>[];
      }
    })();

    _gigReviewReminderCoordinator.beginDisplay();

    if (!mounted || opportunities.isEmpty) {
      _gigReviewReminderCoordinator.endDisplay();
      return;
    }

    final activeDialogContext = rootNavigatorKey.currentContext;
    if (activeDialogContext == null || !activeDialogContext.mounted) {
      _gigReviewReminderCoordinator.endDisplay();
      return;
    }

    final opportunity = opportunities.first;
    final shouldOpenReview = await GigReviewReminderDialog.show(
      activeDialogContext,
      opportunity: opportunity,
    );

    _gigReviewReminderCoordinator.endDisplay();
    if (!mounted || shouldOpenReview != true) return;

    final route = RoutePaths.gigReviewById(
      opportunity.gigId,
      opportunity.reviewedUserId,
    );
    if (_currentAppPath != route) {
      unawaited(
        _goRouter.push(
          route,
          extra: {
            'userName': opportunity.reviewedUserName,
            'userPhoto': opportunity.reviewedUserPhoto,
            'gigTitle': opportunity.gigTitle,
          },
        ),
      );
    }
  }
}
