import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command_result.dart';

import 'matchpoint_repository.dart';

abstract class MatchpointSwipeCommandRepository {
  FutureResult<MatchpointSwipeCommandResult> submit(
    MatchpointSwipeCommand command,
  );
}

class LegacyMatchpointSwipeCommandRepository
    implements MatchpointSwipeCommandRepository {
  final MatchpointRepository _legacyRepository;

  LegacyMatchpointSwipeCommandRepository(this._legacyRepository);

  @override
  FutureResult<MatchpointSwipeCommandResult> submit(
    MatchpointSwipeCommand command,
  ) async {
    final result = await _legacyRepository.submitAction(
      targetUserId: command.targetUserId,
      type: command.action.value,
    );

    return result.map(
      (actionResult) => MatchpointSwipeCommandResult.fromLegacyAction(
        command: command,
        actionResult: actionResult,
      ),
    );
  }
}

final matchpointSwipeCommandRepositoryProvider =
    Provider<MatchpointSwipeCommandRepository>((ref) {
      return LegacyMatchpointSwipeCommandRepository(
        ref.read(matchpointRepositoryProvider),
      );
    });
