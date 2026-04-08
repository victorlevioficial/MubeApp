import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_availability.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_dynamic_fields.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:mube/src/utils/distance_calculator.dart';
import 'package:mube/src/utils/geohash_helper.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/providers/firebase_providers.dart';

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

  /// Fetch many users in a single (or few) batched Firestore queries using
  /// `whereIn` on `FieldPath.documentId`. Returns a map keyed by uid for
  /// O(1) lookup. Missing or unparseable users are simply absent from the
  /// map. Consolidating N parallel `fetchUserById` calls into 1-2 batched
  /// queries dramatically reduces the iOS Swift Concurrency Pigeon load
  /// (Crashlytics issue a37e597a).
  Future<Map<String, AppUser>> fetchUsersByIds(List<String> ids);

  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20});

  Future<List<HashtagRanking>> searchHashtags(String query, {int limit = 20});

  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  });
}

enum _CandidateFetchQueryMode { globalOnly, nearbyOnly }

class MatchpointRemoteDataSourceImpl implements MatchpointRemoteDataSource {
  static const _CandidateFetchQueryMode _candidateFetchQueryMode =
      _CandidateFetchQueryMode.globalOnly;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  MatchpointRemoteDataSourceImpl(this._firestore, this._functions);

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
    AppLogger.breadcrumb('mp:fetch:start');
    AppLogger.setCustomKey('mp_step', 'fetch:start');
    AppLogger.setCustomKey('mp_fetch_mode', _candidateFetchQueryMode.name);
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

