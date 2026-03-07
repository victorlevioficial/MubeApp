import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_remote_data_source.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';

class _FakeMatchpointRemoteDataSource implements MatchpointRemoteDataSource {
  Object? submitActionError;

  @override
  Future<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String action,
  }) async {
    final error = submitActionError;
    if (error != null) throw error;
    return MatchpointActionResult(success: true, isMatch: false);
  }

  @override
  Future<List<String>> fetchExistingInteractions(String currentUserId) {
    throw UnimplementedError();
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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppUser?> fetchUserById(String userId) {
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

void main() {
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
          expect(failure.message, 'Sua sessão expirou. Faça login novamente.');
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
          'Falha de verificação de segurança. Feche e abra o app e tente novamente.',
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
            'Não foi possível registrar sua ação agora. Tente novamente.',
          );
          expect(failure.debugMessage, 'internal');
        }, (_) => fail('Expected failure'));
      },
    );
  });
}
