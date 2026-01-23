import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/text_utils.dart';
import '../../feed/domain/feed_item.dart';
import '../domain/search_filters.dart';

/// Search configuration constants
class SearchConfig {
  static const int batchSize = 50;
  static const int maxDocsRead = 300;
  static const int targetResults = 20;
}

/// Repository for searching users with smart pagination and filtering.
class SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Search for users based on filters.
  ///
  /// Uses smart pagination: fetches batches until [targetResults] valid matches
  /// are found or [maxDocsRead] is reached.
  Future<List<FeedItem>> searchUsers({
    required SearchFilters filters,
    DocumentSnapshot? startAfter,
    required int requestId,
    required ValueGetter<int> getCurrentRequestId,
  }) async {
    final List<FeedItem> results = [];
    final Set<String> seenUids = {};
    DocumentSnapshot? lastDoc = startAfter;
    int totalDocsRead = 0;

    while (results.length < SearchConfig.targetResults &&
        totalDocsRead < SearchConfig.maxDocsRead) {
      // Check if request is still valid (not cancelled by newer request)
      if (getCurrentRequestId() != requestId) {
        debugPrint('[Search] Request $requestId cancelled');
        return [];
      }

      // Build and execute query
      final query = _buildBaseQuery(filters, lastDoc);
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) break;

      totalDocsRead += snapshot.docs.length;
      lastDoc = snapshot.docs.last;

      // Filter and deduplicate in memory
      for (final doc in snapshot.docs) {
        if (getCurrentRequestId() != requestId) return [];

        final data = doc.data();

        // Skip contractors - NEVER show in results
        if (data['tipo_perfil'] == 'contratante') continue;

        // Skip non-searchable (incomplete/inactive profiles)
        final cadastroStatus = data['cadastro_status'] as String?;
        final status = data['status'] as String? ?? 'ativo';
        if (cadastroStatus != 'concluido' || status != 'ativo') continue;

        // Deduplicate
        if (seenUids.contains(doc.id)) continue;

        // Apply filters
        final item = FeedItem.fromFirestore(data, doc.id);
        if (!_matchesFilters(item, data, filters)) continue;

        seenUids.add(doc.id);
        results.add(item);

        if (results.length >= SearchConfig.targetResults) break;
      }
    }

    debugPrint(
      '[Search] Request $requestId: ${results.length} results from $totalDocsRead docs',
    );
    return results;
  }

  /// Builds the base Firestore query.
  Query<Map<String, dynamic>> _buildBaseQuery(
    SearchFilters filters,
    DocumentSnapshot? startAfter,
  ) {
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    // Category filter (contractors are filtered in memory, not here)
    // We only add tipo_perfil filter when a SPECIFIC category is selected
    if (filters.category != SearchCategory.all) {
      final tipoPerfil = _categoryToTipoPerfil(filters.category);
      if (tipoPerfil != null) {
        query = query.where('tipo_perfil', isEqualTo: tipoPerfil);
      }
    }

    // Order by creation date (stable pagination)
    query = query.orderBy('created_at', descending: true);

    // Pagination
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.limit(SearchConfig.batchSize);
  }

  /// Converts SearchCategory to Firestore tipo_perfil value.
  String? _categoryToTipoPerfil(SearchCategory category) {
    switch (category) {
      case SearchCategory.professionals:
        return 'profissional';
      case SearchCategory.bands:
        return 'banda';
      case SearchCategory.studios:
        return 'estudio';
      case SearchCategory.all:
        return null;
    }
  }

  /// Checks if an item matches all active filters.
  bool _matchesFilters(
    FeedItem item,
    Map<String, dynamic> rawData,
    SearchFilters filters,
  ) {
    // Text search (name/artistic name)
    if (filters.term.isNotEmpty) {
      final normalizedTerm = normalizeText(filters.term);
      final normalizedName = normalizeText(item.displayName);
      if (!normalizedName.contains(normalizedTerm)) {
        return false;
      }
    }

    // Get nested data for detailed filters
    final profData = rawData['profissional'] as Map<String, dynamic>? ?? {};
    final bandData = rawData['banda'] as Map<String, dynamic>? ?? {};
    final studioData = rawData['estudio'] as Map<String, dynamic>? ?? {};

    // Professional subcategory filter
    if (filters.professionalSubcategory != null &&
        item.tipoPerfil == 'profissional') {
      final categories = List<String>.from(profData['categorias'] ?? []);
      final subcatValue = filters.professionalSubcategory!.name;
      if (!categories.contains(subcatValue)) {
        return false;
      }
    }

    // Genre filter
    if (filters.genres.isNotEmpty) {
      List<String> itemGenres = [];
      if (item.tipoPerfil == 'profissional') {
        itemGenres = List<String>.from(profData['generosMusicais'] ?? []);
      } else if (item.tipoPerfil == 'banda') {
        itemGenres = List<String>.from(bandData['generosMusicais'] ?? []);
      }
      if (!listContainsAny(itemGenres, filters.genres)) {
        return false;
      }
    }

    // Instruments filter (professionals only)
    if (filters.instruments.isNotEmpty && item.tipoPerfil == 'profissional') {
      final itemInstruments = List<String>.from(profData['instrumentos'] ?? []);
      if (!listContainsAny(itemInstruments, filters.instruments)) {
        return false;
      }
    }

    // Roles filter (crew only)
    if (filters.roles.isNotEmpty && item.tipoPerfil == 'profissional') {
      final itemRoles = List<String>.from(profData['funcoes'] ?? []);
      if (!listContainsAny(itemRoles, filters.roles)) {
        return false;
      }
    }

    // Services filter (studios only)
    if (filters.services.isNotEmpty && item.tipoPerfil == 'estudio') {
      final itemServices = List<String>.from(studioData['services'] ?? []);
      if (!listContainsAny(itemServices, filters.services)) {
        return false;
      }
    }

    // Studio type filter
    if (filters.studioType != null && item.tipoPerfil == 'estudio') {
      final studioType = studioData['studioType'] as String?;
      if (studioType != filters.studioType) {
        return false;
      }
    }

    // Backing vocal filter
    if (filters.canDoBackingVocal != null &&
        item.tipoPerfil == 'profissional') {
      final categories = List<String>.from(profData['categorias'] ?? []);

      bool canDoBacking = false;

      // Singer: check backingVocalMode
      if (categories.contains('singer')) {
        final mode = profData['backingVocalMode'] as String? ?? '0';
        canDoBacking = mode == '1' || mode == '2';
      }

      // Instrumentalist: check fazBackingVocal
      if (categories.contains('instrumentalist')) {
        final fazBacking = profData['fazBackingVocal'] as bool? ?? false;
        if (fazBacking) canDoBacking = true;
      }

      if (filters.canDoBackingVocal! && !canDoBacking) {
        return false;
      }
    }

    return true;
  }

  /// Calculates distance in km between two coordinates using Haversine formula.
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;

  /// Sorts results by distance (if available), then by name.
  static List<FeedItem> sortByProximity(
    List<FeedItem> items,
    double? userLat,
    double? userLng,
  ) {
    if (userLat == null || userLng == null) {
      // Fallback: sort by name
      return items..sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    // Calculate distances
    for (final item in items) {
      final loc = item.location;
      if (loc != null && loc['lat'] != null && loc['lng'] != null) {
        final itemLat = (loc['lat'] as num).toDouble();
        final itemLng = (loc['lng'] as num).toDouble();
        item.distanceKm = calculateDistanceKm(
          userLat,
          userLng,
          itemLat,
          itemLng,
        );
      }
    }

    // Sort: distance asc (nulls last), then name
    return items..sort((a, b) {
      if (a.distanceKm == null && b.distanceKm == null) {
        return a.displayName.compareTo(b.displayName);
      }
      if (a.distanceKm == null) return 1;
      if (b.distanceKm == null) return -1;
      return a.distanceKm!.compareTo(b.distanceKm!);
    });
  }
}

/// Provider for SearchRepository
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository();
});
