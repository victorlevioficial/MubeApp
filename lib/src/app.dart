import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/push_notification_event_bus.dart';
import 'core/services/push_notification_service.dart';
import 'design_system/foundations/theme/app_scroll_behavior.dart';
import 'design_system/foundations/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/account_deletion_provider.dart';
import 'features/onboarding/providers/notification_permission_prompt_provider.dart';
import 'routing/app_router.dart';
import 'routing/route_paths.dart';
import 'utils/app_logger.dart';

/// Global key for ScaffoldMessenger to show snackbars across navigation.
/// This allows snackbars to persist even when navigating between screens.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MubeApp extends ConsumerStatefulWidget {
  const MubeApp({super.key});

  @override
  ConsumerState<MubeApp> createState() => _MubeAppState();
}

class _MubeAppState extends ConsumerState<MubeApp> {
  StreamSubscription? _onMessageOpenedSub;
  bool _hasBootstrappedPushForSession = false;

  @override
  void initState() {
    super.initState();
    _setupPushListeners();
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
        final targetPath = '${RoutePaths.conversation}/$conversationId';
        if (currentPath != targetPath) {
          router.push(targetPath);
        }
      }
    });
  }

  void _handlePushBootstrapForAuthState(User? user) {
    if (user == null) {
      _hasBootstrappedPushForSession = false;
      return;
    }

    if (_hasBootstrappedPushForSession) return;
    _hasBootstrappedPushForSession = true;
    unawaited(_bootstrapPushForLoggedInUser());
  }

  Future<void> _bootstrapPushForLoggedInUser() async {
    try {
      final hasShownPermission = await ref.read(
        notificationPermissionPromptProvider.future,
      );

      if (!hasShownPermission) {
        AppLogger.info(
          'Push bootstrap skipped: notification onboarding not shown yet.',
        );
        return;
      }

      await PushNotificationService().initIfPermissionAlreadyGranted();
    } catch (e, stack) {
      AppLogger.warning('Failed to bootstrap push for logged user', e, stack);
    }
  }

  @override
  void dispose() {
    _onMessageOpenedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (previous, next) {
      next.whenData((user) {
        _handlePushBootstrapForAuthState(user);
        if (user == null && ref.read(accountDeletionInProgressProvider)) {
          ref.read(accountDeletionInProgressProvider.notifier).clear();
        }
      });
    });

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
        return OfflineIndicator(child: child ?? const SizedBox.shrink());
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
