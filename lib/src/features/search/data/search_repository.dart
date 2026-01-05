import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../domain/search_filters.dart';

part 'search_repository.g.dart';

/// Repository for searching users in Firestore.
///
/// Note: Firestore has limited full-text search capabilities.
/// For production, consider integrating Algolia or Elasticsearch.
class SearchRepository {
  final FirebaseFirestore _firestore;

  SearchRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Searches users based on filters.
  ///
  /// Due to Firestore limitations:
  /// - Text search is prefix-based (startsWith)
  /// - Only one inequality filter per query
  /// - Complex filters are applied client-side
  Future<List<AppUser>> searchUsers(SearchFilters filters) async {
    Query<Map<String, dynamic>> query = _usersCollection
        .where('cadastro_status', isEqualTo: 'concluido')
        .where('status', isEqualTo: 'ativo');

    // Filter by type (Firestore-side)
    if (filters.type != null) {
      query = query.where('tipo_perfil', isEqualTo: filters.type!.name);
    }

    // Filter by state (Firestore-side)
    if (filters.state != null) {
      query = query.where('location.estado', isEqualTo: filters.state);
    }

    // Limit results
    query = query.limit(50);

    final snapshot = await query.get();

    var results = snapshot.docs
        .map((doc) => AppUser.fromJson(doc.data()))
        .toList();

    // Client-side filtering for complex queries
    results = _applyClientSideFilters(results, filters);

    return results;
  }

  /// Applies filters that Firestore can't handle efficiently.
  List<AppUser> _applyClientSideFilters(
    List<AppUser> users,
    SearchFilters filters,
  ) {
    var filtered = users;

    // Text search on name
    if (filters.query != null && filters.query!.isNotEmpty) {
      final queryLower = filters.query!.toLowerCase();
      filtered = filtered.where((user) {
        final name = user.nome?.toLowerCase() ?? '';
        final artisticName = _getArtisticName(user)?.toLowerCase() ?? '';
        return name.contains(queryLower) || artisticName.contains(queryLower);
      }).toList();
    }

    // Filter by city
    if (filters.city != null) {
      filtered = filtered.where((user) {
        return user.location?['cidade'] == filters.city;
      }).toList();
    }

    // Filter by genres
    if (filters.genres.isNotEmpty) {
      filtered = filtered.where((user) {
        final userGenres = _getUserGenres(user);
        return filters.genres.any((g) => userGenres.contains(g));
      }).toList();
    }

    return filtered;
  }

  /// Extracts artistic name based on user type.
  String? _getArtisticName(AppUser user) {
    return switch (user.tipoPerfil) {
      AppUserType.professional => user.dadosProfissional?['nomeArtistico'],
      AppUserType.studio => user.dadosEstudio?['nomeArtistico'],
      _ => null,
    };
  }

  /// Extracts genres based on user type.
  List<String> _getUserGenres(AppUser user) {
    final genres = switch (user.tipoPerfil) {
      AppUserType.professional =>
        user.dadosProfissional?['generosMusicais'] as List?,
      AppUserType.band => user.dadosBanda?['generosMusicais'] as List?,
      _ => null,
    };
    return genres?.cast<String>() ?? [];
  }

  /// Gets users by specific type.
  Future<List<AppUser>> getUsersByType(AppUserType type) async {
    return searchUsers(SearchFilters(type: type));
  }

  /// Gets nearby users based on location.
  ///
  /// Note: For accurate geo-queries, consider using GeoFlutterFire
  /// or Firestore's native GeoPoint with geohash.
  Future<List<AppUser>> getNearbyUsers({
    required double lat,
    required double lng,
    double radiusKm = 50,
  }) async {
    // Simplified: get all users and filter by approximate distance
    final allUsers = await searchUsers(const SearchFilters());

    return allUsers.where((user) {
      final userLat = user.location?['lat'] as double?;
      final userLng = user.location?['long'] as double?;
      if (userLat == null || userLng == null) return false;

      // Approximate distance (Haversine would be more accurate)
      final distance = _approximateDistance(lat, lng, userLat, userLng);
      return distance <= radiusKm;
    }).toList();
  }

  /// Rough distance calculation (not accurate but fast).
  double _approximateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const kmPerDegree = 111.0;
    final dLat = (lat2 - lat1).abs() * kmPerDegree;
    final dLng =
        (lng2 - lng1).abs() * kmPerDegree * 0.7; // Rough longitude adjustment
    return dLat + dLng;
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provides a [SearchRepository] instance.
@Riverpod(keepAlive: true)
SearchRepository searchRepository(Ref ref) {
  return SearchRepository(FirebaseFirestore.instance);
}

/// Current search filters state.
@riverpod
class SearchFiltersNotifier extends _$SearchFiltersNotifier {
  @override
  SearchFilters build() => const SearchFilters();

  void updateQuery(String query) {
    state = state.copyWith(query: query.isEmpty ? null : query);
  }

  void updateType(AppUserType? type) {
    state = state.copyWith(type: type);
  }

  void updateLocation({String? city, String? stateCode}) {
    state = state.copyWith(city: city, state: stateCode);
  }

  void toggleGenre(String genre) {
    final genres = List<String>.from(state.genres);
    if (genres.contains(genre)) {
      genres.remove(genre);
    } else {
      genres.add(genre);
    }
    state = state.copyWith(genres: genres);
  }

  void clearFilters() {
    state = const SearchFilters();
  }
}

/// Provides search results based on current filters.
@riverpod
Future<List<AppUser>> searchResults(Ref ref) async {
  final filters = ref.watch(searchFiltersNotifierProvider);
  final repository = ref.watch(searchRepositoryProvider);

  // Don't search if no filters active
  if (!filters.hasActiveFilters) {
    return [];
  }

  return repository.searchUsers(filters);
}
