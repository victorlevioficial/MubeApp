import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/data/feed_remote_data_source.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';

void main() {
  late FeedRepository repository;
  late FeedRemoteDataSource dataSource;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FeedRemoteDataSourceImpl(fakeFirestore);
    repository = FeedRepository(dataSource);
  });

  group('FeedRepository', () {
    const myUid = 'user1';
    const otherUid = 'user2';

    setUp(() async {
      // Setup current user
      await fakeFirestore.collection('users').doc(myUid).set({
        'uid': myUid,
        'email': 'me@test.com',
        'cadastro_status': 'concluido',
        'location': {'lat': 0.0, 'lng': 0.0},
        'geohash': 's0000',
      });

      // Setup other user
      await fakeFirestore.collection('users').doc(otherUid).set({
        'uid': otherUid,
        'nome': 'Other User',
        'tipo_perfil': 'profissional', // matched with ProfileType.professional
        'cadastro_status': 'concluido',
        'status': 'ativo',
        'profissional': {
          'categorias': ['singer'],
          'generosMusicais': ['rock'],
        },
        'location': {'lat': 0.1, 'lng': 0.1},
        'geohash': 's0001',
      });
    });

    test('getNearbyUsers should return list of users', () async {
      final result = await repository.getNearbyUsers(
        lat: 0.0,
        long: 0.0,
        radiusKm: 50.0,
        currentUserId: myUid,
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not fail: $l'), (r) {
        expect(r.length, 1);
        expect(r.first.uid, otherUid);
      });
    });

    test('getUsersByType should filter by type', () async {
      final result = await repository.getUsersByType(
        type: 'profissional',
        currentUserId: myUid,
      );

      expect(result.isRight(), true);
      result.fold((l) => fail('Should not fail: $l'), (r) {
        expect(r.length, 1);
        expect(r.first.uid, otherUid);
      });
    });
  });
}
