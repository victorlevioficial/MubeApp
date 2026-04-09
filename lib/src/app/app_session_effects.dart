part of 'package:mube/src/app.dart';

extension _MubeAppSessionEffects on _MubeAppState {
  void _initializeSessionEffects() {
    _goRouter.routerDelegate.addListener(_handleRouterStateChanged);
    _setupPushListeners();
    _setupAuthStateListener();
    _setupProfileBootstrapListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouterStateChanged();
    });
  }

  void _disposeSessionEffects() {
    _pushBootstrapTimer?.cancel();
    _authStateSubscription?.close();
    _profileSubscription?.close();
    try {
      _goRouter.routerDelegate.removeListener(_handleRouterStateChanged);
    } catch (_) {
      // Router may already be disposed.
    }
    PushNotificationEventBus.instance.dispose();
  }

  void _setupAuthStateListener() {
    AppPerformanceTracker.mark('app.auth_listener.setup');
    _authStateSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateChangesProvider,
      (previous, next) {
        next.whenData((user) {
          AppPerformanceTracker.mark(
            'app.auth_listener.event',
            data: {'authenticated': user != null},
          );
          if (user != null) {
            AppLogger.setUserIdentifier(user.uid);
            AppLogger.setCustomKey('auth_user_present', true);
          } else {
            AppLogger.clearUserIdentifier();
            AppLogger.setCustomKey('auth_user_present', false);
          }
          _handleOnboardingDraftSession(user);
          _handleBandMembersReminderSession(user);
          _handleGigReviewReminderSession(user);
          _handleStoreReviewSession(user);
          _handlePushBootstrapForAuthState(user);
          if (user != null && !_isMatchpointRoute(_currentAppPath)) {
            ref
                .read(matchpointSwipeOutboxCoordinatorProvider)
                .scheduleFlush(reason: 'auth_state_logged_in');
          }
          if (user == null && ref.read(accountDeletionInProgressProvider)) {
            ref.read(accountDeletionInProgressProvider.notifier).clear();
          }
        });
      },
    );
  }

  void _handleOnboardingDraftSession(User? user) {
    final nextUid = user?.uid;
    final previousUid = _onboardingDraftOwnerUid;
    _onboardingDraftOwnerUid = nextUid;

    if (previousUid == null || previousUid == nextUid) {
      return;
    }

    unawaited(ref.read(onboardingFormProvider.notifier).clearState());
  }

  void _handlePushBootstrapForAuthState(User? user) {
    if (user == null) {
      _pushBootstrapTimer?.cancel();
      _hasBootstrappedPushForSession = false;
      _hasPrefetchedFeedForSession = false;
      return;
    }

    if (_hasBootstrappedPushForSession) return;
    _hasBootstrappedPushForSession = true;
    _pushBootstrapTimer?.cancel();
    AppPerformanceTracker.mark('push.bootstrap_for_logged_user.scheduled');
    _pushBootstrapTimer = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final currentUser = ref.read(authRepositoryProvider).currentUser;
      if (currentUser == null) {
        _hasBootstrappedPushForSession = false;
        return;
      }
      unawaited(_bootstrapPushForLoggedInUser());
    });
  }

  void _handleStoreReviewSession(User? user) {
    final nextUid = user?.uid;
    if (nextUid == null) {
      _storeReviewSessionOwnerUid = null;
      return;
    }

    if (_storeReviewSessionOwnerUid == nextUid) {
      return;
    }

    _storeReviewSessionOwnerUid = nextUid;
    unawaited(ref.read(storeReviewServiceProvider).registerCurrentSession());
  }

  void _setupProfileBootstrapListener() {
    AppPerformanceTracker.mark('app.profile_listener.setup');
    _profileSubscription = ref.listenManual<AsyncValue<AppUser?>>(
      currentUserProfileProvider,
      (previous, next) {
        next.whenData((profile) {
          AppPerformanceTracker.mark(
            'app.profile_listener.event',
            data: {
              'has_profile': profile != null,
              'cadastro_status': profile?.cadastroStatus,
            },
          );
          _maybePrefetchFeed(profile);
          unawaited(_maybeShowBandMembersReminder(profile));
          unawaited(_maybeShowGigReviewReminder(profile));
        });
      },
    );
  }

  void _handleBandMembersReminderSession(User? user) {
    if (_bandMembersReminderCoordinator.handleAuthUser(user?.uid)) {
      unawaited(
        _maybeShowBandMembersReminder(
          ref.read(currentUserProfileProvider).value,
        ),
      );
    }
  }

  void _handleGigReviewReminderSession(User? user) {
    if (_gigReviewReminderCoordinator.handleAuthUser(user?.uid)) {
      unawaited(
        _maybeShowGigReviewReminder(ref.read(currentUserProfileProvider).value),
      );
    }
  }

  void _maybePrefetchFeed(AppUser? profile) {
    if (profile == null || !profile.isCadastroConcluido) {
      _hasPrefetchedFeedForSession = false;
      return;
    }

    if (_hasPrefetchedFeedForSession) return;
    _hasPrefetchedFeedForSession = true;
    AppPerformanceTracker.mark(
      'app.feed_prefetch.skipped',
      data: {'uid': profile.uid, 'reason': 'disabled_to_reduce_boot_work'},
    );
  }

  Future<void> _bootstrapPushForLoggedInUser() async {
    final pushBootstrapStopwatch = AppPerformanceTracker.startSpan(
      'push.bootstrap_for_logged_user',
    );
    try {
      await ref
          .read(pushNotificationServiceProvider)
          .initIfPermissionAlreadyGranted();
      AppPerformanceTracker.finishSpan(
        'push.bootstrap_for_logged_user',
        pushBootstrapStopwatch,
        data: {'status': 'initialized'},
      );
    } catch (e, stack) {
      AppLogger.warning('Failed to bootstrap push for logged user', e, stack);
      AppPerformanceTracker.finishSpan(
        'push.bootstrap_for_logged_user',
        pushBootstrapStopwatch,
        data: {'status': 'error', 'error_type': e.runtimeType.toString()},
      );
    }
  }
}
