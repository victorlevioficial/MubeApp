import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../utils/app_logger.dart';
import 'push_notification_event_bus.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// The conversation currently being viewed by the user.
  /// When set, push notifications for this conversation are suppressed
  /// (messages still arrive via real-time listeners).
  static String? activeConversationId;

  /// Sets the active conversation to suppress push notifications for it.
  static void setActiveConversation(String? conversationId) {
    activeConversationId = conversationId;
    AppLogger.info('Active conversation set to: ${conversationId ?? "none"}');
  }

  Future<void> init() async {
    await _initInternal(requestPermission: true);
  }

  /// Bootstraps push without triggering the OS permission prompt.
  ///
  /// Useful for users who already completed onboarding in older app versions.
  Future<void> initIfPermissionAlreadyGranted() async {
    await _initInternal(requestPermission: false);
  }

  Future<void> _initInternal({required bool requestPermission}) async {
    try {
      // 0. Init Local Notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/launcher_icon',
      );
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Handle tap
        },
      );

      // Create High Importance Channel (Android 8+)
      const androidChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'Notificações Importantes',
        description: 'Usado para mensagens e alertas importantes.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // 1. Resolve Permission
      final authorizationStatus = await _resolveAuthorizationStatus(
        requestPermission: requestPermission,
      );

      if (authorizationStatus != AuthorizationStatus.authorized &&
          authorizationStatus != AuthorizationStatus.provisional) {
        if (requestPermission) {
          AppLogger.warning('User declined or has not accepted permission');
        } else {
          AppLogger.info(
            'Push permission not granted yet; silent init skipped.',
          );
        }
        return;
      }

      // 2. Handle Token
      // On iOS, we need the APNS token first
      if (Platform.isIOS) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          AppLogger.warning('APNS Token not yet available');
        }
      }

      final token = await _fcm.getToken();
      if (token != null) {
        AppLogger.info('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }

      // 3. Listen for Token Refresh
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      // 4. Handle Foreground Messages (with anti-flood suppression)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Handle Background/Terminated Message Tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('A new onMessageOpenedApp event was published!');
        // Emit to global event bus for navigation handling
        PushNotificationEventBus.instance.emitMessageOpened(message);
      });
    } catch (e, stack) {
      AppLogger.error('Failed to init PushNotificationService', e, stack);
    }
  }

  Future<AuthorizationStatus> _resolveAuthorizationStatus({
    required bool requestPermission,
  }) async {
    if (requestPermission) {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info('User granted data permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        AppLogger.info('User granted provisional permission');
      }

      return settings.authorizationStatus;
    }

    final settings = await _fcm.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.info('Push permission already authorized');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      AppLogger.info('Push permission already provisional');
    }

    return settings.authorizationStatus;
  }

  /// Handles foreground messages with contextual suppression.
  ///
  /// If the user is currently viewing the conversation that the message
  /// belongs to, the push notification banner is NOT shown (the message
  /// is already visible in real-time via Firestore listeners).
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Got a message whilst in the foreground!');

    // Emit to global event bus for Riverpod consumers (always)
    PushNotificationEventBus.instance.emitMessage(message);

    final notification = message.notification;
    final conversationId = message.data['conversation_id'];

    // Suppress push banner if user is viewing this conversation
    if (conversationId != null && conversationId == activeConversationId) {
      AppLogger.info(
        'Push suppressed — user is viewing conversation $conversationId',
      );
      return;
    }

    // Show local notification with grouping and stable ID
    if (notification != null) {
      // Use conversation-based ID so pushes from the same
      // conversation REPLACE each other instead of stacking
      final notificationId = conversationId?.hashCode ?? notification.hashCode;

      final groupKey = conversationId != null
          ? 'chat_$conversationId'
          : 'general';

      _localNotifications.show(
        notificationId,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notificações Importantes',
            channelDescription: 'Usado para mensagens e alertas importantes.',
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
            groupKey: groupKey,
            setAsGroupSummary: false,
          ),
          iOS: DarwinNotificationDetails(
            threadIdentifier: conversationId ?? 'general',
          ),
        ),
      );
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcm_token': token,
        'fcm_updated_at': FieldValue.serverTimestamp(),
      });
      AppLogger.info('FCM Token saved to Firestore for user ${user.uid}');
    } catch (e) {
      AppLogger.warning('Error saving FCM token: $e');
    }
  }
}
