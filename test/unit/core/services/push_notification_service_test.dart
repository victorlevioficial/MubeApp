import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/push_notification_service.dart';

import '../../../helpers/firebase_mocks.dart';

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? currentUserValue;

  @override
  User? get currentUser => currentUserValue;
}

class _FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  _FakeFirebaseMessaging({
    required this.notificationSettings,
    required this.token,
  });

  NotificationSettings notificationSettings;
  String? token;
  int getTokenCalls = 0;
  int getNotificationSettingsCalls = 0;
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    getNotificationSettingsCalls += 1;
    return notificationSettings;
  }

  @override
  Future<String?> getToken({String? vapidKey}) async {
    getTokenCalls += 1;
    return token;
  }

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;

  @override
  Future<String?> getAPNSToken() async => null;

  void emitTokenRefresh(String nextToken) {
    _tokenRefreshController.add(nextToken);
  }

  Future<void> dispose() => _tokenRefreshController.close();
}

class _FakeLocalNotifications extends Fake
    implements FlutterLocalNotificationsPlugin {
  final _FakeAndroidLocalNotifications android =
      _FakeAndroidLocalNotifications();
  int initializeCalls = 0;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initializeCalls += 1;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async {
    return const NotificationAppLaunchDetails(false);
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() {
    if (T == AndroidFlutterLocalNotificationsPlugin) {
      return android as T;
    }
    return null;
  }
}

class _FakeAndroidLocalNotifications extends Fake
    implements AndroidFlutterLocalNotificationsPlugin {
  int createNotificationChannelCalls = 0;

  @override
  Future<void> createNotificationChannel(
    AndroidNotificationChannel notificationChannel,
  ) async {
    createNotificationChannelCalls += 1;
  }
}

NotificationSettings _authorizedSettings() {
  return const NotificationSettings(
    alert: AppleNotificationSetting.enabled,
    announcement: AppleNotificationSetting.notSupported,
    authorizationStatus: AuthorizationStatus.authorized,
    badge: AppleNotificationSetting.enabled,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.notSupported,
    notificationCenter: AppleNotificationSetting.notSupported,
    showPreviews: AppleShowPreviewSetting.notSupported,
    timeSensitive: AppleNotificationSetting.notSupported,
    criticalAlert: AppleNotificationSetting.notSupported,
    sound: AppleNotificationSetting.enabled,
    providesAppNotificationSettings: AppleNotificationSetting.notSupported,
  );
}

void main() {
  group('PushNotificationService', () {
    late FakeFirebaseFirestore firestore;
    late _FakeFirebaseAuth auth;
    late _FakeFirebaseMessaging messaging;
    late _FakeLocalNotifications localNotifications;
    late PushNotificationService service;

    setUp(() async {
      PushNotificationService.debugReset();
      firestore = FakeFirebaseFirestore();
      auth = _FakeFirebaseAuth();
      messaging = _FakeFirebaseMessaging(
        notificationSettings: _authorizedSettings(),
        token: 'token-user-1',
      );
      localNotifications = _FakeLocalNotifications();
      service = PushNotificationService(
        fcm: messaging,
        firestore: firestore,
        auth: auth,
        localNotifications: localNotifications,
      );

      await firestore.collection('users').doc('user-1').set({});
      await firestore.collection('users').doc('user-2').set({});
    });

    tearDown(() async {
      await messaging.dispose();
      PushNotificationService.debugReset();
    });

    test(
      're-syncs the FCM token for a new session without requiring app restart',
      () async {
        auth.currentUserValue = MockUser(uid: 'user-1');

        await service.initIfPermissionAlreadyGranted();

        expect(
          (await firestore.collection('users').doc('user-1').get())
              .data()?['fcm_token'],
          'token-user-1',
        );
        expect(messaging.getTokenCalls, 1);

        auth.currentUserValue = MockUser(uid: 'user-2');
        messaging.token = 'token-user-2';

        await service.initIfPermissionAlreadyGranted();

        expect(
          (await firestore.collection('users').doc('user-2').get())
              .data()?['fcm_token'],
          'token-user-2',
        );
        expect(messaging.getTokenCalls, 2);
      },
    );

    test(
      'saves refreshed tokens for the currently authenticated user',
      () async {
        auth.currentUserValue = MockUser(uid: 'user-1');

        await service.initIfPermissionAlreadyGranted();

        auth.currentUserValue = MockUser(uid: 'user-2');
        messaging.emitTokenRefresh('refresh-token-user-2');
        await pumpEventQueue();

        expect(
          (await firestore.collection('users').doc('user-2').get())
              .data()?['fcm_token'],
          'refresh-token-user-2',
        );
      },
    );
  });
}
