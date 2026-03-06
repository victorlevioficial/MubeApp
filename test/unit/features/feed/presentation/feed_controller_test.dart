import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_discovery.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/feed_section.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late ProviderContainer container;
  late FakeAuthRepository fakeAuthRepository;
  late FakeFeedRepository fakeFeedRepository;
  late FakeFavoriteRepository fakeFavoriteRepository;
  late FakeFeedImagePrecacheService fakePrecacheService;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeFeedRepository = FakeFeedRepository();
    fakeFavoriteRepository = FakeFavoriteRepository();
    fakePrecacheService = FakeFeedImagePrecacheService();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        feedRepositoryProvider.overrideWithValue(fakeFeedRepository),
        favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
        feedImagePrecacheServiceProvider.overrideWithValue(fakePrecacheService),
        currentUserProfileProvider.overrideWith(
          (ref) => fakeAuthRepository.watchUser(''),
        ),
        blockedUsersProvider.overrideWith((ref) => Stream.value([])),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('FeedController', () {
    test('initial state is correct', () {
      expect(container.read(feedControllerProvider).value, const FeedState());
    });

    test(
      'loadAllData builds sections and first page from a single pool',
      () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.appUser = user;
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        await waitForUser(container);

        fakeFeedRepository.discoverFeedPool = const [
          FeedItem(
            uid: 'artist-1',
            nome: 'Artist 1',
            nomeArtistico: 'Artist 1',
            tipoPerfil: ProfileType.professional,
            subCategories: ['singer'],
            distanceKm: 2.0,
          ),
          FeedItem(
            uid: 'tech-1',
            nome: 'Tech 1',
            nomeArtistico: 'Tech 1',
            tipoPerfil: ProfileType.professional,
            subCategories: ['crew'],
            distanceKm: 3.0,
          ),
          FeedItem(
            uid: 'band-1',
            nome: 'Band 1',
            tipoPerfil: ProfileType.band,
            distanceKm: 4.0,
          ),
          FeedItem(
            uid: 'studio-1',
            nome: 'Studio 1',
            tipoPerfil: ProfileType.studio,
            distanceKm: 5.0,
          ),
        ];

        final controller = container.read(feedControllerProvider.notifier);
        await controller.loadAllData();

        final state = container.read(feedControllerProvider).value!;
        expect(state.isInitialLoading, false);
        expect(state.items.map((item) => item.uid), [
          'artist-1',
          'tech-1',
          'band-1',
          'studio-1',
        ]);
        expect(
          state.sectionItems[FeedSectionType.technicians]?.map(
            (item) => item.uid,
          ),
          ['tech-1'],
        );
        expect(
          state.sectionItems[FeedSectionType.bands]?.map((item) => item.uid),
          ['band-1'],
        );
        expect(
          state.sectionItems[FeedSectionType.studios]?.map((item) => item.uid),
          ['studio-1'],
        );
      },
    );

    test(
      'onFilterChanged reapplies local filter without losing ordering',
      () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.appUser = user;
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        await waitForUser(container);

        fakeFeedRepository.discoverFeedPool = const [
          FeedItem(uid: 'band-1', nome: 'Band 1', tipoPerfil: ProfileType.band),
          FeedItem(
            uid: 'artist-1',
            nome: 'Artist 1',
            tipoPerfil: ProfileType.professional,
          ),
          FeedItem(uid: 'band-2', nome: 'Band 2', tipoPerfil: ProfileType.band),
        ];

        final controller = container.read(feedControllerProvider.notifier);
        await controller.loadAllData();
        await controller.onFilterChanged('Bandas');

        final state = container.read(feedControllerProvider).value!;
        expect(state.currentFilter, 'Bandas');
        expect(state.items.map((item) => item.uid), ['band-1', 'band-2']);
      },
    );

    test('loadMoreMainFeed paginates locally from the sorted pool', () async {
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      fakeFeedRepository.discoverFeedPool = List.generate(
        25,
        (index) => FeedItem(
          uid: 'item-$index',
          nome: 'Item $index',
          tipoPerfil: ProfileType.professional,
          distanceKm: index.toDouble(),
        ),
      );

      final controller = container.read(feedControllerProvider.notifier);
      await controller.loadAllData();
      await controller.loadMoreMainFeed();

      final state = container.read(feedControllerProvider).value!;
      expect(state.items, hasLength(25));
      expect(state.items.first.uid, 'item-0');
      expect(state.items.last.uid, 'item-24');
      expect(state.hasMore, false);
    });

    test('updateLikeCount updates state locally', () async {
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      fakeFeedRepository.discoverFeedPool = const [
        FeedItem(
          uid: 'tech-1',
          nome: 'Tech 1',
          tipoPerfil: ProfileType.professional,
          subCategories: ['crew'],
          likeCount: 0,
        ),
      ];

      final controller = container.read(feedControllerProvider.notifier);
      await controller.loadAllData();

      controller.updateLikeCount('tech-1', isLiked: true);

      final state = container.read(feedControllerProvider).value!;
      final updatedItem =
          state.sectionItems[FeedSectionType.technicians]?.first;
      expect(updatedItem?.likeCount, 1);
    });

    test('handles error in loadAllData', () async {
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      fakeFeedRepository.throwError = true;

      final controller = container.read(feedControllerProvider.notifier);
      await controller.loadAllData();

      final state = container.read(feedControllerProvider);
      expect(state.value?.status, PaginationStatus.error);
    });

    test(
      'loadAllData surfaces discovery pool failure on initial reset',
      () async {
        final failureRepository = _DiscoverPoolFailureFeedRepository();
        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            feedRepositoryProvider.overrideWithValue(failureRepository),
            favoriteRepositoryProvider.overrideWithValue(
              fakeFavoriteRepository,
            ),
            feedImagePrecacheServiceProvider.overrideWithValue(
              fakePrecacheService,
            ),
            currentUserProfileProvider.overrideWith(
              (ref) => fakeAuthRepository.watchUser(''),
            ),
            blockedUsersProvider.overrideWith((ref) => Stream.value([])),
          ],
        );
        addTearDown(localContainer.dispose);

        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.appUser = user;
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        await waitForUser(localContainer);

        final controller = localContainer.read(feedControllerProvider.notifier);
        await controller.loadAllData();

        final state = localContainer.read(feedControllerProvider).value!;
        expect(state.status, PaginationStatus.error);
        expect(state.errorMessage, contains('Pool failed'));
      },
    );
  });
}

class _DiscoverPoolFailureFeedRepository extends FakeFeedRepository {
  @override
  FutureResult<List<FeedItem>> getDiscoverFeedPoolSorted({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    List<String> excludedIds = const [],
    FeedDiscoveryFilter filter = FeedDiscoveryFilter.all,
  }) async {
    return Either.left(const ServerFailure(message: 'Pool failed'));
  }
}

Future<void> waitForUser(ProviderContainer container) async {
  final completer = Completer<void>();
  final sub = container.listen(currentUserProfileProvider, (previous, next) {
    if (next.hasValue && next.value != null) {
      if (!completer.isCompleted) completer.complete();
    }
  }, fireImmediately: true);
  await completer.future.timeout(const Duration(seconds: 1));
  sub.close();
}
