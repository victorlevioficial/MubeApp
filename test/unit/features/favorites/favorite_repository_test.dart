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

    test(
      'loadReceivedFavorites returns user ids ordered by latest favorite',
      () async {
        await fakeFirestore
            .collection('users')
            .doc('fan-older')
            .collection('favorites')
            .doc(tUserId)
            .set({
              'favoritedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
              'target_user_id': tUserId,
            });
        await fakeFirestore
            .collection('users')
            .doc('fan-newer')
            .collection('favorites')
            .doc(tUserId)
            .set({
              'favoritedAt': Timestamp.fromDate(DateTime(2026, 2, 1)),
              'target_user_id': tUserId,
            });

        final result = await repository.loadReceivedFavorites();

        expect(result, ['fan-newer', 'fan-older']);
      },
    );

    test(
      'loadReceivedFavorites includes likes from interactions when favorites docs are absent',
      () async {
        await fakeFirestore.collection('interactions').doc('i1').set({
          'source_user_id': 'fan-older',
          'target_user_id': tUserId,
          'type': 'like',
          'created_at': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });
        await fakeFirestore.collection('interactions').doc('i2').set({
          'source_user_id': 'fan-newer',
          'target_user_id': tUserId,
          'type': 'like',
          'created_at': Timestamp.fromDate(DateTime(2026, 2, 1)),
        });
        await fakeFirestore.collection('interactions').doc('i3').set({
          'source_user_id': 'fan-dislike',
          'target_user_id': tUserId,
          'type': 'dislike',
          'created_at': Timestamp.fromDate(DateTime(2026, 3, 1)),
        });

        final result = await repository.loadReceivedFavorites();

        expect(result, ['fan-newer', 'fan-older']);
      },
    );

    test(
      'loadReceivedFavorites includes migrated legacy interactions with receiverId schema',
      () async {
        await fakeFirestore.collection('interactions').doc('legacy-1').set({
          'senderId': 'fan-older',
          'receiverId': tUserId,
          'type': 'like',
          'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1)),
        });
        await fakeFirestore.collection('interactions').doc('legacy-2').set({
          'senderId': 'fan-newer',
          'receiverId': tUserId,
          'type': 'like',
          'timestamp': Timestamp.fromDate(DateTime(2026, 2, 1)),
        });
        await fakeFirestore.collection('interactions').doc('legacy-3').set({
          'senderId': 'fan-dislike',
          'receiverId': tUserId,
          'type': 'dislike',
          'timestamp': Timestamp.fromDate(DateTime(2026, 3, 1)),
        });

        final result = await repository.loadReceivedFavorites();

        expect(result, ['fan-newer', 'fan-older']);
      },
    );

    test(
      'loadReceivedFavorites merges favorites and interactions without duplicates',
      () async {
        await fakeFirestore
            .collection('users')
            .doc('fan-1')
            .collection('favorites')
            .doc(tUserId)
            .set({
              'favoritedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
              'target_user_id': tUserId,
            });
        await fakeFirestore.collection('interactions').doc('i1').set({
          'source_user_id': 'fan-1',
          'target_user_id': tUserId,
          'type': 'like',
          'created_at': Timestamp.fromDate(DateTime(2026, 3, 1)),
        });
        await fakeFirestore.collection('interactions').doc('i2').set({
          'source_user_id': 'fan-2',
          'target_user_id': tUserId,
          'type': 'like',
          'created_at': Timestamp.fromDate(DateTime(2026, 2, 1)),
        });

        final result = await repository.loadReceivedFavorites();

        expect(result, ['fan-1', 'fan-2']);
      },
    );

    test(
      'loadReceivedFavorites recovers legacy favorites without target_user_id when expectedCount is provided',
      () async {
        await fakeFirestore.collection('users').doc('fan-legacy-1').set({
          'nome': 'Fan Legacy 1',
        });
        await fakeFirestore.collection('users').doc('fan-legacy-2').set({
          'nome': 'Fan Legacy 2',
        });
        await fakeFirestore.collection('users').doc('fan-interaction').set({
          'nome': 'Fan Interaction',
        });

        await fakeFirestore
            .collection('users')
            .doc('fan-legacy-1')
            .collection('favorites')
            .doc(tUserId)
            .set({'favoritedAt': Timestamp.fromDate(DateTime(2026, 1, 1))});
        await fakeFirestore
            .collection('users')
            .doc('fan-legacy-2')
            .collection('favorites')
            .doc(tUserId)
            .set({'favoritedAt': Timestamp.fromDate(DateTime(2026, 3, 1))});
        await fakeFirestore.collection('interactions').doc('i1').set({
          'source_user_id': 'fan-interaction',
          'target_user_id': tUserId,
          'type': 'like',
          'created_at': Timestamp.fromDate(DateTime(2026, 2, 1)),
        });

        final result = await repository.loadReceivedFavorites(expectedCount: 3);

        expect(
          result,
          containsAll(<String>[
            'fan-legacy-1',
            'fan-legacy-2',
            'fan-interaction',
          ]),
        );
        expect(result.length, 3);
      },
    );

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
      expect(favoriteDoc.data(), containsPair('target_user_id', tTargetId));
      expect(favoriteDoc.data(), containsPair('source_user_id', tUserId));
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

    test('getLikeCount ignores legacy profiles collection', () async {
      await fakeFirestore.collection('profiles').doc(tTargetId).set({
        'likeCount': 5,
      });

      final count = await repository.getLikeCount(tTargetId);

      expect(count, 0);
    });
  });
}
