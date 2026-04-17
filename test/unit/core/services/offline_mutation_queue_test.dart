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
}
