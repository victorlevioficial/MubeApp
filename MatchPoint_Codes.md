# Feature MatchPoint - Códigos Completos

Este documento contém todo o código fonte da feature MatchPoint, organizado por pastas e arquivos.

---

pasta: data / arquivo: matchpoint_remote_data_source.dart
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../../../constants/firestore_constants.dart';

/// Resultado de uma ação no Matchpoint
class MatchpointActionResult {
  final bool success;
  final bool isMatch;
  final String? matchId;
  final String? conversationId;
  final int? remainingLikes;
  final String? message;

  MatchpointActionResult({
    required this.success,
    this.isMatch = false,
    this.matchId,
    this.conversationId,
    this.remainingLikes,
    this.message,
  });

  factory MatchpointActionResult.fromJson(Map<String, dynamic> json) {
    return MatchpointActionResult(
      success: json['success'] ?? false,
      isMatch: json['isMatch'] ?? false,
      matchId: json['matchId'],
      conversationId: json['conversationId'],
      remainingLikes: json['remainingLikes'],
      message: json['message'],
    );
  }
}

/// Informações de quota de likes
class LikesQuotaInfo {
  final int remaining;
  final int limit;
  final DateTime resetTime;

  LikesQuotaInfo({
    required this.remaining,
    required this.limit,
    required this.resetTime,
  });

  factory LikesQuotaInfo.fromJson(Map<String, dynamic> json) {
    return LikesQuotaInfo(
      remaining: json['remaining'] ?? 0,
      limit: json['limit'] ?? 50,
      resetTime: DateTime.parse(json['resetTime']),
    );
  }
}

abstract class MatchpointRemoteDataSource {
  Future<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> excludedUserIds, // Blocked users
    int limit = 50,
  });

  /// Submete uma ação (like/dislike) via Cloud Function
  Future<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String action, // 'like' or 'dislike'
  });

  /// Busca interações existentes (para filtrar candidatos)
  Future<List<String>> fetchExistingInteractions(String currentUserId);

  /// Obtém informações de quota de likes restantes
  Future<LikesQuotaInfo> getRemainingLikes();

  /// Busca matches do usuário atual
  Future<List<Map<String, dynamic>>> fetchMatches(String currentUserId);

  /// Busca usuário por ID
  Future<AppUser?> fetchUserById(String userId);

  /// Busca ranking de hashtags em alta
  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20});

  /// Busca hashtags por termo de pesquisa
  Future<List<HashtagRanking>> searchHashtags(String query, {int limit = 20});
}