    AppLogger.breadcrumb('mp:fetch:docs_call');
    final candidateDocs = await _fetchCandidateDocuments(
      currentUserGeohash: currentGeohash,
      poolLimit: poolLimit,
      queryMode: _candidateFetchQueryMode,
    );
    AppLogger.breadcrumb('mp:fetch:docs_done count=${candidateDocs.length}');
    AppLogger.setCustomKey('mp_pool_docs', candidateDocs.length);

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
      _logRankingAudit(pool: const [], returned: const []);
      AppLogger.info('MatchPoint: no eligible candidates found after ranking.');
      AppLogger.breadcrumb('mp:fetch:return_empty');
      return const [];
    }

    final returnedCandidates = scoredCandidates
        .take(limit)
        .toList(growable: false);
    AppLogger.breadcrumb(
      'mp:fetch:audit_call pool=${scoredCandidates.length} ret=${returnedCandidates.length}',
    );
    _logRankingAudit(pool: scoredCandidates, returned: returnedCandidates);
    AppLogger.breadcrumb('mp:fetch:audit_done');

    final result = returnedCandidates.map((item) => item.user).toList();
    AppLogger.breadcrumb('mp:fetch:return count=${result.length}');
    AppLogger.setCustomKey('mp_step', 'fetch:return');
    return result;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _fetchCandidateDocuments({
    required String? currentUserGeohash,
    required int poolLimit,
    required _CandidateFetchQueryMode queryMode,
  }) async {
    switch (queryMode) {
      case _CandidateFetchQueryMode.globalOnly:
        AppLogger.breadcrumb('mp:fetch:global_q');
        final globalSnapshot = await _firestore
            .collection(FirestoreCollections.users)
            .where(
              '${FirestoreFields.matchpointProfile}.${FirestoreFields.isActive}',
              isEqualTo: true,
            )
            .limit(poolLimit)
            .get();
        AppLogger.breadcrumb(
          'mp:fetch:global_done count=${globalSnapshot.size}',
        );
        return globalSnapshot.docs;
      case _CandidateFetchQueryMode.nearbyOnly:
        if (currentUserGeohash == null || currentUserGeohash.isEmpty) {
          AppLogger.breadcrumb('mp:fetch:nearby_skip_no_geohash');
          return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        }

        AppLogger.breadcrumb('mp:fetch:geohash_q');
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
        AppLogger.breadcrumb(
          'mp:fetch:geohash_done count=${nearbySnapshot.size}',
        );
        return nearbySnapshot.docs;
    }
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
      user = AppUser.fromJson({...userData, 'uid': userData['uid'] ?? docId});
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
    // Isolation release for Crashlytics issue a37e597a:
    // keep the initial candidate pool tighter to reduce document parsing and
    // image churn while we narrow the native iOS crash. The previous pool of
    // ~30+ docs still put the app under meaningful pressure on entry.
    if (limit <= 0) return 20;
    final scaled = limit + 4;
    if (scaled < 18) return 18;
    if (scaled > 24) return 24;
    return scaled;
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
    // Keep ranking telemetry local-only. The previous Firebase Analytics event
    // (`matchpoint_ranking_audit`) was consistently the last breadcrumb before
    // iOS Swift Concurrency SIGABRT crashes under memory pressure.
    AppLogger.breadcrumb('mp:audit:local_only');
    AppLogger.setCustomKey('mp_step', 'audit:local_only');
    AppLogger.setCustomKey('mp_audit_pool', pool.length);
    AppLogger.setCustomKey('mp_audit_returned', returned.length);
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
      final callable = _functions.httpsCallable('getRemainingLikes');
      final result = await callable.call();

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
  Future<Map<String, AppUser>> fetchUsersByIds(List<String> ids) async {
    if (ids.isEmpty) return const <String, AppUser>{};

    AppLogger.breadcrumb('mp:users_by_ids:start count=${ids.length}');
    final result = <String, AppUser>{};

    // Firestore `whereIn` allows up to 30 values per query.
    const batchSize = 30;
    final uniqueIds = ids.toSet().toList(growable: false);

    for (var offset = 0; offset < uniqueIds.length; offset += batchSize) {
      final end = (offset + batchSize) > uniqueIds.length
          ? uniqueIds.length
          : (offset + batchSize);
      final batch = uniqueIds.sublist(offset, end);

      AppLogger.breadcrumb(
        'mp:users_by_ids:batch_q offset=$offset size=${batch.length}',
      );
      final snapshot = await _firestore
          .collection(FirestoreCollections.users)
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      AppLogger.breadcrumb(
        'mp:users_by_ids:batch_done offset=$offset count=${snapshot.size}',
      );

      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          result[doc.id] = AppUser.fromJson({
            ...data,
            'uid': data['uid'] ?? doc.id,
          });
        } catch (e, stack) {
          AppLogger.warning(
            'MatchPoint: failed to parse user ${doc.id}',
            e,
            stack,
            false,
          );
        }
      }

      // Brief pause between batches to let the iOS Swift Concurrency
      // cooperative pool drain the previous Pigeon call.
      if (end < uniqueIds.length) {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    }

    AppLogger.breadcrumb('mp:users_by_ids:done count=${result.length}');
    return result;
  }

  @override
  Future<List<HashtagRanking>> fetchHashtagRanking({int limit = 20}) async {
    // Direct Firestore read instead of getTrendingHashtags Cloud Function.
    // The Cloud Function call (cloud_functions Pigeon to Swift plugin) was
    // the smoking-gun trigger for the SIGABRT crash on iOS when the user
    // tapped the "Trending" tab in the matchpoint tabs (Crashlytics issue
    // a37e597a, last seen 1.6.19+166). Same family of failure as the
    // _likesQuotaTimer fetchRemainingLikes() call we removed: another
    // Cloud Functions Pigeon landing on the Swift cooperative pool while
    // earlier tasks were still draining.
    //
    // The Firestore fallback path was already implemented as the catch
    // branch and uses HashtagRanking.fromFirestore which has all the
    // same fields the UI consumes. Promoting it to the primary path
    // eliminates the Cloud Function Pigeon call entirely.
    AppLogger.breadcrumb('mp:hashtag_rank:fetch_start');
    final snapshot = await _firestore
        .collection('hashtagRanking')
        .orderBy('use_count', descending: true)
        .limit(limit)
        .get();
    AppLogger.breadcrumb('mp:hashtag_rank:fetch_done count=${snapshot.size}');

    return snapshot.docs.map(HashtagRanking.fromFirestore).toList();
  }

  @override
  Future<List<HashtagRanking>> searchHashtags(
    String query, {
    int limit = 20,
  }) async {
    // Direct Firestore read instead of searchHashtags Cloud Function — same
    // reasoning as fetchHashtagRanking above. Eliminates a cloud_functions
    // Pigeon call that can trigger the iOS Swift Concurrency SIGABRT.
    AppLogger.breadcrumb('mp:hashtag_search:fetch_start');
    final normalized = query.toLowerCase().trim();
    if (normalized.length < 2) return [];

    final snapshot = await _firestore
        .collection('hashtagRanking')
        .where('hashtag', isGreaterThanOrEqualTo: normalized)
        .where('hashtag', isLessThanOrEqualTo: '$normalized\uf8ff')
        .orderBy('hashtag')
        .limit(limit)
        .get();
    AppLogger.breadcrumb('mp:hashtag_search:fetch_done count=${snapshot.size}');

    final results = snapshot.docs.map(HashtagRanking.fromFirestore).toList();
    results.sort((a, b) => b.useCount.compareTo(a.useCount));

    return results;
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
