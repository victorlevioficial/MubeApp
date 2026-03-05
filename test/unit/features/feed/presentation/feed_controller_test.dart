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

    test('loadAllData fetches sections and main feed', () async {
      // Setup
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );

      // Wait for user to be emitted
      await waitForUser(container);

      const feedItem = FeedItem(
        uid: 'item-1',
        nome: 'Artist 1',
        nomeArtistico: 'The Artist',
        foto: 'http://url.com',
        tipoPerfil: 'profissional',
        generosMusicais: ['Rock'],
        skills: ['Guitar'],
      );

      fakeFeedRepository.nearbyUsers = [feedItem];
      fakeFeedRepository.technicians = [feedItem];
      fakeFeedRepository.bands = [feedItem];
      fakeFeedRepository.studios = [feedItem];

      // Act
      final controller = container.read(feedControllerProvider.notifier);
      await controller.loadAllData();
      await Future.delayed(const Duration(milliseconds: 1000));

      // Assert
      final state = container.read(feedControllerProvider).value!;
      expect(state.isInitialLoading, false);
      expect(state.sectionItems[FeedSectionType.technicians], hasLength(1));
      expect(state.sectionItems[FeedSectionType.bands], hasLength(1));
      expect(state.sectionItems[FeedSectionType.studios], hasLength(1));
    });

    test(
      'loadAllData does not wait for sections before ending skeleton',
      () async {
        final slowFeedRepository = _SlowSectionsFeedRepository();
        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            feedRepositoryProvider.overrideWithValue(slowFeedRepository),
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

        const feedItem = FeedItem(
          uid: 'item-1',
          nome: 'Artist 1',
          nomeArtistico: 'The Artist',
          foto: 'http://url.com',
          tipoPerfil: 'profissional',
          generosMusicais: ['Rock'],
          skills: ['Guitar'],
        );

        slowFeedRepository.nearbyUsers = [feedItem];
        slowFeedRepository.technicians = [feedItem];
        slowFeedRepository.bands = [feedItem];
        slowFeedRepository.studios = [feedItem];

        final controller = localContainer.read(feedControllerProvider.notifier);
        await controller.loadAllData().timeout(
          const Duration(milliseconds: 700),
        );

        final stateAfterMain = localContainer
            .read(feedControllerProvider)
            .value!;
        expect(stateAfterMain.isInitialLoading, false);
        expect(stateAfterMain.items, hasLength(1));
        expect(stateAfterMain.sectionItems, isEmpty);

        slowFeedRepository.sectionsCompleter.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final finalState = localContainer.read(feedControllerProvider).value!;
        expect(
          finalState.sectionItems[FeedSectionType.technicians],
          hasLength(1),
        );
        expect(finalState.sectionItems[FeedSectionType.bands], hasLength(1));
        expect(finalState.sectionItems[FeedSectionType.studios], hasLength(1));
      },
    );

    test('onFilterChanged updates filter and reloads feed', () async {
      // Setup
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      final controller = container.read(feedControllerProvider.notifier);

      // Act
      await controller.onFilterChanged('Bandas');

      // Assert
      final state = container.read(feedControllerProvider).value!;
      expect(state.currentFilter, 'Bandas');
    });

    test(
      'onFilterChanged backfills bandas with cursor when geohash returns partial batch',
      () async {
        final user = TestData.user(uid: 'user-1');
        fakeAuthRepository.appUser = user;
        fakeAuthRepository.emitUser(
          FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        );
        await waitForUser(container);

        const nearbyBand = FeedItem(
          uid: 'band-nearby',
          nome: 'Nearby Band',
          tipoPerfil: ProfileType.band,
        );
        const cursorBand1 = FeedItem(
          uid: 'band-cursor-1',
          nome: 'Cursor Band 1',
          tipoPerfil: ProfileType.band,
        );
        const cursorBand2 = FeedItem(
          uid: 'band-cursor-2',
          nome: 'Cursor Band 2',
          tipoPerfil: ProfileType.band,
        );

        fakeFeedRepository.nearbyUsers = [nearbyBand];
        fakeFeedRepository.mainFeedResponse = const PaginatedFeedResponse(
          items: [cursorBand1, cursorBand2],
          hasMore: false,
          lastDocument: null,
        );

        final controller = container.read(feedControllerProvider.notifier);
        await controller.loadAllData();
        await controller.onFilterChanged('Bandas');

        final state = container.read(feedControllerProvider).value!;
        expect(state.currentFilter, 'Bandas');
        expect(state.items.map((item) => item.uid), {
          'band-nearby',
          'band-cursor-1',
          'band-cursor-2',
        });
      },
    );

    test('updateLikeCount updates state locally', () async {
      // Setup
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      const feedItem = FeedItem(
        uid: 'item-1',
        nome: 'Artist 1',
        foto: 'http://url.com',
        tipoPerfil: 'profissional',
        generosMusicais: ['Rock'],
        skills: ['Guitar'],
        likeCount: 0,
      );
      fakeFeedRepository.technicians = [feedItem];

      final controller = container.read(feedControllerProvider.notifier);
      await controller.loadAllData();
      await Future.delayed(const Duration(milliseconds: 600));

      // Act
      controller.updateLikeCount('item-1', isLiked: true);
      await Future.delayed(const Duration(milliseconds: 600));

      // Assert
      final state = container.read(feedControllerProvider).value!;
      final updatedItem =
          state.sectionItems[FeedSectionType.technicians]?.first;
      expect(updatedItem?.likeCount, 1);
    });

    test('handles error in loadAllData', () async {
      // Setup
      final user = TestData.user(uid: 'user-1');
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(container);

      fakeFeedRepository.throwError = true;

      // Act
      final controller = container.read(feedControllerProvider.notifier);
      await controller.loadAllData();
      await Future.delayed(const Duration(milliseconds: 1000));

      // Assert
      final state = container.read(feedControllerProvider);
      expect(state.value?.status, PaginationStatus.error);
    });

    test('loadAllData surfaces cursor failure on initial reset', () async {
      final cursorFailureRepository = _CursorFailureFeedRepository();
      final localContainer = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          feedRepositoryProvider.overrideWithValue(cursorFailureRepository),
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

      final user = TestData.user(uid: 'user-1').copyWith(location: null);
      fakeAuthRepository.appUser = user;
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );
      await waitForUser(localContainer);

      final controller = localContainer.read(feedControllerProvider.notifier);
      await controller.loadAllData();

      final state = localContainer.read(feedControllerProvider).value!;
      expect(state.status, PaginationStatus.error);
      expect(state.errorMessage, contains('Cursor failed'));
    });
  });
}

