import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';

import '../../helpers/test_fakes.dart';

/// Extended Fake MatchpointRepository for comprehensive testing
class FakeMatchpointRepositoryExtended extends Fake
    implements MatchpointRepository {
  bool throwError = false;
  bool throwQuotaError = false;
  bool throwPermissionError = false;
  MatchpointActionResult? nextResult;
  LikesQuotaInfo? nextQuotaInfo;
  List<AppUser> candidates = [];

  @override
  FutureResult<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String type,
  }) async {
    if (throwError) {
      return Left(ServerFailure(message: 'Action failed'));
    }
    if (throwQuotaError) {
      return Left(QuotaExceededFailure.dailyLikes());
    }
    if (throwPermissionError) {
      return Left(PermissionFailure.firestore());
    }
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
    if (throwError) {
      return Left(ServerFailure(message: 'Failed to get quota'));
    }
    return Either.right(
      nextQuotaInfo ??
          LikesQuotaInfo(
            remaining: 50,
            limit: 50,
            resetTime: DateTime.now().add(const Duration(hours: 24)),
          ),
    );
  }

  @override
  FutureResult<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    if (throwError) {
      return Left(ServerFailure(message: 'Failed to fetch candidates'));
    }
    return Right(candidates);
  }
}

void main() {
  late ProviderContainer container;
  late FakeAuthRepository fakeAuthRepository;
  late FakeMatchpointRepositoryExtended fakeMatchpointRepository;
  late FakeAnalyticsService fakeAnalyticsService;
  late FakeFirebaseUser fakeUser;
  late AppUser testAppUser;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeMatchpointRepository = FakeMatchpointRepositoryExtended();
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
    container.read(currentUserProfileProvider.future);
  });

  tearDown(() {
    container.dispose();
  });

  group('MatchpointController - Lógica de Compatibilidade', () {
    test('swipeRight should handle quota exceeded error', () async {
      // Arrange
      fakeMatchpointRepository.throwQuotaError = true;
      const targetUser = AppUser(
        uid: 'target123',
        email: 'target@test.com',
        nome: 'Target',
      );

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act
      final result = await controller.swipeRight(targetUser);

      // Assert
      expect(result.success, false);
      expect(result.matchedUser, null);
    });

    test('swipeRight should handle permission denied error', () async {
      // Arrange
      fakeMatchpointRepository.throwPermissionError = true;
      const targetUser = AppUser(
        uid: 'target123',
        email: 'target@test.com',
        nome: 'Target',
      );

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act
      final result = await controller.swipeRight(targetUser);

      // Assert
      expect(result.success, false);
    });

    test('swipeRight should update remaining likes when provided', () async {
      // Arrange
      fakeMatchpointRepository.nextResult = MatchpointActionResult(
        success: true,
        isMatch: false,
        remainingLikes: 42,
      );
      const targetUser = AppUser(
        uid: 'target123',
        email: 'target@test.com',
        nome: 'Target',
      );

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act
      await controller.swipeRight(targetUser);

      // Assert - quota should be updated via likesQuotaProvider
      final quotaState = container.read(likesQuotaProvider);
      expect(quotaState.remaining, 42);
    });

    test('swipeLeft should return false on error', () async {
      // Arrange
      fakeMatchpointRepository.throwError = true;
      const targetUser = AppUser(
        uid: 'target123',
        email: 'target@test.com',
        nome: 'Target',
      );

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act
      final result = await controller.swipeLeft(targetUser);

      // Assert
      expect(result, false);
    });

    test('fetchRemainingLikes should update quota state on success', () async {
      // Arrange
      fakeMatchpointRepository.nextQuotaInfo = LikesQuotaInfo(
        remaining: 25,
        limit: 50,
        resetTime: DateTime.now().add(const Duration(hours: 12)),
      );

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act
      await controller.fetchRemainingLikes();

      // Assert
      final quotaState = container.read(likesQuotaProvider);
      expect(quotaState.remaining, 25);
      expect(quotaState.limit, 50);
      expect(quotaState.hasReachedLimit, false);
    });

    test('fetchRemainingLikes should handle error gracefully', () async {
      // Arrange
      fakeMatchpointRepository.throwError = true;

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act - should not throw
      await controller.fetchRemainingLikes();

      // Assert - quota state should remain unchanged (default)
      final quotaState = container.read(likesQuotaProvider);
      expect(quotaState.remaining, 50); // Default value
    });

    test('saveMatchpointProfile should handle update failure', () async {
      // Arrange
      fakeAuthRepository.shouldThrow = true;

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act
      await controller.saveMatchpointProfile(
        intent: 'dating',
        genres: ['rock', 'pop'],
        hashtags: ['music'],
        isVisibleInHome: true,
      );

      // Assert
      final state = container.read(matchpointControllerProvider);
      expect(state.hasError, true);
    });

    test('unmatchUser should handle error gracefully', () async {
      // Arrange
      fakeMatchpointRepository.throwError = true;

      final controller = container.read(matchpointControllerProvider.notifier);

      // Act - should not throw
      await controller.unmatchUser('target123');

      // Assert - no exception thrown
      expect(true, true);
    });
  });

  group('LikesQuota - Regras de Negócio', () {
    test(
      'LikesQuotaState hasReachedLimit should be true when remaining is 0',
      () {
        const state = LikesQuotaState(remaining: 0, limit: 50);
        expect(state.hasReachedLimit, true);
      },
    );

    test(
      'LikesQuotaState hasReachedLimit should be true when remaining is negative',
      () {
        const state = LikesQuotaState(remaining: -1, limit: 50);
        expect(state.hasReachedLimit, true);
      },
    );

    test(
      'LikesQuotaState hasReachedLimit should be false when remaining is positive',
      () {
        const state = LikesQuotaState(remaining: 1, limit: 50);
        expect(state.hasReachedLimit, false);
      },
    );

    test('LikesQuota copyWith should update values correctly', () {
      const state = LikesQuotaState(remaining: 50, limit: 50);
      final updated = state.copyWith(remaining: 25);

      expect(updated.remaining, 25);
      expect(updated.limit, 50); // Preserved
    });

    test('LikesQuota notifier should set quota correctly', () {
      final notifier = container.read(likesQuotaProvider.notifier);
      final resetTime = DateTime.now().add(const Duration(hours: 24));

      notifier.setQuota(remaining: 30, limit: 50, resetTime: resetTime);

      final state = container.read(likesQuotaProvider);
      expect(state.remaining, 30);
      expect(state.limit, 50);
      expect(state.resetTime, resetTime);
      expect(state.isLoading, false);
    });

    test('LikesQuota notifier should update remaining correctly', () {
      final notifier = container.read(likesQuotaProvider.notifier);

      notifier.setQuota(remaining: 50, limit: 50, resetTime: DateTime.now());
      notifier.updateRemaining(40);

      final state = container.read(likesQuotaProvider);
      expect(state.remaining, 40);
    });

    test('LikesQuota decrementOptimistically should decrease remaining', () {
      final notifier = container.read(likesQuotaProvider.notifier);

      notifier.setQuota(remaining: 10, limit: 50, resetTime: DateTime.now());
      notifier.decrementOptimistically();

      final state = container.read(likesQuotaProvider);
      expect(state.remaining, 9);
    });

    test('LikesQuota decrementOptimistically should not go below 0', () {
      final notifier = container.read(likesQuotaProvider.notifier);

      notifier.setQuota(remaining: 0, limit: 50, resetTime: DateTime.now());
      notifier.decrementOptimistically();

      final state = container.read(likesQuotaProvider);
      expect(state.remaining, 0);
    });

    test('LikesQuota setLoading should update loading state', () {
      final notifier = container.read(likesQuotaProvider.notifier);

      notifier.setLoading(true);
      expect(container.read(likesQuotaProvider).isLoading, true);

      notifier.setLoading(false);
      expect(container.read(likesQuotaProvider).isLoading, false);
    });
  });

  group('SwipeActionResult - Regras de Negócio', () {
    test('SwipeActionResult should be created with correct values', () {
      const targetUser = AppUser(
        uid: 'target123',
        email: 'target@test.com',
        nome: 'Target User',
      );

      const result = SwipeActionResult(
        success: true,
        matchedUser: targetUser,
        conversationId: 'conv123',
      );

      expect(result.success, true);
      expect(result.matchedUser, targetUser);
      expect(result.conversationId, 'conv123');
    });

    test('SwipeActionResult should handle non-match result', () {
      const result = SwipeActionResult(success: false);

      expect(result.success, false);
      expect(result.matchedUser, null);
      expect(result.conversationId, null);
    });
  });

  group('MatchpointActionResult - Regras de Negócio', () {
    test('MatchpointActionResult equality should work correctly', () {
      final result1 = MatchpointActionResult(
        success: true,
        isMatch: true,
        matchId: 'match123',
        conversationId: 'conv123',
        remainingLikes: 49,
      );

      final result2 = MatchpointActionResult(
        success: true,
        isMatch: true,
        matchId: 'match123',
        conversationId: 'conv123',
        remainingLikes: 49,
      );

      final result3 = MatchpointActionResult(success: false, isMatch: false);

      expect(result1, result2);
      expect(result1, isNot(result3));
    });

    test('MatchpointActionResult fromJson should parse correctly', () {
      final json = {
        'success': true,
        'isMatch': true,
        'matchId': 'match123',
        'conversationId': 'conv123',
        'message': 'It\'s a match!',
      };

      final result = MatchpointActionResult.fromJson(json);

      expect(result.success, true);
      expect(result.isMatch, true);
      expect(result.matchId, 'match123');
      expect(result.conversationId, 'conv123');
      expect(result.message, 'It\'s a match!');
    });

    test('MatchpointActionResult fromJson should handle missing fields', () {
      final json = <String, dynamic>{};

      final result = MatchpointActionResult.fromJson(json);

      expect(result.success, false);
      expect(result.isMatch, false);
      expect(result.matchId, null);
      expect(result.conversationId, null);
    });
  });
}
