import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Global stream controller for push notification events.
/// Used to bridge PushNotificationService with Riverpod state.
class PushNotificationEventBus {
  PushNotificationEventBus._();
  static final instance = PushNotificationEventBus._();

  final _onMessageController = StreamController<RemoteMessage>.broadcast();
  final _onMessageOpenedController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream emitted when a push is received in foreground.
  Stream<RemoteMessage> get onMessage => _onMessageController.stream;

  /// Stream emitted when user taps on a notification.
  Stream<RemoteMessage> get onMessageOpened =>
      _onMessageOpenedController.stream;

  void emitMessage(RemoteMessage message) {
    _onMessageController.add(message);
  }

  void emitMessageOpened(RemoteMessage message) {
    _onMessageOpenedController.add(message);
  }

  void dispose() {
    _onMessageController.close();
    _onMessageOpenedController.close();
  }
}
