import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';

import 'favorite_repository_test.mocks.dart';

@GenerateMocks([FirebaseAuth, User])
void main() {
  late FavoriteRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  const tUserId = 'user1';
  const tTargetId = 'target1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(tUserId);

    repository = FavoriteRepository(fakeFirestore, mockAuth);
  });

  group('FavoriteRepository', () {
    test('loadFavorites returns set of IDs', () async {
      // Arrange
      await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .doc(tTargetId)
          .set({'favoritedAt': Timestamp.now()});

      // Act
      final result = await repository.loadFavorites();

      // Assert
      expect(result, contains(tTargetId));
      expect(result.length, 1);
    });

    test(
      'addFavorite updates user favorites and target user like count',
      () async {
        // Arrange
        // Create target user doc (professional)
        await fakeFirestore.collection('users').doc(tTargetId).set({
          'likeCount': 0,
        });

        // Act
        await repository.addFavorite(tTargetId);

        // Assert
        // Check user favorites
        final userFavorites = await fakeFirestore
            .collection('users')
            .doc(tUserId)
            .collection('favorites')
            .get();
        expect(userFavorites.docs.map((d) => d.id), contains(tTargetId));

        // Check target user like count
        final targetUser = await fakeFirestore
            .collection('users')
            .doc(tTargetId)
            .get();
        expect(targetUser.data()?['likeCount'], 1);
      },
    );

    test('removeFavorite removes favorite and decrements count', () async {
      // Arrange
      // Setup initial state
      await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .doc(tTargetId)
          .set({'favoritedAt': Timestamp.now()});

      await fakeFirestore.collection('users').doc(tTargetId).set({
        'likeCount': 10,
      });

      // Act
      await repository.removeFavorite(tTargetId);

      // Assert
      final userFavorites = await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .get();
      expect(userFavorites.docs, isEmpty);

      final targetUser = await fakeFirestore
          .collection('users')
          .doc(tTargetId)
          .get();
      expect(targetUser.data()?['likeCount'], 9);
    });

    test('getLikeCount returns correct count from profiles collection', () async {
      // Note: Repository reads from 'profiles' for getLikeCount, but updates 'users' in add/remove
      // This seems to be a discrepancy in the repository implementation or architecture
      // But we test what IS implemented.

      // Arrange
      await fakeFirestore.collection('profiles').doc(tTargetId).set({
        'likeCount': 5,
      });

      // Act
      final count = await repository.getLikeCount(tTargetId);

      // Assert
      expect(count, 5);
    });
  });
}
