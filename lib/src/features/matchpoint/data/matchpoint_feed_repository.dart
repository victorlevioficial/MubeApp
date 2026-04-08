import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_feed_snapshot.dart';

import 'matchpoint_repository.dart';

abstract class MatchpointFeedRepository {
  FutureResult<MatchpointFeedSnapshot> fetchExploreFeed({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  });
}

class LegacyMatchpointFeedRepository implements MatchpointFeedRepository {
  final MatchpointRepository _legacyRepository;

  LegacyMatchpointFeedRepository(this._legacyRepository);

  @override
  FutureResult<MatchpointFeedSnapshot> fetchExploreFeed({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    final result = await _legacyRepository.fetchCandidates(
      currentUser: currentUser,
      genres: genres,
      hashtags: hashtags,
      blockedUsers: blockedUsers,
      limit: limit,
    );

    return result.map(
      (candidates) => MatchpointFeedSnapshot(
        candidates: candidates,
        fetchedAt: DateTime.now(),
        source: MatchpointFeedSource.legacyQuery,
        isServerRanked: false,
      ),
    );
  }
}

final matchpointFeedRepositoryProvider = Provider<MatchpointFeedRepository>((
  ref,
) {
  return LegacyMatchpointFeedRepository(ref.read(matchpointRepositoryProvider));
});
