import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:diacritic/diacritic.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_availability.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_dynamic_fields.dart';
import 'package:mube/src/utils/app_check_refresh_coordinator.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:mube/src/utils/distance_calculator.dart';
import 'package:mube/src/utils/geohash_helper.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/analytics/analytics_provider.dart';
import '../../../core/services/analytics/analytics_service.dart';

abstract class MatchpointRemoteDataSource {
  Future<List<AppUser>> fetchCandidates({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> excludedUserIds,
    int limit = 50,
  });

  Future<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String action,
  });

  Future<List<String>> fetchExistingInteractions(String currentUserId);

  Future<LikesQuotaInfo> getRemainingLikes();

  Future<List<Map<String, dynamic>>> fetchMatches(String currentUserId);

  Future<AppUser?> fetchUserById(String userId);

  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20});

  Future<List<HashtagRanking>> searchHashtags(String query, {int limit = 20});

  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  });
}

class MatchpointRemoteDataSourceImpl implements MatchpointRemoteDataSource {
  static const Duration _forcedAppCheckRefreshCooldown = Duration(minutes: 2);
  static const Duration _throttledAppCheckBackoff = Duration(minutes: 10);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final AnalyticsService? _analytics;
  final FirebaseAuth _auth;
  final app_check.FirebaseAppCheck _appCheck;
  Future<void>? _securityRefreshInFlight;

  MatchpointRemoteDataSourceImpl(
    this._firestore,
    this._functions, {
    AnalyticsService? analytics,
    required FirebaseAuth auth,
    required app_check.FirebaseAppCheck appCheck,
  }) : _analytics = analytics,
       _auth = auth,
       _appCheck = appCheck;

  FirebaseAuth get _firebaseAuth => _auth;
  app_check.FirebaseAppCheck get _firebaseAppCheck => _appCheck;

  bool _isAuthContextError(FirebaseFunctionsException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    if (code == 'unauthenticated') return true;

    final appCheckHint = message.contains('app check');
    return appCheckHint &&
        (code == 'failed-precondition' || code == 'permission-denied');
  }

  Future<void> _refreshSecurityTokens() {
    final inFlight = _securityRefreshInFlight;
    if (inFlight != null) return inFlight;

    final refreshFuture = _refreshSecurityTokensInternal();
    _securityRefreshInFlight = refreshFuture.whenComplete(() {
      _securityRefreshInFlight = null;
    });
    return _securityRefreshInFlight!;
  }

