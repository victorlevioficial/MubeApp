import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/utils/app_logger.dart';

import '../../../constants/firestore_constants.dart';

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

  /// Salva o perfil do matchpoint
  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  });
}

class MatchpointRemoteDataSourceImpl implements MatchpointRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  MatchpointRemoteDataSourceImpl(this._firestore, this._functions);

  bool _isAuthContextError(FirebaseFunctionsException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    if (code == 'unauthenticated') return true;

    final appCheckHint = message.contains('app check');
    return appCheckHint &&
        (code == 'failed-precondition' || code == 'permission-denied');
  }

  Future<void> _refreshSecurityTokens() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        await currentUser.getIdToken(true);
      } catch (e, stack) {
        AppLogger.warning(
          'Falha ao forçar refresh do FirebaseAuth token antes do retry',
          e,
          stack,
        );
      }
    }

    try {
      await app_check.FirebaseAppCheck.instance.getToken(true);
    } catch (e, stack) {
      AppLogger.warning(
        'Falha ao obter token App Check antes do retry',
        e,
        stack,
      );
    }
  }

  Future<HttpsCallableResult<dynamic>> _callWithRecovery(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    final callable = _functions.httpsCallable(functionName);
    try {
      return await callable.call(data);
    } on FirebaseFunctionsException catch (e) {
      if (!_isAuthContextError(e)) rethrow;

      AppLogger.warning(
        '$functionName retornou ${e.code}. Fazendo refresh de sessão e retry único.',
      );
      await _refreshSecurityTokens();
      return await callable.call(data);
    }
  }

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
    final primaryCandidates = snapshot.docs
        .where(
          (doc) => doc.id != currentUserId && !excludedUserIds.contains(doc.id),
        )
        .map((doc) => AppUser.fromJson(doc.data() as Map<String, dynamic>))
        .toList();

    if (primaryCandidates.isNotEmpty || genres.isEmpty) {
      return primaryCandidates;
    }

    // Fallback para dados legados:
    // alguns perfis antigos salvaram gêneros em chaves diferentes dentro de
    // matchpoint_profile (musicalGenres/musical_genres) ou só no perfil base.
    final fallbackSnapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where(
          '${FirestoreFields.matchpointProfile}.${FirestoreFields.isActive}',
          isEqualTo: true,
        )
        .limit(limit * 5)
        .get();

    final targetGenres = genres
        .map((genre) => _normalizeGenreToken(genre))
        .where((genre) => genre.isNotEmpty)
        .toSet();

    final fallbackCandidates = fallbackSnapshot.docs
        .where((doc) {
          if (doc.id == currentUserId || excludedUserIds.contains(doc.id)) {
            return false;
          }
          final data = doc.data();
          return _hasAnyGenreMatch(data, targetGenres);
        })
        .map((doc) => AppUser.fromJson(doc.data()))
        .take(limit);

    final result = fallbackCandidates.toList();
    if (result.isNotEmpty) {
      AppLogger.info(
        'MatchPoint fallback de gêneros acionado. candidatos=${result.length}',
      );
    }
    return result;
  }

  bool _hasAnyGenreMatch(
    Map<String, dynamic> userData,
    Set<String> targetGenres,
  ) {
    final genres = _extractCandidateGenres(
      userData,
    ).map(_normalizeGenreToken).where((genre) => genre.isNotEmpty);
    return genres.any(targetGenres.contains);
  }

  List<String> _extractCandidateGenres(Map<String, dynamic> userData) {
    final genres = <String>[];

    final matchpointProfile =
        userData[FirestoreFields.matchpointProfile] as Map<String, dynamic>?;
    final fromMatchpoint =
        matchpointProfile?[FirestoreFields.musicalGenres] ??
        matchpointProfile?['musicalGenres'] ??
        matchpointProfile?['musical_genres'] ??
        matchpointProfile?['genres'];

    if (fromMatchpoint is List) {
      genres.addAll(fromMatchpoint.whereType<String>());
    }

    final professional = userData[FirestoreFields.professional];
    if (professional is Map<String, dynamic>) {
      final list = professional[FirestoreFields.musicalGenres];
      if (list is List) genres.addAll(list.whereType<String>());
    }

    final band = userData[FirestoreFields.band];
    if (band is Map<String, dynamic>) {
      final list = band[FirestoreFields.musicalGenres];
      if (list is List) genres.addAll(list.whereType<String>());
    }

    return genres;
  }

  String _normalizeGenreToken(String token) => token.trim().toLowerCase();

  @override
  Future<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String action,
  }) async {
    try {
      final result = await _callWithRecovery(
        'submitMatchpointAction',
        data: {'targetUserId': targetUserId, 'action': action},
      );

      return MatchpointActionResult.fromJson(
        result.data as Map<String, dynamic>,
      );
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
      final result = await _callWithRecovery('getRemainingLikes');

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
    // Query única usando campo array user_ids
    // IMPORTANTE: Adicione o campo 'user_ids' ao documento de match no backend:
    //   user_ids: [user_id_1, user_id_2]
    final snapshot = await _firestore
        .collection(FirestoreCollections.matches)
        .where('user_ids', arrayContains: currentUserId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    return snapshot.docs.map((d) => {...d.data(), 'id': d.id}).toList();
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

      final result = await callable.call({'limit': limit, 'includeAll': false});

      final data = result.data as Map<String, dynamic>;
      final hashtags = data['hashtags'] as List<dynamic>? ?? [];

      return hashtags
          .map(
            (h) => HashtagRanking.fromCloudFunction(h as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Falha ao buscar trending via Function. Fallback Firestore: $e',
      );

      final snapshot = await _firestore
          .collection('hashtagRanking')
          .orderBy('use_count', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(HashtagRanking.fromFirestore).toList();
    }
  }

  @override
  Future<List<HashtagRanking>> searchHashtags(
    String query, {
    int limit = 20,
  }) async {
    try {
      final callable = _functions.httpsCallable('searchHashtags');

      final result = await callable.call({'query': query, 'limit': limit});

      final data = result.data as Map<String, dynamic>;
      final hashtags = data['hashtags'] as List<dynamic>? ?? [];

      return hashtags
          .map(
            (h) => HashtagRanking.fromCloudFunction(h as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Falha ao buscar hashtag via Function. Fallback Firestore: $e',
      );

      final normalized = query.toLowerCase().trim();
      if (normalized.length < 2) return [];

      // Removido orderBy conflitante — sort client-side
      final snapshot = await _firestore
          .collection('hashtagRanking')
          .where('hashtag', isGreaterThanOrEqualTo: normalized)
          .where('hashtag', isLessThanOrEqualTo: '$normalized\uf8ff')
          .orderBy('hashtag')
          .limit(limit)
          .get();

      final results = snapshot.docs.map(HashtagRanking.fromFirestore).toList();

      // Sort by use_count client-side
      results.sort((a, b) => b.useCount.compareTo(a.useCount));

      return results;
    }
  }

  @override
  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    await _firestore.collection(FirestoreCollections.users).doc(userId).update({
      'matchpoint_profile': profileData,
    });
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
