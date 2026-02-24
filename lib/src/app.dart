import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/services/push_notification_event_bus.dart';
import 'design_system/foundations/theme/app_scroll_behavior.dart';
import 'design_system/foundations/theme/app_theme.dart';
import 'routing/app_router.dart';

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
      final conversationId = message.data['conversation_id'];
      if (conversationId != null && mounted) {
        final router = ref.read(goRouterProvider);
        final targetPath = '/conversation/$conversationId';
        final currentPath = router.routerDelegate.currentConfiguration.uri.path;
        if (currentPath != targetPath) {
          router.push(targetPath);
        }
      }
    });
  }

  @override
  void dispose() {
    _onMessageOpenedSub?.cancel();
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
