import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feed_item.dart';
import '../domain/paginated_feed_response.dart';

/// Provider for FeedRepository
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(FirebaseFirestore.instance);
});

/// Repository for feed-related data operations.
class FeedRepository {
  final FirebaseFirestore _firestore;

  FeedRepository(this._firestore);

  /// Fetches users near a location within a radius.
  Future<List<FeedItem>> getNearbyUsers({
    required double lat,
    required double long,
    required double radiusKm,
    required String currentUserId,
    int limit = 10,
  }) async {
    try {
      final query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', whereIn: ['profissional', 'banda', 'estudio'])
          .limit(limit * 2);

      final snapshot = await query.get();
      final items = <FeedItem>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;

        try {
          final data = doc.data();
          final item = FeedItem.fromFirestore(data, doc.id);

          if (item.location != null) {
            final itemLat = item.location!['lat'] as double?;
            final itemLng = item.location!['lng'] as double?;

            if (itemLat != null && itemLng != null) {
              item.distanceKm = _calculateDistance(lat, long, itemLat, itemLng);
              if (item.distanceKm! <= radiusKm) {
                items.add(item);
              }
            }
          }
        } catch (_) {
          // Skip invalid items
        }
      }

      items.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );
      return items.take(limit).toList();
    } catch (_) {
      rethrow;
    }
  }

  /// Fetches users by profile type.
  Future<List<FeedItem>> getUsersByType({
    required String type,
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', isEqualTo: type)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return _processSnapshot(snapshot, currentUserId, userLat, userLong);
    } catch (_) {
      rethrow;
    }
  }

  /// Fetches users by profile type with pagination support.
  /// Returns a [PaginatedFeedResponse] with items and cursor for next page.
  Future<PaginatedFeedResponse> getUsersByTypePaginated({
    required String type,
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', isEqualTo: type)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      return PaginatedFeedResponse(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length >= limit,
      );
    } catch (_) {
      rethrow;
    }
  }

  /// Fetches professional users by category.
  Future<List<FeedItem>> getUsersByCategory({
    required String category,
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', isEqualTo: 'profissional')
          .where('profissional.categoria', isEqualTo: category)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return _processSnapshot(snapshot, currentUserId, userLat, userLong);
    } catch (_) {
      rethrow;
    }
  }

  /// Fetches artists (professional profiles excluding technical crew).
  Future<List<FeedItem>> getArtists({
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    try {
      final query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', isEqualTo: 'profissional')
          .limit(limit * 2);

      final snapshot = await query.get();
      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      // Filter out technical crew
      return items
          .where((item) => item.categoria != 'Equipe Técnica')
          .take(limit)
          .toList();
    } catch (_) {
      rethrow;
    }
  }

  /// Fetches technical crew only.
  Future<List<FeedItem>> getTechnicians({
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    return getUsersByCategory(
      category: 'Equipe Técnica',
      currentUserId: currentUserId,
      userLat: userLat,
      userLong: userLong,
      limit: limit,
    );
  }

  /// Toggles favorite status for a user.
  Future<bool> toggleFavorite({
    required String userId,
    required String targetId,
  }) async {
    final favoriteRef = _firestore
        .collection('favorites')
        .doc('${userId}_$targetId');

    final targetRef = _firestore.collection('users').doc(targetId);

    return _firestore.runTransaction((transaction) async {
      final favoriteDoc = await transaction.get(favoriteRef);

      if (favoriteDoc.exists) {
        // Remove favorite
        transaction.delete(favoriteRef);
        transaction.update(targetRef, {
          'favoriteCount': FieldValue.increment(-1),
        });
        return false;
      } else {
        // Add favorite
        transaction.set(favoriteRef, {
          'userId': userId,
          'targetId': targetId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(targetRef, {
          'favoriteCount': FieldValue.increment(1),
        });
        return true;
      }
    });
  }

  /// Checks if user has favorited a target.
  Future<bool> isFavorited({
    required String userId,
    required String targetId,
  }) async {
    final doc = await _firestore
        .collection('favorites')
        .doc('${userId}_$targetId')
        .get();
    return doc.exists;
  }

  /// Gets list of user's favorites.
  Future<Set<String>> getUserFavorites(String userId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => doc.data()['targetId'] as String).toSet();
  }

  /// Gets list of favorited feed items for a user
  Future<List<FeedItem>> getFavoriteItems({
    required String userId,
    double? userLat,
    double? userLong,
    int limit = 20,
  }) async {
    // Get favorite IDs
    final favoriteIds = await getUserFavorites(userId);

    if (favoriteIds.isEmpty) {
      return [];
    }

    // Firestore 'whereIn' supports max 10 items, so we batch
    final batches = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    final idBatches = _chunk(favoriteIds.toList(), 10);

    for (final batch in idBatches) {
      batches.add(
        _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get(),
      );
    }

    final results = await Future.wait(batches);
    final items = <FeedItem>[];

    for (final snapshot in results) {
      items.addAll(_processSnapshot(snapshot, userId, userLat, userLong));
    }

    // Sort by favoriteCount (most popular first) or distance
    if (userLat != null && userLong != null) {
      items.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );
    } else {
      items.sort((a, b) => b.favoriteCount.compareTo(a.favoriteCount));
    }

    return items.take(limit).toList();
  }

  /// Helper to chunk a list into batches
  List<List<T>> _chunk<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  // Helper to process query snapshot
  List<FeedItem> _processSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
    double? userLat,
    double? userLong,
  ) {
    final items = <FeedItem>[];

    for (final doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;

      final data = doc.data();
      final item = FeedItem.fromFirestore(data, doc.id);

      // Calculate distance if we have user location
      if (userLat != null && userLong != null && item.location != null) {
        final itemLat = item.location!['lat'] as double?;
        final itemLng = item.location!['lng'] as double?;

        if (itemLat != null && itemLng != null) {
          item.distanceKm = _calculateDistance(
            userLat,
            userLong,
            itemLat,
            itemLng,
          );
        }
      }

      items.add(item);
    }

    return items;
  }

  /// Haversine formula for distance calculation.
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// DIAGNOSTIC METHOD
  Future<String> debugDiagnose({required String currentUserId}) async {
    final report = StringBuffer();
    report.writeln('=== DIAGNÓSTICO DO FREED ===');
    report.writeln('User ID: $currentUserId');

    try {
      // 1. Check connection and total users
      final allUsers = await _firestore.collection('users').limit(5).get();
      report.writeln('Total users found (limit 5): ${allUsers.docs.length}');

      if (allUsers.docs.isEmpty) {
        report.writeln('⚠️ NENHUM USUÁRIO ENCONTRADO NA COLEÇÃO "users".');
        return report.toString();
      }

      // 2. Analyze first user structure
      final firstDoc = allUsers.docs.first;
      report.writeln('-- Sample User (${firstDoc.id}) --');
      final data = firstDoc.data();
      report.writeln('cadastro_status: "${data['cadastro_status']}"');
      report.writeln('tipoPerfil: "${data['tipoPerfil']}"');
      report.writeln('nome: "${data['nome']}"');
      if (data['location'] != null) {
        report.writeln('location: ${data['location']}');
      } else {
        report.writeln('⚠️ location is NULL');
      }

      // 3. Test Query Matches
      // 3. Test Query Matches
      final completeUsers = await _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .limit(10)
          .get();
      report.writeln(
        'Users with status="concluido": ${completeUsers.docs.length}',
      );

      if (completeUsers.docs.isNotEmpty) {
        report.writeln('-- Analyzing Completed Users --');
        for (var doc in completeUsers.docs) {
          final d = doc.data();
          report.writeln(
            'User ${doc.id.substring(0, 5)}... -> tipo_perfil: "${d['tipo_perfil']}"',
          );
        }
      }

      final proUsers = await _firestore
          .collection('users')
          .where('tipo_perfil', whereIn: ['profissional', 'banda', 'estudio'])
          .get();
      report.writeln('Users with valid profile type: ${proUsers.docs.length}');
    } catch (e) {
      report.writeln('❌ ERRO NO DIAGNÓSTICO: $e');
    }

    return report.toString();
  }

  /// ONE-TIME MIGRATION: Rename 'long' to 'lng' in all user location fields.
  /// This should be called once to fix existing data to the new standard.
  Future<String> migrateLocationLongToLng() async {
    final report = StringBuffer();
    report.writeln('=== MIGRAÇÃO: long -> lng ===');

    int updated = 0;
    int skipped = 0;

    try {
      final snapshot = await _firestore.collection('users').get();
      report.writeln('Total de usuários: ${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = data['location'] as Map<String, dynamic>?;

        if (location != null &&
            location['long'] != null &&
            location['lng'] == null) {
          // Create new location map with 'lng' instead of 'long'
          final newLocation = Map<String, dynamic>.from(location);
          newLocation['lng'] = newLocation['long'];
          newLocation.remove('long');

          await _firestore.collection('users').doc(doc.id).update({
            'location': newLocation,
          });

          report.writeln('✅ Atualizado: ${doc.id.substring(0, 8)}...');
          updated++;
        } else {
          skipped++;
        }
      }

      report.writeln('');
      report.writeln('Migração concluída!');
      report.writeln('Atualizados: $updated');
      report.writeln('Ignorados: $skipped');
    } catch (e) {
      report.writeln('❌ ERRO: $e');
    }

    return report.toString();
  }

  /// Fetches ALL users sorted by distance from closest to farthest.
  /// This is an Option B approach that loads everything and sorts locally.
  /// Suitable for apps with < 10,000 users.
  Future<List<FeedItem>> getAllUsersSortedByDistance({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido');

      // Apply type filter if provided
      if (filterType != null && filterType.isNotEmpty) {
        query = query.where('tipo_perfil', isEqualTo: filterType);
      } else {
        query = query.where(
          'tipo_perfil',
          whereIn: ['profissional', 'banda', 'estudio'],
        );
      }

      final snapshot = await query.get();
      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      // Sort by distance (closest first)
      items.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );

      return items;
    } catch (_) {
      rethrow;
    }
  }

  /// Fetches the main feed with optional filtering and pagination.
  ///
  /// [filterType]: Optional. If provided, filters by 'tipo_perfil' (e.g., 'profissional', 'banda', 'estudio').
  /// If null, returns all valid profile types.
  Future<PaginatedFeedResponse> getMainFeedPaginated({
    required String currentUserId,
    String? filterType,
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      var query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido');

      // Apply filter if selected, otherwise fetch all relevant types
      if (filterType != null && filterType.isNotEmpty) {
        if (filterType == 'Perto de mim' &&
            userLat != null &&
            userLong != null) {
          // Geo-query simulation: fetch larger batch and filter locally or use geohash
          // For MVP without Geofire: fetch all valid types and sort by distance locally (heavy)
          // OR: Just return 'profissional' sorted by created_at for now as per plan
          query = query.where(
            'tipo_perfil',
            whereIn: ['profissional', 'banda', 'estudio'],
          );
        } else {
          query = query.where('tipo_perfil', isEqualTo: filterType);
        }
      } else {
        query = query.where(
          'tipo_perfil',
          whereIn: ['profissional', 'banda', 'estudio'],
        );
      }

      // Order by generic field (e.g. created_at)
      // Note: This requires an index compound with filters.
      // For now, let's rely on default ordering or add simplistic ordering if index exists.
      // query = query.orderBy('created_at', descending: true);

      query = query.limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      var items = _processSnapshot(snapshot, currentUserId, userLat, userLong);

      // Post-processing for "Perto de mim" specific filter
      if (filterType == 'Perto de mim' && userLat != null && userLong != null) {
        items = items
            .where((i) => i.distanceKm != null && i.distanceKm! <= 50)
            .toList();
        items.sort(
          (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
        );
      }

      return PaginatedFeedResponse(
        items: items,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length >= limit,
      );
    } catch (_) {
      rethrow;
    }
  }
}
