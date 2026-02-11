import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/moderation/data/moderation_repository.dart';

void main() {
  late ModerationRepository repository;
  late FakeFirebaseFirestore fakeFirestore;

  const tCurrentUserId = 'user-1';
  const tBlockedUserId = 'user-2';
  const tReporterId = 'user-1';
  const tReportedUserId = 'user-3';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = ModerationRepository(fakeFirestore);
  });

  group('ModerationRepository', () {
    group('reportUser', () {
      test('should create report document and return Right', () async {
        // Act
        final result = await repository.reportUser(
          reporterId: tReporterId,
          reportedUserId: tReportedUserId,
          reason: 'spam',
          description: 'Enviando spam no chat',
        );

        // Assert
        expect(result.isRight(), true);

        final reports = await fakeFirestore.collection('reports').get();
        expect(reports.docs.length, 1);

        final reportData = reports.docs.first.data();
        expect(reportData['reporter_user_id'], tReporterId);
        expect(reportData['reported_item_id'], tReportedUserId);
        expect(reportData['reported_item_type'], 'user');
        expect(reportData['reason'], 'spam');
        expect(reportData['description'], 'Enviando spam no chat');
        expect(reportData['status'], 'pending');
      });

      test('should create report without description', () async {
        // Act
        final result = await repository.reportUser(
          reporterId: tReporterId,
          reportedUserId: tReportedUserId,
          reason: 'inappropriate',
        );

        // Assert
        expect(result.isRight(), true);

        final reports = await fakeFirestore.collection('reports').get();
        expect(reports.docs.length, 1);
        expect(reports.docs.first.data()['description'], isNull);
      });
    });

    group('blockUser', () {
      test('should create blocked document and return Right', () async {
        // Act
        final result = await repository.blockUser(
          currentUserId: tCurrentUserId,
          blockedUserId: tBlockedUserId,
        );

        // Assert
        expect(result.isRight(), true);

        final blockedDoc = await fakeFirestore
            .collection('users')
            .doc(tCurrentUserId)
            .collection('blocked')
            .doc(tBlockedUserId)
            .get();
        expect(blockedDoc.exists, true);
        expect(blockedDoc.data()?['blockedUserId'], tBlockedUserId);
      });

      test('should not fail when blocking an already blocked user', () async {
        // Arrange
        await repository.blockUser(
          currentUserId: tCurrentUserId,
          blockedUserId: tBlockedUserId,
        );

        // Act
        final result = await repository.blockUser(
          currentUserId: tCurrentUserId,
          blockedUserId: tBlockedUserId,
        );

        // Assert
        expect(result.isRight(), true);
      });
    });

    group('unblockUser', () {
      test('should delete blocked document and return Right', () async {
        // Arrange
        await fakeFirestore
            .collection('users')
            .doc(tCurrentUserId)
            .collection('blocked')
            .doc(tBlockedUserId)
            .set({
              'blockedUserId': tBlockedUserId,
              'blockedAt': DateTime.now().toIso8601String(),
            });

        // Act
        final result = await repository.unblockUser(
          currentUserId: tCurrentUserId,
          blockedUserId: tBlockedUserId,
        );

        // Assert
        expect(result.isRight(), true);

        final blockedDoc = await fakeFirestore
            .collection('users')
            .doc(tCurrentUserId)
            .collection('blocked')
            .doc(tBlockedUserId)
            .get();
        expect(blockedDoc.exists, false);
      });

      test('should return Right even when user was not blocked', () async {
        // Act
        final result = await repository.unblockUser(
          currentUserId: tCurrentUserId,
          blockedUserId: tBlockedUserId,
        );

        // Assert
        expect(result.isRight(), true);
      });
    });
  });
}
