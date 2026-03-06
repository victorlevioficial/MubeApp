import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/feed/data/feed_remote_data_source.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_discovery.dart';

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

    test(
      'getDiscoverFeedPoolSorted scans visible profiles and sorts by distance',
      () async {
        await fakeFirestore.collection('users').doc('band-1').set({
          'uid': 'band-1',
          'nome': 'Band 1',
          'tipo_perfil': 'banda',
          'cadastro_status': 'concluido',
          'status': 'ativo',
          'banda': {'nomeBanda': 'Band 1'},
          'location': {'lat': 0.2, 'lng': 0.2},
        });

        await fakeFirestore.collection('users').doc('hidden-1').set({
          'uid': 'hidden-1',
          'nome': 'Hidden 1',
          'tipo_perfil': 'estudio',
          'cadastro_status': 'concluido',
          'status': 'ativo',
          'privacy_settings': {'visible_in_home': false},
          'estudio': {'nomeEstudio': 'Hidden Studio'},
          'location': {'lat': 0.01, 'lng': 0.01},
        });

        await fakeFirestore.collection('users').doc('inactive-1').set({
          'uid': 'inactive-1',
          'nome': 'Inactive 1',
          'tipo_perfil': 'profissional',
          'cadastro_status': 'concluido',
          'status': 'suspenso',
          'profissional': {
            'categorias': ['singer'],
          },
          'location': {'lat': 0.05, 'lng': 0.05},
        });

        final result = await repository.getDiscoverFeedPoolSorted(
          currentUserId: myUid,
          userLat: 0.0,
          userLong: 0.0,
          filter: FeedDiscoveryFilter.all,
        );

        expect(result.isRight(), true);
        result.fold((l) => fail('Should not fail: $l'), (r) {
          expect(r.map((item) => item.uid), [otherUid, 'band-1']);
          expect(r.every((item) => item.uid != 'hidden-1'), true);
          expect(r.every((item) => item.uid != 'inactive-1'), true);
          expect(r.first.distanceKm, isNotNull);
          expect(r.first.distanceKm! < r.last.distanceKm!, true);
        });
      },
    );
  });
}
