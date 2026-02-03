import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        router.push('/conversation/$conversationId');
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
    );
  }
}
