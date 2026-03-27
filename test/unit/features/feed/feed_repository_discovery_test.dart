import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/features/feed/data/feed_remote_data_source.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_discovery.dart';
import 'package:mube/src/utils/geohash_helper.dart';

void main() {
  group('FeedRepository discovery pool', () {
    test(
      'caps nearby discovery pool instead of loading every matching user',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));
        const currentUserId = 'current-user';
        const userLat = -23.5505;
        const userLong = -46.6333;
        final geohash = GeohashHelper.encode(userLat, userLong, precision: 5);

        await firestore
            .collection(FirestoreCollections.users)
            .doc(currentUserId)
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.professional,
              FirestoreFields.name: 'Current User',
              FirestoreFields.geohash: geohash,
              FirestoreFields.location: {'lat': userLat, 'lng': userLong},
              'status': 'ativo',
            });

        for (var i = 0; i < 150; i++) {
          await firestore
              .collection(FirestoreCollections.users)
              .doc('user-$i')
              .set({
                FirestoreFields.registrationStatus: RegistrationStatus.complete,
                FirestoreFields.profileType: ProfileType.professional,
                FirestoreFields.name: 'User $i',
                FirestoreFields.geohash: geohash,
                FirestoreFields.location: {
                  'lat': userLat + (i * 0.0001),
                  'lng': userLong + (i * 0.0001),
                },
                'status': 'ativo',
              });
        }

        final result = await repository.getDiscoverFeedPoolSorted(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Expected discovery pool items'), (items) {
          expect(items.length, lessThanOrEqualTo(120));
          expect(items.length, greaterThanOrEqualTo(100));
          expect(items.first.uid, isNot(currentUserId));
        });
      },
    );

    test(
      'backfills discovery pool with visible profiles when nearby results are scarce',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));
        const currentUserId = 'current-user';
        const userLat = -23.5505;
        const userLong = -46.6333;
        final centerGeohash = GeohashHelper.encode(
          userLat,
          userLong,
          precision: 5,
        );
        final farGeohash = GeohashHelper.encode(
          userLat + 8,
          userLong + 8,
          precision: 5,
        );

        await firestore
            .collection(FirestoreCollections.users)
            .doc(currentUserId)
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.professional,
              FirestoreFields.name: 'Current User',
              FirestoreFields.geohash: centerGeohash,
              FirestoreFields.location: {'lat': userLat, 'lng': userLong},
              'status': 'ativo',
            });

        for (var i = 0; i < 25; i++) {
          await firestore
              .collection(FirestoreCollections.users)
              .doc('near-$i')
              .set({
                FirestoreFields.registrationStatus: RegistrationStatus.complete,
                FirestoreFields.profileType: ProfileType.professional,
                FirestoreFields.name: 'Near User $i',
                FirestoreFields.geohash: centerGeohash,
                FirestoreFields.location: {
                  'lat': userLat + (i * 0.0001),
                  'lng': userLong + (i * 0.0001),
                },
                'status': 'ativo',
              });
        }

        for (var i = 0; i < 40; i++) {
          await firestore
              .collection(FirestoreCollections.users)
              .doc('far-$i')
              .set({
                FirestoreFields.registrationStatus: RegistrationStatus.complete,
                FirestoreFields.profileType: ProfileType.band,
                FirestoreFields.name: 'Far User $i',
                FirestoreFields.geohash: farGeohash,
                FirestoreFields.location: {
                  'lat': userLat + 8 + (i * 0.0001),
                  'lng': userLong + 8 + (i * 0.0001),
                },
                'status': 'ativo',
              });
        }

        final result = await repository.getDiscoverFeedPoolSorted(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Expected discovery pool items'), (items) {
          expect(items.length, greaterThan(25));
          expect(items.map((item) => item.uid), contains('near-0'));
          expect(items.map((item) => item.uid), contains('far-0'));
        });
      },
    );

    test(
      'returns a fast nearby-only partial pool before bounded scan backfill',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));
        const currentUserId = 'current-user';
        const userLat = -23.5505;
        const userLong = -46.6333;
        final centerGeohash = GeohashHelper.encode(
          userLat,
          userLong,
          precision: 5,
        );
        final farGeohash = GeohashHelper.encode(
          userLat + 8,
          userLong + 8,
          precision: 5,
        );

        await firestore
            .collection(FirestoreCollections.users)
            .doc(currentUserId)
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.professional,
              FirestoreFields.name: 'Current User',
              FirestoreFields.geohash: centerGeohash,
              FirestoreFields.location: {'lat': userLat, 'lng': userLong},
              'status': 'ativo',
            });

        for (var i = 0; i < 25; i++) {
          await firestore
              .collection(FirestoreCollections.users)
              .doc('near-$i')
              .set({
                FirestoreFields.registrationStatus: RegistrationStatus.complete,
                FirestoreFields.profileType: ProfileType.professional,
                FirestoreFields.name: 'Near User $i',
                FirestoreFields.geohash: centerGeohash,
                FirestoreFields.location: {
                  'lat': userLat + (i * 0.0001),
                  'lng': userLong + (i * 0.0001),
                },
                'status': 'ativo',
              });
        }

        for (var i = 0; i < 40; i++) {
          await firestore
              .collection(FirestoreCollections.users)
              .doc('far-$i')
              .set({
                FirestoreFields.registrationStatus: RegistrationStatus.complete,
                FirestoreFields.profileType: ProfileType.band,
                FirestoreFields.name: 'Far User $i',
                FirestoreFields.geohash: farGeohash,
                FirestoreFields.location: {
                  'lat': userLat + 8 + (i * 0.0001),
                  'lng': userLong + 8 + (i * 0.0001),
                },
                'status': 'ativo',
              });
        }

        final result = await repository.getDiscoverFeedPool(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          targetResults: 40,
          fastPartialThreshold: 20,
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Expected discovery pool result'), (pool) {
          expect(pool.source, 'nearby_partial');
          expect(pool.isExhaustive, isFalse);
          expect(pool.items.length, 25);
          expect(pool.items.map((item) => item.uid), contains('near-0'));
          expect(pool.items.map((item) => item.uid), isNot(contains('far-0')));
        });
      },
    );

    test('caps bounded scan results when location is unavailable', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));
      const currentUserId = 'current-user';

      for (var i = 0; i < 160; i++) {
        await firestore
            .collection(FirestoreCollections.users)
            .doc('band-$i')
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.band,
              FirestoreFields.name: 'Band $i',
              'status': 'ativo',
            });
      }

      final result = await repository.getDiscoverFeedPoolSorted(
        currentUserId: currentUserId,
        userLat: null,
        userLong: null,
        filter: FeedDiscoveryFilter.bands,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected discovery pool items'),
        (items) => expect(items.length, 80),
      );
    });

    test('classic fallback excludes hidden and inactive profiles', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));
      const currentUserId = 'current-user';
      const userLat = 0.0;
      const userLong = 0.0;

      await firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .set({
            FirestoreFields.registrationStatus: RegistrationStatus.complete,
            FirestoreFields.name: 'Current User',
            FirestoreFields.location: {'lat': userLat, 'lng': userLong},
            FirestoreFields.geohash: 's0000',
          });

      await firestore
          .collection(FirestoreCollections.users)
          .doc('artist-1')
          .set({
            FirestoreFields.registrationStatus: RegistrationStatus.complete,
            FirestoreFields.profileType: ProfileType.professional,
            FirestoreFields.name: 'Artist 1',
            FirestoreFields.location: {'lat': 0.02, 'lng': 0.02},
            'status': 'ativo',
          });

      await firestore
          .collection(FirestoreCollections.users)
          .doc('hidden-1')
          .set({
            FirestoreFields.registrationStatus: RegistrationStatus.complete,
            FirestoreFields.profileType: ProfileType.studio,
            FirestoreFields.name: 'Hidden 1',
            FirestoreFields.location: {'lat': 0.01, 'lng': 0.01},
            'status': 'ativo',
            'privacy_settings': {'visible_in_home': false},
          });

      await firestore
          .collection(FirestoreCollections.users)
          .doc('inactive-1')
          .set({
            FirestoreFields.registrationStatus: RegistrationStatus.complete,
            FirestoreFields.profileType: ProfileType.band,
            FirestoreFields.name: 'Inactive 1',
            FirestoreFields.location: {'lat': 0.03, 'lng': 0.03},
            'status': 'suspenso',
          });

      final result = await repository.getDiscoverFeedPoolSorted(
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected discovery pool items'),
        (items) => expect(items.map((item) => item.uid), ['artist-1']),
      );
    });

    test(
      'loads center and neighbor geohashes without compound whereIn',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));
        const currentUserId = 'current-user';
        const userLat = -23.5505;
        const userLong = -46.6333;
        final centerGeohash = GeohashHelper.encode(
          userLat,
          userLong,
          precision: 5,
        );
        final neighborGeohash = GeohashHelper.neighbors(centerGeohash)[1];

        await firestore
            .collection(FirestoreCollections.users)
            .doc(currentUserId)
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.professional,
              FirestoreFields.name: 'Current User',
              FirestoreFields.geohash: centerGeohash,
              FirestoreFields.location: {'lat': userLat, 'lng': userLong},
              'status': 'ativo',
            });

        await firestore
            .collection(FirestoreCollections.users)
            .doc('band-center')
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.band,
              FirestoreFields.name: 'Band Center',
              FirestoreFields.geohash: centerGeohash,
              FirestoreFields.location: {
                'lat': userLat + 0.002,
                'lng': userLong,
              },
              'status': 'ativo',
            });

        await firestore
            .collection(FirestoreCollections.users)
            .doc('studio-neighbor')
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.studio,
              FirestoreFields.name: 'Studio Neighbor',
              FirestoreFields.geohash: neighborGeohash,
              FirestoreFields.location: {
                'lat': userLat,
                'lng': userLong + 0.01,
              },
              'status': 'ativo',
            });

        final result = await repository.getAllUsersSortedByDistance(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          userGeohash: centerGeohash,
          limit: 10,
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected geohash items'),
          (items) => expect(
            items.map((item) => item.uid),
            containsAll(['band-center', 'studio-neighbor']),
          ),
        );
      },
    );

    test('filters technician candidates to pure technicians only', () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));

      await firestore.collection(FirestoreCollections.users).doc('tech-1').set({
        FirestoreFields.registrationStatus: RegistrationStatus.complete,
        FirestoreFields.profileType: ProfileType.professional,
        FirestoreFields.name: 'Tech 1',
        FirestoreFields.professional: {
          'categorias': ['stage_tech'],
          'funcoes': ['roadie'],
        },
        'status': 'ativo',
      });

      await firestore.collection(FirestoreCollections.users).doc('tech-2').set({
        FirestoreFields.registrationStatus: RegistrationStatus.complete,
        FirestoreFields.profileType: ProfileType.professional,
        FirestoreFields.name: 'Tech 2',
        FirestoreFields.professional: {
          'categorias': ['crew'],
          'funcoes': ['backline_tech'],
        },
        'status': 'ativo',
      });

      await firestore.collection(FirestoreCollections.users).doc('mixed-1').set(
        {
          FirestoreFields.registrationStatus: RegistrationStatus.complete,
          FirestoreFields.profileType: ProfileType.professional,
          FirestoreFields.name: 'Mixed 1',
          FirestoreFields.professional: {
            'categorias': ['singer', 'stage_tech'],
            'funcoes': ['backline_tech'],
          },
          'status': 'ativo',
        },
      );

      final result = await repository.getTechniciansPaginated(
        currentUserId: 'current-user',
        limit: 10,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected technician items'),
        (page) =>
            expect(page.items.map((item) => item.uid), ['tech-1', 'tech-2']),
      );
    });

    test(
      'loads only public contractors and ignores visible_in_home for venues',
      () async {
        final firestore = FakeFirebaseFirestore();
        final repository = FeedRepository(FeedRemoteDataSourceImpl(firestore));

        await firestore
            .collection(FirestoreCollections.users)
            .doc('venue-1')
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.contractor,
              FirestoreFields.name: 'Venue 1',
              FirestoreFields.location: {'lat': -23.55, 'lng': -46.63},
              'status': 'ativo',
              'privacy_settings': {'visible_in_home': false},
              FirestoreFields.contractor: {
                'isPublic': true,
                'nomeExibicao': 'Venue 1',
              },
            });

        await firestore
            .collection(FirestoreCollections.users)
            .doc('venue-2')
            .set({
              FirestoreFields.registrationStatus: RegistrationStatus.complete,
              FirestoreFields.profileType: ProfileType.contractor,
              FirestoreFields.name: 'Venue 2',
              FirestoreFields.location: {'lat': -23.56, 'lng': -46.64},
              'status': 'ativo',
              FirestoreFields.contractor: {
                'isPublic': false,
                'nomeExibicao': 'Venue 2',
              },
            });

        final result = await repository.getPublicContractorsPaginated(
          currentUserId: 'current-user',
          userLat: -23.55,
          userLong: -46.63,
          limit: 10,
        );

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected public contractor items'),
          (page) => expect(page.items.map((item) => item.uid), ['venue-1']),
        );
      },
    );
  });
}
