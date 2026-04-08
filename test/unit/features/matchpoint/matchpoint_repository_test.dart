import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_remote_data_source.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';

class _FakeMatchpointRemoteDataSource implements MatchpointRemoteDataSource {
  Object? submitActionError;
  MatchpointActionResult submitActionResult = MatchpointActionResult(
    success: true,
    isMatch: false,
  );
  int fetchExistingInteractionsCalls = 0;
  List<String> fetchExistingInteractionsResult = const [];
  List<AppUser> fetchCandidatesResult = const [];
  List<String>? lastExcludedUserIds;

  @override
  Future<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String action,
  }) async {
    final error = submitActionError;
    if (error != null) throw error;
    return submitActionResult;
  }

  @override
  Future<List<String>> fetchExistingInteractions(String currentUserId) async {
    fetchExistingInteractionsCalls += 1;
    return fetchExistingInteractionsResult;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMatches(String currentUserId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AppUser>> fetchCandidates({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> excludedUserIds,
    int limit = 50,
  }) async {
    lastExcludedUserIds = excludedUserIds;
    return fetchCandidatesResult;
  }

  @override
  Future<AppUser?> fetchUserById(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, AppUser>> fetchUsersByIds(List<String> ids) {
    throw UnimplementedError();
  }

  @override
  Future<LikesQuotaInfo> getRemainingLikes() {
    throw UnimplementedError();
  }

  @override
  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<HashtagRanking>> searchHashtags(String query, {int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) {
    throw UnimplementedError();
  }
}

class _CompletingAnalyticsService implements AnalyticsService {
  _CompletingAnalyticsService(this._completer);

  final Completer<void> _completer;
  int logEventCalls = 0;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    logEventCalls += 1;
    return _completer.future;
  }

  @override
  NavigatorObserver getObserver() => NavigatorObserver();

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
}

void main() {
  group('MatchpointRepository.fetchCandidates', () {
    test('skips server interaction lookup during MatchPoint entry', () async {
      final dataSource = _FakeMatchpointRemoteDataSource()
        ..fetchExistingInteractionsResult = const ['server-like']
        ..fetchCandidatesResult = const [
          AppUser(uid: 'candidate-1', email: 'candidate@mube.app'),
        ];
      final repository = MatchpointRepository(dataSource);

      final result = await repository.fetchCandidates(
        currentUser: const AppUser(uid: 'current', email: 'current@mube.app'),
        genres: const ['rock'],
        hashtags: const ['#cover'],
        blockedUsers: const ['blocked-1'],
      );

      expect(result.isRight(), isTrue);
      expect(dataSource.fetchExistingInteractionsCalls, 0);
      expect(dataSource.lastExcludedUserIds, ['blocked-1']);
    });
  });

  group('MatchpointRepository.submitAction', () {
    test(
      'maps unauthenticated without app check hint to auth failure',
      () async {
        final dataSource = _FakeMatchpointRemoteDataSource()
          ..submitActionError = FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'User is not authenticated.',
          );
        final repository = MatchpointRepository(dataSource);

        final result = await repository.submitAction(
          targetUserId: 'target-1',
          type: 'like',
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthFailure>());
          expect(failure.message, 'Sua sessao expirou. Faca login novamente.');
          expect(failure.debugMessage, 'functions-unauthenticated');
        }, (_) => fail('Expected failure'));
      },
    );

    test('maps unauthenticated with app check hint to server failure', () async {
      final dataSource = _FakeMatchpointRemoteDataSource()
        ..submitActionError = FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'App Check token is invalid.',
        );
      final repository = MatchpointRepository(dataSource);

      final result = await repository.submitAction(
        targetUserId: 'target-1',
        type: 'like',
      );

      expect(result, isA<Either<Failure, MatchpointActionResult>>());
      expect(result.isLeft(), true);
      result.fold((failure) {
        expect(failure, isA<ServerFailure>());
        expect(
          failure.message,
          'App Check de desenvolvimento nao configurado. Cadastre o token de debug no Firebase Console e reabra o app.',
        );
        expect(failure.debugMessage, 'app-check-auth-context-failure');
      }, (_) => fail('Expected failure'));
    });

    test(
      'maps internal code leaked by Cloud Functions to a friendly message',
      () async {
        final dataSource = _FakeMatchpointRemoteDataSource()
          ..submitActionError = FirebaseFunctionsException(
            code: 'internal',
            message: 'internal',
          );
        final repository = MatchpointRepository(dataSource);

        final result = await repository.submitAction(
          targetUserId: 'target-1',
          type: 'like',
        );

        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(
            failure.message,
            'Nao foi possivel registrar sua acao agora. Tente novamente.',
          );
          expect(failure.debugMessage, 'internal');
        }, (_) => fail('Expected failure'));
      },
    );

    test('does not await analytics before returning swipe success', () async {
      final completer = Completer<void>();
      final analytics = _CompletingAnalyticsService(completer);
      final dataSource = _FakeMatchpointRemoteDataSource()
        ..submitActionResult = MatchpointActionResult(
          success: true,
          isMatch: true,
        );
      final repository = MatchpointRepository(dataSource, analytics: analytics);

      final result = await repository.submitAction(
        targetUserId: 'target-1',
        type: 'like',
      );

      expect(result.isRight(), true);
      expect(analytics.logEventCalls, 2);
      expect(completer.isCompleted, false);
    });
  });
}
