import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';

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

    test('methods throw when throwError is true', () async {
      repository.throwError = true;

      expect(
        () => repository.getArtists(currentUserId: tUserId),
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
