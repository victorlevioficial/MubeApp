import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNavigationIntent {
  const PushNavigationIntent({this.route, this.conversationId, this.extra});

  final String? route;
  final String? conversationId;
  final Map<String, dynamic>? extra;
}

/// Global stream controller for push notification events.
/// Used to bridge PushNotificationService with Riverpod state.
class PushNotificationEventBus {
  PushNotificationEventBus._();
  static final instance = PushNotificationEventBus._();

  final _onMessageController = StreamController<RemoteMessage>.broadcast();
  final _onMessageOpenedController =
      StreamController<RemoteMessage>.broadcast();
  final _onNavigationController =
      StreamController<PushNavigationIntent>.broadcast();

  /// Stream emitted when a push is received in foreground.
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  /// Stream emitted when user taps on a notification.
  Stream<RemoteMessage> get onMessageOpened =>
      _onMessageOpenedController.stream;

  /// Stream emitted when a push/local notification should trigger navigation.
  Stream<PushNavigationIntent> get onNavigation =>
      _onNavigationController.stream;

  void emitMessage(RemoteMessage message) {
    _onMessageController.add(message);
  }

  void emitMessageOpened(RemoteMessage message) {
    _onMessageOpenedController.add(message);
  }

  void emitNavigation(PushNavigationIntent intent) {
    _onNavigationController.add(intent);
  }

  void dispose() {
    _onMessageController.close();
    _onMessageOpenedController.close();
    _onNavigationController.close();
  }
}
