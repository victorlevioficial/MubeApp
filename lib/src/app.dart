import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/push_notification_event_bus.dart';
import 'core/services/push_notification_provider.dart';
import 'design_system/foundations/theme/app_scroll_behavior.dart';
import 'design_system/foundations/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/domain/user_type.dart';
import 'features/auth/presentation/account_deletion_provider.dart';
import 'features/bands/domain/band_activation_rules.dart';
import 'features/bands/presentation/band_formation_reminder_dialog.dart';
import 'features/feed/presentation/feed_controller.dart';
import 'features/onboarding/presentation/onboarding_form_provider.dart';
import 'features/onboarding/providers/notification_permission_prompt_provider.dart';
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
  bool _hasBootstrappedPushForSession = false;
  bool _hasPrefetchedFeedForSession = false;
  bool _hasReleasedInitialRoute = false;
  bool _hasPendingBandMembersReminderEvaluation = false;
  bool _hasShownBandMembersReminderForSession = false;
  bool _isBandMembersReminderVisible = false;
  String? _bandMembersReminderUserId;
  String? _onboardingDraftOwnerUid;
  Timer? _pushBootstrapTimer;

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

    _onMessageOpenedSub = eventBus.onMessageOpened.listen((message) {
      if (!mounted) return;

      final router = ref.read(goRouterProvider);
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      final route = message.data['route'];
      if (route is String && route.isNotEmpty) {
        if (currentPath != route) {
          router.push(route);
        }
        return;
      }

      final conversationId = message.data['conversation_id'];
      if (conversationId != null) {
        final targetPath = RoutePaths.conversationById('$conversationId');
        if (currentPath != targetPath) {
          router.push(targetPath);
        }
      }
    });
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
    _pushBootstrapTimer = Timer(const Duration(seconds: 2), () {
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
        });
      },
    );
  }

  void _handleBandMembersReminderSession(User? user) {
    if (user == null) {
      _hasPendingBandMembersReminderEvaluation = false;
      _hasShownBandMembersReminderForSession = false;
      _isBandMembersReminderVisible = false;
      _bandMembersReminderUserId = null;
      return;
    }

    if (_bandMembersReminderUserId == user.uid) return;

    _bandMembersReminderUserId = user.uid;
    _hasPendingBandMembersReminderEvaluation = true;
    _hasShownBandMembersReminderForSession = false;
    _isBandMembersReminderVisible = false;
    unawaited(
      _maybeShowBandMembersReminder(ref.read(currentUserProfileProvider).value),
    );
  }

  void _maybePrefetchFeed(AppUser? profile) {
    if (profile == null || !profile.isCadastroConcluido) {
      _hasPrefetchedFeedForSession = false;
      return;
    }

    if (_hasPrefetchedFeedForSession) return;
    _hasPrefetchedFeedForSession = true;
    AppPerformanceTracker.mark(
      'app.feed_prefetch.scheduled',
      data: {'uid': profile.uid},
    );
    unawaited(ref.read(feedControllerProvider.notifier).loadAllData());
  }

  Future<void> _bootstrapPushForLoggedInUser() async {
    final pushBootstrapStopwatch = AppPerformanceTracker.startSpan(
      'push.bootstrap_for_logged_user',
    );
    try {
      final hasShownPermission = await ref.read(
        notificationPermissionPromptProvider.future,
      );

      if (!hasShownPermission) {
        AppLogger.info(
          'Push bootstrap skipped: notification onboarding not shown yet.',
        );
        AppPerformanceTracker.finishSpan(
          'push.bootstrap_for_logged_user',
          pushBootstrapStopwatch,
          data: {
            'status': 'skipped',
            'reason': 'permission_onboarding_pending',
          },
        );
        return;
      }

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

    unawaited(
      _maybeShowBandMembersReminder(ref.read(currentUserProfileProvider).value),
    );
  }

  Future<void> _maybeShowBandMembersReminder(AppUser? profile) async {
    if (!mounted ||
        !_hasPendingBandMembersReminderEvaluation ||
        _hasShownBandMembersReminderForSession ||
        _isBandMembersReminderVisible) {
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
      _skipBandMembersReminderForSession(
        reason: 'registration_incomplete',
        currentPath: currentPath,
      );
      return;
    }

    if (profile.tipoPerfil != AppUserType.band) {
      _skipBandMembersReminderForSession(
        reason: 'not_a_band',
        currentPath: currentPath,
      );
      return;
    }

    if (isBandEligibleForActivation(profile.members.length)) {
      _skipBandMembersReminderForSession(
        reason: 'minimum_members_met',
        currentPath: currentPath,
      );
      return;
    }

    if (!_canShowBandMembersReminderOnPath(currentPath)) {
      _skipBandMembersReminderForSession(
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

    _hasPendingBandMembersReminderEvaluation = false;
    _hasShownBandMembersReminderForSession = true;
    _isBandMembersReminderVisible = true;

    final shouldOpenManageMembers = await BandFormationReminderDialog.show(
      context: dialogContext,
      bandName: profile.appDisplayName,
      acceptedMembers: profile.members.length,
    );

    _isBandMembersReminderVisible = false;
    if (!mounted || !shouldOpenManageMembers) return;

    final activePath = _goRouter.routerDelegate.currentConfiguration.uri.path;
    if (activePath != RoutePaths.manageMembers) {
      unawaited(_goRouter.push(RoutePaths.manageMembers));
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

  void _skipBandMembersReminderForSession({
    required String reason,
    required String currentPath,
  }) {
    _hasPendingBandMembersReminderEvaluation = false;
    AppLogger.debug(
      '[BandFormationReminder] Skipped for session: $reason ($currentPath)',
    );
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

    return MaterialApp.router(
      scaffoldMessengerKey: scaffoldMessengerKey,
      scrollBehavior: const AppScrollBehavior(),
      title: 'Mube',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,

      // Wrap all screens with offline indicator banner
      builder: (context, child) {
        return DismissKeyboardOnTap(
          child: OfflineIndicator(child: child ?? const SizedBox.shrink()),
        );
      },

      // Localization configuration
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'), // Portuguese (Brazil) - default
      ],
      locale: const Locale('pt'),
    );
  }
}
