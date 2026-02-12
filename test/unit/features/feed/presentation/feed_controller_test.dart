import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/feed_section.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

      // Assert
      final state = container.read(feedControllerProvider).value!;
      expect(state.isInitialLoading, false);
      expect(state.sectionItems[FeedSectionType.technicians], hasLength(1));
      expect(state.sectionItems[FeedSectionType.bands], hasLength(1));
      expect(state.sectionItems[FeedSectionType.studios], hasLength(1));
    });

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
      controller.onFilterChanged('Bandas');

      // Assert
      final state = container.read(feedControllerProvider).value!;
      expect(state.currentFilter, 'Bandas');
    });

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

      // Act
      controller.updateLikeCount('item-1', isLiked: true);

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

      // Assert
      final state = container.read(feedControllerProvider);
      expect(state, isA<AsyncError>());
    });
  });
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
