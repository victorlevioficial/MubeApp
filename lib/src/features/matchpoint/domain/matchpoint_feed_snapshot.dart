import 'package:flutter/foundation.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

enum MatchpointFeedSource { legacyQuery, projectedFeed }

@immutable
class MatchpointFeedSnapshot {
  final List<AppUser> candidates;
  final DateTime fetchedAt;
  final MatchpointFeedSource source;
  final bool isServerRanked;

  const MatchpointFeedSnapshot({
    required this.candidates,
    required this.fetchedAt,
    required this.source,
    required this.isServerRanked,
  });

  bool get isEmpty => candidates.isEmpty;
  int get count => candidates.length;
}
