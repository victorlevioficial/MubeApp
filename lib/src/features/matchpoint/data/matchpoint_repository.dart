import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'matchpoint_remote_data_source.dart';

part 'matchpoint_repository.g.dart';

class MatchpointRepository {
  final MatchpointRemoteDataSource _dataSource;

  MatchpointRepository(this._dataSource);

  FutureResult<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    try {
      final candidates = await _dataSource.fetchCandidates(
        currentUserId: currentUserId,
        genres: genres,
        excludedUserIds: blockedUsers,
        limit: limit,
      );

      // Filter out existing interactions (client-side for now)
      if (candidates.isEmpty) return const Right([]);

      final existingIds = await _dataSource.fetchExistingInteractions(
        currentUserId,
      );
      final filtered = candidates
          .where((u) => !existingIds.contains(u.uid))
          .toList();

      return Right(filtered);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<bool> saveInteraction({
    required String currentUserId,
    required String targetUserId,
    required String type, // 'like' or 'dislike'
  }) async {
    try {
      await _dataSource.saveInteraction(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
        type: type,
      );

      bool isMatch = false;
      if (type == 'like') {
        isMatch = await _dataSource.checkMutualLike(
          currentUserId,
          targetUserId,
        );
        if (isMatch) {
          await _dataSource.createMatch(currentUserId, targetUserId);
        }
      }

      return Right(isMatch);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

@riverpod
MatchpointRepository matchpointRepository(Ref ref) {
  final dataSource = ref.watch(matchpointRemoteDataSourceProvider);
  return MatchpointRepository(dataSource);
}
