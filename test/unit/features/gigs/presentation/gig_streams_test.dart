import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';

import '../../../../helpers/test_fakes.dart';
import '../../../../helpers/test_utils.dart';

void main() {
  test(
    'myApplications resolves with an empty list when auth has not emitted yet',
    () async {
      final fakeAuthRepository = FakeAuthRepository();
      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<firebase_auth.User?>.empty(),
          ),
        ],
      );

      addTearDown(() {
        fakeAuthRepository.dispose();
        container.dispose();
      });

      final subscription = container.listen(
        myApplicationsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final applications = await container.read(myApplicationsProvider.future);

      expect(applications, isEmpty);
    },
  );
}
