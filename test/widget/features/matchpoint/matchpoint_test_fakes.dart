// ignore: unused_import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/match_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';

class MockMatchpointRepository extends Mock implements MatchpointRepository {
  @override
  FutureResult<MatchpointActionResult> submitAction({
    required String? targetUserId,
    required String? type,
  }) {
    return super.noSuchMethod(
          Invocation.method(#submitAction, [], {
            #targetUserId: targetUserId,
            #type: type,
          }),
          returnValue: Future.value(
            Right<Failure, MatchpointActionResult>(
              MatchpointActionResult(
                success: true,
                isMatch: false,
                remainingLikes: 50,
              ),
            ),
          ),
          returnValueForMissingStub: Future.value(
            Right<Failure, MatchpointActionResult>(
              MatchpointActionResult(
                success: true,
                isMatch: false,
                remainingLikes: 50,
              ),
            ),
          ),
        )
        as FutureResult<MatchpointActionResult>;
  }

  @override
  FutureResult<LikesQuotaInfo> getRemainingLikes() {
    return super.noSuchMethod(
          Invocation.method(#getRemainingLikes, []),
          returnValue: Future.value(
            Right<Failure, LikesQuotaInfo>(
              LikesQuotaInfo(
                remaining: 50,
                limit: 50,
                resetTime: DateTime.now(),
              ),
            ),
          ),
          returnValueForMissingStub: Future.value(
            Right<Failure, LikesQuotaInfo>(
              LikesQuotaInfo(
                remaining: 50,
                limit: 50,
                resetTime: DateTime.now(),
              ),
            ),
          ),
        )
        as FutureResult<LikesQuotaInfo>;
  }

  @override
  FutureResult<List<AppUser>> fetchCandidates({
    String? currentUserId,
    List<String>? genres,
    List<String>? blockedUsers,
    int? limit = 20,
  }) {
    return super.noSuchMethod(
          Invocation.method(#fetchCandidates, [], {
            #currentUserId: currentUserId,
            #genres: genres,
            #blockedUsers: blockedUsers,
            #limit: limit,
          }),
          returnValue: Future.value(const Right<Failure, List<AppUser>>([])),
          returnValueForMissingStub: Future.value(
            const Right<Failure, List<AppUser>>([]),
          ),
        )
        as FutureResult<List<AppUser>>;
  }

  @override
  FutureResult<List<MatchInfo>> fetchMatches(String? currentUserId) {
    return super.noSuchMethod(
          Invocation.method(#fetchMatches, [currentUserId]),
          returnValue: Future.value(const Right<Failure, List<MatchInfo>>([])),
          returnValueForMissingStub: Future.value(
            const Right<Failure, List<MatchInfo>>([]),
          ),
        )
        as FutureResult<List<MatchInfo>>;
  }

  @override
  FutureResult<List<HashtagRanking>> fetchHashtagRanking({int? limit = 20}) {
    return super.noSuchMethod(
          Invocation.method(#fetchHashtagRanking, [], {#limit: limit}),
          returnValue: Future.value(
            const Right<Failure, List<HashtagRanking>>([]),
          ),
          returnValueForMissingStub: Future.value(
            const Right<Failure, List<HashtagRanking>>([]),
          ),
        )
        as FutureResult<List<HashtagRanking>>;
  }
}
