import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/match_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fakes.dart';

class _StubAnalyticsService extends Fake implements AnalyticsService {
  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {}

  @override
  Future<void> logAuthSignupComplete({required String method}) async {}

  @override
  Future<void> logFeedPostView({required String postId}) async {}

  @override
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  }) async {}

  @override
  Future<void> logProfileEdit({required String userId}) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}

  @override
  NavigatorObserver getObserver() => NavigatorObserver();
}

class _CountingFirebaseUser extends FakeFirebaseUser {
  _CountingFirebaseUser({required super.uid, super.email});

  int getIdTokenCalls = 0;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    getIdTokenCalls += 1;
    return super.getIdToken(forceRefresh);
  }
}

typedef _SubmitHandler = FutureResult<MatchpointActionResult> Function();

class _QueueingMatchpointRepository extends Fake
    implements MatchpointRepository {
  _QueueingMatchpointRepository(this._submitHandlers);

  final List<_SubmitHandler> _submitHandlers;
  int submitActionCalls = 0;
  final List<String> submittedActions = [];

  @override
  FutureResult<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String type,
  }) async {
    submitActionCalls++;
    submittedActions.add(type);
    final handler = _submitHandlers.removeAt(0);
    return handler();
  }

  @override
  FutureResult<LikesQuotaInfo> getRemainingLikes() async {
    return Right(
      LikesQuotaInfo(remaining: 50, limit: 50, resetTime: DateTime.now()),
    );
  }

  @override
  FutureResult<List<AppUser>> fetchCandidates({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    return const Right([]);
  }

  @override
  FutureResult<List<MatchInfo>> fetchMatches(String currentUserId) async {
    return const Right([]);
  }

  @override
  FutureResult<List<HashtagRanking>> fetchHashtagRanking({
    int limit = 20,
  }) async {
    return const Right([]);
  }

  @override
  FutureResult<AppUser?> fetchUserById(String userId) async {
    return const Right(null);
  }

  @override
  FutureResult<List<HashtagRanking>> searchHashtags(
    String query, {
    int limit = 20,
  }) async {
    return const Right([]);
  }

  @override
  FutureResult<void> saveProfile({
    required String userId,
    required String intent,
    required List<String> musicalGenres,
    required List<String> hashtags,
    required bool isPublic,
  }) async {
    return const Right(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeAuthRepository fakeAuthRepository;
  late _StubAnalyticsService analyticsService;
  late AppUser currentUserProfile;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeAuthRepository = FakeAuthRepository();
    analyticsService = _StubAnalyticsService();
    fakeAuthRepository.emitUser(FakeFirebaseUser(uid: 'user-1'));
    currentUserProfile = const AppUser(
      uid: 'user-1',
      email: 'user-1@mube.app',
      nome: 'User 1',
      matchpointProfile: {},
      privacySettings: {},
      blockedUsers: [],
    );
  });

  tearDown(() {
    fakeAuthRepository.dispose();
    container.dispose();
  });

  Future<void> flushQueue() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  ProviderContainer buildContainer(MatchpointRepository repository) {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        analyticsServiceProvider.overrideWithValue(analyticsService),
        matchpointRepositoryProvider.overrideWithValue(repository),
        currentUserProfileProvider.overrideWithValue(
          AsyncValue.data(currentUserProfile),
        ),
      ],
    );
  }

  group('Matchpoint swipe queue', () {
    test(
      'processes queued swipes sequentially without blocking the queue',
      () async {
        final firstSwipeCompleter =
            Completer<Either<Failure, MatchpointActionResult>>();
        final secondSwipeCompleter =
            Completer<Either<Failure, MatchpointActionResult>>();
        final repository = _QueueingMatchpointRepository([
          () => firstSwipeCompleter.future,
          () => secondSwipeCompleter.future,
        ]);
        container = buildContainer(repository);
        final controller = container.read(
          matchpointControllerProvider.notifier,
        );

        const firstTarget = AppUser(
          uid: 'target-1',
          email: 'target-1@mube.app',
          nome: 'Target 1',
        );
        const secondTarget = AppUser(
          uid: 'target-2',
          email: 'target-2@mube.app',
          nome: 'Target 2',
        );

        expect(await controller.queueSwipeRight(firstTarget), isTrue);
        await flushQueue();
        expect(repository.submitActionCalls, 1);
        expect(
          container.read(matchpointSwipeQueueStateProvider).pendingActions,
          1,
        );

        expect(await controller.queueSwipeLeft(secondTarget), isTrue);
        expect(
          container.read(matchpointSwipeQueueStateProvider).pendingActions,
          2,
        );
        expect(repository.submitActionCalls, 1);

        firstSwipeCompleter.complete(
          Right(
            MatchpointActionResult(
              success: true,
              isMatch: false,
              remainingLikes: 49,
            ),
          ),
        );
        await flushQueue();

        expect(repository.submitActionCalls, 2);
        expect(repository.submittedActions, ['like', 'dislike']);
        expect(
          container.read(matchpointSwipeQueueStateProvider).pendingActions,
          1,
        );

        secondSwipeCompleter.complete(
          Right(
            MatchpointActionResult(
              success: true,
              isMatch: false,
              remainingLikes: 49,
            ),
          ),
        );
        await flushQueue();

        expect(
          container.read(matchpointSwipeQueueStateProvider).pendingActions,
          0,
        );
      },
    );

    test('emits match feedback after queued like succeeds', () async {
      final repository = _QueueingMatchpointRepository([
        () async => Right(
          MatchpointActionResult(
            success: true,
            isMatch: true,
            remainingLikes: 49,
            conversationId: 'conversation-123',
          ),
        ),
      ]);
      container = buildContainer(repository);
      final controller = container.read(matchpointControllerProvider.notifier);

      const targetUser = AppUser(
        uid: 'target-1',
        email: 'target-1@mube.app',
        nome: 'Target 1',
      );

      expect(await controller.queueSwipeRight(targetUser), isTrue);
      await flushQueue();

      final feedback = container.read(matchpointSwipeFeedbackProvider);
      expect(feedback, isNotNull);
      expect(feedback!.isMatch, isTrue);
      expect(feedback.targetUser.uid, targetUser.uid);
      expect(feedback.conversationId, 'conversation-123');
      expect(container.read(likesQuotaProvider).remaining, 49);
    });

    test('emits failure feedback after queued swipe fails', () async {
      final repository = _QueueingMatchpointRepository([
        () async => const Left(ServerFailure(message: 'Backend indisponível')),
      ]);
      container = buildContainer(repository);
      final controller = container.read(matchpointControllerProvider.notifier);

      const targetUser = AppUser(
        uid: 'target-1',
        email: 'target-1@mube.app',
        nome: 'Target 1',
      );

      expect(await controller.queueSwipeLeft(targetUser), isTrue);
      await flushQueue();

      final feedback = container.read(matchpointSwipeFeedbackProvider);
      expect(feedback, isNotNull);
      expect(feedback!.isFailure, isTrue);
      expect(feedback.message, 'Backend indisponível');
      expect(
        container.read(matchpointSwipeQueueStateProvider).pendingActions,
        0,
      );
      expect(container.read(matchpointControllerProvider).hasError, isTrue);
    });

    test(
      'optimistically decrements and restores likes quota on failure',
      () async {
        final repository = _QueueingMatchpointRepository([
          () async =>
              const Left(ServerFailure(message: 'Backend indisponível')),
        ]);
        container = buildContainer(repository);
        final controller = container.read(
          matchpointControllerProvider.notifier,
        );

        container
            .read(likesQuotaProvider.notifier)
            .setQuota(remaining: 10, limit: 50, resetTime: DateTime.now());

        const targetUser = AppUser(
          uid: 'target-1',
          email: 'target-1@mube.app',
          nome: 'Target 1',
        );

        expect(await controller.queueSwipeRight(targetUser), isTrue);
        expect(container.read(likesQuotaProvider).remaining, 9);

        await flushQueue();

        expect(container.read(likesQuotaProvider).remaining, 10);
      },
    );

    test(
      'reuses recent swipe security validation across queued swipes',
      () async {
        final countingUser = _CountingFirebaseUser(
          uid: 'user-1',
          email: 'user-1@mube.app',
        );
        fakeAuthRepository.emitUser(countingUser);

        final repository = _QueueingMatchpointRepository([
          () async => Right(
            MatchpointActionResult(
              success: true,
              isMatch: false,
              remainingLikes: 49,
            ),
          ),
          () async => Right(
            MatchpointActionResult(
              success: true,
              isMatch: false,
              remainingLikes: 48,
            ),
          ),
        ]);
        container = buildContainer(repository);
        final controller = container.read(
          matchpointControllerProvider.notifier,
        );

        const firstTarget = AppUser(
          uid: 'target-1',
          email: 'target-1@mube.app',
          nome: 'Target 1',
        );
        const secondTarget = AppUser(
          uid: 'target-2',
          email: 'target-2@mube.app',
          nome: 'Target 2',
        );

        expect(await controller.queueSwipeRight(firstTarget), isTrue);
        expect(await controller.queueSwipeRight(secondTarget), isTrue);

        await flushQueue();

        expect(countingUser.getIdTokenCalls, 1);
      },
    );
  });
}
