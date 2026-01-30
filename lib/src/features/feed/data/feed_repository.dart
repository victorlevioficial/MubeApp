import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/typedefs.dart';
import '../../../utils/geohash_helper.dart';
import '../domain/feed_item.dart';
import '../domain/paginated_feed_response.dart';
import 'feed_remote_data_source.dart';

/// Provider for FeedRepository
final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  final dataSource = ref.watch(feedRemoteDataSourceProvider);
  return FeedRepository(dataSource);
});

/// Repository for feed-related data operations.
class FeedRepository {
  final FeedRemoteDataSource _dataSource;

  FeedRepository(this._dataSource);

  /// Fetches users near a location. Returns [Right(List<FeedItem>)] or [Left(Failure)].
  FutureResult<List<FeedItem>> getNearbyUsers({
    required double lat,
    required double long,
    required double radiusKm,
    required String currentUserId,
    List<String> excludedIds = const [],
    int limit = 10,
  }) async {
    try {
      final snapshot = await _dataSource.getNearbyUsers(limit: limit * 2);
      final items = <FeedItem>[];

      for (final doc in snapshot.docs) {
        if (doc.id == currentUserId || excludedIds.contains(doc.id)) continue;

        try {
          final data = doc.data();
          var item = FeedItem.fromFirestore(data, doc.id);

          if (item.location != null) {
            final itemLat = item.location!['lat'] as double?;
            final itemLng = item.location!['lng'] as double?;

            if (itemLat != null && itemLng != null) {
              item = item.copyWith(
                distanceKm: _calculateDistance(lat, long, itemLat, itemLng),
              );
              if (item.distanceKm! <= radiusKm) {
                items.add(item);
              }
            }
          }
        } catch (_) {
          continue;
        }
      }

      items.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );
      return Right(items.take(limit).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetches users by profile type.
  FutureResult<List<FeedItem>> getUsersByType({
    required String type,
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final snapshot = await _dataSource.getUsersByType(
        type: type,
        limit: limit + excludedIds.length, // Fetch more to compensate
        startAfter: startAfter,
      );
      final allItems = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      // Filter blocked users
      final filteredItems = allItems
          .where((item) => !excludedIds.contains(item.uid))
          .take(limit)
          .toList();

      return Right(filteredItems);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetches users by profile type with pagination support.
  FutureResult<PaginatedFeedResponse> getUsersByTypePaginated({
    required String type,
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final snapshot = await _dataSource.getUsersByType(
        type: type,
        limit: limit,
        startAfter: startAfter,
      );
      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      return Right(
        PaginatedFeedResponse(
          items: items,
          lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
          hasMore: snapshot.docs.length >= limit,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetches professional users by category.
  FutureResult<List<FeedItem>> getUsersByCategory({
    required String category,
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final snapshot = await _dataSource.getUsersByCategory(
        category: category,
        limit: limit + excludedIds.length,
        startAfter: startAfter,
      );
      final allItems = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      final filteredItems = allItems
          .where((item) => !excludedIds.contains(item.uid))
          .take(limit)
          .toList();

      return Right(filteredItems);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetches artists (professional profiles excluding technical crew).
  FutureResult<List<FeedItem>> getArtists({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    try {
      final userDoc = await _dataSource.getUser(currentUserId);
      final userGeohash = userDoc.data()?[FirestoreFields.geohash] as String?;

      if (userLat != null && userLong != null) {
        final result = await getAllUsersSortedByDistance(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: ProfileType.professional,
          excludeCategory: ProfessionalCategory.techCrew,
          userGeohash: userGeohash,
          excludedIds: excludedIds,
        );

        // Handle result of getAllUsersSortedByDistance (which is now async result)
        return result.map((items) => items.take(limit).toList());
      }

      // Fallback
      final snapshot = await _dataSource.getUsersByType(
        type: ProfileType.professional,
        limit: limit * 2,
        startAfter: null,
      );

      final items = _processSnapshot(
        snapshot,
        currentUserId,
        userLat,
        userLong,
      );

      return Right(
        items
            .where(
              (item) =>
                  item.categoria != ProfessionalCategory.techCrew &&
                  !excludedIds.contains(item.uid),
            )
            .take(limit)
            .toList(),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetches technical crew only.
  FutureResult<List<FeedItem>> getTechnicians({
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    try {
      final userDoc = await _dataSource.getUser(currentUserId);
      final userGeohash = userDoc.data()?[FirestoreFields.geohash] as String?;

      if (userLat != null && userLong != null) {
        final result = await getAllUsersSortedByDistance(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: ProfileType.professional,
          category: ProfessionalCategory.techCrew,
          userGeohash: userGeohash,
        );
        return result.map((items) => items.take(limit).toList());
      }

      // Fallback
      final snapshot = await _dataSource.getUsersByCategory(
        category: ProfessionalCategory.techCrew,
        limit: limit,
        startAfter: null,
      );

      return Right(
        _processSnapshot(snapshot, currentUserId, userLat, userLong),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  List<FeedItem> _processSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
    double? userLat,
    double? userLong,
  ) {
    final items = <FeedItem>[];

    for (final doc in snapshot.docs) {
      if (doc.id == currentUserId) continue;

      var item = FeedItem.fromFirestore(doc.data(), doc.id);

      // Calculate distance if we have user location
      if (userLat != null && userLong != null && item.location != null) {
        final itemLat = item.location!['lat'] as double?;
        final itemLng = item.location!['lng'] as double?;

        if (itemLat != null && itemLng != null) {
          item = item.copyWith(
            distanceKm: _calculateDistance(userLat, userLong, itemLat, itemLng),
          );
        }
      }

      items.add(item);
    }

    return items;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0;
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

  FutureResult<List<FeedItem>> getAllUsersSortedByDistance({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    List<String> excludedIds = const [],
    int? limit,
    String? userGeohash,
  }) async {
    try {
      if (userGeohash != null && userGeohash.isNotEmpty) {
        return _getAllUsersSortedByDistanceGeohash(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: filterType,
          category: category,
          excludeCategory: excludeCategory,
          userGeohash: userGeohash,
          excludedIds: excludedIds,
        );
      }

      return _getAllUsersSortedByDistanceClassic(
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        filterType: filterType,
        category: category,
        excludeCategory: excludeCategory,
        excludedIds: excludedIds,
        limit: limit,
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<List<FeedItem>> _getAllUsersSortedByDistanceGeohash({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    required String userGeohash,
    List<String> excludedIds = const [],
  }) async {
    final neighbors = GeohashHelper.neighbors(userGeohash);

    final snapshot = await _dataSource.getGeohashNeighbors(
      neighbors: neighbors,
      filterType: filterType,
      category: category,
    );

    final items = _processSnapshot(snapshot, currentUserId, userLat, userLong);

    // Filter blocked
    if (excludedIds.isNotEmpty) {
      items.removeWhere((item) => excludedIds.contains(item.uid));
    }

    if (excludeCategory != null && excludeCategory.isNotEmpty) {
      items.removeWhere((item) => item.categoria == excludeCategory);
    }

    items.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

    return Right(items);
  }

  FutureResult<List<FeedItem>> _getAllUsersSortedByDistanceClassic({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    List<String> excludedIds = const [],
    int? limit,
  }) async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    if (category != null) {
      // Prioritize category search at DB level to ensure we get results
      snapshot = await _dataSource.getUsersByCategory(
        category: category,
        limit: limit ?? 50,
        startAfter: null,
      );
    } else {
      snapshot = await _dataSource.getMainFeed(
        filterType: filterType,
        limit: limit ?? 50,
        startAfter: null,
      );
    }

    final items = _processSnapshot(snapshot, currentUserId, userLat, userLong);

    if (category != null) {
      items.retainWhere((i) => i.categoria == category);
    }

    // Filter blocked
    if (excludedIds.isNotEmpty) {
      items.removeWhere((item) => excludedIds.contains(item.uid));
    }

    if (excludeCategory != null) {
      items.removeWhere((i) => i.categoria == excludeCategory);
    }

    items.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));

    return Right(items);
  }

  FutureResult<PaginatedFeedResponse> getMainFeedPaginated({
    required String currentUserId,
    String? filterType,
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      final snapshot = await _dataSource.getMainFeed(
        filterType: filterType,
        limit: limit,
        startAfter: startAfter,
      );

      var items = _processSnapshot(snapshot, currentUserId, userLat, userLong);

      if (filterType == 'Perto de mim' && userLat != null && userLong != null) {
        items = items
            .where((i) => i.distanceKm != null && i.distanceKm! <= 50)
            .toList();
        items.sort(
          (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
        );
      }

      return Right(
        PaginatedFeedResponse(
          items: items,
          lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
          hasMore: snapshot.docs.length >= limit,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Fetches users by a list of IDs (for Favorites).
  FutureResult<List<FeedItem>> getUsersByIds({
    required List<String> ids,
    required String currentUserId,
    double? userLat,
    double? userLong,
  }) async {
    try {
      if (ids.isEmpty) return const Right([]);

      // Batching for > 30 items
      final List<FeedItem> allItems = [];

      // Chunking logic if list is large
      const batchSize = 30;
      for (var i = 0; i < ids.length; i += batchSize) {
        final end = (i + batchSize < ids.length) ? i + batchSize : ids.length;
        final batchIds = ids.sublist(i, end);

        final snapshot = await _dataSource.getUsersByIds(batchIds);
        final batchItems = _processSnapshot(
          snapshot,
          currentUserId,
          userLat,
          userLong,
        );
        allItems.addAll(batchItems);
      }

      return Right(allItems);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
