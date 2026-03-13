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
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fakes.dart';

class _AnalyticsEvent {
  final String name;
  final Map<String, Object>? parameters;

  const _AnalyticsEvent({required this.name, required this.parameters});
}

class _RecordingAnalyticsService extends Fake implements AnalyticsService {
  final List<_AnalyticsEvent> events = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    events.add(_AnalyticsEvent(name: name, parameters: parameters));
  }

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

class _QueuedMatchpointRepository extends Fake implements MatchpointRepository {
  _QueuedMatchpointRepository(this.responses);

  final List<Either<Failure, MatchpointActionResult>> responses;
  int submitActionCalls = 0;

  @override
  FutureResult<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String type,
  }) async {
    submitActionCalls++;
    if (responses.isEmpty) {
      return Right(MatchpointActionResult(success: true, isMatch: false));
    }
    return responses.removeAt(0);
  }

  @override
  FutureResult<LikesQuotaInfo> getRemainingLikes() async {
    return Right(
      LikesQuotaInfo(remaining: 50, limit: 50, resetTime: DateTime.now()),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late FakeAuthRepository fakeAuthRepository;
  late _QueuedMatchpointRepository fakeMatchpointRepository;
  late _RecordingAnalyticsService fakeAnalyticsService;
  late FakeFirebaseUser fakeFirebaseUser;
  late AppUser testProfile;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeAuthRepository = FakeAuthRepository();
    fakeAnalyticsService = _RecordingAnalyticsService();
    fakeFirebaseUser = FakeFirebaseUser(uid: 'user-1');
    testProfile = const AppUser(
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

  ProviderContainer buildContainer() {
    return ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        matchpointRepositoryProvider.overrideWithValue(
          fakeMatchpointRepository,
        ),
        analyticsServiceProvider.overrideWithValue(fakeAnalyticsService),
        currentUserProfileProvider.overrideWithValue(
          AsyncValue.data(testProfile),
        ),
      ],
    );
  }

  group('MatchpointController session recovery', () {
    test(
      'retries swipe once after session failure when refresh succeeds',
      () async {
        fakeAuthRepository.emitUser(fakeFirebaseUser);
        fakeMatchpointRepository = _QueuedMatchpointRepository([
          const Left(
            AuthFailure(message: 'Sua sessão expirou. Faça login novamente.'),
          ),
          Right(
            MatchpointActionResult(
              success: true,
              isMatch: false,
              remainingLikes: 48,
            ),
          ),
        ]);
        container = buildContainer();

        const targetUser = AppUser(
          uid: 'target-1',
          email: 'target-1@mube.app',
          nome: 'Target',
        );

        final result = await container
            .read(matchpointControllerProvider.notifier)
            .swipeRight(targetUser);

        expect(result.success, true);
        expect(fakeMatchpointRepository.submitActionCalls, 2);
        expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
        expect(container.read(likesQuotaProvider).remaining, 48);
        final events = fakeAnalyticsService.events
            .where((event) => event.name == 'matchpoint_swipe_session_recovery')
            .toList();
        expect(events.length, 3);
        expect(events[0].parameters?['stage'], 'submit_action');
        expect(events[0].parameters?['outcome'], 'attempt');
        expect(events[1].parameters?['stage'], 'submit_action');
        expect(events[1].parameters?['outcome'], 'succeeded');
        expect(events[2].parameters?['stage'], 'submit_action');
        expect(events[2].parameters?['outcome'], 'retry_succeeded');
      },
    );

    test(
      'does not call submitAction when user is null and refresh fails',
      () async {
        fakeAuthRepository.emitUser(null);
        fakeAuthRepository.refreshSecurityContextResult = const Left(
          AuthFailure(message: 'Sua sessão expirou. Faça login novamente.'),
        );
        fakeMatchpointRepository = _QueuedMatchpointRepository([]);
        container = buildContainer();

        const targetUser = AppUser(
          uid: 'target-1',
          email: 'target-1@mube.app',
          nome: 'Target',
        );

        final result = await container
            .read(matchpointControllerProvider.notifier)
            .swipeRight(targetUser);

        expect(result.success, false);
        expect(fakeMatchpointRepository.submitActionCalls, 0);
        expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
        final state = container.read(matchpointControllerProvider);
        expect(state.hasError, true);
        expect(
          state.whenOrNull(error: (error, _) => error.toString()),
          contains('Sua sessão expirou'),
        );
        final events = fakeAnalyticsService.events
            .where((event) => event.name == 'matchpoint_swipe_session_recovery')
            .toList();
        expect(events.length, 2);
        expect(events[0].parameters?['stage'], 'missing_user');
        expect(events[0].parameters?['outcome'], 'attempt');
        expect(events[1].parameters?['stage'], 'missing_user');
        expect(events[1].parameters?['outcome'], 'failed');
      },
    );

    test(
      'returns failure without retrying submit when refresh fails after session failure',
      () async {
        fakeAuthRepository.emitUser(fakeFirebaseUser);
        fakeAuthRepository.refreshSecurityContextResult = const Left(
          AuthFailure(message: 'Sua sessão expirou. Faça login novamente.'),
        );
        fakeMatchpointRepository = _QueuedMatchpointRepository([
          const Left(
            AuthFailure(message: 'Sua sessão expirou. Faça login novamente.'),
          ),
        ]);
        container = buildContainer();

        const targetUser = AppUser(
          uid: 'target-1',
          email: 'target-1@mube.app',
          nome: 'Target',
        );

        final result = await container
            .read(matchpointControllerProvider.notifier)
            .swipeRight(targetUser);

        expect(result.success, false);
        expect(fakeMatchpointRepository.submitActionCalls, 1);
        expect(fakeAuthRepository.refreshSecurityContextCalls, 1);
        final events = fakeAnalyticsService.events
            .where((event) => event.name == 'matchpoint_swipe_session_recovery')
            .toList();
        expect(events.length, 2);
        expect(events[0].parameters?['stage'], 'submit_action');
        expect(events[0].parameters?['outcome'], 'attempt');
        expect(events[1].parameters?['stage'], 'submit_action');
        expect(events[1].parameters?['outcome'], 'failed');
      },
    );
  });
}
