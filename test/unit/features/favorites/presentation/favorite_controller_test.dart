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

/// Extended fake that allows errors and async control on add/remove.
class _TestFavoriteRepository extends FakeFavoriteRepository {
  bool throwOnAdd = false;
  bool throwOnRemove = false;
  Completer<void>? addCompleter;
  Completer<void>? removeCompleter;

  @override
  Future<void> addFavorite(String targetUserId) async {
    if (addCompleter != null) await addCompleter!.future;
    if (throwOnAdd) throw Exception('Add failed');
    return super.addFavorite(targetUserId);
  }

  @override
  Future<void> removeFavorite(String targetUserId) async {
    if (removeCompleter != null) await removeCompleter!.future;
    if (throwOnRemove) throw Exception('Remove failed');
    return super.removeFavorite(targetUserId);
  }
}

/// Stub FeedController used only to satisfy provider dependency.
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

  Future<void> pumpAsync() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  /// Waits for auth user profile to become available.
  Future<void> waitForUser() async {
    final completer = Completer<void>();
    final sub = container.listen(currentUserProfileProvider, (_, next) {
      if (next.hasValue && next.value != null && !completer.isCompleted) {
        completer.complete();
      }
    }, fireImmediately: true);

    await completer.future.timeout(const Duration(seconds: 1));
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

        expect(getState().localFavorites, contains('target-1'));

        await pumpAsync();

        expect(getState().serverFavorites, contains('target-1'));
      });

      test('removes item optimistically and syncs with server', () async {
        fakeFavRepo.favorites = {'target-1'};
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('target-1');

        expect(getState().localFavorites, isNot(contains('target-1')));

        await pumpAsync();

        expect(getState().serverFavorites, isNot(contains('target-1')));
      });

      test('rolls back on add failure', () async {
        fakeFavRepo.favorites = {};
        fakeFavRepo.throwOnAdd = true;
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('target-1');

        expect(getState().localFavorites, contains('target-1'));

        await pumpAsync();

        expect(getState().localFavorites, isNot(contains('target-1')));
        expect(getState().serverFavorites, isNot(contains('target-1')));
      });

      test('rolls back on remove failure', () async {
        fakeFavRepo.favorites = {'target-1'};
        fakeFavRepo.throwOnRemove = true;
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('target-1');

        expect(getState().localFavorites, isNot(contains('target-1')));

        await pumpAsync();

        expect(getState().localFavorites, contains('target-1'));
        expect(getState().serverFavorites, contains('target-1'));
      });

      test('coalesces rapid toggles and keeps latest intent', () async {
        fakeFavRepo.favorites = {};
        fakeFavRepo.addCompleter = Completer<void>();
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        // First tap (like) starts sync and blocks in addCompleter.
        ctrl.toggle('target-1');
        expect(getState().localFavorites, contains('target-1'));

        // Second tap (unlike) should become latest intent.
        ctrl.toggle('target-1');
        expect(getState().localFavorites, isNot(contains('target-1')));

        fakeFavRepo.addCompleter!.complete();
        await pumpAsync();

        expect(getState().localFavorites, isNot(contains('target-1')));
        expect(getState().serverFavorites, isNot(contains('target-1')));
        expect(fakeFavRepo.favorites, isNot(contains('target-1')));
      });

      test('ignores stale failed request when a newer intent exists', () async {
        fakeFavRepo.favorites = {};
        fakeFavRepo.addCompleter = Completer<void>();
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('target-1'); // desired: like (in flight)
        ctrl.toggle('target-1'); // desired: unlike (latest)

        // Make stale add fail after newer intent already exists.
        fakeFavRepo.throwOnAdd = true;
        fakeFavRepo.addCompleter!.complete();
        await pumpAsync();

        expect(getState().localFavorites, isNot(contains('target-1')));
        expect(getState().serverFavorites, isNot(contains('target-1')));
      });

      test('multiple toggles on different items work independently', () async {
        fakeFavRepo.favorites = {};
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.toggle('a');
        ctrl.toggle('b');

        expect(getState().localFavorites, containsAll(['a', 'b']));

        await pumpAsync();

        expect(getState().serverFavorites, containsAll(['a', 'b']));
      });

      test('keeps local like count when stale server count arrives', () async {
        fakeFavRepo.favorites = {};
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.ensureLikeCount('target-1', 0);
        expect(getState().likeCounts['target-1'], 0);

        ctrl.toggle('target-1');
        await pumpAsync();
        expect(getState().likeCounts['target-1'], 1);

        // Simulate stale backend read after navigation to another screen.
        ctrl.ensureLikeCount('target-1', 0);
        expect(getState().likeCounts['target-1'], 1);
      });

      test('rolls back like count on add failure', () async {
        fakeFavRepo.favorites = {};
        fakeFavRepo.throwOnAdd = true;
        await waitForUser();

        final ctrl = getController();
        await ctrl.loadFavorites();

        ctrl.ensureLikeCount('target-1', 0);
        ctrl.toggle('target-1');

        // Optimistic increment.
        expect(getState().likeCounts['target-1'], 1);

        await pumpAsync();

        // Rollback after failed server sync.
        expect(getState().likeCounts['target-1'], 0);
      });
    });
  });
}
