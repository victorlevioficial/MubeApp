import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/failures.dart';

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
  static const int defaultDiscoverPoolTargetResults = 120;
  static const int defaultFilteredDiscoverPoolTargetResults = 80;
  static const int _discoverScanBatchSize = 120;
  static const int _discoverPoolTargetResults =
      defaultDiscoverPoolTargetResults;
  static const int _filteredDiscoverPoolTargetResults =
      defaultFilteredDiscoverPoolTargetResults;
  static const int _discoverPoolMaxScannedDocs = _discoverScanBatchSize * 3;
  static const int _filteredDiscoverPoolMaxScannedDocs =
      _discoverScanBatchSize * 4;
  static const int _preemptiveNeighborQueryThreshold = 60;

  final FeedRemoteDataSource _dataSource;

  FeedRepository(this._dataSource);

  /// Loads a bounded visible discovery pool and sorts it deterministically.
  ///
  /// This keeps pagination deterministic without scanning the entire `users`
  /// collection on every load. With location available we prioritize the
  /// optimized nearby query; otherwise we fall back to a bounded Firestore scan.
  FutureResult<List<FeedItem>> getDiscoverFeedPoolSorted({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    List<String> excludedIds = const [],
    FeedDiscoveryFilter filter = FeedDiscoveryFilter.all,
    int? targetResults,
    int? fastPartialThreshold,
  }) async {
    final poolResult = await getDiscoverFeedPool(
      currentUserId: currentUserId,
      userLat: userLat,
      userLong: userLong,
      excludedIds: excludedIds,
      filter: filter,
      targetResults: targetResults,
      fastPartialThreshold: fastPartialThreshold,
    );
    return poolResult.map((pool) => pool.items);
  }

  /// Loads a deterministic discovery pool with optional fast partial mode.
  ///
  /// When [fastPartialThreshold] is provided, the repository may return a
  /// nearby-only partial pool as soon as it has enough items to fill the first
  /// visible page, deferring bounded scan backfill until a later request.
  FutureResult<DiscoverFeedPoolResult> getDiscoverFeedPool({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    List<String> excludedIds = const [],
    FeedDiscoveryFilter filter = FeedDiscoveryFilter.all,
    int? targetResults,
    int? fastPartialThreshold,
  }) async {
    final scanStopwatch = AppPerformanceTracker.startSpan(
      'feed.repo.discover_pool_scan',
      data: {'filter': filter.name},
    );
    try {
      final diagnostics = _FeedPoolDiagnostics();
      final effectiveTargetResults = targetResults ?? _targetResultsFor(filter);
      final maxScannedDocs = _maxScannedDocsFor(filter);
      final discoverPool = await _loadDiscoverPool(
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        excludedIds: excludedIds,
        filter: filter,
        targetResults: effectiveTargetResults,
        maxScannedDocs: maxScannedDocs,
        fastPartialThreshold: fastPartialThreshold,
        diagnostics: diagnostics,
      );
      final items = discoverPool.items;

      items.sort(FeedDiscovery.compareByDistance);
      AppPerformanceTracker.finishSpan(
        'feed.repo.discover_pool_scan',
        scanStopwatch,
        data: {
          'source': discoverPool.source,
          'scanned_docs': discoverPool.scannedDocs,
          'target_results': effectiveTargetResults,
          'results': items.length,
          'is_exhaustive': discoverPool.isExhaustive,
          ...diagnostics.toMap(),
        },
      );
      return Right(discoverPool.copyWith(items: items));
    } catch (e) {
      AppPerformanceTracker.finishSpan(
        'feed.repo.discover_pool_scan',
        scanStopwatch,
        data: {'status': 'error', 'error_type': e.runtimeType.toString()},
      );
      if (e is Failure) return Left(e);
      return Left(mapExceptionToFailure(e));
    }
  }

  Future<DiscoverFeedPoolResult> _loadDiscoverPool({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required List<String> excludedIds,
    required FeedDiscoveryFilter filter,
    required int targetResults,
    required int maxScannedDocs,
    required int? fastPartialThreshold,
    required _FeedPoolDiagnostics diagnostics,
  }) async {
    if (userLat == null || userLong == null) {
      return _loadDiscoverPoolFromBoundedScan(
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        excludedIds: excludedIds,
        filter: filter,
        targetResults: targetResults,
        maxScannedDocs: maxScannedDocs,
        diagnostics: diagnostics,
      );
    }

    final nearbyPool = await _loadDiscoverPoolFromNearby(
      currentUserId: currentUserId,
      userLat: userLat,
      userLong: userLong,
      excludedIds: excludedIds,
      filter: filter,
      targetResults: targetResults,
      diagnostics: diagnostics,
    );

    if (nearbyPool.items.length >= targetResults) {
      return nearbyPool;
    }

    if (fastPartialThreshold != null &&
        fastPartialThreshold > 0 &&
        nearbyPool.items.length >= fastPartialThreshold) {
      return nearbyPool.copyWith(source: 'nearby_partial');
    }

    final backfillExcludedIds = <String>{
      ...excludedIds,
      ...nearbyPool.items.map((item) => item.uid),
    }.toList(growable: false);
    final remainingTarget = targetResults - nearbyPool.items.length;
    final backfillPool = await _loadDiscoverPoolFromBoundedScan(
      currentUserId: currentUserId,
      userLat: userLat,
      userLong: userLong,
      excludedIds: backfillExcludedIds,
      filter: filter,
      targetResults: remainingTarget,
      maxScannedDocs: maxScannedDocs,
      diagnostics: diagnostics,
    );

    return DiscoverFeedPoolResult(
      items: _mergeUniqueItems(nearbyPool.items, backfillPool.items),
      scannedDocs: nearbyPool.scannedDocs + backfillPool.scannedDocs,
      source: backfillPool.items.isEmpty
          ? nearbyPool.source
          : 'nearby_plus_scan',
      isExhaustive: backfillPool.isExhaustive,
    );
  }

  int _targetResultsFor(FeedDiscoveryFilter filter) {
    return switch (filter) {
      FeedDiscoveryFilter.all => _discoverPoolTargetResults,
      _ => _filteredDiscoverPoolTargetResults,
    };
  }

  int _maxScannedDocsFor(FeedDiscoveryFilter filter) {
    return switch (filter) {
      FeedDiscoveryFilter.all => _discoverPoolMaxScannedDocs,
      _ => _filteredDiscoverPoolMaxScannedDocs,
    };
  }

  String? _profileTypeForDiscoverFilter(FeedDiscoveryFilter filter) {
    return switch (filter) {
      FeedDiscoveryFilter.professionals ||
      FeedDiscoveryFilter.artists ||
      FeedDiscoveryFilter.technicians => ProfileType.professional,
      FeedDiscoveryFilter.bands => ProfileType.band,
      FeedDiscoveryFilter.studios => ProfileType.studio,
      FeedDiscoveryFilter.all => null,
    };
  }

  Future<DiscoverFeedPoolResult> _loadDiscoverPoolFromNearby({
    required String currentUserId,
    required double userLat,
    required double userLong,
    required List<String> excludedIds,
    required FeedDiscoveryFilter filter,
    required int targetResults,
    required _FeedPoolDiagnostics diagnostics,
  }) async {
    final nearbyResult = await getNearbyUsersOptimized(
      currentUserId: currentUserId,
      userLat: userLat,
      userLong: userLong,
      filterType: _profileTypeForDiscoverFilter(filter),
      excludedIds: excludedIds,
      targetResults: targetResults,
    );

    final items = nearbyResult.fold(
      (failure) => throw failure,
      (items) => items,
    );
    final filteredItems = items
        .where((item) => FeedDiscovery.matchesFilter(item, filter))
        .toList(growable: false);

    for (final item in filteredItems) {
      if (item.distanceKm == null) {
        diagnostics.resultsWithoutDistance++;
      }
      diagnostics.countAdded(item);
    }

    return DiscoverFeedPoolResult(
      items: filteredItems,
      scannedDocs: filteredItems.length,
      source: 'nearby_optimized',
      isExhaustive: false,
    );
  }

  Future<DiscoverFeedPoolResult> _loadDiscoverPoolFromBoundedScan({
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required List<String> excludedIds,
    required FeedDiscoveryFilter filter,
    required int targetResults,
    required int maxScannedDocs,
    required _FeedPoolDiagnostics diagnostics,
  }) async {
    final items = <FeedItem>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    var scannedDocs = 0;
    var exhaustedSource = false;

    while (scannedDocs < maxScannedDocs && items.length < targetResults) {
      final remainingDocs = maxScannedDocs - scannedDocs;
      final batchLimit = remainingDocs < _discoverScanBatchSize
          ? remainingDocs
          : _discoverScanBatchSize;
      final snapshot = await _dataSource.getDiscoverFeedBatch(
        limit: batchLimit,
        profileType: _profileTypeForDiscoverFilter(filter),
        startAfter: cursor,
      );

      if (snapshot.docs.isEmpty) {
        exhaustedSource = true;
        break;
      }

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
        if (items.length >= targetResults) {
          break;
        }
      }
      if (snapshot.docs.length < batchLimit) {
        exhaustedSource = true;
        break;
      }
    }

    return DiscoverFeedPoolResult(
      items: items,
      scannedDocs: scannedDocs,
      source: 'bounded_scan',
      isExhaustive: items.length < targetResults && exhaustedSource,
    );
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

  /// Fetches public contractor profiles for dedicated venue discovery.
  FutureResult<List<FeedItem>> getPublicContractors({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    final result = await getPublicContractorsPaginated(
      currentUserId: currentUserId,
      excludedIds: excludedIds,
      userLat: userLat,
      userLong: userLong,
      limit: limit,
    );
    return result.map((page) => page.items);
  }

  /// Fetches public contractor profiles with pagination support.
  FutureResult<PaginatedFeedResponse> getPublicContractorsPaginated({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    const candidateMultiplier = 3;
    const maxCandidatePasses = 3;

    try {
      final collectedItems = <FeedItem>[];
      final seenIds = <String>{};
      DocumentSnapshot? cursor = startAfter;
      var hasMoreCandidates = true;
      var passCount = 0;

      while (collectedItems.length < limit &&
          hasMoreCandidates &&
          passCount < maxCandidatePasses) {
        final snapshot = await _dataSource.getUsersByType(
          type: ProfileType.contractor,
          limit: limit * candidateMultiplier,
          startAfter: cursor,
        );
        passCount++;

        if (snapshot.docs.isEmpty) {
          hasMoreCandidates = false;
          break;
        }

        cursor = snapshot.docs.last;
        hasMoreCandidates = snapshot.docs.length >= limit * candidateMultiplier;

        final candidateItems = _processPublicContractorsSnapshot(
          snapshot,
          currentUserId,
          userLat,
          userLong,
          excludedIds,
        );
        for (final item in candidateItems) {
          if (seenIds.add(item.uid)) {
            collectedItems.add(item);
          }
        }
      }

      collectedItems.sort(FeedDiscovery.compareByDistance);
      final pageItems = collectedItems.take(limit).toList(growable: false);

      return Right(
        PaginatedFeedResponse(
          items: pageItems,
          lastDocument: cursor,
          hasMore: hasMoreCandidates,
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
  }) async {
    final result = await getTechniciansPaginated(
      currentUserId: currentUserId,
      excludedIds: excludedIds,
      userLat: userLat,
      userLong: userLong,
      limit: limit,
    );
    return result.map((page) => page.items);
  }

  FutureResult<PaginatedFeedResponse> getTechniciansPaginated({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    const candidateMultiplier = 3;
    const maxCandidatePasses = 3;

    try {
      final collectedItems = <FeedItem>[];
      DocumentSnapshot? cursor = startAfter;
      var hasMoreCandidates = true;
      var passCount = 0;

      while (collectedItems.length < limit &&
          hasMoreCandidates &&
          passCount < maxCandidatePasses) {
        final snapshot = await _dataSource.getTechnicianCandidates(
          limit: limit * candidateMultiplier,
          startAfter: cursor,
        );
        passCount++;

        if (snapshot.docs.isEmpty) {
          hasMoreCandidates = false;
          break;
        }

        cursor = snapshot.docs.last;
        hasMoreCandidates = snapshot.docs.length >= limit * candidateMultiplier;

        final candidateItems = _processSnapshot(
          snapshot,
          currentUserId,
          userLat,
          userLong,
        );
        final filteredItems = candidateItems
            .where((item) => !excludedIds.contains(item.uid))
            .where(FeedDiscovery.isPureTechnician)
            .toList(growable: false);
        collectedItems.addAll(filteredItems);
      }

      collectedItems.sort(FeedDiscovery.compareByDistance);
      final uniqueItems = <String, FeedItem>{};
      for (final item in collectedItems) {
        uniqueItems[item.uid] = item;
      }
      final pageItems = uniqueItems.values.take(limit).toList(growable: false);

      return Right(
        PaginatedFeedResponse(
          items: pageItems,
          lastDocument: cursor,
          hasMore: hasMoreCandidates,
        ),
      );
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

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

  List<FeedItem> _processPublicContractorsSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String currentUserId,
    double? userLat,
    double? userLong,
    List<String> excludedIds,
  ) {
    final items = <FeedItem>[];

    for (final doc in snapshot.docs) {
      final item = _buildVisiblePublicContractorFeedItem(
        data: doc.data(),
        docId: doc.id,
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        excludedIds: excludedIds,
      );
      if (item != null) {
        items.add(item);
      }
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

  FeedItem? _buildVisiblePublicContractorFeedItem({
    required Map<String, dynamic> data,
    required String docId,
    required String currentUserId,
    required double? userLat,
    required double? userLong,
    required List<String> excludedIds,
  }) {
    if (docId == currentUserId || excludedIds.contains(docId)) {
      return null;
    }

    final tipoPerfil = data[FirestoreFields.profileType] as String?;
    if (tipoPerfil != ProfileType.contractor) {
      return null;
    }

    final cadastroStatus = data[FirestoreFields.registrationStatus] as String?;
    if (cadastroStatus != RegistrationStatus.complete) {
      return null;
    }

    final status = data['status'] as String? ?? 'ativo';
    if (status != 'ativo') {
      return null;
    }

    final contractorData =
        data[FirestoreFields.contractor] as Map<String, dynamic>? ?? {};
    if (contractorData['isPublic'] != true) {
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
      }
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

  List<FeedItem> _mergeUniqueItems(
    List<FeedItem> primaryItems,
    List<FeedItem> secondaryItems,
  ) {
    final uniqueItems = <String, FeedItem>{};
    for (final item in primaryItems) {
      uniqueItems[item.uid] = item;
    }
    for (final item in secondaryItems) {
      uniqueItems[item.uid] = item;
    }
    return uniqueItems.values.toList(growable: false);
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
    final geohashes = <String>{
      ...GeohashHelper.neighbors(userGeohash),
    }.toList(growable: false);
    final effectiveFilterType = _resolveGeohashFilterType(
      filterType: filterType,
      category: category,
    );
    final perGeohashLimit = _resolveGeohashQueryLimit(
      geohashCount: geohashes.length,
      requestedLimit: limit,
      hasCategoryFilter: category != null && category.isNotEmpty,
      hasExcludeCategory: excludeCategory != null && excludeCategory.isNotEmpty,
    );

    final snapshots = await Future.wait(
      geohashes.map(
        (geohash) => _dataSource.getUsersByGeohash(
          geohash: geohash,
          filterType: effectiveFilterType,
          category: category,
          limit: perGeohashLimit,
        ),
      ),
    );

    final items = <FeedItem>[];
    final seenUids = <String>{};
    for (final snapshot in snapshots) {
      _processGeohashResults(
        snapshot,
        items,
        seenUids,
        currentUserId,
        userLat,
        userLong,
        excludedIds,
      );
    }

    if (category != null && category.isNotEmpty) {
      items.retainWhere((item) => item.categoria == category);
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

  String? _resolveGeohashFilterType({
    required String? filterType,
    required String? category,
  }) {
    if (category != null &&
        category.isNotEmpty &&
        (filterType == null ||
            filterType.isEmpty ||
            filterType == 'Perto de mim')) {
      return ProfileType.professional;
    }

    return filterType;
  }

  int _resolvePreemptiveNeighborLimit({
    required int targetResults,
    required int neighborCount,
  }) {
    final estimatedCenterResults = (targetResults / (neighborCount + 1)).ceil();
    return ((targetResults - estimatedCenterResults) / neighborCount)
        .ceil()
        .clamp(3, targetResults)
        .toInt();
  }

  int _resolveGeohashQueryLimit({
    required int geohashCount,
    required int? requestedLimit,
    required bool hasCategoryFilter,
    required bool hasExcludeCategory,
  }) {
    final baseLimit = requestedLimit != null && requestedLimit > 0
        ? (requestedLimit / geohashCount).ceil()
        : 8;
    final multiplier = hasCategoryFilter || hasExcludeCategory ? 3 : 2;
    return (baseLimit * multiplier).clamp(6, 30);
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

    final items = <FeedItem>[];
    for (final doc in snapshot.docs) {
      final item = _buildVisibleFeedItem(
        data: doc.data(),
        docId: doc.id,
        currentUserId: currentUserId,
        userLat: userLat,
        userLong: userLong,
        excludedIds: excludedIds,
      );
      if (item != null) {
        items.add(item);
      }
    }

    if (category != null) {
      items.retainWhere((i) => i.categoria == category);
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
      final neighbors = GeohashHelper.neighbors(userGeohash)
        ..remove(userGeohash);
      final shouldPreloadNeighbors =
          targetResults >= _preemptiveNeighborQueryThreshold &&
          neighbors.isNotEmpty;

      Future<List<QuerySnapshot<Map<String, dynamic>>>>? preloadedNeighbors;
      Stopwatch? neighborQueryStopwatch;
      var neighborSpanFinished = false;
      var preloadedNeighborLimit = 0;

      void finishNeighborQuerySpan(Map<String, Object?> data) {
        if (neighborSpanFinished || neighborQueryStopwatch == null) {
          return;
        }
        neighborSpanFinished = true;
        AppPerformanceTracker.finishSpan(
          'feed.repo.nearby_users_neighbors_query',
          neighborQueryStopwatch,
          data: data,
        );
      }

      if (shouldPreloadNeighbors) {
        preloadedNeighborLimit = _resolvePreemptiveNeighborLimit(
          targetResults: targetResults,
          neighborCount: neighbors.length,
        );
        neighborQueryStopwatch = AppPerformanceTracker.startSpan(
          'feed.repo.nearby_users_neighbors_query',
          data: {
            'neighbors': neighbors.length,
            'per_neighbor_limit': preloadedNeighborLimit,
            'mode': 'preloaded',
          },
        );
        preloadedNeighbors = Future.wait(
          neighbors.map(
            (neighborHash) => _dataSource.getUsersByGeohash(
              geohash: neighborHash,
              filterType: filterType,
              limit: preloadedNeighborLimit,
            ),
          ),
        );
      }

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
      if (results.length < targetResults && neighbors.isNotEmpty) {
        // Remove o centro que já buscamos

        final perNeighborLimit = shouldPreloadNeighbors
            ? preloadedNeighborLimit
            : ((targetResults - results.length) / neighbors.length)
                  .ceil()
                  .clamp(3, targetResults);

        if (!shouldPreloadNeighbors) {
          neighborQueryStopwatch = AppPerformanceTracker.startSpan(
            'feed.repo.nearby_users_neighbors_query',
            data: {
              'neighbors': neighbors.length,
              'per_neighbor_limit': perNeighborLimit,
              'mode': 'progressive',
            },
          );
        }

        final resolvedNeighborSnapshots = preloadedNeighbors != null
            ? await preloadedNeighbors
            : await Future.wait(
                neighbors.map(
                  (neighborHash) => _dataSource.getUsersByGeohash(
                    geohash: neighborHash,
                    filterType: filterType,
                    limit: perNeighborLimit,
                  ),
                ),
              );

        final totalNeighborDocs = resolvedNeighborSnapshots.fold<int>(
          0,
          (totalDocs, snapshot) => totalDocs + snapshot.docs.length,
        );
        finishNeighborQuerySpan({
          'docs': totalNeighborDocs,
          'mode': shouldPreloadNeighbors ? 'preloaded' : 'progressive',
        });

        for (final neighborSnapshot in resolvedNeighborSnapshots) {
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
      // 3. Ordena por distância real calculada
      else if (preloadedNeighbors != null) {
        unawaited(
          preloadedNeighbors
              .then((snapshots) {
                final totalNeighborDocs = snapshots.fold<int>(
                  0,
                  (totalDocs, snapshot) => totalDocs + snapshot.docs.length,
                );
                finishNeighborQuerySpan({
                  'docs': totalNeighborDocs,
                  'mode': 'preloaded',
                  'status': 'discarded',
                });
              })
              .catchError((Object error, StackTrace stack) {
                finishNeighborQuerySpan({
                  'mode': 'preloaded',
                  'status': 'discarded_error',
                  'error_type': error.runtimeType.toString(),
                });
                AppLogger.warning(
                  'Preloaded neighbor queries failed after center query was sufficient',
                  error,
                  stack,
                );
              }),
        );
      }

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

final class DiscoverFeedPoolResult {
  const DiscoverFeedPoolResult({
    required this.items,
    required this.scannedDocs,
    required this.source,
    required this.isExhaustive,
  });

  final List<FeedItem> items;
  final int scannedDocs;
  final String source;
  final bool isExhaustive;

  DiscoverFeedPoolResult copyWith({
    List<FeedItem>? items,
    int? scannedDocs,
    String? source,
    bool? isExhaustive,
  }) {
    return DiscoverFeedPoolResult(
      items: items ?? this.items,
      scannedDocs: scannedDocs ?? this.scannedDocs,
      source: source ?? this.source,
      isExhaustive: isExhaustive ?? this.isExhaustive,
    );
  }
}
