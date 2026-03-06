import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/firebase_providers.dart';
import 'push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((
  ref,
) {
  return PushNotificationService(
    fcm: ref.watch(firebaseMessagingProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
    localNotifications: ref.watch(flutterLocalNotificationsPluginProvider),
  );
});
