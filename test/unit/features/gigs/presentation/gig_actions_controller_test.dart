import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';
import 'package:mube/src/features/gigs/presentation/controllers/gig_actions_controller.dart';

import '../../../../helpers/test_fakes.dart';

class MockGigRepository extends Mock implements GigRepository {}

void main() {
  test(
    'applyToGig completes without using ref after controller disposal',
    () async {
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
}
