import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failure_mapper.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/errors/firestore_resilience.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:mube/src/utils/category_normalizer.dart';
import 'package:mube/src/utils/professional_profile_utils.dart';
import '../../../constants/venue_type_constants.dart';
import '../../../utils/text_utils.dart';
import '../../feed/domain/feed_item.dart';
import '../domain/paginated_search_response.dart';
import '../domain/search_filters.dart';

/// Search configuration constants
class SearchConfig {
  static const int batchSize = 40;
  static const int maxDocsRead = 180;
  static const int targetResults = 20;
}

enum _SearchProfileScope {
  any,
  professional,
  band,
  studio,
  contractor,
  impossible,
}

/// Repository for searching users with smart pagination and filtering.
class SearchRepository {
  static const FirestoreResilience _firestoreResilience = FirestoreResilience(
    'SearchRepository',
  );
  static final Map<String, List<String>> _searchQueryAliases = {
    'cantor': ['cantora', 'cantores', 'vocalista', 'vocal', 'singer'],
    'cantora': ['cantor', 'cantores', 'vocalista', 'vocal', 'singer'],
    'cantores': ['cantor', 'cantora', 'vocalista', 'vocal', 'singer'],
    'vocalista': ['cantor', 'cantora', 'cantores', 'vocal', 'singer'],
    'vocalistas': ['cantor', 'cantora', 'cantores', 'vocalista', 'singer'],
    'guitarrista': ['guitarra', 'violao', 'guitar', 'instrumentalist'],
    'guitarristas': ['guitarra', 'violao', 'guitar', 'instrumentalist'],
    'baixista': ['baixo', 'contrabaixo', 'bass', 'instrumentalist'],
    'baixistas': ['baixo', 'contrabaixo', 'bass', 'instrumentalist'],
    'baterista': ['bateria', 'percussao', 'drum', 'instrumentalist'],
    'bateristas': ['bateria', 'percussao', 'drum', 'instrumentalist'],
    'tecladista': ['teclado', 'piano', 'keyboard', 'instrumentalist'],
    'tecladistas': ['teclado', 'piano', 'keyboard', 'instrumentalist'],
    'dj': ['djs', 'disc jockey'],
    'djs': ['dj', 'disc jockey'],
    'produtor': ['producao', 'producer', 'beatmaker', 'arranjador'],
    'produtores': ['producao', 'producer', 'beatmaker', 'arranjador'],
    'roadie': ['roadies', 'stage tech', 'tecnico de palco'],
    'roadies': ['roadie', 'stage tech', 'tecnico de palco'],
    'estudio': ['studio', 'estudios', 'gravacao', 'ensaio'],
    'estudios': ['estudio', 'studio', 'gravacao', 'ensaio'],
    'banda': ['band', 'bandas', 'grupo'],
    'bandas': ['band', 'banda', 'grupo'],
    'local': ['locais', 'venue', 'contratante', 'casa de show'],
    'locais': ['local', 'venue', 'contratante', 'casa de show'],
  };
  static final Map<String, String> _venueTypeLookup = {
    for (final option in venueTypeOptions) option.id.toLowerCase(): option.id,
    for (final option in venueTypeOptions)
      option.label.toLowerCase(): option.id,
  };
  static final Map<String, String> _venueAmenityLookup = {
    for (final option in venueAmenityOptions)
      option.id.toLowerCase(): option.id,
    for (final option in venueAmenityOptions)
      option.label.toLowerCase(): option.id,
  };

  final FirebaseFirestore _firestore;
  final AnalyticsService? _analytics;

  SearchRepository({
    required FirebaseFirestore firestore,
    AnalyticsService? analytics,
  }) : _firestore = firestore,
       _analytics = analytics;

