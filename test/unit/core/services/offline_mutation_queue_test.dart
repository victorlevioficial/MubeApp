import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/offline_mutation_queue.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository authRepository;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    authRepository = FakeAuthRepository(
      initialUser: FakeFirebaseUser(uid: 'user-1'),
    );

    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
  });

  tearDown(() {
    container.dispose();
    authRepository.dispose();
  });

  test(
    'coalesces favorite mutations by scope with latest intent winning',
    () async {
      final store = container.read(offlineMutationStoreProvider.notifier);
      await store.ensureUserLoaded('user-1');

      await store.upsertFavoriteDesiredState(
        targetId: 'target-1',
        isFavorite: true,
      );
      await store.upsertFavoriteDesiredState(
        targetId: 'target-1',
        isFavorite: false,
      );

      final entries = container.read(offlineMutationStoreProvider);
      expect(entries, hasLength(1));
      expect(entries.single.type, OfflineMutationType.favoriteRemove);
      expect(entries.single.favoriteTargetId, 'target-1');
      expect(store.favoriteDesiredStatusByTarget(), {'target-1': false});

      final persisted = await OfflineMutationQueue(
        SharedPreferences.getInstance,
      ).load('user-1');
      expect(persisted, hasLength(1));
      expect(persisted.single.type, OfflineMutationType.favoriteRemove);
    },
  );

  test(
    'stores queued gig apply with stable scope and retry metadata',
    () async {
      final store = container.read(offlineMutationStoreProvider.notifier);
      await store.ensureUserLoaded('user-1');

      await store.upsertGigApply(
        gigId: 'gig-1',
        message: 'Tenho experiencia em shows.',
        gigTitle: 'Show na sexta',
      );
      await store.markRetry(gigApplyMutationScopeKey('gig-1'));

      final entry = store.pendingGigApplyFor('gig-1');
      expect(entry, isNotNull);
      expect(entry!.type, OfflineMutationType.gigApply);
      expect(entry.gigId, 'gig-1');
      expect(entry.gigMessage, 'Tenho experiencia em shows.');
      expect(entry.gigTitle, 'Show na sexta');
      expect(entry.retryCount, 1);

      await store.removeScopeKey(gigApplyMutationScopeKey('gig-1'));
      expect(container.read(offlineMutationStoreProvider), isEmpty);
    },
  );

  test('ignores stale load results when auth user changes quickly', () async {
    final delayedQueue = _DelayedOfflineMutationQueue();
    final localAuthRepository = FakeAuthRepository();
    final localContainer = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(localAuthRepository),
        authStateChangesProvider.overrideWithValue(const AsyncValue.data(null)),
        offlineMutationQueueProvider.overrideWithValue(delayedQueue),
      ],
    );

    addTearDown(() {
      localContainer.dispose();
      localAuthRepository.dispose();
    });

    final store = localContainer.read(offlineMutationStoreProvider.notifier);

    final firstLoad = store.loadForUser('user-1');
    final secondLoad = store.loadForUser('user-2');

    delayedQueue.complete('user-2', [_favoriteMutation('target-2')]);
    await secondLoad;

    expect(store.currentUserId, 'user-2');
    expect(
      localContainer.read(offlineMutationStoreProvider).single.favoriteTargetId,
      'target-2',
    );

    delayedQueue.complete('user-1', [_favoriteMutation('target-1')]);
    await firstLoad;

    expect(store.currentUserId, 'user-2');
    expect(
      localContainer.read(offlineMutationStoreProvider).single.favoriteTargetId,
      'target-2',
    );
  });
}

OfflineMutation _favoriteMutation(String targetId) {
  final scopeKey = favoriteMutationScopeKey(targetId);
  return OfflineMutation(
    id: scopeKey,
    type: OfflineMutationType.favoriteAdd,
    scopeKey: scopeKey,
    payload: {'target_id': targetId},
    createdAtMs: 1,
    updatedAtMs: 1,
  );
}

class _DelayedOfflineMutationQueue extends OfflineMutationQueue {
  _DelayedOfflineMutationQueue() : super(SharedPreferences.getInstance);

  final _loads = <String, Completer<List<OfflineMutation>>>{};

  @override
  Future<List<OfflineMutation>> load(String userId) {
    final completer = Completer<List<OfflineMutation>>();
    _loads[userId] = completer;
    return completer.future;
  }

  void complete(String userId, List<OfflineMutation> entries) {
    final completer = _loads.remove(userId);
    if (completer == null) {
      throw StateError('No pending load for $userId');
    }
    completer.complete(entries);
  }

  @override
  Future<void> save(String userId, List<OfflineMutation> entries) async {}
}
