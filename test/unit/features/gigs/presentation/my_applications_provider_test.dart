import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';
import 'package:mube/src/features/gigs/domain/application_status.dart';
import 'package:mube/src/features/gigs/domain/gig_application.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';

import '../../../../helpers/test_fakes.dart';

class MockGigRepository extends Mock implements GigRepository {}

void main() {
  test(
    'myApplicationsProvider uses current FirebaseAuth user while auth stream is still loading',
    () async {
      final repository = MockGigRepository();
      final authRepository = FakeAuthRepository(
        initialUser: FakeFirebaseUser(uid: 'user-1'),
      );

      when(() => repository.watchMyApplications()).thenAnswer(
        (_) => Stream.value(const [
          GigApplication(
            id: 'application-1',
            gigId: 'gig-1',
            applicantId: 'user-1',
            message: 'Tenho disponibilidade total.',
            status: ApplicationStatus.pending,
          ),
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<firebase_auth.User?>.empty(),
          ),
          gigRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);
      final subscription = container.listen(
        myApplicationsProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final applications = await container.read(myApplicationsProvider.future);

      expect(applications.map((application) => application.id), [
        'application-1',
      ]);
      verify(() => repository.watchMyApplications()).called(1);
    },
  );

  test(
    'myApplicationsProvider returns an empty list when auth resolves without user',
    () async {
      final repository = MockGigRepository();
      final authRepository = FakeAuthRepository();

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateChangesProvider.overrideWith((ref) => Stream.value(null)),
          gigRepositoryProvider.overrideWith((ref) => repository),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(authRepository.dispose);
      final subscription = container.listen(
        myApplicationsProvider,
        (previous, next) {},
      );
      addTearDown(subscription.close);

      final applications = await container.read(myApplicationsProvider.future);

      expect(applications, isEmpty);
      verifyNever(() => repository.watchMyApplications());
    },
  );
}
