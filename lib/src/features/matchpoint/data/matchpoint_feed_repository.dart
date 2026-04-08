import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_feed_snapshot.dart';
import 'package:mube/src/utils/app_logger.dart';

import 'matchpoint_remote_data_source.dart';
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

class ProjectedMatchpointFeedRepository implements MatchpointFeedRepository {
  final FirebaseFirestore _firestore;
  final MatchpointRemoteDataSource _remoteDataSource;
  final LegacyMatchpointFeedRepository _legacyRepository;

  ProjectedMatchpointFeedRepository(
    this._firestore,
    this._remoteDataSource,
    this._legacyRepository,
  );

  CollectionReference<Map<String, dynamic>> get _feeds =>
      _firestore.collection(FirestoreCollections.matchpointFeeds);

  CollectionReference<Map<String, dynamic>> get _refreshRequests =>
      _firestore.collection(FirestoreCollections.matchpointFeedRefreshRequests);

  @override
  FutureResult<MatchpointFeedSnapshot> fetchExploreFeed({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    try {
      final projectedFeed = await _readProjectedFeed(
        userId: currentUser.uid,
        limit: limit,
      );

      if (projectedFeed != null) {
        if (projectedFeed.isExpired) {
          unawaited(
            _requestFeedRefresh(currentUser.uid, reason: 'projection_expired'),
          );
        }

        if (projectedFeed.candidateIds.isEmpty && !projectedFeed.isExpired) {
          return Right(
            MatchpointFeedSnapshot(
              candidates: const [],
              fetchedAt: projectedFeed.generatedAt,
              source: MatchpointFeedSource.projectedFeed,
              isServerRanked: true,
            ),
          );
        }

        final usersById = await _remoteDataSource.fetchUsersByIds(
          projectedFeed.candidateIds,
        );
        final excludedIds = {...blockedUsers, currentUser.uid};
        final orderedCandidates = projectedFeed.candidateIds
            .map((userId) => usersById[userId])
            .whereType<AppUser>()
            .where((user) => !excludedIds.contains(user.uid))
            .take(limit)
            .toList(growable: false);

        if (orderedCandidates.isNotEmpty || !projectedFeed.isExpired) {
          return Right(
            MatchpointFeedSnapshot(
              candidates: orderedCandidates,
              fetchedAt: projectedFeed.generatedAt,
              source: MatchpointFeedSource.projectedFeed,
              isServerRanked: true,
            ),
          );
        }
      }

      unawaited(
        _requestFeedRefresh(
          currentUser.uid,
          reason: projectedFeed == null
              ? 'projection_missing'
              : 'projection_stale',
        ),
      );
      return _legacyRepository.fetchExploreFeed(
        currentUser: currentUser,
        genres: genres,
        hashtags: hashtags,
        blockedUsers: blockedUsers,
        limit: limit,
      );
    } on FirebaseException catch (error) {
      return Left(
        ServerFailure(
          message:
              'Nao foi possivel carregar o feed do MatchPoint agora. Tente novamente.',
          debugMessage: error.code,
          originalError: error,
        ),
      );
    } catch (error) {
      return Left(ServerFailure(message: error.toString()));
    }
  }

  Future<_ProjectedFeedDocument?> _readProjectedFeed({
    required String userId,
    required int limit,
  }) async {
    final snapshot = await _feeds.doc(userId).get();
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null) return null;

    final candidateIds = (data['candidate_ids'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .take(limit)
        .toList(growable: false);
    final generatedAt = _readTimestamp(data['generated_at']) ?? DateTime.now();
    final expiresAt = _readTimestamp(data['expires_at']);

    return _ProjectedFeedDocument(
      candidateIds: candidateIds,
      generatedAt: generatedAt,
      expiresAt: expiresAt,
    );
  }

  DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  Future<void> _requestFeedRefresh(
    String userId, {
    required String reason,
  }) async {
    try {
      await _refreshRequests.add({
        'user_id': userId,
        'reason': reason,
        'requested_at': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to request MatchPoint feed refresh.',
        error,
        stackTrace,
        false,
      );
    }
  }
}

final matchpointFeedRepositoryProvider = Provider<MatchpointFeedRepository>((
  ref,
) {
  final legacyRepository = LegacyMatchpointFeedRepository(
    ref.read(matchpointRepositoryProvider),
  );

  return ProjectedMatchpointFeedRepository(
    ref.read(firebaseFirestoreProvider),
    ref.read(matchpointRemoteDataSourceProvider),
    legacyRepository,
  );
});

class _ProjectedFeedDocument {
  final List<String> candidateIds;
  final DateTime generatedAt;
  final DateTime? expiresAt;

  const _ProjectedFeedDocument({
    required this.candidateIds,
    required this.generatedAt,
    required this.expiresAt,
  });

  bool get isExpired {
    final expiresAt = this.expiresAt;
    if (expiresAt == null) return true;
    return expiresAt.isBefore(DateTime.now());
  }
}
