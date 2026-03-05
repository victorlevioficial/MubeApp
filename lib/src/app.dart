import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/generated/app_localizations.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/push_notification_event_bus.dart';
import 'core/services/push_notification_service.dart';
import 'design_system/foundations/theme/app_scroll_behavior.dart';
import 'design_system/foundations/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/account_deletion_provider.dart';
import 'features/feed/presentation/feed_controller.dart';
import 'features/onboarding/providers/notification_permission_prompt_provider.dart';
import 'routing/app_router.dart';
import 'routing/route_paths.dart';
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
          _handlePushBootstrapForAuthState(user);
          if (user == null && ref.read(accountDeletionInProgressProvider)) {
            ref.read(accountDeletionInProgressProvider.notifier).clear();
          }
        });
      },
    );
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
        });
      },
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

      await PushNotificationService().initIfPermissionAlreadyGranted();
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
    if (_hasReleasedInitialRoute) return;

    final currentPath = _goRouter.routerDelegate.currentConfiguration.uri.path;
    if (currentPath == RoutePaths.splash) return;

    _hasReleasedInitialRoute = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onInitialRouteReady?.call();
    });
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
        return _DismissKeyboardOnTap(
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
        Locale('en'), // English
      ],
      locale: const Locale('pt'), // Default to Portuguese for MVP
    );
  }
}

/// Dismisses the active keyboard focus when tapping outside the focused field.
class _DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;

  const _DismissKeyboardOnTap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      child: child,
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    final focusedNode = FocusManager.instance.primaryFocus;
    if (focusedNode == null) return;

    final focusedContext = focusedNode.context;
    final focusedRenderObject = focusedContext?.findRenderObject();
    if (focusedRenderObject is! RenderBox || !focusedRenderObject.hasSize) {
      focusedNode.unfocus();
      return;
    }

    final localTapPosition = focusedRenderObject.globalToLocal(event.position);
    final tapInsideFocusedField = focusedRenderObject.paintBounds.contains(
      localTapPosition,
    );

    if (!tapInsideFocusedField) {
      focusedNode.unfocus();
    }
  }
}
