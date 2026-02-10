import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/match_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/analytics/analytics_provider.dart';
import 'matchpoint_remote_data_source.dart';

part 'matchpoint_repository.g.dart';

class MatchpointRepository {
  final MatchpointRemoteDataSource _dataSource;
  final AnalyticsService? _analytics;

  MatchpointRepository(this._dataSource, {AnalyticsService? analytics})
    : _analytics = analytics;

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

      // Garantir unicidade local por UID para evitar cards duplicados.
      final seen = <String>{};
      final unique = filtered.where((u) => seen.add(u.uid)).toList();

      return Right(unique);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Submete uma ação de like/dislike via Cloud Function
  FutureResult<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String type, // 'like' or 'dislike'
  }) async {
    try {
      final result = await _dataSource.submitAction(
        targetUserId: targetUserId,
        action: type,
      );

      if (!result.success) {
        // Verificar se é erro de quota
        if (result.message?.contains('Limite') == true) {
          return Left(QuotaExceededFailure.dailyLikes());
        }
        return Left(
          ServerFailure(message: result.message ?? 'Erro desconhecido'),
        );
      }

      // Se foi um match, logar analytics
      if (result.isMatch == true) {
        await _analytics?.logEvent(
          name: 'match_created',
          parameters: {'matched_user_id': targetUserId, 'source': 'matchpoint'},
        );
      }

      // Logar interação
      await _analytics?.logEvent(
        name: 'match_interaction',
        parameters: {
          'target_user_id': targetUserId,
          'action': type,
          'is_match': result.isMatch,
        },
      );

      return Right(result);
    } on FirebaseFunctionsException catch (e) {
      // Tratar erros específicos do Firebase Functions
      if (e.code == 'resource-exhausted') {
        return Left(QuotaExceededFailure.dailyLikes());
      }
      if (e.code == 'permission-denied') {
        return Left(PermissionFailure.firestore());
      }
      return Left(
        ServerFailure(
          message: e.message ?? 'Erro no servidor',
          debugMessage: e.code,
        ),
      );
    } catch (e) {
      await _analytics?.logEvent(
        name: 'match_interaction_error',
        parameters: {
          'target_user_id': targetUserId,
          'action': type,
          'error': e.toString(),
        },
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Obtém quantidade de likes restantes
  FutureResult<LikesQuotaInfo> getRemainingLikes() async {
    try {
      final quota = await _dataSource.getRemainingLikes();
      return Right(quota);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Busca matches do usuário com dados completos
  /// Usa Future.wait para paralelizar busca de usuários
  FutureResult<List<MatchInfo>> fetchMatches(String currentUserId) async {
    try {
      final matchesData = await _dataSource.fetchMatches(currentUserId);

      final normalizedMatches = <Map<String, dynamic>>[];
      for (final matchData in matchesData) {
        final otherUserId = _extractOtherUserId(matchData, currentUserId);
        if (otherUserId == null) continue;

        normalizedMatches.add({...matchData, '_other_user_id': otherUserId});
      }

      if (normalizedMatches.isEmpty) return const Right([]);

      // Paralelizar busca de usuários (ao invés de sequencial N+1)
      final otherUserIds = normalizedMatches
          .map((m) => m['_other_user_id'] as String)
          .toList();

      final userFutures = otherUserIds.map(
        (id) => _dataSource.fetchUserById(id),
      );
      final users = await Future.wait(userFutures);

      final matches = <MatchInfo>[];
      for (int i = 0; i < normalizedMatches.length; i++) {
        final matchData = normalizedMatches[i];
        matches.add(
          MatchInfo(
            id: matchData['id'] as String,
            otherUserId: otherUserIds[i],
            otherUser: users[i],
            conversationId: matchData['conversation_id'] as String?,
            createdAt:
                (matchData['created_at'] as Timestamp?)?.toDate() ??
                DateTime.now(),
          ),
        );
      }

      return Right(matches);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Busca ranking de hashtags em alta
  FutureResult<List<HashtagRanking>> fetchHashtagRanking({
    int limit = 20,
  }) async {
    try {
      final hashtags = await _dataSource.fetchHashtagRanking(limit: limit);
      return Right(hashtags);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Busca hashtags por termo de pesquisa
  FutureResult<List<HashtagRanking>> searchHashtags(
    String query, {
    int limit = 20,
  }) async {
    try {
      final hashtags = await _dataSource.searchHashtags(query, limit: limit);
      return Right(hashtags);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Salva o perfil do matchpoint diretamente pelo repository
  FutureResult<void> saveProfile({
    required String userId,
    required String intent,
    required List<String> musicalGenres,
    required List<String> hashtags,
    required bool isPublic,
  }) async {
    try {
      final profileData = {
        FirestoreFields.intent: intent,
        FirestoreFields.musicalGenres: musicalGenres,
        FirestoreFields.hashtags: hashtags,
        FirestoreFields.isActive: true,
        'is_public': isPublic,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _dataSource.saveProfile(userId: userId, profileData: profileData);

      await _analytics?.logEvent(
        name: 'matchpoint_profile_saved',
        parameters: {
          'intent': intent,
          'genre_count': musicalGenres.length,
          'hashtag_count': hashtags.length,
        },
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  String? _extractOtherUserId(
    Map<String, dynamic> matchData,
    String currentUserId,
  ) {
    final userIds = matchData['user_ids'];
    if (userIds is List) {
      final ids = userIds.whereType<String>().toList();
      if (ids.length >= 2 && ids.contains(currentUserId)) {
        final otherId = ids.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );
        if (otherId.isNotEmpty) return otherId;
      }
    }

    final uid1 = matchData['user_id_1'] as String?;
    final uid2 = matchData['user_id_2'] as String?;
    if (uid1 == null || uid2 == null) return null;

    return uid1 == currentUserId ? uid2 : uid1;
  }
}

@riverpod
MatchpointRepository matchpointRepository(Ref ref) {
  final dataSource = ref.watch(matchpointRemoteDataSourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return MatchpointRepository(dataSource, analytics: analytics);
}