  /// Search for users based on filters.
  ///
  /// Uses smart pagination: fetches batches until [targetResults] valid matches
  /// are found or [maxDocsRead] is reached.
  FutureResult<PaginatedSearchResponse> searchUsers({
    required SearchFilters filters,
    DocumentSnapshot? startAfter,
    required int requestId,
    required ValueGetter<int> getCurrentRequestId,
    List<String> blockedUsers = const [],
  }) async {
    try {
      final effectiveFilters = filters.sanitizedForSearch();
      final scope = _resolveSearchProfileScope(effectiveFilters);

      if (scope == _SearchProfileScope.impossible) {
        return const Right(PaginatedSearchResponse.empty());
      }

      final List<FeedItem> results = [];
      final Set<String> seenUids = {};
      DocumentSnapshot? lastDoc = startAfter;
      int totalDocsRead = 0;
      var reachedEnd = false;

      while (results.length < SearchConfig.targetResults &&
          totalDocsRead < SearchConfig.maxDocsRead) {
        // Check if request is still valid (not cancelled by newer request)
        if (getCurrentRequestId() != requestId) {
          AppLogger.debug('Search request $requestId cancelled');
          return const Right(PaginatedSearchResponse.empty());
        }

        // Build and execute query
        final query = _buildBaseQuery(startAfter: lastDoc, scope: scope);
        final snapshot = await _firestoreResilience.run(
          () => query.get(),
          operationLabel: 'search_users_page',
          onFinalError: (error) => mapExceptionToFailure(error),
        );

        if (snapshot.docs.isEmpty) {
          reachedEnd = true;
          break;
        }

        totalDocsRead += snapshot.docs.length;
        lastDoc = snapshot.docs.last;

        // Filter and deduplicate in memory
        for (final doc in snapshot.docs) {
          if (getCurrentRequestId() != requestId) {
            return const Right(PaginatedSearchResponse.empty());
          }

          final data = doc.data();

          // Skip non-searchable (incomplete/inactive profiles)
          final cadastroStatus = data['cadastro_status'] as String?;
          final status = data['status'] as String? ?? 'ativo';
          if (cadastroStatus != 'concluido' || status != 'ativo') continue;

          final isContractor = data['tipo_perfil'] == 'contratante';
          if (isContractor) {
            final contractorData =
                data['contratante'] as Map<String, dynamic>? ?? {};
            if (contractorData['isPublic'] != true) continue;
          } else {
            // Skip if hidden from search (Ghost Mode)
            final privacy = data['privacy_settings'] as Map<String, dynamic>?;
            if (privacy != null && privacy['visible_in_home'] == false) {
              continue;
            }
          }

          // Deduplicate
          if (seenUids.contains(doc.id)) continue;

          // Blocked check
          if (blockedUsers.contains(doc.id)) continue;

          // Apply filters
          final item = FeedItem.fromFirestore(data, doc.id);
          if (!_matchesFilters(item, data, effectiveFilters)) continue;

          seenUids.add(doc.id);
          results.add(item);

          if (results.length >= SearchConfig.targetResults) break;
        }
      }

      AppLogger.debug(
        'Search request $requestId returned ${results.length} results after reading $totalDocsRead docs',
      );

      // Log analytics event for search performed
      await _analytics?.logEvent(
        name: 'search_performed',
        parameters: {
          'query': filters.term,
          'results_count': results.length,
          'has_filters': effectiveFilters.hasActiveFilters,
          'category': effectiveFilters.category.name,
        },
      );

      final hasMore = !reachedEnd && lastDoc != null;

      return Right(
        PaginatedSearchResponse(
          items: results,
          lastDocument: lastDoc,
          hasMore: hasMore,
        ),
      );
    } catch (e, stack) {
      final failure = e is Failure ? e : mapExceptionToFailure(e, stack);
      AppLogger.error('Search repository failed', e, stack);

      // Log analytics event for search error
      await _analytics?.logEvent(
        name: 'search_error',
        parameters: {'query': filters.term, 'error_message': failure.message},
      );

      return Left(failure);
    }
  }