  Future<void> _refreshSecurityTokensInternal() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      try {
        await currentUser.getIdToken(true);
      } catch (e, stack) {
        AppLogger.warning(
          'Failed to refresh FirebaseAuth token before retry.',
          e,
          stack,
        );
      }
    }

    await AppCheckRefreshCoordinator.ensureValidTokenOrThrow(
      _firebaseAppCheck,
      operationLabel: 'retry de MatchPoint',
      forcedRefreshCooldown: _forcedAppCheckRefreshCooldown,
      throttledBackoff: _throttledAppCheckBackoff,
    );
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
        '$functionName returned ${e.code}. Refreshing auth context and retrying once.',
      );
      try {
        await _refreshSecurityTokens();
      } on AppCheckRefreshException catch (error, stackTrace) {
        AppLogger.warning(
          'MatchPoint App Check refresh failed before retrying $functionName.',
          error,
          stackTrace,
          false,
        );
        throw FirebaseFunctionsException(
          code: 'failed-precondition',
          message: 'App Check token unavailable for MatchPoint retry.',
        );
      }
      return await callable.call(data);
    }
  }

  Map<String, dynamic> _normalizeCloudFunctionMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key, _normalizeCloudFunctionValue(nestedValue)),
      );
    }

    if (value is Map) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _normalizeCloudFunctionValue(nestedValue)),
      );
    }

    AppLogger.warning(
      'Expected cloud function payload to be a map, got ${value.runtimeType}. Returning empty map.',
    );
    return const <String, dynamic>{};
  }

  List<Map<String, dynamic>> _normalizeCloudFunctionMapList(Object? value) {
    if (value is! List) return const [];
    return value
        .map<Map<String, dynamic>>((item) => _normalizeCloudFunctionMap(item))
        .toList(growable: false);
  }

  Object? _normalizeCloudFunctionValue(Object? value) {
    if (value is Map) return _normalizeCloudFunctionMap(value);
    if (value is List) {
      return value
          .map<Object?>((item) => _normalizeCloudFunctionValue(item))
          .toList(growable: false);
    }
    return value;
  }

  @override
  Future<List<AppUser>> fetchCandidates({
    required AppUser currentUser,
    required List<String> genres,
    required List<String> hashtags,
    required List<String> excludedUserIds,
    int limit = 20,
  }) async {
    final excludedIds = {...excludedUserIds, currentUser.uid};
    final currentLocation = _extractUserCoordinates(currentUser);
    final currentGeohash = _resolveCurrentUserGeohash(
      currentUser,
      currentLocation,
    );
    final searchRadiusKm = _resolveSearchRadius(currentUser.matchpointProfile);
    final targetGenres = genres
        .map(_normalizeGenreToken)
        .where((genre) => genre.isNotEmpty)
        .toSet();
    final targetHashtags = hashtags
        .map(_normalizeHashtagToken)
        .where((hashtag) => hashtag.isNotEmpty)
        .toSet();
    final poolLimit = _resolvePoolLimit(limit);

    final candidateDocs = await _fetchCandidateDocuments(
      currentUserGeohash: currentGeohash,
      poolLimit: poolLimit,
    );

    final scoredCandidates =
        candidateDocs
            .where((doc) => !excludedIds.contains(doc.id))
            .map(
              (doc) => _scoreCandidate(
                docId: doc.id,
                userData: doc.data(),
                currentLocation: currentLocation,
                searchRadiusKm: searchRadiusKm,
                targetGenres: targetGenres,
                targetHashtags: targetHashtags,
              ),
            )
            .whereType<_ScoredCandidate>()
            .toList()
          ..sort(_compareCandidates);

    if (scoredCandidates.isEmpty) {
      _logRankingAudit(
        currentUserGeohash: currentGeohash,
        queryGenresCount: targetGenres.length,
        queryHashtagsCount: targetHashtags.length,
        pool: const [],
        returned: const [],
      );
      AppLogger.info('MatchPoint: no eligible candidates found after ranking.');
      return const [];
    }

    final returnedCandidates = scoredCandidates
        .take(limit)
        .toList(growable: false);
    _logRankingAudit(
      currentUserGeohash: currentGeohash,
      queryGenresCount: targetGenres.length,
      queryHashtagsCount: targetHashtags.length,
      pool: scoredCandidates,
      returned: returnedCandidates,
    );

    return returnedCandidates.map((item) => item.user).toList();
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchCandidateDocuments({
    required String? currentUserGeohash,
    required int poolLimit,
  }) async {
    final seenIds = <String>{};
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    void appendSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
      for (final doc in snapshot.docs) {
        if (seenIds.add(doc.id)) {
          docs.add(doc);
        }
      }
    }

    if (currentUserGeohash != null && currentUserGeohash.isNotEmpty) {
      try {
        final nearbySnapshot = await _firestore
            .collection(FirestoreCollections.users)
            .where(
              '${FirestoreFields.matchpointProfile}.${FirestoreFields.isActive}',
              isEqualTo: true,
            )
            .where(
              FirestoreFields.geohash,
              whereIn: GeohashHelper.neighbors(currentUserGeohash),
            )
            .limit(poolLimit)
            .get();
        appendSnapshot(nearbySnapshot);
      } catch (e, stack) {
        AppLogger.warning(
          'MatchPoint: geohash query failed, falling back to global pool.',
          e,
          stack,
        );
      }
    }

    if (docs.length < poolLimit) {
      final fallbackSnapshot = await _firestore
          .collection(FirestoreCollections.users)
          .where(
            '${FirestoreFields.matchpointProfile}.${FirestoreFields.isActive}',
            isEqualTo: true,
          )
          .limit(poolLimit)
          .get();
      appendSnapshot(fallbackSnapshot);
    }

    return docs;
  }

  _ScoredCandidate? _scoreCandidate({
    required String docId,
    required Map<String, dynamic> userData,
    required _Coordinates? currentLocation,
    required double searchRadiusKm,
    required Set<String> targetGenres,
    required Set<String> targetHashtags,
  }) {
    if (!_isVisibleCandidate(userData)) return null;

    final candidateLocation = _extractCoordinatesFromMap(userData['location']);
    final distanceKm = currentLocation == null || candidateLocation == null
        ? null
        : DistanceCalculator.haversine(
            fromLat: currentLocation.lat,
            fromLng: currentLocation.lng,
            toLat: candidateLocation.lat,
            toLng: candidateLocation.lng,
          );

    final locationBucket = _resolveLocationBucket(
      distanceKm: distanceKm,
      searchRadiusKm: searchRadiusKm,
      hasCurrentLocation: currentLocation != null,
    );
    final hashtagMatches = _extractCandidateHashtags(
      userData,
    ).map(_normalizeHashtagToken).where(targetHashtags.contains).length;
    final genreMatches = _extractCandidateGenres(
      userData,
    ).map(_normalizeGenreToken).where(targetGenres.contains).length;

    final AppUser user;
    try {
      user = AppUser.fromJson({
        ...userData,
        'uid': userData['uid'] ?? docId,
      });
    } catch (e, stack) {
      AppLogger.warning(
        'MatchPoint: skipping candidate $docId due to deserialization error',
        e,
        stack,
        false,
      );
      return null;
    }

    return _ScoredCandidate(
      user: user,
      distanceKm: distanceKm,
      locationBucket: locationBucket,
      hashtagMatches: hashtagMatches,
      genreMatches: genreMatches,
    );
  }

  int _compareCandidates(_ScoredCandidate a, _ScoredCandidate b) {
    final locationOrder = a.locationBucket.compareTo(b.locationBucket);
    if (locationOrder != 0) return locationOrder;

    final hashtagOrder = b.hashtagMatches.compareTo(a.hashtagMatches);
    if (hashtagOrder != 0) return hashtagOrder;

    final genreOrder = b.genreMatches.compareTo(a.genreMatches);
    if (genreOrder != 0) return genreOrder;

    final distanceOrder = (a.distanceKm ?? double.infinity).compareTo(
      b.distanceKm ?? double.infinity,
    );
    if (distanceOrder != 0) return distanceOrder;

    return a.user.uid.compareTo(b.user.uid);
  }

  bool _isVisibleCandidate(Map<String, dynamic> userData) {
    final cadastroStatus =
        userData[FirestoreFields.registrationStatus] as String?;
    final status = userData['status'] as String? ?? 'ativo';

    return cadastroStatus == RegistrationStatus.complete &&
        status == 'ativo' &&
        _isEligibleMatchpointType(userData);
  }

  bool _isEligibleMatchpointType(Map<String, dynamic> userData) {
    final profileType = userData[FirestoreFields.profileType] as String?;
    if (profileType == ProfileType.band) return true;
    if (profileType != ProfileType.professional) return false;

    final professional = userData[FirestoreFields.professional];
    final rawCategories = <String>[];
    final rawRoles = <String>[];

    if (professional is Map<String, dynamic>) {
      rawCategories.addAll(matchpointStringList(professional['categorias']));

      final legacyCategory = professional['categoria'];
      if (legacyCategory is String && legacyCategory.isNotEmpty) {
        rawCategories.add(legacyCategory);
      }

      rawRoles.addAll(matchpointStringList(professional['funcoes']));
    }

    return isMatchpointAvailableForProfileType(
      profileType,
      rawCategories: rawCategories,
      rawRoles: rawRoles,
    );
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

  List<String> _extractCandidateHashtags(Map<String, dynamic> userData) {
    final hashtags = <String>[];

    final matchpointProfile =
        userData[FirestoreFields.matchpointProfile] as Map<String, dynamic>?;
    final fromMatchpoint = matchpointProfile?[FirestoreFields.hashtags];
    if (fromMatchpoint is List) {
      hashtags.addAll(fromMatchpoint.whereType<String>());
    }

    final fromLegacyRoot = userData[FirestoreFields.hashtags];
    if (fromLegacyRoot is List) {
      hashtags.addAll(fromLegacyRoot.whereType<String>());
    }

    return hashtags;
  }

  _Coordinates? _extractUserCoordinates(AppUser user) {
    for (final address in user.addresses) {
      if (address.isPrimary && address.lat != null && address.lng != null) {
        return _Coordinates(address.lat!, address.lng!);
      }
    }

    for (final address in user.addresses) {
      if (address.lat != null && address.lng != null) {
        return _Coordinates(address.lat!, address.lng!);
      }
    }

    return _extractCoordinatesFromMap(user.location);
  }

  _Coordinates? _extractCoordinatesFromMap(dynamic rawLocation) {
    if (rawLocation is! Map) return null;

    final rawLat = rawLocation['lat'];
    final rawLng = rawLocation['lng'] ?? rawLocation['long'];

    final lat = rawLat is num ? rawLat.toDouble() : null;
    final lng = rawLng is num ? rawLng.toDouble() : null;
    if (lat == null || lng == null) return null;

    return _Coordinates(lat, lng);
  }

  String? _resolveCurrentUserGeohash(
    AppUser currentUser,
    _Coordinates? currentLocation,
  ) {
    if (currentUser.geohash != null && currentUser.geohash!.isNotEmpty) {
      return currentUser.geohash;
    }

    if (currentLocation == null) return null;

    return GeohashHelper.encode(
      currentLocation.lat,
      currentLocation.lng,
      precision: 5,
    );
  }

  int _resolveLocationBucket({
    required double? distanceKm,
    required double searchRadiusKm,
    required bool hasCurrentLocation,
  }) {
    if (!hasCurrentLocation) return 0;
    if (distanceKm == null) return 2;
    if (distanceKm <= searchRadiusKm) return 0;
    return 1;
  }

  int _resolvePoolLimit(int limit) {
    if (limit <= 0) return 80;
    final scaled = limit * 5;
    return scaled < 80 ? 80 : scaled;
  }

  double _resolveSearchRadius(Map<String, dynamic>? matchpointProfile) {
    final rawRadius = matchpointProfile?[FirestoreFields.searchRadius];
    if (rawRadius is num && rawRadius > 0) {
      return rawRadius.toDouble();
    }
    return 50;
  }

  String _normalizeGenreToken(String token) {
    return removeDiacritics(
      token,
    ).toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeHashtagToken(String token) {
    final withoutHash = token.replaceAll('#', '');
    return removeDiacritics(withoutHash)
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  void _logRankingAudit({
    required String? currentUserGeohash,
    required int queryGenresCount,
    required int queryHashtagsCount,
    required List<_ScoredCandidate> pool,
    required List<_ScoredCandidate> returned,
  }) {
    final poolStats = _RankingAuditStats.fromCandidates(pool);
    final returnedStats = _RankingAuditStats.fromCandidates(returned);

    AppLogger.info(
      'MatchPoint ranking audit: '
      'pool=${pool.length} '
      'returned=${returned.length} '
      'pool[p=${poolStats.proximity},h=${poolStats.hashtag},g=${poolStats.genre},f=${poolStats.fallback},local=${poolStats.localTotal},lh=${poolStats.localHashtag},lg=${poolStats.localGenre}] '
      'returned[p=${returnedStats.proximity},h=${returnedStats.hashtag},g=${returnedStats.genre},f=${returnedStats.fallback},local=${returnedStats.localTotal},lh=${returnedStats.localHashtag},lg=${returnedStats.localGenre}]',
    );

    final analytics = _analytics;
    if (analytics != null) {
      unawaited(
        analytics.logEvent(
          name: 'matchpoint_ranking_audit',
          parameters: {
            'pool_total': pool.length,
            'returned_total': returned.length,
            'pool_proximity': poolStats.proximity,
            'pool_hashtag': poolStats.hashtag,
            'pool_genre': poolStats.genre,
            'pool_fallback': poolStats.fallback,
            'ret_proximity': returnedStats.proximity,
            'ret_hashtag': returnedStats.hashtag,
            'ret_genre': returnedStats.genre,
            'ret_fallback': returnedStats.fallback,
            'pool_local_total': poolStats.localTotal,
            'pool_local_hashtag': poolStats.localHashtag,
            'pool_local_genre': poolStats.localGenre,
            'ret_local_total': returnedStats.localTotal,
            'ret_local_hashtag': returnedStats.localHashtag,
            'ret_local_genre': returnedStats.localGenre,
            'query_genres': queryGenresCount,
            'query_tags': queryHashtagsCount,
            'used_geohash': currentUserGeohash != null,
          },
        ),
      );
    }

    unawaited(
      _mirrorRankingAudit(
        currentUserGeohash: currentUserGeohash,
        queryGenresCount: queryGenresCount,
        queryHashtagsCount: queryHashtagsCount,
        poolStats: poolStats,
        returnedStats: returnedStats,
        poolTotal: pool.length,
        returnedTotal: returned.length,
      ),
    );
  }

  Future<void> _mirrorRankingAudit({
    required String? currentUserGeohash,
    required int queryGenresCount,
    required int queryHashtagsCount,
    required _RankingAuditStats poolStats,
    required _RankingAuditStats returnedStats,
    required int poolTotal,
    required int returnedTotal,
  }) async {
    try {
      await _callWithRecovery(
        'recordMatchpointRankingAudit',
        data: {
          'poolTotal': poolTotal,
          'returnedTotal': returnedTotal,
          'poolProximity': poolStats.proximity,
          'poolHashtag': poolStats.hashtag,
          'poolGenre': poolStats.genre,
          'poolFallback': poolStats.fallback,
          'poolLocalTotal': poolStats.localTotal,
          'poolLocalHashtag': poolStats.localHashtag,
          'poolLocalGenre': poolStats.localGenre,
          'returnedProximity': returnedStats.proximity,
          'returnedHashtag': returnedStats.hashtag,
          'returnedGenre': returnedStats.genre,
          'returnedFallback': returnedStats.fallback,
          'returnedLocalTotal': returnedStats.localTotal,
          'returnedLocalHashtag': returnedStats.localHashtag,
          'returnedLocalGenre': returnedStats.localGenre,
          'queryGenres': queryGenresCount,
          'queryHashtags': queryHashtagsCount,
          'usedGeohash': currentUserGeohash != null,
        },
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'MatchPoint: failed to mirror ranking audit to backend.',
        error,
        stackTrace,
        false,
      );
    }
  }

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
        _normalizeCloudFunctionMap(result.data),
      );
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error(
        'submitMatchpointAction failed: code=${e.code}, message=${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<List<String>> fetchExistingInteractions(String currentUserId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.interactions)
        .where('source_user_id', isEqualTo: currentUserId)
        .where('type', whereIn: ['like', 'dislike'])
        .get();

    final now = Timestamp.now();

    final result = <String>[];
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String?;
      final targetUserId = data['target_user_id'];

      if (targetUserId is! String || targetUserId.isEmpty) continue;

      if (type == 'like') {
        result.add(targetUserId);
        continue;
      }
      if (type != 'dislike') continue;

      final expiresAt = data['expires_at'];
      if (expiresAt is! Timestamp) continue;
      if (expiresAt.compareTo(now) > 0) {
        result.add(targetUserId);
      }
    }
    return result;
  }

  @override
  Future<LikesQuotaInfo> getRemainingLikes() async {
    try {
      final result = await _callWithRecovery('getRemainingLikes');

      return LikesQuotaInfo.fromJson(_normalizeCloudFunctionMap(result.data));
    } on FirebaseFunctionsException catch (e) {
      AppLogger.error(
        'getRemainingLikes failed: code=${e.code}, message=${e.message}',
      );
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMatches(String currentUserId) async {
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

    final data = doc.data();
    if (data is! Map<String, dynamic>) return null;

    try {
      return AppUser.fromJson(data);
    } catch (e, stack) {
      AppLogger.warning(
        'MatchPoint: failed to parse user $userId',
        e,
        stack,
        false,
      );
      return null;
    }
  }

  @override
  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20}) async {
    try {
      final callable = _functions.httpsCallable('getTrendingHashtags');

      final result = await callable.call({'limit': limit, 'includeAll': false});

      final data = _normalizeCloudFunctionMap(result.data);
      final hashtags = _normalizeCloudFunctionMapList(data['hashtags']);

      return hashtags.map(HashtagRanking.fromCloudFunction).toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to load trending hashtags from Function. Falling back to Firestore: $e',
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

      final data = _normalizeCloudFunctionMap(result.data);
      final hashtags = _normalizeCloudFunctionMapList(data['hashtags']);

      return hashtags.map(HashtagRanking.fromCloudFunction).toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to search hashtags via Function. Falling back to Firestore: $e',
      );

      final normalized = query.toLowerCase().trim();
      if (normalized.length < 2) return [];

      final snapshot = await _firestore
          .collection('hashtagRanking')
          .where('hashtag', isGreaterThanOrEqualTo: normalized)
          .where('hashtag', isLessThanOrEqualTo: '$normalized\uf8ff')
          .orderBy('hashtag')
          .limit(limit)
          .get();

      final results = snapshot.docs.map(HashtagRanking.fromFirestore).toList();
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
      ref.read(firebaseFirestoreProvider),
      ref.read(firebaseFunctionsProvider),
      analytics: ref.watch(analyticsServiceProvider),
      auth: ref.read(firebaseAuthProvider),
      appCheck: ref.read(firebaseAppCheckProvider),
    );
  },
);