class MatchpointRemoteDataSourceImpl implements MatchpointRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  MatchpointRemoteDataSourceImpl(this._firestore, this._functions);

  @override
  Future<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> excludedUserIds,
    int limit = 20,
  }) async {
    // 1. Basic filtering in Firestore
    Query query = _firestore.collection(FirestoreCollections.users);

    // Active users only
    query = query.where(
      '${FirestoreFields.matchpointProfile}.${FirestoreFields.isActive}',
      isEqualTo: true,
    );

    // Filter by Genre (Array Contains Any)
    if (genres.isNotEmpty) {
      query = query.where(
        '${FirestoreFields.matchpointProfile}.${FirestoreFields.musicalGenres}',
        arrayContainsAny: genres
            .take(10)
            .toList(), // Limit 10 for 'in/array-contains-any'
      );
    }

    final snapshot = await query.limit(limit).get();

    // 2. Map to AppUser and filter blocked users
    return snapshot.docs
        .where(
          (doc) => doc.id != currentUserId && !excludedUserIds.contains(doc.id),
        )
        .map((doc) => AppUser.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String action,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitMatchpointAction');

      final result = await callable.call({
        'targetUserId': targetUserId,
        'action': action,
      });

      return MatchpointActionResult.fromJson(result.data as Map<String, dynamic>);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error(
        'submitMatchpointAction falhou: code=${e.code}, message=${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchExistingInteractions(String currentUserId) async {
    // Buscar da coleção global de interactions (não mais subcoleção)
    final snapshot = await _firestore
        .collection(FirestoreCollections.interactions)
        .where('source_user_id', isEqualTo: currentUserId)
        .where('type', whereIn: ['like', 'dislike'])
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['target_user_id'] as String)
        .toList();
  }

  @override
  Future<LikesQuotaInfo> getRemainingLikes() async {
    try {
      final callable = _functions.httpsCallable('getRemainingLikes');

      final result = await callable.call();

      return LikesQuotaInfo.fromJson(result.data as Map<String, dynamic>);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error(
        'getRemainingLikes falhou: code=${e.code}, message=${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMatches(String currentUserId) async {
    // Buscar matches onde o usuário é user_id_1 ou user_id_2
    final [matches1, matches2] = await Future.wait([
      _firestore
          .collection(FirestoreCollections.matches)
          .where('user_id_1', isEqualTo: currentUserId)
          .orderBy('created_at', descending: true)
          .get(),
      _firestore
          .collection(FirestoreCollections.matches)
          .where('user_id_2', isEqualTo: currentUserId)
          .orderBy('created_at', descending: true)
          .get(),
    ]);

    final allMatches = [
      ...matches1.docs.map((d) => {...d.data(), 'id': d.id}),
      ...matches2.docs.map((d) => {...d.data(), 'id': d.id}),
    ];

    // Ordenar por data de criação
    allMatches.sort((a, b) {
      final aTime = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      final bTime = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    return allMatches;
  }

  @override
  Future<AppUser?> fetchUserById(String userId) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(userId)
        .get();

    if (!doc.exists) return null;

    return AppUser.fromJson(doc.data() as Map<String, dynamic>);
  }

  @override
  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20}) async {
    try {
      final callable = _functions.httpsCallable('getTrendingHashtags');

      final result = await callable.call({
        'limit': limit,
        'includeAll': false,
      });

      final data = result.data as Map<String, dynamic>;
      final hashtags = data['hashtags'] as List<dynamic>? ?? [];

      return hashtags
          .map((h) => HashtagRanking.fromCloudFunction(h as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('Falha ao buscar trending via Function. Fallback Firestore: $e');

      final snapshot = await _firestore
          .collection('hashtagRanking')
          .orderBy('use_count', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(HashtagRanking.fromFirestore).toList();
    }
  }

  @override
  Future<List<HashtagRanking>> searchHashtags(String query, {int limit = 20}) async {
    try {
      final callable = _functions.httpsCallable('searchHashtags');

      final result = await callable.call({
        'query': query,
        'limit': limit,
      });

      final data = result.data as Map<String, dynamic>;
      final hashtags = data['hashtags'] as List<dynamic>? ?? [];

      return hashtags
          .map((h) => HashtagRanking.fromCloudFunction(h as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.warning('Falha ao buscar hashtag via Function. Fallback Firestore: $e');

      final normalized = query.toLowerCase().trim();
      if (normalized.length < 2) return [];

      final snapshot = await _firestore
          .collection('hashtagRanking')
          .where('hashtag', isGreaterThanOrEqualTo: normalized)
          .where('hashtag', isLessThanOrEqualTo: '$normalized\uf8ff')
          .orderBy('hashtag')
          .orderBy('use_count', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(HashtagRanking.fromFirestore).toList();
    }
  }
}

final matchpointRemoteDataSourceProvider = Provider<MatchpointRemoteDataSource>(
  (ref) {
    return MatchpointRemoteDataSourceImpl(
      FirebaseFirestore.instance,
      FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
    );
  },
);
```

---

pasta: data / arquivo: matchpoint_repository.dart
```dart
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
```

---

pasta: domain / arquivo: hashtag_ranking.dart
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'hashtag_ranking.freezed.dart';
part 'hashtag_ranking.g.dart';

/// Modelo de ranking de hashtags para o Matchpoint
@freezed
abstract class HashtagRanking with _$HashtagRanking {
  const factory HashtagRanking({
    required String id,
    required String hashtag,
    required String displayName,
    required int useCount,
    required int currentPosition,
    required int previousPosition,
    required String trend,
    required int trendDelta,
    required bool isTrending,
    @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
    required Timestamp lastUpdated,
  }) = _HashtagRanking;

  factory HashtagRanking.fromJson(Map<String, dynamic> json) =>
      _$HashtagRankingFromJson(json);

  /// Cria a partir de um documento do Firestore
  factory HashtagRanking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HashtagRanking(
      id: doc.id,
      hashtag: data['hashtag'] as String? ?? '',
      displayName: data['display_name'] as String? ?? data['hashtag'] as String? ?? '',
      useCount: data['use_count'] as int? ?? 0,
      currentPosition: data['current_position'] as int? ?? 0,
      previousPosition: data['previous_position'] as int? ?? 0,
      trend: data['trend'] as String? ?? 'stable',
      trendDelta: data['trend_delta'] as int? ?? 0,
      isTrending: data['is_trending'] as bool? ?? false,
      lastUpdated: data['updated_at'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Cria a partir da resposta da Cloud Function
  factory HashtagRanking.fromCloudFunction(Map<String, dynamic> data) {
    return HashtagRanking(
      id: data['id'] as String? ?? '',
      hashtag: data['hashtag'] as String? ?? '',
      displayName: data['display_name'] as String? ?? data['hashtag'] as String? ?? '',
      useCount: data['use_count'] as int? ?? 0,
      currentPosition: data['current_position'] as int? ?? 0,
      previousPosition: data['previous_position'] as int? ?? 0,
      trend: data['trend'] as String? ?? 'stable',
      trendDelta: data['trend_delta'] as int? ?? 0,
      isTrending: data['is_trending'] as bool? ?? false,
      lastUpdated: Timestamp.now(),
    );
  }
}

/// Converte Timestamp do Firestore para o formato JSON
Timestamp _timestampFromJson(dynamic json) => json as Timestamp;

/// Converte Timestamp para o formato JSON
dynamic _timestampToJson(Timestamp timestamp) => timestamp;

/// Extensão para facilitar o uso do model
extension HashtagRankingX on HashtagRanking {
  /// Retorna a mudança de posição (positivo = subiu, negativo = desceu)
  int get positionChange => previousPosition - currentPosition;

  /// Retorna se subiu no ranking
  bool get isUp => trend == 'up';

  /// Retorna se desceu no ranking
  bool get isDown => trend == 'down';

  /// Retorna se manteve posição
  bool get isStable => trend == 'stable';

  /// Retorna o emoji de tendência
  String get trendEmoji {
    if (isUp) return '↑';
    if (isDown) return '↓';
    return '→';
  }

  /// Retorna a cor da tendência (para uso no UI)
  String get trendColor {
    if (isUp) return 'success';
    if (isDown) return 'error';
    return 'neutral';
  }
}
```

---

pasta: presentation/controllers / arquivo: matchpoint_controller.dart
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_remote_data_source.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failures.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

part 'matchpoint_controller.g.dart';

@riverpod
class MatchpointController extends _$MatchpointController {
  @override
  FutureOr<void> build() async {
    // Inicialização se necessário
  }

  /// Salva as configurações de perfil do Matchpoint
  Future<bool> saveProfile({
    required String intent,
    required List<String> musicalGenres,
    required List<String> hashtags,
    required bool isPublic,
  }) async {
    state = const AsyncLoading();

    final user = ref.read(authControllerProvider).value;
    if (user == null) return false;

    state = await AsyncValue.guard(() async {
      final repository = ref.read(matchpointRepositoryProvider);
      
      // Criar o objeto de perfil
      final profile = {
        'intent': intent,
        'musical_genres': musicalGenres,
        'hashtags': hashtags,
        'is_active': true,
        'is_public': isPublic,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Salvar no Firestore via Repository/DataSource
      // NOTA: Implementar no Repository se ainda não existir
      // Por enquanto, atualiza via AuthController indiretamente
      await ref.read(authControllerProvider.notifier).updateUserData({
        'matchpoint_profile': profile,
      });
    });

    return !state.hasError;
  }

  /// Submete uma ação de like/dislike
  Future<MatchpointActionResult?> submitAction({
    required String targetUserId,
    required String action,
  }) async {
    final repository = ref.read(matchpointRepositoryProvider);
    final result = await repository.submitAction(
      targetUserId: targetUserId,
      type: action,
    );

    return result.fold(
      (failure) {
        // Se for erro de quota, atualizar o provider de quota
        if (failure is QuotaExceededFailure) {
           ref.invalidate(likesQuotaProvider);
        }
        return null;
      },
      (success) {
        // Atualizar quota de likes localmente
        ref.invalidate(likesQuotaProvider);
        
        // Se for um match, invalidar lista de matches
        if (success.isMatch) {
          ref.invalidate(matchesProvider);
        }

        // Adicionar ao histórico local
        ref.read(swipeHistoryProvider.notifier).addEntry(
          targetUserId: targetUserId,
          action: action,
        );

        return success;
      },
    );
  }
}

/// Provider para gerenciar a quota de likes diários
@riverpod
class LikesQuota extends _$LikesQuota {
  @override
  Future<LikesQuotaInfo> build() async {
    final repository = ref.watch(matchpointRepositoryProvider);
    final result = await repository.getRemainingLikes();
    
    return result.fold(
      (l) => throw l,
      (r) => r,
    );
  }

  bool get hasReachedLimit {
    if (!state.hasValue) return false;
    return state.value!.remaining <= 0;
  }

  int get remaining => state.value?.remaining ?? 0;
  int get limit => state.value?.limit ?? 50;
}

/// Provider para candidatos a match
@riverpod
class MatchpointCandidates extends _$MatchpointCandidates {
  @override
  Future<List<AppUser>> build() async {
    final user = ref.watch(authControllerProvider).value;
    if (user == null || user.matchpointProfile == null) return [];

    final repository = ref.watch(matchpointRepositoryProvider);
    
    // Pegar lista de bloqueados/excluídos (opcional)
    final blockedUsers = <String>[]; 

    final result = await repository.fetchCandidates(
      currentUserId: user.uid,
      genres: user.matchpointProfile!.musicalGenres,
      blockedUsers: blockedUsers,
    );

    return result.fold(
      (l) => throw l,
      (r) => r,
    );
  }

  /// Remove um candidato da lista local após swipe
  void removeCandidate(String userId) {
    if (!state.hasValue) return;
    
    final currentList = state.value!;
    state = AsyncValue.data(
      currentList.where((u) => u.uid != userId).toList(),
    );
  }
}

/// Provider para matches do usuário
@riverpod
Future<List<MatchInfo>> matches(Ref ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return [];

  final repository = ref.watch(matchpointRepositoryProvider);
  final result = await repository.fetchMatches(user.uid);

  return result.fold(
    (l) => throw l,
    (r) => r,
  );
}

/// Provider para o ranking de hashtags
@riverpod
Future<List<HashtagRanking>> hashtagRanking(Ref ref) async {
  final repository = ref.watch(matchpointRepositoryProvider);
  final result = await repository.fetchHashtagRanking();

  return result.fold(
    (l) => throw l,
    (r) => r,
  );
}

/// Provider para busca de hashtags
@riverpod
Future<List<HashtagRanking>> hashtagSearch(Ref ref, String query) async {
  if (query.isEmpty) return [];
  
  final repository = ref.watch(matchpointRepositoryProvider);
  final result = await repository.searchHashtags(query);

  return result.fold(
    (l) => throw l,
    (r) => r,
  );
}

/// Modelo simples para histórico de swipes local
class SwipeHistoryEntry {
  final String targetUserId;
  final String action;
  final DateTime timestamp;

  SwipeHistoryEntry({
    required this.targetUserId,
    required this.action,
    required this.timestamp,
  });
}

/// Provider para histórico de swipes da sessão atual
@riverpod
class SwipeHistory extends _$SwipeHistory {
  @override
  List<SwipeHistoryEntry> build() => [];

  void addEntry({required String targetUserId, required String action}) {
    state = [
      SwipeHistoryEntry(
        targetUserId: targetUserId,
        action: action,
        timestamp: DateTime.now(),
      ),
      ...state,
    ];
  }
}
```

---

pasta: presentation/screens / arquivo: hashtag_ranking_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/shared/widgets/app_app_bar.dart';
import 'package:mube/src/shared/widgets/skeleton_shimmer.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:intl/intl.dart';

class HashtagRankingScreen extends ConsumerWidget {
  const HashtagRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(hashtagRankingProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Trending Hashtags',
        showBackButton: true,
      ),
      body: rankingAsync.when(
        data: (hashtags) => _buildList(context, hashtags),
        loading: () => _buildLoading(),
        error: (err, stack) => _buildError(context, ref),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<HashtagRanking> hashtags) {
    if (hashtags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.tag_rounded, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Nenhuma hashtag em alta no momento',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(hashtagRankingProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s16),
        itemCount: hashtags.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          final item = hashtags[index];
          return _HashtagRankTile(hashtag: item, rank: index + 1);
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: 10,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
        child: SkeletonShimmer(
          height: 80,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.s16),
          const Text('Erro ao carregar ranking'),
          TextButton(
            onPressed: () => ref.refresh(hashtagRankingProvider),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _HashtagRankTile extends StatelessWidget {
  final HashtagRanking hashtag;
  final int rank;

  const _HashtagRankTile({required this.hashtag, required this.rank});

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatter = NumberFormat.compact();
    
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTypography.titleMedium.copyWith(
                  color: _getRankColor(rank),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hashtag.displayName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${formatter.format(hashtag.useCount)} posts',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _buildTrendIndicator(),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator() {
    Color color;
    IconData icon;
    String label = '';

    if (hashtag.isUp) {
      color = AppColors.success;
      icon = Icons.trending_up_rounded;
      label = '+${hashtag.trendDelta}';
    } else if (hashtag.isDown) {
      color = AppColors.error;
      icon = Icons.trending_down_rounded;
      label = '-${hashtag.trendDelta}';
    } else {
      color = AppColors.textTertiary;
      icon = Icons.remove_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(icon, color: color, size: 20),
        if (label.isNotEmpty)
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFD700); // Gold
    if (rank == 2) return const Color(0xFFC0C0C0); // Silver
    if (rank == 3) return const Color(0xFFCD7F32); // Bronze
    return AppColors.primary;
  }
}
```

---

pasta: presentation/screens / arquivo: match_success_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/shared/widgets/app_button.dart';
import 'package:mube/src/shared/widgets/user_avatar.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:mube/src/constants/app_radius.dart';
import '../widgets/confetti_overlay.dart';

class MatchSuccessScreen extends StatefulWidget {
  final AppUser matchedUser;
  final String? conversationId;

  const MatchSuccessScreen({
    super.key,
    required this.matchedUser,
    this.conversationId,
  });

  @override
  State<MatchSuccessScreen> createState() => _MatchSuccessScreenState();
}

class _MatchSuccessScreenState extends State<MatchSuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: Stack(
        children: [
          // Efeito de Confete
          const ConfettiOverlay(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      children: [
                        Text(
                          "It's a Match!",
                          style: AppTypography.displayMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Você e ${widget.matchedUser.displayName} se curtiram!',
                          style: AppTypography.bodyLarge.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s48),
                  
                  // Avatares lado a lado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatar(widget.matchedUser.photoUrl),
                    ],
                  ),
                  
                  const SizedBox(height: AppSpacing.s64),
                  
                  AppButton(
                    text: 'Enviar Mensagem',
                    onPressed: () {
                      if (widget.conversationId != null) {
                        context.pop(); // Fecha modal
                        context.push('/chat/${widget.conversationId}');
                      } else {
                        context.pop();
                      }
                    },
                    variant: AppButtonVariant.primary,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  AppButton(
                    text: 'Continuar Explorando',
                    onPressed: () => context.pop(),
                    variant: AppButtonVariant.outline,
                  ),
                ],
              ),
            ),
          ),
          
          // Botão de fechar
          Positioned(
            top: AppSpacing.s16,
            right: AppSpacing.s16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: UserAvatar(
        url: url,
        size: 120,
      ),
    );
  }
}
```

---

pasta: presentation/screens / arquivo: matchpoint_explore_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/match_swipe_deck.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/matchpoint_tutorial_overlay.dart';
import 'package:mube/src/shared/widgets/skeleton_shimmer.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_success_screen.dart';

class MatchpointExploreScreen extends ConsumerStatefulWidget {
  const MatchpointExploreScreen({super.key});

  @override
  ConsumerState<MatchpointExploreScreen> createState() => _MatchpointExploreScreenState();
}

class _MatchpointExploreScreenState extends ConsumerState<MatchpointExploreScreen> {
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('matchpoint_tutorial_seen') ?? false;
    if (!hasSeenTutorial) {
      if (mounted) setState(() => _showTutorial = true);
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('matchpoint_tutorial_seen', true);
    if (mounted) setState(() => _showTutorial = false);
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(matchpointCandidatesProvider);

    return Scaffold(
      body: Stack(
        children: [
          candidatesAsync.when(
            data: (candidates) {
              if (candidates.isEmpty) {
                return _buildEmptyState();
              }
              return MatchSwipeDeck(
                candidates: candidates,
                onMatch: (matchedUser, conversationId) {
                  _showMatchSuccess(context, matchedUser, conversationId);
                },
              );
            },
            loading: () => _buildLoadingState(),
            error: (err, stack) => _buildErrorState(),
          ),
          
          if (_showTutorial)
            MatchpointTutorialOverlay(onDismiss: _dismissTutorial),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.s24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Fim dos candidatos',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Você já viu todos os perfis compatíveis por agora. Tente mudar seus interesses ou volte mais tarde!',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s32),
            ElevatedButton.icon(
              onPressed: () => ref.refresh(matchpointCandidatesProvider),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Recarregar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: SkeletonShimmer(
          height: MediaQuery.of(context).size.height * 0.7,
          width: double.infinity,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.s16),
          const Text('Ocorreu um erro ao carregar candidatos'),
          TextButton(
            onPressed: () => ref.refresh(matchpointCandidatesProvider),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  void _showMatchSuccess(BuildContext context, dynamic matchedUser, String? conversationId) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) {
        return MatchSuccessScreen(
          matchedUser: matchedUser,
          conversationId: conversationId,
        );
      },
    );
  }
}
```

---

pasta: presentation/screens / arquivo: matchpoint_intro_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/shared/widgets/app_button.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:mube/src/routing/app_router.dart';

class MatchpointIntroScreen extends StatelessWidget {
  const MatchpointIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.s32),
              Text(
                'Bem-vindo ao MatchPoint',
                style: AppTypography.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Encontre músicos e artistas que compartilham seu estilo e paixão. Dê match e comece a criar juntos!',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s64),
              AppButton(
                text: 'Começar Configuração',
                onPressed: () => context.push(RoutePaths.matchpointWizard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

pasta: presentation/screens / arquivo: matchpoint_matches_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/shared/widgets/user_avatar.dart';
import 'package:mube/src/shared/widgets/skeleton_shimmer.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:intl/intl.dart';

class MatchpointMatchesScreen extends ConsumerWidget {
  const MatchpointMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);

    return Scaffold(
      body: matchesAsync.when(
        data: (matches) => _buildMatchesList(context, ref, matches),
        loading: () => _buildLoadingList(),
        error: (err, stack) => _buildErrorState(ref),
      ),
    );
  }

  Widget _buildMatchesList(BuildContext context, WidgetRef ref, List<MatchInfo> matches) {
    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Ainda nenhum match',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Continue explorando para encontrar pessoas!',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(matchesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.s16),
        itemCount: matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          final match = matches[index];
          return _MatchTile(match: match);
        },
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
        child: SkeletonShimmer(
          height: 80,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
          const SizedBox(height: AppSpacing.s16),
          const Text('Erro ao carregar seus matches'),
          TextButton(
            onPressed: () => ref.refresh(matchesProvider),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchInfo match;

  const _MatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final user = match.otherUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.s12),
        leading: UserAvatar(url: user.photoUrl, size: 56),
        title: Text(
          user.displayName ?? 'Usuário',
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.matchpointProfile?.intent ?? 'Músico',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              'Match em ${DateFormat('dd/MM/yy').format(match.createdAt)}',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        onTap: () {
          if (match.conversationId != null) {
            context.push('/chat/${match.conversationId}');
          }
        },
      ),
    );
  }
}
```

---

pasta: presentation/screens / arquivo: matchpoint_setup_wizard_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/shared/widgets/app_button.dart';
import 'package:mube/src/shared/widgets/app_text_field.dart';
import 'package:mube/src/shared/widgets/app_filter_chip.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';

import '../../auth/presentation/controllers/auth_controller.dart';

class MatchpointSetupWizardScreen extends ConsumerStatefulWidget {
  const MatchpointSetupWizardScreen({super.key});

  @override
  ConsumerState<MatchpointSetupWizardScreen> createState() => _MatchpointSetupWizardScreenState();
}

class _MatchpointSetupWizardScreenState extends ConsumerState<MatchpointSetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form State
  String _selectedIntent = '';
  final List<String> _selectedGenres = [];
  final List<String> _hashtags = [];
  bool _isPublic = true;
  final TextEditingController _hashtagController = TextEditingController();

  final List<String> _genreOptions = [
    'Rock', 'Pop', 'Jazz', 'Blues', 'Metal', 'Funk', 'MPB', 'Sertanejo',
    'Rap', 'Hip Hop', 'Eletrônica', 'Clássica', 'Reggae', 'Indie', 'Punk'
  ];

  final List<Map<String, dynamic>> _intentOptions = [
    {'id': 'jam', 'label': 'Fazer uma Jam', 'icon': Icons.music_note_rounded},
    {'id': 'band', 'label': 'Montar uma Banda', 'icon': Icons.groups_rounded},
    {'id': 'collab', 'label': 'Colaboração Online', 'icon': Icons.public_rounded},
    {'id': 'lessons', 'label': 'Dar/Receber Aulas', 'icon': Icons.school_rounded},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-populando se já existir perfil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      if (user?.matchpointProfile != null) {
        final p = user!.matchpointProfile!;
        setState(() {
          _selectedIntent = p.intent;
          _selectedGenres.addAll(p.musicalGenres);
          _hashtags.addAll(p.hashtags ?? []);
          _isPublic = p.isVisible;
        });
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.pop();
    }
  }

  Future<void> _saveProfile() async {
    final success = await ref.read(matchpointControllerProvider.notifier).saveProfile(
      intent: _selectedIntent,
      musicalGenres: _selectedGenres,
      hashtags: _hashtags,
      isPublic: _isPublic,
    );

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(matchpointControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              children: [
                _buildIntentStep(),
                _buildGenreStep(),
                _buildHashtagStep(),
                _buildPrivacyStep(),
              ],
            ),
          ),
          _buildNavigation(isSaving),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentStep + 1) / _totalSteps,
      backgroundColor: AppColors.outlineVariant,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
    );
  }

  Widget _buildStepHeader({required IconData icon, required String title, required String subtitle}) {
    return Column(
      children: [
        Icon(icon, size: 48, color: AppColors.primary),
        const SizedBox(height: AppSpacing.s16),
        Text(title, style: AppTypography.headlineLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.s8),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIntentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        children: [
          _buildStepHeader(
            icon: Icons.rocket_launch_rounded,
            title: 'Qual seu objetivo?',
            subtitle: 'Isso nos ajuda a encontrar pessoas com a mesma intenção que você.',
          ),
          const SizedBox(height: AppSpacing.s32),
          ..._intentOptions.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: InkWell(
              onTap: () => setState(() => _selectedIntent = opt['id']),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s20),
                decoration: BoxDecoration(
                  color: _selectedIntent == opt['id'] 
                    ? AppColors.primary.withValues(alpha: 0.1) 
                    : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedIntent == opt['id'] 
                      ? AppColors.primary 
                      : AppColors.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(opt['icon'], color: _selectedIntent == opt['id'] ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.s16),
                    Text(
                      opt['label'],
                      style: AppTypography.titleMedium.copyWith(
                        color: _selectedIntent == opt['id'] ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedIntent == opt['id'])
                      const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGenreStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        children: [
          _buildStepHeader(
            icon: Icons.music_note_rounded,
            title: 'Seus Gêneros Musicais',
            subtitle: 'Escolha até 5 estilos que definem sua sonoridade.',
          ),
          const SizedBox(height: AppSpacing.s32),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _genreOptions.map((genre) {
              final isSelected = _selectedGenres.contains(genre);
              return AppFilterChip(
                label: genre,
                isSelected: isSelected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      if (_selectedGenres.length < 5) _selectedGenres.add(genre);
                    } else {
                      _selectedGenres.remove(genre);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        children: [
          _buildStepHeader(
            icon: Icons.tag_rounded,
            title: 'Hashtags e Tags',
            subtitle: 'Adicione termos específicos como instrumentos ou influências.',
          ),
          const SizedBox(height: AppSpacing.s24),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _hashtagController,
                  hintText: 'Ex: #guitarra, #pinkfloyd',
                  onSubmitted: (val) => _addHashtag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addHashtag,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hashtags.map((tag) => Chip(
              label: Text(tag, style: AppTypography.labelMedium),
              onDeleted: () => setState(() => _hashtags.remove(tag)),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              deleteIconColor: AppColors.primary,
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _addHashtag() {
    final val = _hashtagController.text.trim();
    if (val.isNotEmpty && !_hashtags.contains(val)) {
      setState(() {
        _hashtags.add(val.startsWith('#') ? val : '#$val');
        _hashtagController.clear();
      });
    }
  }

  Widget _buildPrivacyStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        children: [
          _buildStepHeader(
            icon: Icons.visibility_rounded,
            title: 'Privacidade do Perfil',
            subtitle: 'Escolha se seu perfil será visível para outros usuários agora.',
          ),
          const SizedBox(height: AppSpacing.s48),
          SwitchListTile.adaptive(
            title: const Text('Perfil Visível', style: AppTypography.titleMedium),
            subtitle: const Text('Outros músicos poderão ver seu card e dar match.'),
            value: _isPublic,
            onChanged: (val) => setState(() => _isPublic = val),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(bool isSaving) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: _currentStep == 0 ? 'Cancelar' : 'Anterior',
              onPressed: _prevStep,
              variant: AppButtonVariant.outline,
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: AppButton(
              text: _currentStep == _totalSteps - 1 ? 'Concluir' : 'Próximo',
              onPressed: _nextStep,
              isLoading: isSaving,
              enabled: _canStepNext(),
            ),
          ),
        ],
      ),
    );
  }

  bool _canStepNext() {
    if (_currentStep == 0) return _selectedIntent.isNotEmpty;
    if (_currentStep == 1) return _selectedGenres.isNotEmpty;
    return true;
  }
}
```

---

pasta: presentation/screens / arquivo: matchpoint_tabs_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/routing/app_router.dart';
import 'package:mube/src/shared/widgets/app_app_bar.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:mube/src/constants/app_radius.dart';

import 'hashtag_ranking_screen.dart';
import 'matchpoint_explore_screen.dart';
import 'matchpoint_matches_screen.dart';

class MatchpointTabsScreen extends ConsumerStatefulWidget {
  const MatchpointTabsScreen({super.key});

  @override
  ConsumerState<MatchpointTabsScreen> createState() => _MatchpointTabsScreenState();
}

class _MatchpointTabsScreenState extends ConsumerState<MatchpointTabsScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MatchpointExploreScreen(),
    const MatchpointMatchesScreen(),
    const HashtagRankingScreen(),
  ];

  final List<String> _titles = [
    'Explorar',
    'Meus Matches',
    'Trending',
  ];

  @override
  void initState() {
    super.initState();
    // Fetch quota initial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(likesQuotaProvider.notifier);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quotaState = ref.watch(likesQuotaProvider).value ?? 
        LikesQuotaInfo(remaining: 0, limit: 50, resetTime: DateTime.now());

    return Scaffold(
      appBar: AppAppBar(
        title: _titles[_selectedIndex],
        actions: [
          // Contador de swipes restantes
          if (_selectedIndex == 0) ...[
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.s8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s4,
              ),
              decoration: BoxDecoration(
                color: quotaState.remaining <= 0
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.all8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: quotaState.remaining <= 0 ? AppColors.error : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    '${quotaState.remaining}/${quotaState.limit}',
                    style: AppTypography.labelMedium.copyWith(
                      color: quotaState.remaining <= 0 ? AppColors.error : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            onPressed: () => context.push(RoutePaths.matchpointHistory),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: () => context.push(RoutePaths.matchpointWizard),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textSecondary),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: AppColors.primary.withValues(alpha: 0.15),
            hoverColor: AppColors.primary.withValues(alpha: 0.05),
            gap: 8,
            activeColor: AppColors.primary,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: AppColors.primary.withValues(alpha: 0.05),
            color: AppColors.textSecondary,
            tabs: const [
              GButton(icon: Icons.explore_rounded, text: 'Explorar'),
              GButton(icon: Icons.favorite_rounded, text: 'Matches'),
              GButton(icon: Icons.trending_up_rounded, text: 'Trends'),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o MatchPoint'),
        content: const Text(
          'O MatchPoint é onde você encontra outros músicos. '
          'Arraste para a direita para curtir e para a esquerda para passar. '
          'Quando ambos se curtem, é um match! Você tem um limite diário de curtidas.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi')),
        ],
      ),
    );
  }
}
```

---

pasta: presentation/screens / arquivo: matchpoint_wrapper_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'matchpoint_intro_screen.dart';
import 'matchpoint_tabs_screen.dart';

/// Wrapper que decide se mostra o Intro ou a Tela Principal do MatchPoint
class MatchpointWrapperScreen extends ConsumerWidget {
  const MatchpointWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authControllerProvider);

    return userAsync.when(
      data: (user) {
        final hasProfile = user?.matchpointProfile != null && 
                          user!.matchpointProfile!.isActive;

        if (hasProfile) {
          return const MatchpointTabsScreen();
        } else {
          return const MatchpointIntroScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Erro ao carregar dados do usuário: $err')),
      ),
    );
  }
}
```

---

pasta: presentation/screens / arquivo: swipe_history_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/shared/widgets/app_app_bar.dart';
import 'package:mube/src/shared/widgets/user_avatar.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:intl/intl.dart';

class SwipeHistoryScreen extends ConsumerWidget {
  const SwipeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(swipeHistoryProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: 'Histórico de Swipes',
        showBackButton: true,
      ),
      body: history.isEmpty ? _buildEmpty(context) : _buildList(context, history),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Nenhuma atividade recente',
            style: AppTypography.bodyLarge.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<SwipeHistoryEntry> history) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s16),
      itemCount: history.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (context, index) {
        final entry = history[index];
        return _HistoryTile(entry: entry);
      },
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  final SwipeHistoryEntry entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLike = entry.action == 'like';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          const UserAvatar(url: null, size: 48), // Aqui buscaria o user data se necessário
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usuário ID: ${entry.targetUserId.substring(0, 8)}...',
                  style: AppTypography.titleSmall,
                ),
                Text(
                  DateFormat('HH:mm - dd/MM').format(entry.timestamp),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isLike ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLike ? Icons.favorite_rounded : Icons.close_rounded,
                  size: 14,
                  color: isLike ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isLike ? 'Like' : 'Dislike',
                  style: AppTypography.labelSmall.copyWith(
                    color: isLike ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

pasta: presentation/widgets / arquivo: confetti_overlay.dart
```dart
import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Criar partículas iniciais
    for (int i = 0; i < 100; i++) {
      _particles.add(_ConfettiParticle(_random));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        for (var p in _particles) {
          p.update();
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles),
        );
      },
    );
  }
}

class _ConfettiParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late Color color;
  late double size;
  late double rotation;
  late double rotationSpeed;
  final Random random;

  _ConfettiParticle(this.random) {
    reset();
    y = random.nextDouble() * -500; // Começa acima da tela
  }

  void reset() {
    x = random.nextDouble() * 400; // Ajustar para largura da tela se possível
    y = -20;
    vx = random.nextDouble() * 4 - 2;
    vy = random.nextDouble() * 5 + 2;
    size = random.nextDouble() * 8 + 4;
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = random.nextDouble() * 0.2;
    
    final colors = [
      Colors.red, Colors.blue, Colors.green, Colors.yellow, 
      Colors.pink, Colors.purple, Colors.orange
    ];
    color = colors[random.nextInt(colors.length)];
  }

  void update() {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
    if (y > 800) { // Reset quando sai da tela
      reset();
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x % size.width, p.y);
      canvas.rotate(p.rotation);
      canvas.drawRect(Rect.fromLTWH(0, 0, p.size, p.size * 0.6), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

---

pasta: presentation/widgets / arquivo: match_card.dart
```dart
import 'package:flutter/material.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/shared/widgets/cached_network_image_wrapper.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';
import 'package:mube/src/constants/app_radius.dart';
import 'package:mube/src/constants/app_effects.dart';

class MatchCard extends StatelessWidget {
  final AppUser user;
  final List<String>? currentUserGenres;

  const MatchCard({
    super.key,
    required this.user,
    this.currentUserGenres,
  });

  @override
  Widget build(BuildContext context) {
    final profile = user.matchpointProfile;
    if (profile == null) return const SizedBox.shrink();

    final compatibility = _getGenreCompatibility();

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.all24,
        boxShadow: [AppEffects.shadowMedium],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.all24,
        child: Stack(
          children: [
            // Foto de Capa
            Positioned.fill(
              child: CachedNetworkImageWrapper(
                imageUrl: user.photoUrl ?? '',
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.person, size: 80, color: AppColors.textTertiary),
                ),
              ),
            ),
            
            // Gradiente Inferior
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.5, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            
            // Indicador de Compatibilidade
            if (compatibility > 0)
              Positioned(
                top: AppSpacing.s16,
                right: AppSpacing.s16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.all20,
                    boxShadow: [AppEffects.shadowSmall],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$compatibility Gêneros em comum',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Informações do Usuário
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName ?? 'Artista',
                          style: AppTypography.headlineLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.verified_rounded, color: AppColors.primary, size: 24),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  Text(
                    profile.intent,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  
                  // Tags/Gêneros
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getTags(profile.musicalGenres).map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.all8,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        tag,
                        style: AppTypography.labelSmall.copyWith(color: Colors.white),
                      ),
                    )).toList(),
                  ),
                  
                  if (profile.hashtags != null && profile.hashtags!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      profile.hashtags!.join(' '),
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getTags(List<String> genres) {
    return genres.take(3).toList();
  }

  int _getGenreCompatibility() {
    if (currentUserGenres == null) return 0;
    final candidateGenres = user.matchpointProfile?.musicalGenres ?? [];
    return candidateGenres.where((g) => currentUserGenres!.contains(g)).length;
  }
}
```

---

pasta: presentation/widgets / arquivo: match_swipe_deck.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import 'match_card.dart';

class MatchSwipeDeck extends ConsumerStatefulWidget {
  final List<AppUser> candidates;
  final Function(AppUser matchedUser, String? conversationId) onMatch;

  const MatchSwipeDeck({
    super.key,
    required this.candidates,
    required this.onMatch,
  });

  @override
  ConsumerState<MatchSwipeDeck> createState() => _MatchSwipeDeckState();
}

class _MatchSwipeDeckState extends ConsumerState<MatchSwipeDeck> {
  final CardSwiperController _controller = CardSwiperController();
  final Set<String> _processedInteractions = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

    return Column(
      children: [
        Expanded(
          child: CardSwiper(
            controller: _controller,
            cardsCount: widget.candidates.length,
            onSwipe: _onSwipe,
            onUndo: _onUndo,
            numberOfCardsDisplayed: 3,
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.all(AppSpacing.s24),
            cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
              return MatchCard(
                user: widget.candidates[index],
                currentUserGenres: user?.matchpointProfile?.musicalGenres,
              );
            },
          ),
        ),
        
        // Botões de Ação Inferiores
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.undo_rounded,
                color: AppColors.textTertiary,
                onPressed: () => _controller.undo(),
                size: 56,
              ),
              const SizedBox(width: AppSpacing.s24),
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppColors.error,
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
                size: 72,
              ),
              const SizedBox(width: AppSpacing.s24),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: AppColors.success,
                onPressed: () => _controller.swipe(CardSwiperDirection.right),
                size: 72,
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    final candidate = widget.candidates[previousIndex];
    final isLike = direction == CardSwiperDirection.right;
    final action = isLike ? 'like' : 'dislike';
    final interactionKey = '${candidate.uid}_$action';

    if (_processedInteractions.contains(interactionKey)) return true;

    _processedInteractions.add(interactionKey);
    
    // Chamar controller para persistir
    ref.read(matchpointControllerProvider.notifier)
       .submitAction(targetUserId: candidate.uid, action: action)
       .then((result) {
         if (result?.isMatch == true) {
           widget.onMatch(candidate, result!.conversationId);
         }
       });

    return true;
  }

  bool _onUndo(int? previousIndex, int currentIndex, CardSwiperDirection direction) {
    if (previousIndex != null) {
      final candidate = widget.candidates[previousIndex];
      _processedInteractions.removeWhere((k) => k.startsWith(candidate.uid));
    }
    return true;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.5),
        onPressed: onPressed,
      ),
    );
  }
}
```

---

pasta: presentation/widgets / arquivo: matchpoint_tutorial_overlay.dart
```dart
import 'package:flutter/material.dart';
import 'package:mube/src/constants/app_colors.dart';
import 'package:mube/src/constants/app_spacing.dart';
import 'package:mube/src/constants/app_typography.dart';

class MatchpointTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const MatchpointTutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.touch_app_rounded, color: Colors.white, size: 80),
            const SizedBox(height: AppSpacing.s32),
            Text(
              'Como Funciona?',
              style: AppTypography.headlineMedium.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.s48),
            _buildTutorialItem(
              icon: Icons.swipe_right_rounded,
              color: AppColors.success,
              text: 'Arraste para a DIREITA para CURTIR um músico',
            ),
            const SizedBox(height: AppSpacing.s24),
            _buildTutorialItem(
              icon: Icons.swipe_left_rounded,
              color: AppColors.error,
              text: 'Arraste para a ESQUERDA para PASSAR',
            ),
            const SizedBox(height: AppSpacing.s24),
            _buildTutorialItem(
              icon: Icons.undo_rounded,
              color: Colors.orange,
              text: 'Use o botão VOLTAR se mudar de ideia',
            ),
            const SizedBox(height: AppSpacing.s64),
            Text(
              'Toque em qualquer lugar para começar',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s48),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyLarge.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
```


