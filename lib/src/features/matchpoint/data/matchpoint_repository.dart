import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
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

  static const String _submitActionFallbackMessage =
      'Nao foi possivel registrar sua acao agora. Tente novamente.';
  static const String _likesQuotaFallbackMessage =
      'Nao foi possivel consultar seus swipes agora. Tente novamente.';
  static const String _appCheckDebugMessage =
      'App Check de desenvolvimento nao configurado. Cadastre o token de debug no Firebase Console e reabra o app.';
  static const String _appCheckReleaseMessage =
      'Falha de verificacao de seguranca. Feche e abra o app e tente novamente.';

  Failure _mapFunctionsFailure(
    FirebaseFunctionsException error, {
    required String fallbackMessage,
  }) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    final mentionsAppCheck = message.contains('app check');

    if (code == 'resource-exhausted') {
      return QuotaExceededFailure.dailyLikes();
    }
    if (mentionsAppCheck) {
      return const ServerFailure(
        message: kDebugMode ? _appCheckDebugMessage : _appCheckReleaseMessage,
        debugMessage: 'app-check-auth-context-failure',
      );
    }
    if (code == 'unauthenticated') {
      return AuthFailure(
        message: 'Sua sessao expirou. Faca login novamente.',
        debugMessage: 'functions-unauthenticated',
        originalError: error,
      );
    }
    if (code == 'permission-denied') {
      return PermissionFailure.firestore();
    }

    return ServerFailure(
      message: _resolveFunctionsMessage(
        error,
        fallbackMessage: fallbackMessage,
      ),
      debugMessage: code,
      originalError: error,
    );
  }

  String _resolveFunctionsMessage(
    FirebaseFunctionsException error, {
    required String fallbackMessage,
  }) {
    final rawMessage = error.message?.trim();
    if (rawMessage == null || rawMessage.isEmpty) {
      return fallbackMessage;
    }

    final normalizedMessage = rawMessage.toLowerCase();
    final normalizedCode = error.code.toLowerCase();
    const genericMessages = <String>{
      'internal',
      'unknown',
      'internal error',
      'an internal error has occurred',
      'an internal error has occurred.',
      'internal server error',
    };

    final isGenericMessage =
        normalizedMessage == normalizedCode ||
        genericMessages.contains(normalizedMessage) ||
        normalizedMessage.contains('erro interno') ||
        normalizedMessage.contains('internal error');

    return isGenericMessage ? fallbackMessage : rawMessage;
  }

  FutureResult<List<AppUser>> fetchCandidates({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> blockedUsers,
    int limit = 20,
  }) async {
    try {
      final interactedUserIds = await _dataSource.fetchExistingInteractions(
        currentUser.uid,
      );
      final excludedUserIds = {...blockedUsers, ...interactedUserIds}.toList();

      final candidates = await _dataSource.fetchCandidates(
        currentUser: currentUser,
        genres: genres,
        hashtags: hashtags,
        excludedUserIds: excludedUserIds,
        limit: limit,
      );

      if (candidates.isEmpty) return const Right([]);

      // Garantir unicidade local por UID para evitar cards duplicados.
      final seen = <String>{};
      final unique = candidates.where((u) => seen.add(u.uid)).toList();

      return Right(unique);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Submete uma acao de like/dislike via Cloud Function
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
        // Verificar se e erro de quota
        if (result.message?.contains('Limite') == true) {
          return Left(QuotaExceededFailure.dailyLikes());
        }
        return Left(
          ServerFailure(message: result.message ?? 'Erro desconhecido'),
        );
      }

      // Se foi um match, logar analytics
      _trackSubmitActionSuccess(
        targetUserId: targetUserId,
        type: type,
        result: result,
      );

      return Right(result);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        _mapFunctionsFailure(e, fallbackMessage: _submitActionFallbackMessage),
      );
    } catch (e) {
      _trackSubmitActionError(targetUserId: targetUserId, type: type, error: e);
      return Left(ServerFailure(message: e.toString()));
    }
  }

  void _trackSubmitActionSuccess({
    required String targetUserId,
    required String type,
    required MatchpointActionResult result,
  }) {
    final analytics = _analytics;
    if (analytics == null) return;

    if (result.isMatch == true) {
      unawaited(
        analytics
            .logEvent(
              name: 'match_created',
              parameters: {
                'matched_user_id': targetUserId,
                'source': 'matchpoint',
              },
            )
            .catchError((_) {}),
      );
    }

    unawaited(
      analytics
          .logEvent(
            name: 'match_interaction',
            parameters: {
              'target_user_id': targetUserId,
              'action': type,
              'is_match': result.isMatch,
            },
          )
          .catchError((_) {}),
    );
  }

  void _trackSubmitActionError({
    required String targetUserId,
    required String type,
    required Object error,
  }) {
    final analytics = _analytics;
    if (analytics == null) return;

    unawaited(
      analytics
          .logEvent(
            name: 'match_interaction_error',
            parameters: {
              'target_user_id': targetUserId,
              'action': type,
              'error': error.toString(),
            },
          )
          .catchError((_) {}),
    );
  }

  /// Obtem quantidade de likes restantes
  FutureResult<LikesQuotaInfo> getRemainingLikes() async {
    try {
      final quota = await _dataSource.getRemainingLikes();
      return Right(quota);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        _mapFunctionsFailure(e, fallbackMessage: _likesQuotaFallbackMessage),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Busca matches do usuario com dados completos.
  ///
  /// Usa um único lote de queries Firestore (`whereIn` em batches de 30)
  /// para hidratar todos os usuarios de uma vez, em vez de N chamadas
  /// `fetchUserById` paralelas. Essa consolidação reduziu drasticamente
  /// a pressão sobre o Swift Concurrency cooperative pool no iOS, que
  /// causava o crash SIGABRT em swift_task_dealloc /
  /// asyncLet_finish_after_task_completion (Crashlytics issue a37e597a).
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

      final otherUserIds = normalizedMatches
          .map((m) => m['_other_user_id'] as String)
          .toList();

      final usersById = await _dataSource.fetchUsersByIds(otherUserIds);

      final matches = <MatchInfo>[];
      for (int i = 0; i < normalizedMatches.length; i++) {
        final matchData = normalizedMatches[i];
        final otherUserId = otherUserIds[i];
        final otherUser = usersById[otherUserId];
        matches.add(
          MatchInfo(
            id: matchData['id'] as String,
            otherUserId: otherUserId,
            otherUser: otherUser,
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

  /// Busca um usuario pelo ID para abrir o preview detalhado do MatchPoint.
  FutureResult<AppUser?> fetchUserById(String userId) async {
    try {
      final user = await _dataSource.fetchUserById(userId);
      return Right(user);
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
