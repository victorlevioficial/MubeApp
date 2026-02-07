import 'package:cloud_functions/cloud_functions.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/analytics/analytics_provider.dart';
import 'matchpoint_remote_data_source.dart';

part 'matchpoint_repository.g.dart';

/// Modelo de Match para a camada de domínio
class MatchInfo {
  final String id;
  final String otherUserId;
  final AppUser? otherUser;
  final String? conversationId;
  final DateTime createdAt;

  MatchInfo({
    required this.id,
    required this.otherUserId,
    this.otherUser,
    this.conversationId,
    required this.createdAt,
  });
}

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

      return Right(filtered);
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
        return Left(ServerFailure(message: result.message ?? 'Erro desconhecido'));
      }

      // Se foi um match, logar analytics
      if (result.isMatch == true) {
        await _analytics?.logEvent(
          name: 'match_created',
          parameters: {
            'matched_user_id': targetUserId,
            'source': 'matchpoint',
          },
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
      return Left(ServerFailure(
        message: e.message ?? 'Erro no servidor',
        debugMessage: e.code,
      ));
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
  FutureResult<List<MatchInfo>> fetchMatches(String currentUserId) async {
    try {
      final matchesData = await _dataSource.fetchMatches(currentUserId);
      
      final matches = <MatchInfo>[];
      
      for (final matchData in matchesData) {
        // Determinar qual é o outro usuário
        final userId1 = matchData['user_id_1'] as String;
        final userId2 = matchData['user_id_2'] as String;
        final otherUserId = userId1 == currentUserId ? userId2 : userId1;
        
        // Buscar dados do outro usuário
        final otherUser = await _dataSource.fetchUserById(otherUserId);
        
        matches.add(MatchInfo(
          id: matchData['id'] as String,
          otherUserId: otherUserId,
          otherUser: otherUser,
          conversationId: matchData['conversation_id'] as String?,
          createdAt: (matchData['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
        ));
      }

      return Right(matches);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Busca ranking de hashtags em alta
  FutureResult<List<HashtagRanking>> fetchHashtagRanking({int limit = 20}) async {
    try {
      final hashtags = await _dataSource.fetchHashtagRanking(limit: limit);
      return Right(hashtags);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Busca hashtags por termo de pesquisa
  FutureResult<List<HashtagRanking>> searchHashtags(String query, {int limit = 20}) async {
    try {
      final hashtags = await _dataSource.searchHashtags(query, limit: limit);
      return Right(hashtags);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

@riverpod
MatchpointRepository matchpointRepository(Ref ref) {
  final dataSource = ref.watch(matchpointRemoteDataSourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return MatchpointRepository(dataSource, analytics: analytics);
}
