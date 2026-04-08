import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_feed_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_command_repository.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_feed_snapshot.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command_result.dart';

class _FakeLegacyMatchpointRepository extends Fake
    implements MatchpointRepository {
  FutureResult<List<AppUser>> Function({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    required int limit,
  })?
  onFetchCandidates;

  FutureResult<MatchpointActionResult> Function({
    required String targetUserId,
    required String type,
  })?
  onSubmitAction;

  @override
  FutureResult<List<AppUser>> fetchCandidates({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    return onFetchCandidates!(
      currentUser: currentUser,
      genres: genres,
      hashtags: hashtags,
      blockedUsers: blockedUsers,
      limit: limit,
    );
  }

  @override
  FutureResult<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String type,
  }) async {
    return onSubmitAction!(targetUserId: targetUserId, type: type);
  }
}

void main() {
  group('MatchPoint restructure adapters', () {
    test(
      'feed repository adapts legacy candidates into a feed snapshot',
      () async {
        final legacyRepository = _FakeLegacyMatchpointRepository()
          ..onFetchCandidates =
              ({
                required currentUser,
                required genres,
                required hashtags,
                required blockedUsers,
                required limit,
              }) async => const Right([
                AppUser(uid: 'target-1', email: 'target-1@mube.app'),
                AppUser(uid: 'target-2', email: 'target-2@mube.app'),
              ]);

        final container = ProviderContainer(
          overrides: [
            matchpointRepositoryProvider.overrideWithValue(legacyRepository),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(matchpointFeedRepositoryProvider);
        final result = await repository.fetchExploreFeed(
          currentUser: const AppUser(uid: 'user-1', email: 'user-1@mube.app'),
          genres: const ['rock'],
          hashtags: const ['#indie'],
          blockedUsers: const ['blocked-1'],
          limit: 12,
        );

        expect(result.isRight(), isTrue);
        final snapshot = result.getRight().toNullable()!;
        expect(snapshot.count, 2);
        expect(snapshot.source, MatchpointFeedSource.legacyQuery);
        expect(snapshot.isServerRanked, isFalse);
      },
    );

    test(
      'swipe command repository adapts legacy submit action result',
      () async {
        final legacyRepository = _FakeLegacyMatchpointRepository()
          ..onSubmitAction = ({required targetUserId, required type}) async =>
              Right(
                MatchpointActionResult(
                  success: true,
                  isMatch: true,
                  matchId: 'match-1',
                  conversationId: 'conversation-1',
                  remainingLikes: 42,
                  message: 'Match criado',
                ),
              );

        final container = ProviderContainer(
          overrides: [
            matchpointRepositoryProvider.overrideWithValue(legacyRepository),
          ],
        );
        addTearDown(container.dispose);

        final repository = container.read(
          matchpointSwipeCommandRepositoryProvider,
        );
        final result = await repository.submit(
          MatchpointSwipeCommand(
            targetUserId: 'target-1',
            action: MatchpointSwipeAction.like,
            createdAt: DateTime(2026, 4, 8, 10),
            idempotencyKey: 'cmd-1',
          ),
        );

        expect(result.isRight(), isTrue);
        final commandResult = result.getRight().toNullable()!;
        expect(commandResult.status, MatchpointSwipeCommandStatus.processed);
        expect(commandResult.action, MatchpointSwipeAction.like);
        expect(commandResult.targetUserId, 'target-1');
        expect(commandResult.isMatch, isTrue);
        expect(commandResult.conversationId, 'conversation-1');
        expect(commandResult.remainingLikes, 42);
      },
    );

    test('swipe command repository preserves legacy failures', () async {
      final legacyRepository = _FakeLegacyMatchpointRepository()
        ..onSubmitAction = ({required targetUserId, required type}) async =>
            const Left(ServerFailure(message: 'Submit falhou'));

      final container = ProviderContainer(
        overrides: [
          matchpointRepositoryProvider.overrideWithValue(legacyRepository),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(
        matchpointSwipeCommandRepositoryProvider,
      );
      final result = await repository.submit(
        MatchpointSwipeCommand(
          targetUserId: 'target-1',
          action: MatchpointSwipeAction.dislike,
          createdAt: DateTime(2026, 4, 8, 11),
        ),
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()!.message, 'Submit falhou');
    });
  });
}
