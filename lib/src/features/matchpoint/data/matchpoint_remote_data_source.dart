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
