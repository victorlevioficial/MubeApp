import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failure_mapper.dart';

import '../../../core/typedefs.dart';

import '../../../utils/app_logger.dart';
import '../../../utils/distance_calculator.dart';
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
  ///
  /// Uses Geohash-based query when available for efficient server-side filtering.
  FutureResult<List<FeedItem>> getNearbyUsers({
    required double lat,
    required double long,
    required double radiusKm,
    required String currentUserId,
    List<String> excludedIds = const [],
    int limit = 10,
  }) async {
    try {
      // Get user's geohash for optimized query
      final userDoc = await _dataSource.getUser(currentUserId);
      final userGeohash = userDoc.data()?[FirestoreFields.geohash] as String?;

      // Use the optimized geohash-based query
      final result = await getAllUsersSortedByDistance(
        currentUserId: currentUserId,
        userLat: lat,
        userLong: long,
        userGeohash: userGeohash,
        excludedIds: excludedIds,
        radiusKm: radiusKm,
      );

      return result.map((items) => items.take(limit).toList());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
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
      return Left(mapExceptionToFailure(e));
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
      return Left(mapExceptionToFailure(e));
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
      return Left(mapExceptionToFailure(e));
    }
  }

  /// Fetches artists (professional profiles excluding technical crew).
  FutureResult<List<FeedItem>> getArtists({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
  }) => _getFilteredProfessionals(
    currentUserId: currentUserId,
    userLat: userLat,
    userLong: userLong,
    limit: limit,
    excludedIds: excludedIds,
    excludeCategory: ProfessionalCategory.techCrew,
  );

  /// Fetches technical crew only.
  FutureResult<List<FeedItem>> getTechnicians({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
  }) => _getFilteredProfessionals(
    currentUserId: currentUserId,
    userLat: userLat,
    userLong: userLong,
    limit: limit,
    excludedIds: excludedIds,
    includeCategory: ProfessionalCategory.techCrew,
  );

  /// Private method containing the shared logic for filtering professionals.
  FutureResult<List<FeedItem>> _getFilteredProfessionals({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required int limit,
    List<String> excludedIds = const [],
    String? includeCategory,
    String? excludeCategory,
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
          category: includeCategory,
          excludeCategory: excludeCategory,
          userGeohash: userGeohash,
          excludedIds: excludedIds,
        );
        return result.map((items) => items.take(limit).toList());
      }

      // Fallback without location
      final snapshot = includeCategory != null
          ? await _dataSource.getUsersByCategory(
              category: includeCategory,
              limit: limit,
              startAfter: null,
            )
          : await _dataSource.getUsersByType(
              type: ProfileType.professional,
              limit: limit * 2,
              startAfter: null,
            );

      var items = _processSnapshot(snapshot, currentUserId, userLat, userLong);

      // Apply filters
      if (excludeCategory != null) {
        items = items.where((i) => i.categoria != excludeCategory).toList();
      }
      if (excludedIds.isNotEmpty) {
        items = items.where((i) => !excludedIds.contains(i.uid)).toList();
      }

      return Right(items.take(limit).toList());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
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
            distanceKm: DistanceCalculator.haversine(
              fromLat: userLat,
              fromLng: userLong,
              toLat: itemLat,
              toLng: itemLng,
            ),
          );
        }
      }

      items.add(item);
    }

    return items;
  }

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
    double? radiusKm,
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
          radiusKm: radiusKm,
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
        radiusKm: radiusKm,
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
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
    double? radiusKm,
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

    // Filter by radius if specified
    if (radiusKm != null) {
      items.removeWhere(
        (item) => item.distanceKm == null || item.distanceKm! > radiusKm,
      );
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
    double? radiusKm,
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

    // Filter by radius if specified
    if (radiusKm != null) {
      items.removeWhere(
        (item) => item.distanceKm == null || item.distanceKm! > radiusKm,
      );
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
      return Left(mapExceptionToFailure(e));
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
      return Left(mapExceptionToFailure(e));
    }
  }

  /// Busca usuários próximos usando geohash com busca progressiva otimizada.
  /// 
  /// Esta é a melhor prática para performance com grandes volumes:
  /// 1. Busca primeiro no geohash do usuário (5km x 5km)
  /// 2. Se não tiver suficientes, expande para vizinhos progressivamente
  /// 3. Limita a 20 resultados por query (eficiente no Firestore)
  /// 4. Ordena por distância real calculada
  /// 
  /// Com 50k usuários, isso lê apenas ~20-60 documentos em vez de 150+
  FutureResult<List<FeedItem>> getNearbyUsersOptimized({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    List<String> excludedIds = const [],
    int targetResults = 20,
  }) async {
    try {
      final List<FeedItem> results = [];
      final Set<String> seenUids = {};
      
      // Gera geohash do usuário com precisão 5 (~5km x 5km)
      final userGeohash = GeohashHelper.encode(userLat, userLong, precision: 5);
      
      // 1. Primeiro busca no geohash do usuário (mais próximos)
      final centerSnapshot = await _dataSource.getUsersByGeohash(
        geohash: userGeohash,
        filterType: filterType,
        limit: targetResults,
      );
      
      _processGeohashResults(
        centerSnapshot,
        results,
        seenUids,
        currentUserId,
        userLat,
        userLong,
        excludedIds,
      );
      
      // 2. Se não tiver suficientes, expande para vizinhos (9 áreas ao todo)
      if (results.length < targetResults) {
        final neighbors = GeohashHelper.neighbors(userGeohash);
        // Remove o centro que já buscamos
        neighbors.remove(userGeohash);
        
        // Busca em cada vizinho até ter resultados suficientes
        for (final neighborHash in neighbors) {
          if (results.length >= targetResults) break;
          
          final neighborSnapshot = await _dataSource.getUsersByGeohash(
            geohash: neighborHash,
            filterType: filterType,
            limit: targetResults - results.length,
          );
          
          _processGeohashResults(
            neighborSnapshot,
            results,
            seenUids,
            currentUserId,
            userLat,
            userLong,
            excludedIds,
          );
        }
      }
      
      // 3. Ordena por distância real calculada
      results.sort((a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999));
      
      // 4. Fallback: se não encontrou nada com geohash, busca todos
      if (results.isEmpty) {
        AppLogger.info('⚠️ Nenhum usuário com geohash encontrado. Usando fallback...');
        return _getAllUsersSortedByDistanceClassic(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: filterType,
          excludedIds: excludedIds,
          limit: targetResults,
        );
      }
      
      return Right(results);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
  
  /// Processa resultados de uma query de geohash
  void _processGeohashResults(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    List<FeedItem> results,
    Set<String> seenUids,
    String currentUserId,
    double userLat,
    double userLong,
    List<String> excludedIds,
  ) {
    for (final doc in snapshot.docs) {
      // Skip self
      if (doc.id == currentUserId) continue;
      
      // Skip duplicates
      if (seenUids.contains(doc.id)) continue;
      
      // Skip blocked
      if (excludedIds.contains(doc.id)) continue;
      
      final data = doc.data();
      
      // Skip contractors
      if (data['tipo_perfil'] == 'contratante') continue;
      
      // Skip incomplete profiles
      final cadastroStatus = data['cadastro_status'] as String?;
      final status = data['status'] as String? ?? 'ativo';
      if (cadastroStatus != 'concluido' || status != 'ativo') continue;
      
      // Skip ghost mode
      final privacy = data['privacy_settings'] as Map<String, dynamic>?;
      if (privacy != null && privacy['visible_in_home'] == false) continue;
      
      var item = FeedItem.fromFirestore(data, doc.id);
      
      // Calculate exact distance
      if (item.location != null) {
        final itemLat = item.location!['lat'] as double?;
        final itemLng = item.location!['lng'] as double?;
        if (itemLat != null && itemLng != null) {
          item = item.copyWith(
            distanceKm: DistanceCalculator.haversine(
              fromLat: userLat,
              fromLng: userLong,
              toLat: itemLat,
              toLng: itemLng,
            ),
          );
        }
      }
      
      seenUids.add(doc.id);
      results.add(item);
    }
  }
}
