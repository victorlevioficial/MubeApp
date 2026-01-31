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

  Future<void> init() async {
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

      // 1. Request Permission
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
      } else {
        AppLogger.warning('User declined or has not accepted permission');
        return;
      }

      // 2. Handle Token
      // On iOS, we need the APNS token first
      if (Platform.isIOS) {
        final apnsToken = await _fcm.getAPNSToken();
        if (apnsToken == null) {
          AppLogger.warning('APNS Token not yet available');
          // Wait a bit? Or just return? Usually getting FCM token handles this internally but good to check.
        }
      }

      final token = await _fcm.getToken();
      if (token != null) {
        AppLogger.info('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }

      // 3. Listen for Token Refresh
      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      // 4. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('Got a message whilst in the foreground!');

        // Emit to global event bus for Riverpod consumers
        PushNotificationEventBus.instance.emitMessage(message);

        final notification = message.notification;
        final android = message.notification?.android;

        // Show local banner if notification exists
        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'high_importance_channel',
                'Notificações Importantes',
                channelDescription:
                    'Usado para mensagens e alertas importantes.',
                icon: '@mipmap/launcher_icon',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

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
      // Ignore if user doc doesn't exist or other error, but verify rules allow update.
      AppLogger.warning('Error saving FCM token: $e');
    }
  }
}