class _SlowSectionsFeedRepository extends FakeFeedRepository {
  final Completer<void> sectionsCompleter = Completer<void>();

  Future<void> _waitForSections() async {
    await sectionsCompleter.future;
  }

  @override
  FutureResult<List<FeedItem>> getTechnicians({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    await _waitForSections();
    return super.getTechnicians(
      currentUserId: currentUserId,
      excludedIds: excludedIds,
      userLat: userLat,
      userLong: userLong,
      limit: limit,
    );
  }

  @override
  FutureResult<List<FeedItem>> getAllUsersSortedByDistance({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    List<String> excludedIds = const [],
    int? limit,
    String? userGeohash,
    double? radiusKm,
  }) async {
    await _waitForSections();
    return super.getAllUsersSortedByDistance(
      currentUserId: currentUserId,
      userLat: userLat,
      userLong: userLong,
      filterType: filterType,
      category: category,
      excludeCategory: excludeCategory,
      excludedIds: excludedIds,
      limit: limit,
      userGeohash: userGeohash,
      radiusKm: radiusKm,
    );
  }
}

class _CursorFailureFeedRepository extends FakeFeedRepository {
  @override
  FutureResult<PaginatedFeedResponse> getMainFeedPaginated({
    required String currentUserId,
    String? filterType,
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    return const Left(ServerFailure(message: 'Cursor failed'));
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
