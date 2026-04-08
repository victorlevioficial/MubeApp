import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_feed_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_remote_data_source.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_feed_snapshot.dart';

class _FakeLegacyRepository extends Fake implements MatchpointRepository {
  FutureResult<List<AppUser>> Function({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    required int limit,
  })?
  onFetchCandidates;

  @override
  FutureResult<List<AppUser>> fetchCandidates({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    return onFetchCandidates!(
      currentUser: currentUser,
      genres: genres,
      hashtags: hashtags,
      blockedUsers: blockedUsers,
      limit: limit,
    );
  }
}

class _FakeRemoteDataSource extends Fake implements MatchpointRemoteDataSource {
  final Map<String, AppUser> usersById;

  _FakeRemoteDataSource(this.usersById);

  @override
  Future<Map<String, AppUser>> fetchUsersByIds(List<String> ids) async {
    return {
      for (final id in ids)
        if (usersById.containsKey(id)) id: usersById[id]!,
    };
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _FakeLegacyRepository legacyRepository;
  late _FakeRemoteDataSource remoteDataSource;
  late ProjectedMatchpointFeedRepository repository;

  const currentUser = AppUser(
    uid: 'user-1',
    email: 'user-1@mube.app',
    blockedUsers: [],
    matchpointProfile: {'is_active': true},
    privacySettings: {},
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    legacyRepository = _FakeLegacyRepository()
      ..onFetchCandidates =
          ({
            required currentUser,
            required genres,
            required hashtags,
            required blockedUsers,
            required limit,
          }) async => const Right([
            AppUser(uid: 'legacy-1', email: 'legacy-1@mube.app'),
          ]);
    remoteDataSource = _FakeRemoteDataSource({
      'target-1': const AppUser(uid: 'target-1', email: 'target-1@mube.app'),
      'target-2': const AppUser(uid: 'target-2', email: 'target-2@mube.app'),
    });
    repository = ProjectedMatchpointFeedRepository(
      firestore,
      remoteDataSource,
      LegacyMatchpointFeedRepository(legacyRepository),
    );
  });

  group('ProjectedMatchpointFeedRepository', () {
    test('returns projected feed when the projection exists', () async {
      await firestore
          .collection(FirestoreCollections.matchpointFeeds)
          .doc(currentUser.uid)
          .set({
            'candidate_ids': ['target-2', 'target-1'],
            'generated_at': Timestamp.fromDate(DateTime(2026, 4, 8, 14)),
            'expires_at': Timestamp.fromDate(DateTime(2099, 1, 1)),
          });

      final result = await repository.fetchExploreFeed(
        currentUser: currentUser,
        genres: const ['rock'],
        hashtags: const ['#indie'],
        blockedUsers: const [],
      );

      expect(result.isRight(), isTrue);
      final snapshot = result.getRight().toNullable()!;
      expect(snapshot.source, MatchpointFeedSource.projectedFeed);
      expect(snapshot.isServerRanked, isTrue);
      expect(snapshot.candidates.map((user) => user.uid).toList(), [
        'target-2',
        'target-1',
      ]);
    });

    test(
      'falls back to legacy and queues refresh when projection is missing',
      () async {
        final result = await repository.fetchExploreFeed(
          currentUser: currentUser,
          genres: const ['rock'],
          hashtags: const ['#indie'],
          blockedUsers: const [],
        );

        expect(result.isRight(), isTrue);
        final snapshot = result.getRight().toNullable()!;
        expect(snapshot.source, MatchpointFeedSource.legacyQuery);
        expect(snapshot.candidates.single.uid, 'legacy-1');

        final refreshRequests = await firestore
            .collection(FirestoreCollections.matchpointFeedRefreshRequests)
            .get();
        expect(refreshRequests.docs, hasLength(1));
        expect(refreshRequests.docs.single.data()['user_id'], currentUser.uid);
      },
    );

    test('returns stale projected feed and still queues refresh', () async {
      await firestore
          .collection(FirestoreCollections.matchpointFeeds)
          .doc(currentUser.uid)
          .set({
            'candidate_ids': ['target-1'],
            'generated_at': Timestamp.fromDate(DateTime(2024, 4, 8, 14)),
            'expires_at': Timestamp.fromDate(DateTime(2024, 4, 8, 14, 1)),
          });

      final result = await repository.fetchExploreFeed(
        currentUser: currentUser,
        genres: const ['rock'],
        hashtags: const ['#indie'],
        blockedUsers: const [],
      );

      expect(result.isRight(), isTrue);
      final snapshot = result.getRight().toNullable()!;
      expect(snapshot.source, MatchpointFeedSource.projectedFeed);
      expect(snapshot.candidates.single.uid, 'target-1');

      await Future<void>.delayed(Duration.zero);
      final refreshRequests = await firestore
          .collection(FirestoreCollections.matchpointFeedRefreshRequests)
          .get();
      expect(refreshRequests.docs, hasLength(1));
    });
  });
}