  /// Builds the base Firestore query.
  Query<Map<String, dynamic>> _buildBaseQuery({
    required DocumentSnapshot? startAfter,
    required _SearchProfileScope scope,
  }) {
    Query<Map<String, dynamic>> query = _firestore.collection('users');

    // Scope filter inferred from explicit category and type-specific filters.
    if (scope != _SearchProfileScope.any) {
      final tipoPerfil = _scopeToTipoPerfil(scope);
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

  String? _scopeToTipoPerfil(_SearchProfileScope scope) {
    switch (scope) {
      case _SearchProfileScope.professional:
        return 'profissional';
      case _SearchProfileScope.band:
        return 'banda';
      case _SearchProfileScope.studio:
        return 'estudio';
      case _SearchProfileScope.contractor:
        return 'contratante';
      case _SearchProfileScope.any:
      case _SearchProfileScope.impossible:
        return null;
    }
  }

  _SearchProfileScope _resolveSearchProfileScope(SearchFilters filters) {
    if (filters.hasConflictingTypeFilters) {
      return _SearchProfileScope.impossible;
    }

    switch (filters.category) {
      case SearchCategory.professionals:
        return _SearchProfileScope.professional;
      case SearchCategory.bands:
        return _SearchProfileScope.band;
      case SearchCategory.studios:
        return _SearchProfileScope.studio;
      case SearchCategory.venues:
        return _SearchProfileScope.contractor;
      case SearchCategory.all:
        if (filters.hasProfessionalOnlyFilters) {
          return _SearchProfileScope.professional;
        }
        if (filters.hasStudioOnlyFilters) {
          return _SearchProfileScope.studio;
        }
        return _SearchProfileScope.any;
    }
  }

  /// Returns a relaxed copy of [filters] for soft-matching.
  ///
  /// Relaxation strategy:
  /// 1. Keep category and text term (core intent).
  /// 2. Remove instruments / roles / services constraints.
  /// 3. Keep subcategory so we stay in the same "type" of professional.
  /// 4. Remove genres (least important for basic discovery).
  static SearchFilters relaxFilters(SearchFilters filters) {
    return filters.copyWith(
      instruments: const [],
      roles: const [],
      services: const [],
      genres: const [],
      studioType: null,
      canDoBackingVocal: null,
      offersRemoteRecording: null,
    );
  }

  /// Whether relaxing filters would actually broaden the search.
  static bool canRelaxFilters(SearchFilters filters) {
    return relaxFilters(filters) != filters;
  }

  /// Checks if an item matches all active filters.
  bool _matchesFilters(
    FeedItem item,
    Map<String, dynamic> rawData,
    SearchFilters filters,
  ) {
    if (filters.hasConflictingTypeFilters) {
      return false;
    }

    // Text search (name/artistic name)
    if (filters.term.isNotEmpty) {
      if (!_matchesSearchTerm(filters.term, item)) {
        return false;
      }
    }

    if (filters.category == SearchCategory.professionals &&
        item.tipoPerfil != 'profissional') {
      return false;
    }

    if (filters.category == SearchCategory.bands &&
        item.tipoPerfil != 'banda') {
      return false;
    }

    if (filters.category == SearchCategory.studios &&
        item.tipoPerfil != 'estudio') {
      return false;
    }

    if (filters.category == SearchCategory.venues &&
        item.tipoPerfil != 'contratante') {
      return false;
    }

    if (filters.hasProfessionalOnlyFilters &&
        item.tipoPerfil != 'profissional') {
      return false;
    }

    if (filters.hasStudioOnlyFilters) {
      if (filters.category == SearchCategory.venues) {
        if (item.tipoPerfil != 'contratante') return false;
      } else if (item.tipoPerfil != 'estudio') {
        return false;
      }
    }

    // Get nested data for detailed filters
    final profData = rawData['profissional'] as Map<String, dynamic>? ?? {};
    final bandData = rawData['banda'] as Map<String, dynamic>? ?? {};
    final studioData = rawData['estudio'] as Map<String, dynamic>? ?? {};
    final contractorData =
        rawData['contratante'] as Map<String, dynamic>? ?? {};

    // Professional subcategory filter
    if (filters.professionalSubcategory != null) {
      final categories = CategoryNormalizer.resolveCategories(
        rawCategories: List<String>.from(profData['categorias'] ?? []),
        rawRoles: List<String>.from(profData['funcoes'] ?? []),
      );
      final subcatValue = filters.professionalSubcategory!.firestoreId;
      if (!categories.contains(subcatValue)) {
        return false;
      }
    }

    // Genre filter (AND logic - must have ALL selected genres)
    if (filters.genres.isNotEmpty) {
      List<String> itemGenres = [];
      if (item.tipoPerfil == 'profissional') {
        itemGenres = List<String>.from(profData['generosMusicais'] ?? []);
      } else if (item.tipoPerfil == 'banda') {
        itemGenres = List<String>.from(bandData['generosMusicais'] ?? []);
      }
      if (!listContainsAll(itemGenres, filters.genres)) {
        return false;
      }
    }

    // Instruments filter (professionals only)
    if (filters.instruments.isNotEmpty) {
      final itemInstruments = List<String>.from(profData['instrumentos'] ?? []);
      if (!listContainsAny(itemInstruments, filters.instruments)) {
        return false;
      }
    }

    // Roles filter (production/stage tech)
    if (filters.roles.isNotEmpty) {
      final itemRoles = List<String>.from(
        profData['funcoes'] ?? [],
      ).map(CategoryNormalizer.normalizeRoleId).toList();
      final filterRoles = filters.roles
          .map(CategoryNormalizer.normalizeRoleId)
          .toList();
      if (!listContainsAny(itemRoles, filterRoles)) {
        return false;
      }
    }

    // Remote recording filter (production profiles only)
    if (filters.offersRemoteRecording == true) {
      if (item.tipoPerfil != 'profissional') {
        return false;
      }
      final offersRemoteRecording = professionalOffersRemoteRecording(profData);
      if (!offersRemoteRecording) {
        return false;
      }
    }

    // Services filter (studios only)
    if (filters.services.isNotEmpty) {
      final itemServices = item.tipoPerfil == 'contratante'
          ? _normalizeVenueAmenityIds(contractorData['comodidades'])
          : switch (item.tipoPerfil) {
              'estudio' => List<String>.from(
                studioData['services'] ??
                    studioData['servicosOferecidos'] ??
                    [],
              ),
              _ => const <String>[],
            };
      final filterServices = item.tipoPerfil == 'contratante'
          ? filters.services
                .map(_normalizeVenueAmenityId)
                .whereType<String>()
                .toList(growable: false)
          : filters.services;
      if (filterServices.isEmpty ||
          !listContainsAny(itemServices, filterServices)) {
        return false;
      }
    }

    // Studio type filter
    if (filters.studioType != null) {
      if (item.tipoPerfil == 'contratante') {
        final filterVenueType = _normalizeVenueTypeId(filters.studioType);
        final itemVenueType = _normalizeVenueTypeId(
          contractorData['venueType'] as String?,
        );
        if (filterVenueType == null || itemVenueType != filterVenueType) {
          return false;
        }
      } else {
        final studioType = switch (item.tipoPerfil) {
          'estudio' => studioData['studioType'] as String?,
          _ => null,
        };
        if (studioType != filters.studioType) {
          return false;
        }
      }
    }

    // Backing vocal filter
    if (filters.canDoBackingVocal != null) {
      final categories = List<String>.from(profData['categorias'] ?? []);

      bool canDoBacking = false;

      // Singer: check backingVocalMode
      if (categories.contains('singer')) {
        final mode = profData['backingVocalMode'] as String? ?? '0';
        canDoBacking = mode == '1' || mode == '2';
      }

      // Instrumentalist: check fazBackingVocal
      if (categories.contains('instrumentalist')) {
        final fazBacking =
            profData['fazBackingVocal'] as bool? ??
            profData['instrumentalistBackingVocal'] as bool? ??
            false;
        if (fazBacking) canDoBacking = true;
      }

      if (filters.canDoBackingVocal! && !canDoBacking) {
        return false;
      }
    }

    return true;
  }

  String? _normalizeVenueTypeId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return _venueTypeLookup[normalized.toLowerCase()];
  }

  String? _normalizeVenueAmenityId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return _venueAmenityLookup[normalized.toLowerCase()];
  }

