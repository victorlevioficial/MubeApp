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

  static const int _firestoreBatchLimit = 500;
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

  /// Returns the unread notification count without capping the result at 50 items.
  Stream<int> watchUnreadNotificationCount(String userId) {
    return _firestoreResilience
        .watch(
          () => _notifications(
            userId,
          ).where('isRead', isEqualTo: false).snapshots(),
          operationLabel: 'watch_unread_notifications_count',
        )
        .map((snapshot) => snapshot.docs.length);
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
    await _runBatchedNotificationMutation(
      operationLabel: 'mark_all_notifications_as_read',
      buildQuery: (cursor) {
        var query = _notifications(
          userId,
        ).where('isRead', isEqualTo: false).orderBy(FieldPath.documentId);

        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }

        return query;
      },
      applyBatch: (batch, docs) {
        for (final doc in docs) {
          batch.update(doc.reference, {'isRead': true});
        }
      },
    );
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
    await _runBatchedNotificationMutation(
      operationLabel: 'delete_all_notifications',
      buildQuery: (cursor) {
        var query = _notifications(userId).orderBy(FieldPath.documentId);

        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }

        return query;
      },
      applyBatch: (batch, docs) {
        for (final doc in docs) {
          batch.delete(doc.reference);
        }
      },
    );
  }

  Future<void> _runBatchedNotificationMutation({
    required String operationLabel,
    required Query<Map<String, dynamic>> Function(
      DocumentSnapshot<Map<String, dynamic>>? cursor,
    )
    buildQuery,
    required void Function(
      WriteBatch batch,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    )
    applyBatch,
  }) async {
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      final snapshot = await _firestoreResilience.run(
        () => buildQuery(cursor).limit(_firestoreBatchLimit).get(),
        operationLabel: '$operationLabel.load_batch',
      );

      if (snapshot.docs.isEmpty) {
        return;
      }

      await _firestoreResilience.run(() async {
        final batch = _firestore.batch();
        applyBatch(batch, snapshot.docs);
        await batch.commit();
      }, operationLabel: '$operationLabel.commit_batch');

      if (snapshot.docs.length < _firestoreBatchLimit) {
        return;
      }

      cursor = snapshot.docs.last;
    }
  }
}
