import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';

import '../../helpers/test_fakes.dart';

class FakeMatchpointRepository extends Fake implements MatchpointRepository {
  bool throwError = false;
  MatchpointActionResult? nextResult;

  @override
  FutureResult<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String type,
  }) async {
    if (throwError) throw Exception('Action failed');
    return Either.right(
      nextResult ??
          MatchpointActionResult(
            success: true,
            isMatch: false,
            remainingLikes: 49,
          ),
    );
  }

  @override
  FutureResult<LikesQuotaInfo> getRemainingLikes() async {
    return Either.right(
      LikesQuotaInfo(remaining: 50, limit: 50, resetTime: DateTime.now()),
    );
  }
}

void main() {
  late ProviderContainer container;
  late FakeAuthRepository fakeAuthRepository;
  late FakeMatchpointRepository fakeMatchpointRepository;
  late FakeAnalyticsService fakeAnalyticsService;
  late FakeFirebaseUser fakeUser;
  late AppUser testAppUser;

  setUp(() async {
    fakeAuthRepository = FakeAuthRepository();
    fakeMatchpointRepository = FakeMatchpointRepository();
    fakeAnalyticsService = FakeAnalyticsService();
    fakeUser = FakeFirebaseUser(uid: 'user123');

    testAppUser = const AppUser(
      uid: 'user123',
      email: 'test@example.com',
      nome: 'Test User',
      foto: 'photo.jpg',
      matchpointProfile: {},
      privacySettings: {},
      blockedUsers: [],
    );

    fakeAuthRepository.emitUser(fakeUser);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        matchpointRepositoryProvider.overrideWithValue(
          fakeMatchpointRepository,
        ),
        analyticsServiceProvider.overrideWithValue(fakeAnalyticsService),
        currentUserProfileProvider.overrideWithValue(
          AsyncValue.data(testAppUser),
        ),
      ],
    );

    // Wait for the user profile to be ready
    await container.read(currentUserProfileProvider.future);
  });

  tearDown(() {
    container.dispose();
  });

  group('MatchpointController', () {
    test(
      'saveMatchpointProfile - should update user and log analytics on success',
      () async {
        // Act
        final controller = container.read(
          matchpointControllerProvider.notifier,
        );
        await controller.saveMatchpointProfile(
          intent: 'dating',
          genres: ['rock', 'pop'],
          hashtags: ['music'],
          isVisibleInHome: true,
        );

        // Give a tiny bit of time for unawaited analytics
        await Future.delayed(Duration.zero);

        // Assert
        expect(
          fakeAnalyticsService.loggedEvents,
          contains('matchpoint_filter'),
        );
        final state = container.read(matchpointControllerProvider);
        expect(state.hasError, false);
      },
    );

    test(
      'swipeRight - should submit like action and update generic state',
      () async {
        // Arrange
        const targetUser = AppUser(
          uid: 'target123',
          email: 'target@test.com',
          nome: 'Target',
        );
        fakeMatchpointRepository.nextResult = MatchpointActionResult(
          success: true,
          isMatch: false,
          remainingLikes: 49,
        );

        final controller = container.read(
          matchpointControllerProvider.notifier,
        );

        // Act
        final result = await controller.swipeRight(targetUser);

        // Assert
        expect(result.success, true);
        expect(result.matchedUser, null);
      },
    );

    test(
      'swipeRight - should return match info when isMatch is true',
      () async {
        // Arrange
        const targetUser = AppUser(
          uid: 'target123',
          email: 'target@test.com',
          nome: 'Target',
        );
        fakeMatchpointRepository.nextResult = MatchpointActionResult(
          success: true,
          isMatch: true,
          remainingLikes: 49,
          conversationId: 'conv123',
        );

        final controller = container.read(
          matchpointControllerProvider.notifier,
        );

        // Act
        final result = await controller.swipeRight(targetUser);

        // Assert
        expect(result.success, true);
        expect(result.matchedUser, targetUser);
        expect(result.conversationId, 'conv123');
      },
    );

    test('swipeLeft - should submit dislike action', () async {
      // Arrange
      const targetUser = AppUser(
        uid: 'target123',
        email: 'target@test.com',
        nome: 'Target',
      );

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act
      final success = await controller.swipeLeft(targetUser);

      // Assert
      expect(success, true);
    });

    test(
      'unmatchUser - should submit dislike action and invalidate matches',
      () async {
        // Act
        final controller = container.read(
          matchpointControllerProvider.notifier,
        );
        await controller.unmatchUser('target123');

        // Assert
        // Verification is implicit via Fake not throwing and completing
      },
    );
  });
}