  List<String> _normalizeVenueAmenityIds(dynamic values) {
    if (values is! Iterable) {
      return const [];
    }
    return values
        .whereType<String>()
        .map(_normalizeVenueAmenityId)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
  }

  bool _matchesSearchTerm(String term, FeedItem item) {
    final normalizedTerm = normalizeText(term);
    if (normalizedTerm.isEmpty) {
      return true;
    }

    final searchableText = _buildSearchableText(item);
    if (searchableText.contains(normalizedTerm)) {
      return true;
    }

    final aliases = _searchQueryAliases[normalizedTerm] ?? const <String>[];
    return aliases.any(searchableText.contains);
  }

  String _buildSearchableText(FeedItem item) {
    final terms = <String>{
      item.nome,
      item.nomeArtistico ?? '',
      item.displayName,
      item.categoria ?? '',
      item.tipoPerfil,
      ...item.generosMusicais,
      ...item.skills,
      ...item.subCategories,
      ..._profileTypeSearchTerms(item.tipoPerfil),
    };

    return terms
        .map(normalizeText)
        .where((value) => value.isNotEmpty)
        .join(' ');
  }

  Iterable<String> _profileTypeSearchTerms(String tipoPerfil) sync* {
    switch (tipoPerfil) {
      case 'profissional':
        yield* const ['musico', 'profissional', 'artista'];
        break;
      case 'banda':
        yield* const ['banda', 'grupo', 'band'];
        break;
      case 'estudio':
        yield* const ['estudio', 'studio', 'gravacao', 'ensaio'];
        break;
      case 'contratante':
        yield* const ['local', 'contratante', 'venue', 'casa de show'];
        break;
    }
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
      return List.of(items)
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    // Calculate distances
    final calculatedItems = items.map((item) {
      final loc = item.location;
      if (loc != null && loc['lat'] != null && loc['lng'] != null) {
        final itemLat = (loc['lat'] as num).toDouble();
        final itemLng = (loc['lng'] as num).toDouble();
        final dist = calculateDistanceKm(userLat, userLng, itemLat, itemLng);
        return item.copyWith(distanceKm: dist);
      }
      return item;
    }).toList();

    // Sort: distance asc (nulls last), then name
    return calculatedItems..sort((a, b) {
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
  final analytics = ref.read(analyticsServiceProvider);
  return SearchRepository(
    firestore: ref.read(firebaseFirestoreProvider),
    analytics: analytics,
  );
});