class _Coordinates {
  final double lat;
  final double lng;

  const _Coordinates(this.lat, this.lng);
}

class _ScoredCandidate {
  final AppUser user;
  final double? distanceKm;
  final int locationBucket;
  final int hashtagMatches;
  final int genreMatches;

  const _ScoredCandidate({
    required this.user,
    required this.distanceKm,
    required this.locationBucket,
    required this.hashtagMatches,
    required this.genreMatches,
  });

  _RankingPrimarySource get primarySource {
    if (locationBucket == 0) return _RankingPrimarySource.proximity;
    if (hashtagMatches > 0) return _RankingPrimarySource.hashtag;
    if (genreMatches > 0) return _RankingPrimarySource.genre;
    return _RankingPrimarySource.fallback;
  }

  bool get isLocal => distanceKm != null && locationBucket == 0;
}

class _RankingAuditStats {
  final int proximity;
  final int hashtag;
  final int genre;
  final int fallback;
  final int localTotal;
  final int localHashtag;
  final int localGenre;

  const _RankingAuditStats({
    required this.proximity,
    required this.hashtag,
    required this.genre,
    required this.fallback,
    required this.localTotal,
    required this.localHashtag,
    required this.localGenre,
  });

  factory _RankingAuditStats.fromCandidates(List<_ScoredCandidate> candidates) {
    var proximity = 0;
    var hashtag = 0;
    var genre = 0;
    var fallback = 0;
    var localTotal = 0;
    var localHashtag = 0;
    var localGenre = 0;

    for (final candidate in candidates) {
      switch (candidate.primarySource) {
        case _RankingPrimarySource.proximity:
          proximity++;
        case _RankingPrimarySource.hashtag:
          hashtag++;
        case _RankingPrimarySource.genre:
          genre++;
        case _RankingPrimarySource.fallback:
          fallback++;
      }

      if (candidate.isLocal) {
        localTotal++;
        if (candidate.hashtagMatches > 0) {
          localHashtag++;
        }
        if (candidate.genreMatches > 0) {
          localGenre++;
        }
      }
    }

    return _RankingAuditStats(
      proximity: proximity,
      hashtag: hashtag,
      genre: genre,
      fallback: fallback,
      localTotal: localTotal,
      localHashtag: localHashtag,
      localGenre: localGenre,
    );
  }
}

enum _RankingPrimarySource { proximity, hashtag, genre, fallback }
