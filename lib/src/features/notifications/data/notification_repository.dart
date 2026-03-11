import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/firestore_resilience.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/notification_model.dart';

/// Provider for the NotificationRepository.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(firebaseFirestoreProvider));
});

/// Repository for managing user notifications in Firestore.
class NotificationRepository {
  NotificationRepository(this._firestore);

  static const FirestoreResilience _firestoreResilience = FirestoreResilience(
    'NotificationRepository',
  );

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _notifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// Returns a stream of notifications for a user, ordered by creation date.
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _firestoreResilience
        .watch(
          () => _notifications(
            userId,
          ).orderBy('createdAt', descending: true).limit(50).snapshots(),
          operationLabel: 'watch_notifications',
        )
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList(),
        );
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String userId, String notificationId) async {
    await _firestoreResilience.run(
      () => _notifications(userId).doc(notificationId).update({'isRead': true}),
      operationLabel: 'mark_notification_as_read',
    );
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead(String userId) async {
    await _firestoreResilience.run(() async {
      final notifications = await _notifications(
        userId,
      ).where('isRead', isEqualTo: false).get();
      if (notifications.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    }, operationLabel: 'mark_all_notifications_as_read');
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String userId, String notificationId) async {
    await _firestoreResilience.run(
      () => _notifications(userId).doc(notificationId).delete(),
      operationLabel: 'delete_notification',
    );
  }

  /// Deletes all notifications for a user.
  Future<void> deleteAllNotifications(String userId) async {
    await _firestoreResilience.run(() async {
      final notifications = await _notifications(userId).get();
      if (notifications.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }, operationLabel: 'delete_all_notifications');
  }
}
