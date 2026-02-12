import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
}

@Riverpod(keepAlive: true)
FavoriteRepository favoriteRepository(Ref ref) {
  return FavoriteRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}
