import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failure_mapper.dart';

import '../../../core/typedefs.dart';

import '../../../utils/app_logger.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../../utils/distance_calculator.dart';
import '../../../utils/geohash_helper.dart';
import '../domain/feed_discovery.dart';
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
  static const int _discoverScanBatchSize = 120;

  final FeedRemoteDataSource _dataSource;

  FeedRepository(this._dataSource);

  /// Loads the complete visible feed pool and sorts it deterministically.
  ///
  /// This is the canonical source for discovery surfaces that need
  /// consistent pagination, because the full candidate set is built before
  /// slicing local pages.
  FutureResult<List<FeedItem>> getDiscoverFeedPoolSorted({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    List<String> excludedIds = const [],
    FeedDiscoveryFilter filter = FeedDiscoveryFilter.all,
  }) async {
    final scanStopwatch = AppPerformanceTracker.startSpan(
      'feed.repo.discover_pool_scan',
      data: {'filter': filter.name},
    );
    try {
      final items = <FeedItem>[];
      DocumentSnapshot<Map<String, dynamic>>? cursor;
      var scannedDocs = 0;
      final diagnostics = _FeedPoolDiagnostics();

      while (true) {
        final snapshot = await _dataSource.getDiscoverFeedBatch(
          limit: _discoverScanBatchSize,
          startAfter: cursor,
        );

        if (snapshot.docs.isEmpty) break;

        scannedDocs += snapshot.docs.length;
        cursor = snapshot.docs.last;

        for (final doc in snapshot.docs) {
          final item = _buildVisibleFeedItem(
            data: doc.data(),
            docId: doc.id,
            currentUserId: currentUserId,
            userLat: userLat,
            userLong: userLong,
            excludedIds: excludedIds,
            diagnostics: diagnostics,
          );
          if (item == null) continue;
          if (!FeedDiscovery.matchesFilter(item, filter)) continue;
          diagnostics.countAdded(item);
          items.add(item);
        }

        if (snapshot.docs.length < _discoverScanBatchSize) {
          break;
        }
      }

      items.sort(FeedDiscovery.compareByDistance);
      AppPerformanceTracker.finishSpan(
        'feed.repo.discover_pool_scan',
        scanStopwatch,
        data: {
          'scanned_docs': scannedDocs,
          'results': items.length,
          ...diagnostics.toMap(),
        },
      );
      return Right(items);
    } catch (e) {
      AppPerformanceTracker.finishSpan(
        'feed.repo.discover_pool_scan',
        scanStopwatch,
        data: {'status': 'error', 'error_type': e.runtimeType.toString()},
      );
      return Left(mapExceptionToFailure(e));
    }
  }

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
      allItems.sort(FeedDiscovery.compareByDistance);

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
    List<String> excludedIds = const [],
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
      if (excludedIds.isNotEmpty) {
        items.removeWhere((item) => excludedIds.contains(item.uid));
      }
      items.sort(FeedDiscovery.compareByDistance);

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
      allItems.sort(FeedDiscovery.compareByDistance);

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
    techniciansOnly: false,
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
    techniciansOnly: true,
  );

  /// Private method containing the shared logic for filtering professionals.
  FutureResult<List<FeedItem>> _getFilteredProfessionals({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required int limit,
    List<String> excludedIds = const [],
    required bool techniciansOnly,
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
          userGeohash: userGeohash,
          excludedIds: excludedIds,
          // Busca mais que o limite final para compensar filtro de tecnicos/artistas.
          limit: limit * 4,
        );
        return result.map(
          (items) => _filterProfessionals(
            items,
            techniciansOnly: techniciansOnly,
          ).take(limit).toList(),
        );
      }

      // Fallback without location
      final snapshot = await _dataSource.getUsersByType(
        type: ProfileType.professional,
        limit: limit * 4,
        startAfter: null,
      );

      var items = _processSnapshot(snapshot, currentUserId, userLat, userLong);

      // Apply filters
      if (excludedIds.isNotEmpty) {
        items = items.where((i) => !excludedIds.contains(i.uid)).toList();
      }
      items = _filterProfessionals(items, techniciansOnly: techniciansOnly);

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
        final itemLat = (item.location!['lat'] as num?)?.toDouble();
        final itemLng = (item.location!['lng'] as num?)?.toDouble();

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

  FeedItem? _buildVisibleFeedItem({
    required Map<String, dynamic> data,
    required String docId,
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required List<String> excludedIds,
    _FeedPoolDiagnostics? diagnostics,
  }) {
    if (docId == currentUserId) {
      diagnostics?.skippedSelf++;
      return null;
    }
    if (excludedIds.contains(docId)) {
      diagnostics?.skippedBlocked++;
      return null;
    }

    final tipoPerfil = data[FirestoreFields.profileType] as String?;
    if (tipoPerfil != ProfileType.professional &&
        tipoPerfil != ProfileType.band &&
        tipoPerfil != ProfileType.studio) {
      diagnostics?.skippedType++;
      return null;
    }

    final cadastroStatus = data[FirestoreFields.registrationStatus] as String?;
    if (cadastroStatus != RegistrationStatus.complete) {
      diagnostics?.skippedIncomplete++;
      return null;
    }

    final status = data['status'] as String? ?? 'ativo';
    if (status != 'ativo') {
      diagnostics?.skippedInactive++;
      return null;
    }

    final privacy = data['privacy_settings'] as Map<String, dynamic>?;
    if (privacy != null && privacy['visible_in_home'] == false) {
      diagnostics?.skippedHidden++;
      return null;
    }

    var item = FeedItem.fromFirestore(data, docId);

    if (userLat != null && userLong != null && item.location != null) {
      final itemLat = (item.location!['lat'] as num?)?.toDouble();
      final itemLng = (item.location!['lng'] as num?)?.toDouble();
      if (itemLat != null && itemLng != null) {
        item = item.copyWith(
          distanceKm: DistanceCalculator.haversine(
            fromLat: userLat,
            fromLng: userLong,
            toLat: itemLat,
            toLng: itemLng,
          ),
        );
      } else {
        diagnostics?.resultsWithoutDistance++;
      }
    } else {
      diagnostics?.resultsWithoutDistance++;
    }

    return item;
  }

  List<FeedItem> _filterProfessionals(
    List<FeedItem> items, {
    required bool techniciansOnly,
  }) {
    return items.where((item) {
      final pureTechnician = _isPureTechnician(item);
      return techniciansOnly ? pureTechnician : !pureTechnician;
    }).toList();
  }

  bool _isPureTechnician(FeedItem item) {
    return FeedDiscovery.isPureTechnician(item);
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
          limit: limit,
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
    int? limit,
    double? radiusKm,
  }) async {
    final neighbors = GeohashHelper.neighbors(userGeohash);

    final snapshot = await _dataSource.getGeohashNeighbors(
      neighbors: neighbors,
      filterType: filterType,
      category: category,
      limit: limit,
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

    if (limit != null && limit > 0 && items.length > limit) {
      return Right(items.take(limit).toList());
    }

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
    List<String> excludedIds = const [],
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
      if (excludedIds.isNotEmpty) {
        items.removeWhere((item) => excludedIds.contains(item.uid));
      }

      if (filterType == 'Perto de mim' && userLat != null && userLong != null) {
        items = items
            .where((i) => i.distanceKm != null && i.distanceKm! <= 50)
            .toList();
      }
      items.sort(FeedDiscovery.compareByDistance);

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
    final nearbyUsersStopwatch = AppPerformanceTracker.startSpan(
      'feed.repo.nearby_users_optimized',
      data: {'target_results': targetResults, 'filter': filterType ?? 'all'},
    );
    try {
      final List<FeedItem> results = [];
      final Set<String> seenUids = {};

      // Gera geohash do usuário com precisão 5 (~5km x 5km)
      final userGeohash = GeohashHelper.encode(userLat, userLong, precision: 5);

      // 1. Primeiro busca no geohash do usuário (mais próximos)
      final centerQueryStopwatch = AppPerformanceTracker.startSpan(
        'feed.repo.nearby_users_center_query',
      );
      final centerSnapshot = await _dataSource.getUsersByGeohash(
        geohash: userGeohash,
        filterType: filterType,
        limit: targetResults,
      );
      AppPerformanceTracker.finishSpan(
        'feed.repo.nearby_users_center_query',
        centerQueryStopwatch,
        data: {'docs': centerSnapshot.docs.length},
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

        if (neighbors.isNotEmpty) {
          final perNeighborLimit =
              ((targetResults - results.length) / neighbors.length)
                  .ceil()
                  .clamp(3, targetResults);

          final neighborsQueryStopwatch = AppPerformanceTracker.startSpan(
            'feed.repo.nearby_users_neighbors_query',
            data: {
              'neighbors': neighbors.length,
              'per_neighbor_limit': perNeighborLimit,
            },
          );

          final neighborSnapshots = await Future.wait(
            neighbors.map(
              (neighborHash) => _dataSource.getUsersByGeohash(
                geohash: neighborHash,
                filterType: filterType,
                limit: perNeighborLimit,
              ),
            ),
          );

          final totalNeighborDocs = neighborSnapshots.fold<int>(
            0,
            (totalDocs, snapshot) => totalDocs + snapshot.docs.length,
          );
          AppPerformanceTracker.finishSpan(
            'feed.repo.nearby_users_neighbors_query',
            neighborsQueryStopwatch,
            data: {'docs': totalNeighborDocs},
          );

          for (final neighborSnapshot in neighborSnapshots) {
            if (results.length >= targetResults) break;
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
      }

      // 3. Ordena por distância real calculada
      results.sort(
        (a, b) => (a.distanceKm ?? 999).compareTo(b.distanceKm ?? 999),
      );

      // 4. Fallback: se não encontrou nada com geohash, busca todos
      if (results.isEmpty) {
        AppLogger.info(
          '⚠️ Nenhum usuário com geohash encontrado. Usando fallback...',
        );
        final fallbackResult = await _getAllUsersSortedByDistanceClassic(
          currentUserId: currentUserId,
          userLat: userLat,
          userLong: userLong,
          filterType: filterType,
          excludedIds: excludedIds,
          limit: targetResults,
        );
        AppPerformanceTracker.finishSpan(
          'feed.repo.nearby_users_optimized',
          nearbyUsersStopwatch,
          data: {'status': 'fallback', 'results': 0},
        );
        return fallbackResult;
      }

      AppPerformanceTracker.finishSpan(
        'feed.repo.nearby_users_optimized',
        nearbyUsersStopwatch,
        data: {'status': 'geohash', 'results': results.length},
      );
      return Right(results);
    } catch (e) {
      AppPerformanceTracker.finishSpan(
        'feed.repo.nearby_users_optimized',
        nearbyUsersStopwatch,
        data: {'status': 'error', 'error_type': e.runtimeType.toString()},
      );
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
      if (seenUids.contains(doc.id)) continue;
      final item = _buildVisibleFeedItem(
        data: doc.data(),
        docId: doc.id,
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        excludedIds: excludedIds,
      );
      if (item == null) continue;

      seenUids.add(doc.id);
      results.add(item);
    }
  }
}

final class _FeedPoolDiagnostics {
  int skippedSelf = 0;
  int skippedBlocked = 0;
  int skippedType = 0;
  int skippedIncomplete = 0;
  int skippedInactive = 0;
  int skippedHidden = 0;
  int professionals = 0;
  int bands = 0;
  int studios = 0;
  int technicians = 0;
  int artists = 0;
  int resultsWithoutDistance = 0;

  void countAdded(FeedItem item) {
    switch (item.tipoPerfil) {
      case ProfileType.professional:
        professionals++;
        if (FeedDiscovery.isPureTechnician(item)) {
          technicians++;
        } else {
          artists++;
        }
        break;
      case ProfileType.band:
        bands++;
        break;
      case ProfileType.studio:
        studios++;
        break;
    }
  }

  Map<String, Object> toMap() {
    return {
      'skipped_self': skippedSelf,
      'skipped_blocked': skippedBlocked,
      'skipped_type': skippedType,
      'skipped_incomplete': skippedIncomplete,
      'skipped_inactive': skippedInactive,
      'skipped_hidden': skippedHidden,
      'pool_professionals': professionals,
      'pool_artists': artists,
      'pool_technicians': technicians,
      'pool_bands': bands,
      'pool_studios': studios,
      'results_without_distance': resultsWithoutDistance,
    };
  }
}
