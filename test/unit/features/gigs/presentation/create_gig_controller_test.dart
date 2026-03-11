import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_draft.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/presentation/controllers/create_gig_controller.dart';

import '../../../../helpers/test_fakes.dart';

class _MockGigRepository extends Mock implements GigRepository {}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late _MockGigRepository repository;
  ProviderContainer? container;

  final unauthenticatedPlatformError = PlatformException(
    code: 'firebase_firestore',
    message:
        'com.google.firebase.firestore.FirebaseFirestoreException: '
        'UNAUTHENTICATED (code: unauthenticated, message: '
        'The request does not have valid authentication credentials '
        'for the operation.)',
  );

  const draft = GigDraft(
    title: 'Procuro baterista para show autoral',
    description: 'Show de teste com repertorio fechado e passagem de som.',
    gigType: GigType.liveShow,
    dateMode: GigDateMode.unspecified,
    locationType: GigLocationType.onsite,
    slotsTotal: 1,
    compensationType: CompensationType.toBeDefined,
  );

  setUp(() {
    fakeAuthRepository = FakeAuthRepository()
      ..emitUser(FakeFirebaseUser(uid: 'user-1'));
    repository = _MockGigRepository();
  });

  tearDown(() {
    container?.dispose();
    fakeAuthRepository.dispose();
  });

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        gigRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
  }

  test(
    'retries create once after Firestore unauthenticated platform exception',
    () async {
      var attempts = 0;
      when(() => repository.createGig(draft)).thenAnswer((_) async {
        attempts += 1;
        if (attempts == 1) {
          throw unauthenticatedPlatformError;
        }
        return 'gig-1';
      });

      container = buildContainer();

      final gigId = await container!
          .read(createGigControllerProvider.notifier)
          .submitDraft(draft);

      expect(gigId, 'gig-1');
      expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
      expect(fakeAuthRepository.signOutCalls, 0);
      verify(() => repository.createGig(draft)).called(2);
      expect(container!.read(createGigControllerProvider).hasError, isFalse);
    },
  );

  test('signs out when session refresh fails after create failure', () async {
    fakeAuthRepository.refreshSecurityContextResult = const Left(
      AuthFailure(
        message: 'Sua sessão expirou. Faça login novamente.',
        debugMessage: 'user-token-expired',
      ),
    );
    when(
      () => repository.createGig(draft),
    ).thenThrow(unauthenticatedPlatformError);

    container = buildContainer();

    await expectLater(
      container!.read(createGigControllerProvider.notifier).submitDraft(draft),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.message,
          'message',
          'Sua sessão expirou. Faça login novamente.',
        ),
      ),
    );

    expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
    expect(fakeAuthRepository.signOutCalls, 1);
    verify(() => repository.createGig(draft)).called(1);
    expect(container!.read(createGigControllerProvider).hasError, isTrue);
  });
}
