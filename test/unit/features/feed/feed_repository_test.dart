import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';

import '../../../helpers/test_fakes.dart';

void main() {
  late FakeFeedRepository repository;

  const tUserId = 'user1';
  const tFeedItem = FeedItem(
    uid: 'user2',
    nome: 'User 2',
    foto: 'photo.jpg',
    tipoPerfil: 'profissional',
    categoria: 'Profissional',
    location: {'lat': 0.0, 'lng': 0.0},
  );

  setUp(() {
    repository = FakeFeedRepository();
  });

  group('FeedRepository', () {
    test('getNearbyUsers returns list of FeedItem on success', () async {
      repository.nearbyUsers = [tFeedItem];

      final result = await repository.getNearbyUsers(
        lat: 0.0,
        long: 0.0,
        radiusKm: 10,
        currentUserId: tUserId,
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r, isA<List<FeedItem>>());
        expect(r.length, 1);
        expect(r.first.uid, tFeedItem.uid);
      });
    });

    test('getUsersByType returns list of FeedItem on success', () async {
      repository.bands = [tFeedItem];

      final result = await repository.getUsersByType(
        type: 'musico',
        currentUserId: tUserId,
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r, isA<List<FeedItem>>());
        expect(r.length, 1);
        expect(r.first.uid, tFeedItem.uid);
      });
    });

    test('getMainFeedPaginated returns PaginatedFeedResponse', () async {
      const response = PaginatedFeedResponse(
        items: [tFeedItem],
        hasMore: false,
        lastDocument: null,
      );
      repository.mainFeedResponse = response;

      final result = await repository.getMainFeedPaginated(
        currentUserId: tUserId,
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.items.length, 1);
        expect(r.hasMore, false);
      });
    });

    test('getNearbyUsers returns empty list when no data', () async {
      final result = await repository.getNearbyUsers(
        lat: 0.0,
        long: 0.0,
        radiusKm: 10,
        currentUserId: tUserId,
      );

      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return failure'),
        (r) => expect(r, isEmpty),
      );
    });

    test('methods throw when throwError is true', () async {
      repository.throwError = true;

      expect(
        () => repository.getNearbyUsers(
          lat: 0.0,
          long: 0.0,
          radiusKm: 10,
          currentUserId: tUserId,
        ),
        throwsException,
      );
    });

    test('getArtists returns artists list', () async {
      repository.artists = [tFeedItem];

      final result = await repository.getArtists(currentUserId: tUserId);

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not return failure'), (r) {
        expect(r.length, 1);
        expect(r.first.uid, tFeedItem.uid);
      });
    });
  });
}
