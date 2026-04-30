import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';
import 'package:mube/src/features/gigs/domain/gig_review_opportunity.dart';
import 'package:mube/src/features/gigs/domain/review_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';
import '../../../../helpers/test_utils.dart';

class MockGigRepository extends Mock implements GigRepository {}

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

  test(
    'pendingGigReviews waits for auth and completed profile before loading',
    () async {
      final fakeAuthRepository = FakeAuthRepository(
        initialUser: FakeFirebaseUser(uid: 'user-1'),
      );
      final repository = MockGigRepository();
      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          authStateChangesProvider.overrideWith(
            (ref) => const Stream<firebase_auth.User?>.empty(),
          ),
          gigRepositoryProvider.overrideWith((ref) => repository),
        ],
      );

      addTearDown(() {
        fakeAuthRepository.dispose();
        container.dispose();
      });

      final reviews = await container.read(pendingGigReviewsProvider.future);

      expect(reviews, isEmpty);
      verifyNever(() => repository.getPendingReviewsForUser(any()));
    },
  );

  test(
    'pendingGigReviews loads only for matching completed auth profile',
    () async {
      final authUser = FakeFirebaseUser(uid: 'user-1');
      final fakeAuthRepository = FakeAuthRepository(initialUser: authUser);
      final authController = StreamController<firebase_auth.User?>.broadcast();
      final profileController = StreamController<AppUser?>.broadcast();
      final repository = MockGigRepository();
      const opportunity = GigReviewOpportunity(
        gigId: 'gig-1',
        gigTitle: 'Gig encerrada',
        reviewedUserId: 'user-2',
        reviewedUserName: 'Pessoa avaliada',
        reviewType: ReviewType.creatorToParticipant,
      );

      when(
        () => repository.getPendingReviewsForUser('user-1'),
      ).thenAnswer((_) async => const [opportunity]);

      final container = createTestContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          authStateChangesProvider.overrideWith((ref) => authController.stream),
          currentUserProfileProvider.overrideWith(
            (ref) => profileController.stream,
          ),
          gigRepositoryProvider.overrideWith((ref) => repository),
        ],
      );

      addTearDown(() {
        authController.close();
        profileController.close();
        fakeAuthRepository.dispose();
        container.dispose();
      });

      final reviewsLoaded = Completer<List<GigReviewOpportunity>>();
      final subscription = container.listen(pendingGigReviewsProvider, (
        _,
        next,
      ) {
        final reviews = next.value;
        if (reviews != null) {
          if (reviews.isNotEmpty && !reviewsLoaded.isCompleted) {
            reviewsLoaded.complete(reviews);
          }
        }
      }, fireImmediately: true);
      addTearDown(subscription.close);

      authController.add(authUser);
      await Future<void>.delayed(Duration.zero);
      profileController.add(TestData.user(uid: 'user-1'));

      final reviews = await reviewsLoaded.future;

      expect(reviews, const [opportunity]);
      verify(() => repository.getPendingReviewsForUser('user-1')).called(1);
    },
  );
}
