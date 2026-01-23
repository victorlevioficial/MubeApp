import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../../../utils/geohash_helper.dart';
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
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          )
          .where(
            FirestoreFields.profileType,
            whereIn: [
              ProfileType.professional,
              ProfileType.band,
              ProfileType.studio,
            ],
          )
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
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          )
          .where(FirestoreFields.profileType, isEqualTo: type)
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
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          )
          .where(FirestoreFields.profileType, isEqualTo: type)
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
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          )
          .where(
            FirestoreFields.profileType,
            isEqualTo: ProfileType.professional,
          )
          .where(
            '${FirestoreFields.professional}.${FirestoreFields.category}',
            isEqualTo: category,
          )
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
      final user = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .get();
      final userGeohash = user.data()?[FirestoreFields.geohash] as String?;

      if (userLat != null && userLong != null) {
        final allItems = await getAllUsersSortedByDistance(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: ProfileType.professional,
          excludeCategory: ProfessionalCategory.techCrew,
          userGeohash: userGeohash,
        );
        return allItems.take(limit).toList();
      }

      // Fallback if no location
      final query = _firestore
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          )
          .where(
            FirestoreFields.profileType,
            isEqualTo: ProfileType.professional,
          )
          .limit(limit * 2);

      final snapshot = await query.get();
      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );
      return items
          .where((item) => item.categoria != ProfessionalCategory.techCrew)
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
    try {
      final user = await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .get();
      final userGeohash = user.data()?[FirestoreFields.geohash] as String?;

      if (userLat != null && userLong != null) {
        final allItems = await getAllUsersSortedByDistance(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: ProfileType.professional,
          category: ProfessionalCategory.techCrew,
          userGeohash: userGeohash,
        );
        return allItems.take(limit).toList();
      }

      return getUsersByCategory(
        category: ProfessionalCategory.techCrew,
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        limit: limit,
      );
    } catch (_) {
      rethrow;
    }
  }

  // Helper to process query snapshot with favorite status
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
      final allUsers = await _firestore
          .collection(FirestoreCollections.users)
          .limit(5)
          .get();
      report.writeln('Total users found (limit 5): ${allUsers.docs.length}');

      if (allUsers.docs.isEmpty) {
        report.writeln('⚠️ NENHUM USUÁRIO ENCONTRADO NA COLEÇÃO "users".');
        return report.toString();
      }

      // 2. Analyze first user structure
      final firstDoc = allUsers.docs.first;
      report.writeln('=== Sample User (${firstDoc.id}) ===');
      final data = firstDoc.data();
      report.writeln('status: "${data[FirestoreFields.registrationStatus]}"');
      report.writeln('type: "${data[FirestoreFields.profileType]}"');
      report.writeln('name: "${data[FirestoreFields.name]}"');
      if (data[FirestoreFields.location] != null) {
        report.writeln('location: ${data[FirestoreFields.location]}');
      } else {
        report.writeln('⚠️ location is NULL');
      }

      // 3. Test Query Matches
      // 3. Test Query Matches
      final completeUsers = await _firestore
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          )
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
            'User ${doc.id.substring(0, 5)}... -> type: "${d[FirestoreFields.profileType]}"',
          );
        }
      }

      final proUsers = await _firestore
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.profileType,
            whereIn: [
              ProfileType.professional,
              ProfileType.band,
              ProfileType.studio,
            ],
          )
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
      final snapshot = await _firestore
          .collection(FirestoreCollections.users)
          .get();
      report.writeln('Total de documentos analisados: ${snapshot.docs.length}');

      for (final doc in snapshot.docs) {
        final data = doc.data();
        bool needsUpdate = false;
        final updates = <String, dynamic>{};

        // 1. Handle 'location' map if it exists
        if (data['location'] is Map) {
          final location = Map<String, dynamic>.from(data['location'] as Map);

          // Rename long -> lng inside location
          if (location.containsKey('long')) {
            location['lng'] = location['long'];
            location.remove('long');
            updates['location'] = location;
            needsUpdate = true;
          }
        }

        // 2. Handle root-level lat/long (Legacy check)
        // If lat/long are at root, move them to location map
        if (data.containsKey('lat') || data.containsKey('long')) {
          final existingLocation = data['location'] is Map
              ? Map<String, dynamic>.from(data['location'] as Map)
              : <String, dynamic>{};

          if (data.containsKey('lat')) {
            existingLocation['lat'] = data['lat'];
            // updates['lat'] = FieldValue.delete(); // We'll keep root for safety or delete later
          }
          if (data.containsKey('long')) {
            existingLocation['lng'] = data['long'];
            // updates['long'] = FieldValue.delete();
          }

          // Also migrate other location fields if at root
          for (final field in [
            'cidade',
            'estado',
            'bairro',
            'logradouro',
            'cep',
          ]) {
            if (data.containsKey(field) &&
                !existingLocation.containsKey(field)) {
              existingLocation[field] = data[field];
            }
          }

          updates['location'] = existingLocation;
          needsUpdate = true;
        }

        // 3. Handle 'addresses' list
        if (data['addresses'] is List) {
          final addresses = List<dynamic>.from(data['addresses'] as List);
          bool addressChanged = false;

          for (int i = 0; i < addresses.length; i++) {
            if (addresses[i] is Map) {
              final addr = Map<String, dynamic>.from(addresses[i] as Map);
              if (addr.containsKey('long')) {
                addr['lng'] = addr['long'];
                addr.remove('long');
                addresses[i] = addr;
                addressChanged = true;
              }
            }
          }

          if (addressChanged) {
            updates['addresses'] = addresses;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          await _firestore
              .collection(FirestoreCollections.users)
              .doc(doc.id)
              .update(updates);
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

  /// Fetches users sorted by distance from closest to farthest.
  ///
  /// **Performance**:
  /// - WITH geohash: Queries only ~15-30 nearby users (< 1s even with 10k users)
  /// - WITHOUT geohash: Falls back to query all users (slower but works)
  ///
  /// Uses progressive loading: starts with a small limit for fast initial load,
  /// then can be called again with higher limits for more content.
  ///
  /// [limit]: Optional. If provided, limits the query to this many users.
  ///          If null, loads all users (use with caution for large datasets).
  /// [userGeohash]: Optional. If provided, uses geohash-optimized query (10x faster).
  Future<List<FeedItem>> getAllUsersSortedByDistance({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    int? limit,
    String? userGeohash,
  }) async {
    try {
      // OPTIMIZATION: Use geohash if available
      if (userGeohash != null && userGeohash.isNotEmpty) {
        return _getAllUsersSortedByDistanceGeohash(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: filterType,
          category: category,
          excludeCategory: excludeCategory,
          limit: limit,
          userGeohash: userGeohash,
        );
      }

      // FALLBACK: Use old method without geohash
      return _getAllUsersSortedByDistanceClassic(
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        filterType: filterType,
        category: category,
        excludeCategory: excludeCategory,
        limit: limit,
      );
    } catch (_) {
      rethrow;
    }
  }

  /// Geohash-optimized version (10x+ faster)
  ///
  /// IMPORTANT: Does NOT use Firestore limit!
  /// Geohash already reduces docs from 100+ to ~30 (9 quadrants).
  /// We fetch ALL from those quadrants, sort by distance, then caller
  /// paginates locally for 100% accurate proximity ordering.
  Future<List<FeedItem>> _getAllUsersSortedByDistanceGeohash({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    int? limit, // Ignored - kept for API consistency
    required String userGeohash,
  }) async {
    try {
      // Get 9 neighboring geohashes (includes center)
      final neighbors = GeohashHelper.neighbors(userGeohash);

      var query = _firestore
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          )
          .where(
            FirestoreFields.geohash,
            whereIn: neighbors,
          ); // Queries ~30 docs

      // Apply type filter if provided
      if (filterType != null && filterType.isNotEmpty) {
        query = query.where(FirestoreFields.profileType, isEqualTo: filterType);
      } else {
        query = query.where(
          FirestoreFields.profileType,
          whereIn: [
            ProfileType.professional,
            ProfileType.band,
            ProfileType.studio,
          ],
        );
      }

      // Category filter
      if (category != null && category.isNotEmpty) {
        query = query.where(
          '${FirestoreFields.professional}.${FirestoreFields.category}',
          isEqualTo: category,
        );
      }

      // Fetch ALL docs from the 9 quadrants (~30 docs)
      final snapshot = await query.get();
      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      // Exclude category filter (e.g., exclude technical crew from artists list)
      if (excludeCategory != null && excludeCategory.isNotEmpty) {
        items.removeWhere((item) => item.categoria == excludeCategory);
      }

      // Sort by distance (closest first) - THIS IS CRITICAL!
      items.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );

      // Return ALL sorted items - caller will paginate locally
      // This ensures perfect proximity ordering!
      return items;
    } catch (_) {
      rethrow;
    }
  }

  /// Classic version (fallback for users without geohash)
  Future<List<FeedItem>> _getAllUsersSortedByDistanceClassic({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    int? limit,
  }) async {
    try {
      var query = _firestore
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          );

      // Apply type filter if provided
      if (filterType != null && filterType.isNotEmpty) {
        query = query.where(FirestoreFields.profileType, isEqualTo: filterType);
      } else {
        query = query.where(
          FirestoreFields.profileType,
          whereIn: [
            ProfileType.professional,
            ProfileType.band,
            ProfileType.studio,
          ],
        );
      }

      // Category filter
      if (category != null && category.isNotEmpty) {
        query = query.where(
          '${FirestoreFields.professional}.${FirestoreFields.category}',
          isEqualTo: category,
        );
      }

      // Apply limit for progressive loading
      if (limit != null && limit > 0) {
        query = query.limit(limit);
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
          .collection(FirestoreCollections.users)
          .where(
            FirestoreFields.registrationStatus,
            isEqualTo: RegistrationStatus.complete,
          );

      // Apply filtering
      if (filterType != null &&
          filterType.isNotEmpty &&
          filterType != 'Perto de mim') {
        query = query.where(FirestoreFields.profileType, isEqualTo: filterType);
      } else if (filterType != 'Perto de mim') {
        // Default feed: show pro types
        query = query.where(
          FirestoreFields.profileType,
          whereIn: [
            ProfileType.professional,
            ProfileType.band,
            ProfileType.studio,
          ],
        );
      }

      if (limit > 0) {
        query = query.limit(limit);
      }

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
