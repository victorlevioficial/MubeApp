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
    test('loadFavorites returns set of ids', () async {
      await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .doc(tTargetId)
          .set({'favoritedAt': Timestamp.now()});

      final result = await repository.loadFavorites();

      expect(result, contains(tTargetId));
      expect(result.length, 1);
    });

    test('addFavorite writes current user favorites subcollection', () async {
      await repository.addFavorite(tTargetId);

      final favoriteDoc = await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .doc(tTargetId)
          .get();

      expect(favoriteDoc.exists, isTrue);
      expect(favoriteDoc.data(), contains('favoritedAt'));
    });

    test('removeFavorite deletes favorite doc', () async {
      await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .doc(tTargetId)
          .set({'favoritedAt': Timestamp.now()});

      await repository.removeFavorite(tTargetId);

      final favoriteDoc = await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .doc(tTargetId)
          .get();

      expect(favoriteDoc.exists, isFalse);
    });

    test('removeFavorite is idempotent when doc does not exist', () async {
      await repository.removeFavorite(tTargetId);

      final favoriteDoc = await fakeFirestore
          .collection('users')
          .doc(tUserId)
          .collection('favorites')
          .doc(tTargetId)
          .get();

      expect(favoriteDoc.exists, isFalse);
    });

    test('getLikeCount reads likeCount from users collection', () async {
      await fakeFirestore.collection('users').doc(tTargetId).set({
        'likeCount': 7,
      });

      final count = await repository.getLikeCount(tTargetId);

      expect(count, 7);
    });

    test('getLikeCount falls back to favorites_count in users', () async {
      await fakeFirestore.collection('users').doc(tTargetId).set({
        'favorites_count': 3,
      });

      final count = await repository.getLikeCount(tTargetId);

      expect(count, 3);
    });

    test(
      'getLikeCount falls back to profiles collection for legacy docs',
      () async {
        await fakeFirestore.collection('profiles').doc(tTargetId).set({
          'likeCount': 5,
        });

        final count = await repository.getLikeCount(tTargetId);

        expect(count, 5);
      },
    );
  });
}
