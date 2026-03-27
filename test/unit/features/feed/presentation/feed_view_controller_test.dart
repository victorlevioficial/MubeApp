import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/feed_section.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/feed/presentation/feed_view_controller.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeFeedRepository fakeFeedRepo;
  late ProviderContainer container;

  FeedItem createArtistItem(String id) => FeedItem(
    uid: id,
    nome: 'Artist $id',
    tipoPerfil: ProfileType.professional,
  );

  FeedItem createBandItem(String id) =>
      FeedItem(uid: id, nome: 'Band $id', tipoPerfil: ProfileType.band);

  FeedItem createStudioItem(String id) =>
      FeedItem(uid: id, nome: 'Studio $id', tipoPerfil: ProfileType.studio);

  FeedItem createVenueItem(String id) =>
      FeedItem(uid: id, nome: 'Venue $id', tipoPerfil: ProfileType.contractor);

  FeedItem createTechnicianItem(String id) => FeedItem(
    uid: id,
    nome: 'Tech $id',
    tipoPerfil: ProfileType.professional,
    subCategories: const ['stage_tech'],
  );

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeFeedRepo = FakeFeedRepository();

    final firebaseUser = FakeFirebaseUser(uid: 'u1', email: 'a@b.com');
    fakeAuthRepo.emitUser(firebaseUser);
    fakeAuthRepo.appUser = TestData.user(uid: 'u1');

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
        blockedUsersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> waitForUser(ProviderContainer activeContainer) async {
    final completer = Completer<void>();
    final sub = activeContainer.listen(currentUserProfileProvider, (_, next) {
      if (next.hasValue && next.value != null && !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);
    await completer.future.timeout(const Duration(seconds: 2));
    sub.close();
  }

  group('FeedListController', () {
    test('returns empty state when user is null', () async {
      fakeAuthRepo.emitUser(null);
      fakeAuthRepo.appUser = null;

      final noUserContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          blockedUsersProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(noUserContainer.dispose);

      final provider = feedListControllerProvider(FeedSectionType.artists);
      await noUserContainer.read(provider.future);
      final state = noUserContainer.read(provider).value!;

      expect(state.items, isEmpty);
      expect(state.hasMore, isFalse);
    });

    test('loads technicians section from paginated technician query', () async {
      fakeFeedRepo.technicians = const [
        FeedItem(
          uid: 'tech-1',
          nome: 'Tech 1',
          tipoPerfil: ProfileType.professional,
          subCategories: ['stage_tech'],
          distanceKm: 1,
        ),
        FeedItem(
          uid: 'tech-2',
          nome: 'Tech 2',
          tipoPerfil: ProfileType.professional,
          subCategories: ['stage_tech'],
          distanceKm: 3,
        ),
      ];
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.technicians);
      await container.read(provider.future);
      final state = container.read(provider).value!;

      expect(state.items.map((item) => item.uid), ['tech-1', 'tech-2']);
      expect(state.hasMore, isFalse);
      expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
      expect(fakeFeedRepo.paginatedTypeCallHistory, isEmpty);
      expect(fakeFeedRepo.techniciansPaginatedStartAfterHistory, [isNull]);
    });

    test('loads nearby section with empty results', () async {
      fakeFeedRepo.nearbyUsers = [];
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.nearby);
      await container.read(provider.future);
      final state = container.read(provider).value!;

      expect(state.items, isEmpty);
      expect(state.hasMore, isFalse);
    });

    test('loads bands section from paginated type query', () async {
      fakeFeedRepo.bands = List.generate(
        3,
        (i) => createBandItem('band-$i').copyWith(distanceKm: i.toDouble()),
      );
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.bands);
      await container.read(provider.future);
      final state = container.read(provider).value!;

      expect(state.items.length, 3);
      expect(state.hasMore, isFalse);
      expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
      expect(fakeFeedRepo.paginatedTypeCallHistory, [ProfileType.band]);
    });

    test('loads studios section from paginated type query', () async {
      fakeFeedRepo.studios = List.generate(
        2,
        (i) => createStudioItem('studio-$i').copyWith(distanceKm: i.toDouble()),
      );
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.studios);
      await container.read(provider.future);
      final state = container.read(provider).value!;

      expect(state.items.map((item) => item.uid), ['studio-0', 'studio-1']);
      expect(state.hasMore, isFalse);
      expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
      expect(fakeFeedRepo.paginatedTypeCallHistory, [ProfileType.studio]);
    });

    test(
      'loads venues section from dedicated public contractor query',
      () async {
        fakeFeedRepo.venues = List.generate(
          2,
          (i) => createVenueItem('venue-$i').copyWith(distanceKm: i.toDouble()),
        );
        await waitForUser(container);

        final provider = feedListControllerProvider(FeedSectionType.venues);
        await container.read(provider.future);
        final state = container.read(provider).value!;

        expect(state.items.map((item) => item.uid), ['venue-0', 'venue-1']);
        expect(state.hasMore, isFalse);
        expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
        expect(fakeFeedRepo.paginatedTypeCallHistory, isEmpty);
        expect(fakeFeedRepo.publicContractorsPaginatedStartAfterHistory, [
          isNull,
        ]);
      },
    );

    test('loads artists without scanning the full discovery pool', () async {
      fakeFeedRepo.artists = [
        createArtistItem('artist-1'),
        createArtistItem('artist-2'),
      ];
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.artists);
      await container.read(provider.future);
      final state = container.read(provider).value!;

      expect(state.items.map((item) => item.uid), ['artist-1', 'artist-2']);
      expect(state.hasMore, isFalse);
    });

    test('loads with fallback when user has no location', () async {
      fakeAuthRepo.appUser = TestData.user(uid: 'u1', location: {});
      fakeFeedRepo.bands = [createBandItem('b1'), createBandItem('b2')];

      final noLocContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          blockedUsersProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(noLocContainer.dispose);
      await waitForUser(noLocContainer);

      final provider = feedListControllerProvider(FeedSectionType.bands);
      await noLocContainer.read(provider.future);
      final state = noLocContainer.read(provider).value!;

      expect(state.items.length, 2);
      expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
      expect(fakeFeedRepo.paginatedTypeCallHistory, [ProfileType.band]);
    });

    test('nearby without location returns empty', () async {
      fakeAuthRepo.appUser = TestData.user(uid: 'u1', location: {});

      final noLocContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          feedRepositoryProvider.overrideWithValue(fakeFeedRepo),
          blockedUsersProvider.overrideWith((ref) => Stream.value([])),
        ],
      );
      addTearDown(noLocContainer.dispose);
      await waitForUser(noLocContainer);

      final provider = feedListControllerProvider(FeedSectionType.nearby);
      await noLocContainer.read(provider.future);
      final state = noLocContainer.read(provider).value!;

      expect(state.items, isEmpty);
      expect(state.hasMore, isFalse);
    });

    test('loadMore appends the next distance-sorted slice', () async {
      final page1Cursor = await _createCursor('page-1');
      fakeFeedRepo.technicianPaginatedResponses = [
        PaginatedFeedResponse(
          items: List.generate(
            20,
            (i) => createTechnicianItem(
              'item-$i',
            ).copyWith(distanceKm: i.toDouble()),
          ),
          hasMore: true,
          lastDocument: page1Cursor,
        ),
        PaginatedFeedResponse(
          items: List.generate(
            5,
            (i) => createTechnicianItem(
              'item-${20 + i}',
            ).copyWith(distanceKm: (20 + i).toDouble()),
          ),
          hasMore: false,
          lastDocument: null,
        ),
      ];
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.technicians);
      final sub = container.listen(provider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
      await container.read(provider.future);

      var state = container.read(provider).value!;
      expect(state.items.length, 20);
      expect(state.hasMore, isTrue);
      expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
      expect(fakeFeedRepo.paginatedTypeCallHistory, isEmpty);
      final notifier = container.read(provider.notifier);
      expect(notifier.state.value?.hasMore, isTrue);

      await notifier.loadMore();

      state = container.read(provider).value!;
      expect(state.items.length, 25);
      expect(state.hasMore, isFalse);
      expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
      expect(fakeFeedRepo.paginatedTypeCallHistory, isEmpty);
      expect(fakeFeedRepo.techniciansPaginatedStartAfterHistory, [
        isNull,
        isNotNull,
      ]);
    });

    test('ignores concurrent loadMore while a page is pending', () async {
      final page1Cursor = await _createCursor('page-1');
      fakeFeedRepo.technicianPaginatedResponses = [
        PaginatedFeedResponse(
          items: List.generate(
            20,
            (i) => createTechnicianItem(
              'item-$i',
            ).copyWith(distanceKm: i.toDouble()),
          ),
          hasMore: true,
          lastDocument: page1Cursor,
        ),
        PaginatedFeedResponse(
          items: List.generate(
            5,
            (i) => createTechnicianItem(
              'item-${20 + i}',
            ).copyWith(distanceKm: (20 + i).toDouble()),
          ),
          hasMore: false,
          lastDocument: null,
        ),
      ];
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.technicians);
      final sub = container.listen(provider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      final firstLoadMore = notifier.loadMore();
      final secondLoadMore = notifier.loadMore();
      await Future.wait([firstLoadMore, secondLoadMore]);

      final state = container.read(provider).value!;
      expect(state.items.length, 25);
      expect(state.hasMore, isFalse);
      expect(fakeFeedRepo.discoverFeedPoolCallHistory, isEmpty);
      expect(fakeFeedRepo.paginatedTypeCallHistory, isEmpty);
    });

    test('does nothing when hasMore is false', () async {
      fakeFeedRepo.technicians = List.generate(
        5,
        (i) =>
            createTechnicianItem('item-$i').copyWith(distanceKm: i.toDouble()),
      );
      await waitForUser(container);

      final provider = feedListControllerProvider(FeedSectionType.technicians);
      final sub = container.listen(provider, (_, _) {}, fireImmediately: true);
      addTearDown(sub.close);
      await container.read(provider.future);
      final notifier = container.read(provider.notifier);

      var state = container.read(provider).value!;
      expect(state.hasMore, isFalse);

      await notifier.loadMore();

      state = container.read(provider).value!;
      expect(state.items.length, 5);
    });
  });
}

Future<DocumentSnapshot<Map<String, dynamic>>> _createCursor(String id) async {
  final firestore = FakeFirebaseFirestore();
  await firestore.collection('feed_test_pages').doc(id).set({'id': id});
  return firestore.collection('feed_test_pages').doc(id).get();
}
