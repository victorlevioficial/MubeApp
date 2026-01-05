import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feed_item.dart';

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
    print('DEBUG: getNearbyUsers called');
    print(
      'DEBUG: Params - lat: $lat, long: $long, radius: $radiusKm, user: $currentUserId',
    );

    try {
      // DEBUG: Check if any users exist at all and dump them to console
      // This helps verify if 'cadastro_status' or 'tipoPerfil' match what we expect
      final debugSnapshot = await _firestore.collection('users').limit(5).get();
      print('DEBUG: RAW SAMPLE of ${debugSnapshot.docs.length} users from DB:');
      for (var d in debugSnapshot.docs) {
        print(
          'DEBUG: User ${d.id} -> cadastro_status: "${d.data()['cadastro_status']}", tipoPerfil: "${d.data()['tipoPerfil']}", nome: "${d.data()['nome']}"',
        );
      }

      final query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', whereIn: ['profissional', 'banda', 'estudio'])
          .limit(limit * 2);

      print('DEBUG: Executing getNearbyUsers Firestore query...');
      final snapshot = await query.get();
      print('DEBUG: Snapshot received. Docs count: ${snapshot.docs.length}');

      final items = <FeedItem>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;

        try {
          final data = doc.data();
          final item = FeedItem.fromFirestore(data, doc.id);

          if (item.location != null) {
            final itemLat = item.location!['lat'] as double?;
            final itemLong = item.location!['long'] as double?;

            if (itemLat != null && itemLong != null) {
              item.distanceKm = _calculateDistance(
                lat,
                long,
                itemLat,
                itemLong,
              );
              print(
                'DEBUG: Item ${item.displayName} distance: ${item.distanceKm?.toStringAsFixed(2)} km',
              );

              if (item.distanceKm! <= radiusKm) {
                items.add(item);
              } else {
                print(
                  'DEBUG: Filtered out ${item.displayName} (distance > radius)',
                );
              }
            }
          } else {
            print('DEBUG: Filtered out ${item.displayName} (no location)');
          }
        } catch (e) {
          print('DEBUG: Error parsing item ${doc.id}: $e');
        }
      }

      items.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );

      print(
        'DEBUG: Returning ${items.take(limit).length} items from getNearbyUsers',
      );
      return items.take(limit).toList();
    } catch (e) {
      print('DEBUG: Error in getNearbyUsers query: $e');
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
    print('DEBUG: getUsersByType called for $type');
    try {
      var query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', isEqualTo: type)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      print('DEBUG: Executing getUsersByType query...');
      final snapshot = await query.get();
      print('DEBUG: getUsersByType result: ${snapshot.docs.length} docs');

      return _processSnapshot(snapshot, currentUserId, userLat, userLong);
    } catch (e) {
      print('DEBUG: Error in getUsersByType: $e');
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
    print('DEBUG: getUsersByCategory called for $category');
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
      print('DEBUG: getUsersByCategory result: ${snapshot.docs.length} docs');

      return _processSnapshot(snapshot, currentUserId, userLat, userLong);
    } catch (e) {
      print('DEBUG: Error in getUsersByCategory: $e');
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
    print('DEBUG: getArtists called');
    try {
      final query = _firestore
          .collection('users')
          .where('cadastro_status', isEqualTo: 'concluido')
          .where('tipo_perfil', isEqualTo: 'profissional')
          .limit(limit * 2);

      final snapshot = await query.get();
      print('DEBUG: getArtists query result: ${snapshot.docs.length} docs');

      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      // Filter out technical crew
      final filtered = items
          .where((item) => item.categoria != 'Equipe Técnica')
          .take(limit)
          .toList();

      print('DEBUG: getArtists filtered result: ${filtered.length} items');
      return filtered;
    } catch (e) {
      print('DEBUG: Error in getArtists: $e');
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
        final itemLong = item.location!['long'] as double?;

        if (itemLat != null && itemLong != null) {
          item.distanceKm = _calculateDistance(
            userLat,
            userLong,
            itemLat,
            itemLong,
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
}
