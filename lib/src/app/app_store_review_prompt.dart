part of 'package:mube/src/app.dart';

extension _MubeAppStoreReviewPrompt on _MubeAppState {
  Future<void> _maybeShowStoreReviewPrompt() async {
    if (!mounted ||
        _isStoreReviewEvaluationInProgress ||
        _appUpdateNoticeCoordinator.blocksOtherPrompts ||
        _bandMembersReminderCoordinator.blocksOtherPrompts ||
        _gigReviewReminderCoordinator.blocksOtherPrompts) {
      return;
    }

    final currentPath = _currentAppPath;
    if (_shouldWaitForBandMembersReminderRoute(currentPath) ||
        !_canShowBandMembersReminderOnPath(currentPath)) {
      return;
    }

    if (ref.read(authRepositoryProvider).currentUser == null) {
      return;
    }

    _isStoreReviewEvaluationInProgress = true;
    try {
      await ref.read(storeReviewServiceProvider).requestIfEligible();
    } finally {
      _isStoreReviewEvaluationInProgress = false;
    }
  }
}
