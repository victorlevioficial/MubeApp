import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/presentation/feed_state.dart';
import 'package:mube/src/features/feed/presentation/providers/feed_main_provider.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthRepository fakeAuthRepository;
  late FakeFeedRepository fakeFeedRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeFeedRepository = FakeFeedRepository();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('FeedMain', () {
    AppUser user0({String uid = 'user-1', Map<String, dynamic>? location}) =>
        TestData.user(uid: uid, location: location);

    Future<FeedState> fetchFirstPage({int batchSize = 20}) async {
      final user = user0();

      final notifier = container.read(feedMainProvider.notifier);
      return notifier.fetch(
        currentState: const FeedState(),
        user: user,
        blockedIds: const [],
        reset: true,
        forceInvalidatePool: true,
        batchSize: batchSize,
      );
    }

    test('initial state is empty FeedState', () {
      final state = container.read(feedMainProvider);
      expect(state, const FeedState());
    });

    test(
      'returns noMoreData when discover pool is empty after reset',
      () async {
        fakeFeedRepository.discoverFeedPool = const [];

        final notifier = container.read(feedMainProvider.notifier);
        final result = await notifier.fetch(
          currentState: const FeedState(),
          user: user0(),
          blockedIds: const [],
          reset: true,
          forceInvalidatePool: true,
          batchSize: 20,
        );

        expect(result.status, PaginationStatus.noMoreData);
        expect(result.items, isEmpty);
        expect(result.hasMore, false);
      },
    );

    test('returns first page of items sorted by distance', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-3',
          nome: 'Item 3',
          tipoPerfil: ProfileType.professional,
          distanceKm: 30,
        ),
        const FeedItem(
          uid: 'item-1',
          nome: 'Item 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 10,
        ),
        const FeedItem(
          uid: 'item-2',
          nome: 'Item 2',
          tipoPerfil: ProfileType.professional,
          distanceKm: 20,
        ),
      ];

      final result = await fetchFirstPage();

      expect(result.status, PaginationStatus.noMoreData);
      expect(result.items.map((e) => e.uid), ['item-1', 'item-2', 'item-3']);
      expect(result.hasMore, false);
    });

    test('paginates correctly with batchSize smaller than pool', () async {
      fakeFeedRepository.discoverFeedPool = List.generate(
        30,
        (i) => FeedItem(
          uid: 'item-$i',
          nome: 'Item $i',
          tipoPerfil: ProfileType.professional,
          distanceKm: (29 - i).toDouble(),
        ),
      );

      final notifier = container.read(feedMainProvider.notifier);
      final firstPage = await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: const [],
        reset: true,
        forceInvalidatePool: true,
        batchSize: 20,
      );

      expect(firstPage.items, hasLength(20));
      expect(firstPage.currentPage, 1);
      expect(firstPage.hasMore, true);

      final secondPage = await notifier.fetch(
        currentState: firstPage,
        user: user0(),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(secondPage.items, hasLength(30));
      expect(secondPage.currentPage, 2);
      expect(secondPage.hasMore, false);
    });

    test('filters items by currentFilter (Bandas)', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'artist-1',
          nome: 'Artist 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
        const FeedItem(
          uid: 'band-1',
          nome: 'Band 1',
          tipoPerfil: ProfileType.band,
          distanceKm: 3,
        ),
        const FeedItem(
          uid: 'band-2',
          nome: 'Band 2',
          tipoPerfil: ProfileType.band,
          distanceKm: 8,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);
      final state = await notifier.fetch(
        currentState: const FeedState(currentFilter: 'Bandas'),
        user: user0(),
        blockedIds: const [],
        reset: true,
        forceInvalidatePool: true,
        batchSize: 20,
      );

      expect(state.items.map((e) => e.uid), ['band-1', 'band-2']);
    });

    test('filters items by currentFilter (Estúdios)', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'artist-1',
          nome: 'Artist 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
        const FeedItem(
          uid: 'studio-1',
          nome: 'Studio 1',
          tipoPerfil: ProfileType.studio,
          distanceKm: 3,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);
      final state = await notifier.fetch(
        currentState: const FeedState(currentFilter: 'Estúdios'),
        user: user0(),
        blockedIds: const [],
        reset: true,
        forceInvalidatePool: true,
        batchSize: 20,
      );

      expect(state.items.map((e) => e.uid), ['studio-1']);
    });

    test('excludes blocked user ids from results', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'user-a',
          nome: 'User A',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
        const FeedItem(
          uid: 'user-b',
          nome: 'User B',
          tipoPerfil: ProfileType.professional,
          distanceKm: 3,
        ),
        const FeedItem(
          uid: 'user-c',
          nome: 'User C',
          tipoPerfil: ProfileType.professional,
          distanceKm: 8,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);
      final state = await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: ['user-a', 'user-c'],
        reset: true,
        forceInvalidatePool: true,
        batchSize: 20,
      );

      expect(state.items.map((e) => e.uid), ['user-b']);
    });

    test('returns error when repository fails', () async {
      fakeFeedRepository.throwError = true;

      final notifier = container.read(feedMainProvider.notifier);
      final result = await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: const [],
        reset: true,
        forceInvalidatePool: true,
        batchSize: 20,
      );

      expect(result.status, PaginationStatus.error);
    });

    test('invalidates pool when forceInvalidatePool is true', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-1',
          nome: 'Item 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: const [],
        reset: true,
        forceInvalidatePool: true,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(1));

      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-2',
          nome: 'Item 2',
          tipoPerfil: ProfileType.professional,
          distanceKm: 3,
        ),
      ];

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: const [],
        reset: true,
        forceInvalidatePool: true,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(2));
    });

    test('reuses cached pool when no invalidation is needed', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-1',
          nome: 'Item 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(1));

      final secondResult = await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(1));
      expect(secondResult.items.map((e) => e.uid), ['item-1']);
    });

    test('invalidates pool when user changes', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-1',
          nome: 'Item 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(uid: 'user-a'),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(1));

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(uid: 'user-b'),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(2));
    });

    test('invalidates pool when blocked ids change', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-1',
          nome: 'Item 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(1));

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(),
        blockedIds: ['blocked-user'],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(2));
    });

    test('invalidates pool when user location changes', () async {
      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-1',
          nome: 'Item 1',
          tipoPerfil: ProfileType.professional,
          distanceKm: 5,
        ),
      ];

      final notifier = container.read(feedMainProvider.notifier);

      await notifier.fetch(
        currentState: const FeedState(),
        user: user0(location: const {'lat': -23.5505, 'lng': -46.6333}),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      fakeFeedRepository.discoverFeedPool = [
        const FeedItem(
          uid: 'item-2',
          nome: 'Item 2',
          tipoPerfil: ProfileType.professional,
          distanceKm: 3,
        ),
      ];

      final secondResult = await notifier.fetch(
        currentState: const FeedState(),
        user: user0(location: const {'lat': -22.9068, 'lng': -43.1729}),
        blockedIds: const [],
        reset: false,
        forceInvalidatePool: false,
        batchSize: 20,
      );

      expect(fakeFeedRepository.discoverFeedPoolCallHistory, hasLength(2));
      expect(secondResult.items.map((e) => e.uid), ['item-2']);
    });
  });
}
