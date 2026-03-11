import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../utils/app_logger.dart';
import '../domain/paginated_favorites_response.dart';

part 'favorite_repository.g.dart';

class FavoriteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FavoriteRepository(this._firestore, this._auth);

  /// Returns current user id or throws when unauthenticated.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario nao autenticado');
    return user.uid;
  }

  /// Loads current user's favorite target ids.
  Future<Set<String>> loadFavorites() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('favorites')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e, stackTrace) {
      // Keep UI resilient while offline/intermittent.
      AppLogger.warning('Erro ao carregar favoritos', e, stackTrace);
      return {};
    }
  }

  /// Loads paginated favorites ordered by favorited date (desc).
  Future<PaginatedFavoritesResponse> loadFavoritesPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .doc(_uid)
          .collection('favorites')
          .orderBy('favoritedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final favoriteIds = snapshot.docs.map((doc) => doc.id).toList();
      final lastDocument = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length >= limit;

      return PaginatedFavoritesResponse(
        favoriteIds: favoriteIds,
        lastDocument: lastDocument,
        hasMore: hasMore,
      );
    } catch (e, stackTrace) {
      AppLogger.warning('Erro ao carregar favoritos paginados', e, stackTrace);
      return const PaginatedFavoritesResponse.empty();
    }
  }

  /// Loads user ids that have favorited the current user.
  ///
  /// Returns merged user ids ordered by most recent interaction first.
  ///
  /// Data may come from:
  /// - `users/{source}/favorites/{target}` (legacy/current favorites flow)
  /// - `interactions` with `{type: like, target_user_id: currentUser}` (MatchPoint)
  /// - migrated legacy `interactions` with
  ///   `{type: like, senderId, receiverId, timestamp}`
  ///
  /// When `expectedCount` is provided and there is a mismatch, a legacy
  /// backfill read scans users and checks `users/{source}/favorites/{me}` docs.
  Future<List<String>> loadReceivedFavorites({int? expectedCount}) async {
    final byUser = <String, int>{};
    var completedSources = 0;

    try {
      final snapshot = await _firestore
          .collectionGroup('favorites')
          .where('target_user_id', isEqualTo: _uid)
          .get();
      completedSources += 1;

      for (final doc in snapshot.docs) {
        final sourceUserId = doc.reference.parent.parent?.id;
        if (sourceUserId == null ||
            sourceUserId.isEmpty ||
            sourceUserId == _uid) {
          continue;
        }

        final favoritedAt = _readMillis(doc.data()['favoritedAt']);
        final previous = byUser[sourceUserId];
        if (previous == null || favoritedAt > previous) {
          byUser[sourceUserId] = favoritedAt;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Erro ao carregar favoritos recebidos via subcolecao favorites',
        e,
        stackTrace,
      );
    }

    try {
      final snapshot = await _firestore
          .collection('interactions')
          .where('target_user_id', isEqualTo: _uid)
          .get();
      completedSources += 1;

      _mergeInteractionDocs(byUser: byUser, docs: snapshot.docs);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Erro ao carregar favoritos recebidos via interactions',
        e,
        stackTrace,
      );
    }

    try {
      final snapshot = await _firestore
          .collection('interactions')
          .where('receiverId', isEqualTo: _uid)
          .get();
      completedSources += 1;

      _mergeInteractionDocs(byUser: byUser, docs: snapshot.docs);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Erro ao carregar favoritos recebidos via interactions legado',
        e,
        stackTrace,
      );
    }

    final desiredCount = expectedCount?.clamp(0, 1000).toInt();
    if (desiredCount != null && byUser.length < desiredCount) {
      try {
        await _loadLegacyReceivedFavoritesViaUserScan(
          byUser: byUser,
          desiredCount: desiredCount,
        );
        completedSources += 1;
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Erro ao carregar favoritos recebidos via fallback legado',
          e,
          stackTrace,
        );
      }
    }

    if (completedSources == 0) {
      throw Exception('Nao foi possivel carregar favoritos recebidos agora.');
    }

    final entries = byUser.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((entry) => entry.key).toList();
  }

  /// Reads global like count for a target user.
  ///
  /// Source of truth is `users/{targetId}`. Legacy fallback to
  /// `profiles/{targetId}` is preserved for compatibility.
  Future<int> getLikeCount(String targetId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(targetId).get();
      if (userDoc.exists) {
        return _readLikeCount(userDoc.data());
      }

      final profileDoc = await _firestore
          .collection('profiles')
          .doc(targetId)
          .get();
      if (profileDoc.exists) {
        return _readLikeCount(profileDoc.data());
      }

      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Adds a favorite for the current user.
  ///
  /// Client only writes to `users/{me}/favorites/{targetId}`.
  /// Global counters are updated by backend triggers.
  Future<void> addFavorite(String targetId) async {
    final userRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(targetId);

    await userRef.set({
      'favoritedAt': FieldValue.serverTimestamp(),
      'source_user_id': _uid,
      'target_user_id': targetId,
    }, SetOptions(merge: true));
  }

  /// Removes a favorite for the current user.
  ///
  /// Client only writes to `users/{me}/favorites/{targetId}`.
  /// Global counters are updated by backend triggers.
  Future<void> removeFavorite(String targetId) async {
    final userRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(targetId);

    await userRef.delete();
  }

  int _readLikeCount(Map<String, dynamic>? data) {
    final likeCount = data?['likeCount'];
    if (likeCount is num) {
      return likeCount.toInt();
    }

    final favoritesCount = data?['favorites_count'];
    if (favoritesCount is num) {
      return favoritesCount.toInt();
    }

    return 0;
  }

  int _readMillis(dynamic raw) {
    if (raw is Timestamp) return raw.millisecondsSinceEpoch;
    if (raw is DateTime) return raw.millisecondsSinceEpoch;
    if (raw is num) return raw.toInt();
    return 0;
  }

  void _mergeInteractionDocs({
    required Map<String, int> byUser,
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    for (final doc in docs) {
      final data = doc.data();
      if (data['type'] != 'like') continue;

      final targetUserId =
          _readNonEmptyString(data['target_user_id']) ??
          _readNonEmptyString(data['receiverId']);
      if (targetUserId != null && targetUserId != _uid) {
        continue;
      }

      final sourceUserId =
          _readNonEmptyString(data['source_user_id']) ??
          _readNonEmptyString(data['senderId']);
      if (sourceUserId == null || sourceUserId == _uid) {
        continue;
      }

      final createdAt = _readMillis(
        data['created_at'] ?? data['updated_at'] ?? data['timestamp'],
      );
      final previous = byUser[sourceUserId];
      if (previous == null || createdAt > previous) {
        byUser[sourceUserId] = createdAt;
      }
    }
  }

  String? _readNonEmptyString(dynamic raw) {
    if (raw is! String) return null;
    final value = raw.trim();
    if (value.isEmpty) return null;
    return value;
  }

  Future<void> _loadLegacyReceivedFavoritesViaUserScan({
    required Map<String, int> byUser,
    required int desiredCount,
  }) async {
    const usersPageSize = 200;
    const checkBatchSize = 20;
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (byUser.length < desiredCount) {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .orderBy(FieldPath.documentId)
          .limit(usersPageSize);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final usersPage = await query.get();
      if (usersPage.docs.isEmpty) break;

      cursor = usersPage.docs.last;

      final candidates = usersPage.docs
          .map((doc) => doc.id)
          .where((userId) => userId != _uid && !byUser.containsKey(userId))
          .toList();

      for (
        var i = 0;
        i < candidates.length && byUser.length < desiredCount;
        i += checkBatchSize
      ) {
        final end = math.min(i + checkBatchSize, candidates.length);
        final batch = candidates.sublist(i, end);

        final checks = await Future.wait(
          batch.map((sourceUserId) async {
            final favoriteDoc = await _firestore
                .collection('users')
                .doc(sourceUserId)
                .collection('favorites')
                .doc(_uid)
                .get();

            if (!favoriteDoc.exists) return null;
            final favoritedAt = _readMillis(favoriteDoc.data()?['favoritedAt']);
            return MapEntry(sourceUserId, favoritedAt);
          }),
        );

        for (final entry in checks.whereType<MapEntry<String, int>>()) {
          final previous = byUser[entry.key];
          if (previous == null || entry.value > previous) {
            byUser[entry.key] = entry.value;
          }
          if (byUser.length >= desiredCount) break;
        }
      }

      if (usersPage.docs.length < usersPageSize) break;
    }
  }
}

@Riverpod(keepAlive: true)
FavoriteRepository favoriteRepository(Ref ref) {
  return FavoriteRepository(
    ref.read(firebaseFirestoreProvider),
    ref.read(firebaseAuthProvider),
  );
}
