import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mube/src/core/providers/connectivity_provider.dart';
import 'package:mube/src/core/services/offline_mutation_coordinator.dart';
import 'package:mube/src/core/services/offline_mutation_queue.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';
import 'package:mube/src/features/gigs/presentation/controllers/gig_actions_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_fakes.dart';

class MockGigRepository extends Mock implements GigRepository {}

class _NoopOfflineMutationCoordinator extends OfflineMutationCoordinator {
  _NoopOfflineMutationCoordinator(super.ref);

  @override
  void scheduleFlush({
    Duration delay = const Duration(seconds: 8),
    String reason = 'unspecified',
  }) {}
}

void main() {
  test(
    'applyToGig completes without using ref after controller disposal',
    () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});

      final repository = MockGigRepository();
      final authRepository = FakeAuthRepository()
        ..emitUser(FakeFirebaseUser(uid: 'user-1'));
      final completer = Completer<void>();

      when(
        () => repository.applyToGig('gig-1', 'Tenho experiencia em shows.'),
      ).thenAnswer((_) => completer.future);

      final container = ProviderContainer(
        overrides: [
          gigRepositoryProvider.overrideWith((ref) => repository),
          authRepositoryProvider.overrideWithValue(authRepository),
          isOnlineProvider.overrideWith((ref) => true),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);

      final future = container
          .read(gigActionsControllerProvider.notifier)
          .applyToGig('gig-1', 'Tenho experiencia em shows.');

      await Future<void>.delayed(Duration.zero);
      container.invalidate(gigActionsControllerProvider);
      completer.complete();

      await expectLater(future, completes);
      verify(
        () => repository.applyToGig('gig-1', 'Tenho experiencia em shows.'),
      ).called(1);
    },
  );

  test('applyToGig queues application while offline', () async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});

    final repository = MockGigRepository();
    final authRepository = FakeAuthRepository()
      ..emitUser(FakeFirebaseUser(uid: 'user-1'));

    final container = ProviderContainer(
      overrides: [
        gigRepositoryProvider.overrideWith((ref) => repository),
        authRepositoryProvider.overrideWithValue(authRepository),
        isOnlineProvider.overrideWith((ref) => false),
        offlineMutationCoordinatorProvider.overrideWith(
          _NoopOfflineMutationCoordinator.new,
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(authRepository.dispose);

    final outcome = await container
        .read(gigActionsControllerProvider.notifier)
        .applyToGig(
          'gig-1',
          'Tenho experiencia em shows.',
          gigTitle: 'Show na sexta',
        );

    expect(outcome, GigApplyOutcome.queued);
    verifyNever(
      () => repository.applyToGig('gig-1', 'Tenho experiencia em shows.'),
    );

    final queued = container.read(offlineMutationStoreProvider);
    expect(queued, hasLength(1));
    expect(queued.single.type, OfflineMutationType.gigApply);
    expect(queued.single.gigId, 'gig-1');
    expect(queued.single.gigTitle, 'Show na sexta');
  });
}
