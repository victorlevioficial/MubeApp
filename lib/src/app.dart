import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'core/providers/app_display_preferences_provider.dart';
import 'core/providers/app_update_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/push_notification_event_bus.dart';
import 'core/services/push_notification_provider.dart';
import 'core/services/session_prompt_coordinator.dart';
import 'core/widgets/app_update_notice_dialog.dart';
import 'design_system/components/feedback/app_snackbar.dart';
import 'design_system/foundations/theme/app_scroll_behavior.dart';
import 'design_system/foundations/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/domain/user_type.dart';
import 'features/auth/presentation/account_deletion_provider.dart';
import 'features/bands/domain/band_activation_rules.dart';
import 'features/bands/presentation/band_formation_reminder_dialog.dart';
import 'features/gigs/domain/gig_review_opportunity.dart';
import 'features/gigs/presentation/gig_review_reminder_dialog.dart';
import 'features/gigs/presentation/providers/gig_streams.dart';
import 'features/onboarding/presentation/onboarding_form_provider.dart';
import 'routing/app_router.dart';
import 'routing/route_paths.dart';
import 'shared/widgets/dismiss_keyboard_on_tap.dart';
import 'utils/app_logger.dart';
import 'utils/app_performance_tracker.dart';

/// Global key for ScaffoldMessenger to show snackbars across navigation.
/// This allows snackbars to persist even when navigating between screens.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MubeApp extends ConsumerStatefulWidget {
  final VoidCallback? onInitialRouteReady;

  const MubeApp({super.key, this.onInitialRouteReady});

  @override
  ConsumerState<MubeApp> createState() => _MubeAppState();
}

class _MubeAppState extends ConsumerState<MubeApp> {
  StreamSubscription? _onMessageOpenedSub;
  ProviderSubscription<AsyncValue<User?>>? _authStateSubscription;
  ProviderSubscription<AsyncValue<AppUser?>>? _profileSubscription;
  late final GoRouter _goRouter;
  PushNavigationIntent? _pendingPushNavigationIntent;
  bool _hasBootstrappedPushForSession = false;
  bool _hasPrefetchedFeedForSession = false;
  bool _hasReleasedInitialRoute = false;
  bool _isPushNavigationDispatchScheduled = false;
  String? _onboardingDraftOwnerUid;
  Timer? _pushBootstrapTimer;
  final SessionPromptCoordinator _appUpdateNoticeCoordinator =
      SessionPromptCoordinator(pendingInitially: true);
  final UserScopedSessionPromptCoordinator _bandMembersReminderCoordinator =
      UserScopedSessionPromptCoordinator(logLabel: 'BandFormationReminder');
  final UserScopedSessionPromptCoordinator _gigReviewReminderCoordinator =
      UserScopedSessionPromptCoordinator(logLabel: 'GigReviewReminder');

  @override
  void initState() {
    super.initState();
    _goRouter = ref.read(goRouterProvider);
    _goRouter.routerDelegate.addListener(_handleRouterStateChanged);
    _setupPushListeners();
    _setupAuthStateListener();
    _setupProfileBootstrapListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleRouterStateChanged();
    });
  }

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
        currentPath == RoutePaths.emailVerification ||
        currentPath == RoutePaths.notificationPermission) {
      return true;
    }

    return currentPath.startsWith(RoutePaths.onboarding);
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
          _handlePushBootstrapForAuthState(user);
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

  void _handleRouterStateChanged() {
    final currentPath = _goRouter.routerDelegate.currentConfiguration.uri.path;
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
    unawaited(
      _maybeShowBandMembersReminder(ref.read(currentUserProfileProvider).value),
    );
    unawaited(
      _maybeShowGigReviewReminder(ref.read(currentUserProfileProvider).value),
    );
  }

  Future<void> _maybeShowAppUpdateNotice() async {
    if (!mounted || !_appUpdateNoticeCoordinator.canEvaluate) {
      return;
    }

    final currentPath = _goRouter.routerDelegate.currentConfiguration.uri.path;
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

  void _resumeDeferredSessionDialogs() {
    unawaited(
      _maybeShowBandMembersReminder(ref.read(currentUserProfileProvider).value),
    );
    unawaited(
      _maybeShowGigReviewReminder(ref.read(currentUserProfileProvider).value),
    );
  }

  Future<void> _maybeShowBandMembersReminder(AppUser? profile) async {
    if (!mounted ||
        _appUpdateNoticeCoordinator.blocksOtherPrompts ||
        !_bandMembersReminderCoordinator.canPresent) {
      return;
    }

    final currentPath = _goRouter.routerDelegate.currentConfiguration.uri.path;
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
        unawaited(
          _maybeShowBandMembersReminder(
            ref.read(currentUserProfileProvider).value,
          ),
        );
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

    final activePath = _goRouter.routerDelegate.currentConfiguration.uri.path;
    if (activePath != RoutePaths.manageMembers) {
      unawaited(_goRouter.push(RoutePaths.manageMembers));
    }
  }

  Future<void> _maybeShowGigReviewReminder(AppUser? profile) async {
    if (!mounted ||
        _appUpdateNoticeCoordinator.blocksOtherPrompts ||
        !_gigReviewReminderCoordinator.canPresent) {
      return;
    }

    final currentPath = _goRouter.routerDelegate.currentConfiguration.uri.path;
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
        unawaited(
          _maybeShowGigReviewReminder(
            ref.read(currentUserProfileProvider).value,
          ),
        );
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
    if (_goRouter.routerDelegate.currentConfiguration.uri.path != route) {
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

  @override
  void dispose() {
    _pushBootstrapTimer?.cancel();
    _authStateSubscription?.close();
    _profileSubscription?.close();
    _onMessageOpenedSub?.cancel();
    _goRouter.routerDelegate.removeListener(_handleRouterStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);
    final displayPreferences = ref.watch(appDisplayPreferencesProvider);

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      scrollBehavior: const AppScrollBehavior(),
      title: 'Mube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      highContrastTheme: AppTheme.highContrastDarkTheme,
      highContrastDarkTheme: AppTheme.highContrastDarkTheme,
      themeMode: displayPreferences.themeMode,
      routerConfig: goRouter,

      // Wrap all screens with offline indicator banner.
      builder: (context, child) {
        return DismissKeyboardOnTap(
          child: OfflineIndicator(child: child ?? const SizedBox.shrink()),
        );
      },

      // Localization configuration.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: displayPreferences.locale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('pt');

        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale.languageCode) {
            return supportedLocale;
          }
        }

        return const Locale('pt');
      },
    );
  }
}
