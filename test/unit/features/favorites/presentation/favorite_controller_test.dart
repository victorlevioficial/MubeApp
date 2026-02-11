import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/favorites/domain/favorite_controller.dart';
import 'package:mube/src/features/favorites/domain/favorite_state.dart';
import 'package:mube/src/features/feed/presentation/feed_controller.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

/// Extended fake that allows errors on add/remove for rollback testing.
class _TestFavoriteRepository extends FakeFavoriteRepository {
  bool throwOnAdd = false;
  bool throwOnRemove = false;

  @override
  Future<void> addFavorite(String targetUserId) async {
    if (throwOnAdd) throw Exception('Add failed');
    return super.addFavorite(targetUserId);
  }

  @override
  Future<void> removeFavorite(String targetUserId) async {
    if (throwOnRemove) throw Exception('Remove failed');
    return super.removeFavorite(targetUserId);
  }
}

/// Stub FeedController that does nothing — we just need the provider to exist.
class _StubFeedController extends FeedController {
  @override
  FutureOr<FeedState> build() => const FeedState();

  @override
  void updateLikeCount(String targetId, {required bool isLiked}) {
    // No-op in tests.
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late _TestFavoriteRepository fakeFavRepo;
  late ProviderContainer container;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeFavRepo = _TestFavoriteRepository();

    final firebaseUser = FakeFirebaseUser(uid: 'u1', email: 'a@b.com');
    fakeAuthRepo.emitUser(firebaseUser);
    fakeAuthRepo.appUser = TestData.user(uid: 'u1');

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        favoriteRepositoryProvider.overrideWithValue(fakeFavRepo),
        feedControllerProvider.overrideWith(_StubFeedController.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  FavoriteController getController() =>
      container.read(favoriteControllerProvider.notifier);

  FavoriteState getState() => container.read(favoriteControllerProvider);

  /// Waits for the auth user profile to become available.
  Future<void> waitForUser() async {
    final c = Completer<void>();
    final sub = container.listen(currentUserProfileProvider, (_, next) {
      if (next.hasValue && next.value != null && !c.isCompleted) {
        c.complete();
      }
    }, fireImmediately: true);
    await c.future.timeout(const Duration(seconds: 1));
    sub.close();
  }

  group('FavoriteController', () {
    test('initial state has empty sets', () {
      final state = getState();
      expect(state.localFavorites, isEmpty);
      expect(state.serverFavorites, isEmpty);
      expect(state.isSyncing, isFalse);
    });

    group('loadFavorites', () {
      test('loads favorites from repository', () async {
        fakeFavRepo.favorites = {'id-1', 'id-2'};
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        final state = getState();
        expect(state.localFavorites, {'id-1', 'id-2'});
        expect(state.serverFavorites, {'id-1', 'id-2'});
        expect(state.isSyncing, isFalse);
      });

      test('handles load error gracefully', () async {
        fakeFavRepo.throwError = true;
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        final state = getState();
        expect(state.localFavorites, isEmpty);
        expect(state.isSyncing, isFalse);
      });

      test('returns early when user is null', () async {
        fakeAuthRepo.emitUser(null);
        fakeAuthRepo.appUser = null;

        final loggedOutContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
            favoriteRepositoryProvider.overrideWithValue(fakeFavRepo),
            feedControllerProvider.overrideWith(_StubFeedController.new),
          ],
        );
        addTearDown(loggedOutContainer.dispose);

        final ctrl = loggedOutContainer.read(
          favoriteControllerProvider.notifier,
        );
        await ctrl.loadFavorites();

        final state = loggedOutContainer.read(favoriteControllerProvider);
        expect(state.localFavorites, isEmpty);
      });
    });

    group('isLiked', () {
      test('returns true when item is in localFavorites', () async {
        fakeFavRepo.favorites = {'id-1'};
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        expect(ctrl.isLiked('id-1'), isTrue);
        expect(ctrl.isLiked('id-999'), isFalse);
      });
    });

    group('toggle (optimistic UI)', () {
      test('adds item optimistically and syncs with server', () async {
        fakeFavRepo.favorites = {};
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('target-1');

        // Optimistic: immediately in localFavorites.
        expect(getState().localFavorites, contains('target-1'));

        // Wait for async sync to complete.
        await Future<void>.delayed(Duration.zero);

        // After sync, serverFavorites should also contain it.
        expect(getState().serverFavorites, contains('target-1'));
      });

      test('removes item optimistically and syncs with server', () async {
        fakeFavRepo.favorites = {'target-1'};
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('target-1');

        // Optimistic: immediately removed from localFavorites.
        expect(getState().localFavorites, isNot(contains('target-1')));

        await Future<void>.delayed(Duration.zero);

        expect(getState().serverFavorites, isNot(contains('target-1')));
      });

      test('rolls back on add failure', () async {
        fakeFavRepo.favorites = {};
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        fakeFavRepo.throwOnAdd = true;
        ctrl.toggle('target-1');

        // Optimistic: added to local.
        expect(getState().localFavorites, contains('target-1'));

        // Wait for async error handling.
        await Future<void>.delayed(Duration.zero);

        // Rollback: removed because server never had it.
        expect(getState().localFavorites, isNot(contains('target-1')));
        expect(getState().serverFavorites, isNot(contains('target-1')));
      });

      test('rolls back on remove failure', () async {
        fakeFavRepo.favorites = {'target-1'};
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        fakeFavRepo.throwOnRemove = true;
        ctrl.toggle('target-1');

        // Optimistic: removed from local.
        expect(getState().localFavorites, isNot(contains('target-1')));

        await Future<void>.delayed(Duration.zero);

        // Rollback: restored because server still has it.
        expect(getState().localFavorites, contains('target-1'));
        expect(getState().serverFavorites, contains('target-1'));
      });

      test('multiple toggles on different items work independently', () async {
        fakeFavRepo.favorites = {};
        await waitForUser();
        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('a');
        ctrl.toggle('b');

        expect(getState().localFavorites, containsAll(['a', 'b']));

        await Future<void>.delayed(Duration.zero);

        expect(getState().serverFavorites, containsAll(['a', 'b']));
      });
    });
  });
}
