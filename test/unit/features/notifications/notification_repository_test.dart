import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';

void main() {
  late NotificationRepository repository;
  late FakeFirebaseFirestore fakeFirestore;

  const tUserId = 'user-1';

  Future<void> seedNotification({
    required String id,
    String type = 'chat_message',
    String title = 'Nova mensagem',
    String body = 'Você recebeu uma nova mensagem',
    bool isRead = false,
  }) async {
    await fakeFirestore
        .collection('users')
        .doc(tUserId)
        .collection('notifications')
        .doc(id)
        .set({
          'type': type,
          'title': title,
          'body': body,
          'isRead': isRead,
          'createdAt': Timestamp.fromDate(DateTime(2025, 1, 1)),
        });
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = NotificationRepository(fakeFirestore);
  });

  group('NotificationRepository', () {
    group('watchNotifications', () {
      test('should emit list of notifications for user', () async {
        // Arrange
        await seedNotification(id: 'notif-1', title: 'Msg 1');
        await seedNotification(id: 'notif-2', title: 'Msg 2');

        // Act
        final stream = repository.watchNotifications(tUserId);
        final first = await stream.first;

        // Assert
        expect(first.length, 2);
        expect(first.map((n) => n.id), containsAll(['notif-1', 'notif-2']));
      });

      test('should emit empty list for user with no notifications', () async {
        // Act
        final stream = repository.watchNotifications('no-user');
        final first = await stream.first;

        // Assert
        expect(first, isEmpty);
      });
    });

    group('markAsRead', () {
      test('should set isRead to true for specific notification', () async {
        // Arrange
        await seedNotification(id: 'notif-1', isRead: false);

        // Act
        await repository.markAsRead(tUserId, 'notif-1');

        // Assert
        final doc = await fakeFirestore
            .collection('users')
            .doc(tUserId)
            .collection('notifications')
            .doc('notif-1')
            .get();
        expect(doc.data()?['isRead'], true);
      });
    });

    group('markAllAsRead', () {
      test('should mark all unread notifications as read', () async {
        // Arrange
        await seedNotification(id: 'notif-1', isRead: false);
        await seedNotification(id: 'notif-2', isRead: false);
        await seedNotification(id: 'notif-3', isRead: true);

        // Act
        await repository.markAllAsRead(tUserId);

        // Assert
        final docs = await fakeFirestore
            .collection('users')
            .doc(tUserId)
            .collection('notifications')
            .get();
        for (final doc in docs.docs) {
          expect(doc.data()['isRead'], true);
        }
      });

      test('should handle no unread notifications gracefully', () async {
        // Arrange
        await seedNotification(id: 'notif-1', isRead: true);

        // Act & Assert — should not throw
        await repository.markAllAsRead(tUserId);
      });
    });

    group('deleteNotification', () {
      test('should delete specific notification', () async {
        // Arrange
        await seedNotification(id: 'notif-1');
        await seedNotification(id: 'notif-2');

        // Act
        await repository.deleteNotification(tUserId, 'notif-1');

        // Assert
        final deletedDoc = await fakeFirestore
            .collection('users')
            .doc(tUserId)
            .collection('notifications')
            .doc('notif-1')
            .get();
        expect(deletedDoc.exists, false);

        final remainingDoc = await fakeFirestore
            .collection('users')
            .doc(tUserId)
            .collection('notifications')
            .doc('notif-2')
            .get();
        expect(remainingDoc.exists, true);
      });
    });

    group('deleteAllNotifications', () {
      test('should delete all notifications for user', () async {
        // Arrange
        await seedNotification(id: 'notif-1');
        await seedNotification(id: 'notif-2');
        await seedNotification(id: 'notif-3');

        // Act
        await repository.deleteAllNotifications(tUserId);

        // Assert
        final docs = await fakeFirestore
            .collection('users')
            .doc(tUserId)
            .collection('notifications')
            .get();
        expect(docs.docs, isEmpty);
      });

      test('should handle empty notification list gracefully', () async {
        // Act & Assert — should not throw
        await repository.deleteAllNotifications(tUserId);
      });
    });
  });
}
