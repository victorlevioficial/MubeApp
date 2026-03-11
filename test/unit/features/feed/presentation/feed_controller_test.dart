import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/feed_section.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';

import '../../../../helpers/firebase_mocks.dart';
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
      'loadAllData builds sections and first page from paginated sources',
      () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.appUser = user;
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        await waitForUser(container);

        fakeFeedRepository.mainFeedResponse = const PaginatedFeedResponse(
          items: [
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
              subCategories: ['stage_tech'],
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
          ],
          hasMore: false,
          lastDocument: null,
        );
        fakeFeedRepository.technicians = const [
          FeedItem(
            uid: 'tech-1',
            nome: 'Tech 1',
            nomeArtistico: 'Tech 1',
            tipoPerfil: ProfileType.professional,
            subCategories: ['stage_tech'],
            distanceKm: 3.0,
          ),
        ];
        fakeFeedRepository.bands = const [
          FeedItem(
            uid: 'band-1',
            nome: 'Band 1',
            tipoPerfil: ProfileType.band,
            distanceKm: 4.0,
          ),
        ];
        fakeFeedRepository.studios = const [
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

    test('onFilterChanged fetches the selected paginated source', () async {
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      fakeFeedRepository.mainFeedResponse = const PaginatedFeedResponse(
        items: [
          FeedItem(
            uid: 'artist-1',
            nome: 'Artist 1',
            tipoPerfil: ProfileType.professional,
          ),
          FeedItem(uid: 'band-0', nome: 'Band 0', tipoPerfil: ProfileType.band),
        ],
        hasMore: false,
        lastDocument: null,
      );
      fakeFeedRepository.enqueueTypePaginatedResponses(ProfileType.band, const [
        PaginatedFeedResponse(
          items: [
            FeedItem(
              uid: 'band-1',
              nome: 'Band 1',
              tipoPerfil: ProfileType.band,
            ),
            FeedItem(
              uid: 'band-2',
              nome: 'Band 2',
              tipoPerfil: ProfileType.band,
            ),
          ],
          hasMore: false,
          lastDocument: null,
        ),
      ]);
      fakeFeedRepository.bands = const [
        FeedItem(uid: 'band-1', nome: 'Band 1', tipoPerfil: ProfileType.band),
        FeedItem(uid: 'band-2', nome: 'Band 2', tipoPerfil: ProfileType.band),
      ];

      final controller = container.read(feedControllerProvider.notifier);
      await controller.loadAllData();
      await controller.onFilterChanged('Bandas');

      final state = container.read(feedControllerProvider).value!;
      expect(state.currentFilter, 'Bandas');
      expect(state.items.map((item) => item.uid), ['band-1', 'band-2']);
    });

    test('loadMoreMainFeed paginates from repository pages', () async {
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      final firstPageDoc = MockDocumentSnapshot<Map<String, dynamic>>(
        id: 'page-1',
        data: const {'id': 'page-1'},
      );
      final secondPageDoc = MockDocumentSnapshot<Map<String, dynamic>>(
        id: 'page-2',
        data: const {'id': 'page-2'},
      );
      fakeFeedRepository.enqueueMainFeedResponses([
        PaginatedFeedResponse(
          items: List.generate(
            20,
            (index) => FeedItem(
              uid: 'item-$index',
              nome: 'Item $index',
              tipoPerfil: ProfileType.professional,
              distanceKm: index.toDouble(),
            ),
          ),
          hasMore: true,
          lastDocument: firstPageDoc,
        ),
        PaginatedFeedResponse(
          items: List.generate(
            5,
            (index) => FeedItem(
              uid: 'item-${index + 20}',
              nome: 'Item ${index + 20}',
              tipoPerfil: ProfileType.professional,
              distanceKm: (index + 20).toDouble(),
            ),
          ),
          hasMore: false,
          lastDocument: secondPageDoc,
        ),
      ]);

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

      fakeFeedRepository.mainFeedResponse = const PaginatedFeedResponse(
        items: [
          FeedItem(
            uid: 'tech-1',
            nome: 'Tech 1',
            tipoPerfil: ProfileType.professional,
            subCategories: ['stage_tech'],
            likeCount: 0,
          ),
        ],
        hasMore: false,
        lastDocument: null,
      );
      fakeFeedRepository.technicians = const [
        FeedItem(
          uid: 'tech-1',
          nome: 'Tech 1',
          tipoPerfil: ProfileType.professional,
          subCategories: ['stage_tech'],
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

    test('maps thrown exceptions in loadAllData to friendly message', () async {
      final failureRepository = _ThrowingMainFeedRepository();
      final localContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          feedRepositoryProvider.overrideWithValue(failureRepository),
          favoriteRepositoryProvider.overrideWithValue(fakeFavoriteRepository),
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
      expect(
        state.errorMessage,
        'Erro no servidor. Tente novamente mais tarde.',
      );
    });

    test(
      'loadAllData surfaces paginated feed failure on initial reset',
      () async {
        final failureRepository = _MainFeedFailureFeedRepository();
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
        expect(state.errorMessage, contains('Main feed failed'));
      },
    );
  });
}

class _MainFeedFailureFeedRepository extends FakeFeedRepository {
  @override
  FutureResult<PaginatedFeedResponse> getMainFeedPaginated({
    required String currentUserId,
    String? filterType,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    return Either.left(const ServerFailure(message: 'Main feed failed'));
  }
}

class _ThrowingMainFeedRepository extends FakeFeedRepository {
  @override
  FutureResult<PaginatedFeedResponse> getMainFeedPaginated({
    required String currentUserId,
    String? filterType,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
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
