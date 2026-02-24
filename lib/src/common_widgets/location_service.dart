import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';

class LocationService {
  // API key from environment configuration
  static String get googleApiKey => AppConfig.googleMapsApiKey;

  static const Duration _positionCacheTtl = Duration(minutes: 2);
  static const Duration _reverseGeocodeCacheTtl = Duration(minutes: 10);
  static const Duration _searchCacheTtl = Duration(minutes: 5);
  static const Duration _placeDetailsCacheTtl = Duration(minutes: 30);

  static Position? _cachedPosition;
  static DateTime? _cachedPositionAt;
  static final Map<String, _TimedCacheEntry<Map<String, dynamic>>>
  _reverseGeocodeCache = {};
  static final Map<String, _TimedCacheEntry<List<Map<String, dynamic>>>>
  _searchCache = {};
  static final Map<String, _TimedCacheEntry<Map<String, dynamic>>>
  _googlePlaceDetailsCache = {};

  final Map<String, Map<String, dynamic>> _openStreetMapDetailsCache = {};

  /// Helper for HTTP requests with optional headers.
  Future<http.Response> _makeRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (kIsWeb && kDebugMode) {
      // CORS helper strictly for local web debugging.
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      return await http.get(Uri.parse(proxyUrl), headers: headers);
    }
    return await http.get(Uri.parse(url), headers: headers);
  }

  /// Address autocomplete. Returns entries with {description, place_id}.
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3) return [];

    final queryKey = normalizedQuery.toLowerCase();
    final cachedSearch = _searchCache[queryKey];
    if (_isCacheFresh(cachedSearch?.cachedAt, _searchCacheTtl)) {
      return List<Map<String, dynamic>>.from(cachedSearch!.value);
    }

    if (AppConfig.googleMapsApiKey.isNotEmpty) {
      final googleResults = await _searchAddressWithGoogle(normalizedQuery);
      if (googleResults.isNotEmpty) {
        _searchCache[queryKey] = _TimedCacheEntry(
          value: List<Map<String, dynamic>>.from(googleResults),
          cachedAt: DateTime.now(),
        );
        return googleResults;
      }
    } else {
      debugPrint(
        'GOOGLE_MAPS_API_KEY not set. Using OpenStreetMap fallback for address search.',
      );
    }

    final fallbackResults = await _searchAddressOpenStreetMap(normalizedQuery);
    if (fallbackResults.isNotEmpty) {
      _searchCache[queryKey] = _TimedCacheEntry(
        value: List<Map<String, dynamic>>.from(fallbackResults),
        cachedAt: DateTime.now(),
      );
    }
    return fallbackResults;
  }

  Future<List<Map<String, dynamic>>> _searchAddressWithGoogle(
    String query,
  ) async {
    final urlString = AppConfig.buildPlacesUrl(query, country: 'br');

    try {
      final response = await _makeRequest(urlString);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final predictions = List<Map<String, dynamic>>.from(
          data['predictions'] as List,
        );
        return predictions
            .map((prediction) {
              final description = (prediction['description'] ?? '')
                  .toString()
                  .trim();
              final placeId = (prediction['place_id'] ?? '').toString().trim();
              if (description.isEmpty || placeId.isEmpty) return null;

              return <String, dynamic>{
                'description': description,
                'place_id': placeId,
                'number_hint': _extractHouseNumberFromText(description),
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList();
      }

      debugPrint(
        'Google API Error: ${data['status']} - ${data['error_message']}',
      );
      return [];
    } catch (e) {
      debugPrint('Erro busca Google: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchAddressOpenStreetMap(
    String query,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'countrycodes': 'br',
      'limit': '10',
      'accept-language': 'pt-BR',
    });

    try {
      final response = await _makeRequest(
        uri.toString(),
        headers: const {'User-Agent': 'mube-app/1.0'},
      );
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body);
      if (data is! List) return [];

      final results = <Map<String, dynamic>>[];
      for (final item in data) {
        if (item is! Map) continue;

        final mapItem = Map<String, dynamic>.from(item);
        final lat = double.tryParse('${mapItem['lat'] ?? ''}');
        final lon = double.tryParse('${mapItem['lon'] ?? ''}');
        if (lat == null || lon == null) continue;

        final token = 'osm:$lat,$lon';
        final details = _parseOpenStreetMapDetails(
          lat: lat,
          lon: lon,
          address: Map<String, dynamic>.from(mapItem['address'] ?? const {}),
          displayName: mapItem['display_name']?.toString(),
          name: mapItem['name']?.toString(),
        );
        _openStreetMapDetailsCache[token] = details;

        final displayName = (mapItem['display_name'] ?? '').toString().trim();
        results.add({
          'description': displayName.isNotEmpty
              ? displayName
              : _buildOpenStreetMapDescription(details),
          'place_id': token,
        });
      }

      return results;
    } catch (e) {
      debugPrint('Erro busca OpenStreetMap: $e');
      return [];
    }
  }

  /// Place details from place id.
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (placeId.startsWith('osm:')) {
      final cached = _openStreetMapDetailsCache[placeId];
      if (cached != null) return cached;

      final coords = _parseOsmToken(placeId);
      if (coords != null) {
        return _reverseGeocodeOpenStreetMap(coords.$1, coords.$2);
      }
      return null;
    }

    if (AppConfig.googleMapsApiKey.isEmpty) {
      debugPrint(
        'GOOGLE_MAPS_API_KEY not set. OpenStreetMap details expect OSM place_id token.',
      );
      return null;
    }

    final cachedGoogleDetails = _googlePlaceDetailsCache[placeId];
    if (_isCacheFresh(cachedGoogleDetails?.cachedAt, _placeDetailsCacheTtl)) {
      return Map<String, dynamic>.from(cachedGoogleDetails!.value);
    }

    final urlString = AppConfig.buildPlaceDetailsUrl(placeId);

    try {
      final response = await _makeRequest(urlString);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final map = _parseGoogleComponents(
            List<dynamic>.from(result['address_components'] ?? const []),
          );

          if (result['geometry'] != null &&
              result['geometry']['location'] != null) {
            map['lat'] = result['geometry']['location']['lat'];
            map['lng'] = result['geometry']['location']['lng'];
          }

          final formattedAddress = (result['formatted_address'] ?? '')
              .toString()
              .trim();
          if ((map['numero'] ?? '').toString().trim().isEmpty &&
              formattedAddress.isNotEmpty) {
            map['numero'] = _extractHouseNumberFromText(formattedAddress);
          }

          if ((map['logradouro'] ?? '').toString().trim().isEmpty) {
            map['logradouro'] = (result['name'] ?? '').toString().trim();
          }

          _googlePlaceDetailsCache[placeId] = _TimedCacheEntry(
            value: Map<String, dynamic>.from(map),
            cachedAt: DateTime.now(),
          );
          return map;
        }

        debugPrint(
          'Google details API Error: ${data['status']} - ${data['error_message']}',
        );
      }
    } catch (e) {
      debugPrint('Erro details Google: $e');
    }

    return null;
  }

  /// Resolve endereço completo a partir de texto livre (incluindo número).
  Future<Map<String, dynamic>?> resolveAddressFromQuery(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3) return null;

    if (AppConfig.googleMapsApiKey.isNotEmpty) {
      try {
        final response = await _makeRequest(
          AppConfig.buildGeocodeUrl(normalizedQuery),
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
            final result = data['results'][0] as Map<String, dynamic>;
            final map = _parseGoogleComponents(
              List<dynamic>.from(result['address_components'] ?? const []),
            );

            final formattedAddress = (result['formatted_address'] ?? '')
                .toString()
                .trim();
            if ((map['numero'] ?? '').toString().trim().isEmpty &&
                formattedAddress.isNotEmpty) {
              map['numero'] = _extractHouseNumberFromText(formattedAddress);
            }

            if (result['geometry'] != null &&
                result['geometry']['location'] != null) {
              map['lat'] = result['geometry']['location']['lat'];
              map['lng'] = result['geometry']['location']['lng'];
            }
            return map;
          }
        }
      } catch (e) {
        debugPrint('Erro geocode por query (Google): $e');
      }
    }

    final fallbackResults = await _searchAddressOpenStreetMap(normalizedQuery);
    if (fallbackResults.isEmpty) return null;
    final placeId = fallbackResults.first['place_id']?.toString();
    if (placeId == null || placeId.isEmpty) return null;

    return getPlaceDetails(placeId);
  }

  /// Reverse geocoding from coordinates.
  Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    final coordinateKey = _buildCoordinateKey(lat, lon);
    final cachedAddress = _reverseGeocodeCache[coordinateKey];
    if (_isCacheFresh(cachedAddress?.cachedAt, _reverseGeocodeCacheTtl)) {
      return Map<String, dynamic>.from(cachedAddress!.value);
    }

    if (AppConfig.googleMapsApiKey.isEmpty) {
      debugPrint(
        'GOOGLE_MAPS_API_KEY not set. Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
      final fallback = await _reverseGeocodeOpenStreetMap(lat, lon);
      if (fallback != null) {
        _reverseGeocodeCache[coordinateKey] = _TimedCacheEntry(
          value: Map<String, dynamic>.from(fallback),
          cachedAt: DateTime.now(),
        );
      }
      return fallback;
    }

    final urlString = AppConfig.buildGeocodeUrl('$lat,$lon');

    try {
      final response = await _makeRequest(urlString);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          final map = _parseGoogleComponents(result['address_components']);

          if (result['geometry'] != null &&
              result['geometry']['location'] != null) {
            map['lat'] = result['geometry']['location']['lat'];
            map['lng'] = result['geometry']['location']['lng'];
          } else {
            map['lat'] = lat;
            map['lng'] = lon;
          }
          _reverseGeocodeCache[coordinateKey] = _TimedCacheEntry(
            value: Map<String, dynamic>.from(map),
            cachedAt: DateTime.now(),
          );
          return map;
        }

        debugPrint(
          'Google geocode API Error: ${data['status']} - ${data['error_message']}',
        );
      }
    } catch (e) {
      debugPrint('Erro geocode Google: $e');
    }

    final fallback = await _reverseGeocodeOpenStreetMap(lat, lon);
    if (fallback != null) {
      _reverseGeocodeCache[coordinateKey] = _TimedCacheEntry(
        value: Map<String, dynamic>.from(fallback),
        cachedAt: DateTime.now(),
      );
    }
    return fallback;
  }

  Future<Map<String, dynamic>?> _reverseGeocodeOpenStreetMap(
    double lat,
    double lon,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': lat.toString(),
      'lon': lon.toString(),
      'addressdetails': '1',
      'accept-language': 'pt-BR',
    });

    try {
      final response = await _makeRequest(
        uri.toString(),
        headers: const {'User-Agent': 'mube-app/1.0'},
      );
      if (response.statusCode != 200) {
        return _fallbackAddressFromCoordinates(lat, lon);
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parseOpenStreetMapDetails(
        lat: lat,
        lon: lon,
        address: Map<String, dynamic>.from(data['address'] ?? const {}),
        displayName: data['display_name']?.toString(),
        name: data['name']?.toString(),
      );
    } catch (e) {
      debugPrint('Erro geocode OpenStreetMap: $e');
      return _fallbackAddressFromCoordinates(lat, lon);
    }
  }

  Map<String, dynamic> _parseOpenStreetMapDetails({
    required double lat,
    required double lon,
    required Map<String, dynamic> address,
    String? displayName,
    String? name,
  }) {
    final logradouro =
        (address['road'] ??
                address['pedestrian'] ??
                address['residential'] ??
                address['highway'] ??
                '')
            .toString();

    final bairro =
        (address['suburb'] ??
                address['neighbourhood'] ??
                address['quarter'] ??
                address['city_district'] ??
                '')
            .toString();

    final cidade =
        (address['city'] ??
                address['town'] ??
                address['village'] ??
                address['municipality'] ??
                address['county'] ??
                '')
            .toString();

    final estado = (address['state'] ?? '').toString();
    final cep = (address['postcode'] ?? '').toString();
    final numero = _extractHouseNumber(
      address: address,
      displayName: displayName,
      name: name,
    );

    return {
      'logradouro': logradouro.isNotEmpty ? logradouro : 'Localizacao atual',
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'lat': lat,
      'lng': lon,
    };
  }

  String _extractHouseNumber({
    required Map<String, dynamic> address,
    String? displayName,
    String? name,
  }) {
    final direct = (address['house_number'] ?? '').toString().trim();
    if (direct.isNotEmpty) return direct;

    if (displayName != null && displayName.isNotEmpty) {
      final firstChunks = displayName.split(',').take(2).join(' ');
      final found = _extractHouseNumberFromText(firstChunks);
      if (found.isNotEmpty) return found;
    }

    if (name != null && name.isNotEmpty) {
      final found = _extractHouseNumberFromText(name);
      if (found.isNotEmpty) return found;
    }

    return '';
  }

  String _extractHouseNumberFromText(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) return '';

    final match = RegExp(r'\b\d{1,6}[A-Za-z0-9\-\/]*\b').firstMatch(normalized);
    return match?.group(0) ?? '';
  }

  String _buildOpenStreetMapDescription(Map<String, dynamic> details) {
    final parts = <String>[
      (details['logradouro'] ?? '').toString(),
      (details['numero'] ?? '').toString(),
      (details['bairro'] ?? '').toString(),
      (details['cidade'] ?? '').toString(),
      (details['estado'] ?? '').toString(),
    ].where((value) => value.trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'Localizacao atual';
    return parts.join(', ');
  }

  (double, double)? _parseOsmToken(String token) {
    if (!token.startsWith('osm:')) return null;

    final payload = token.substring(4);
    final parts = payload.split(',');
    if (parts.length != 2) return null;

    final lat = double.tryParse(parts[0]);
    final lon = double.tryParse(parts[1]);
    if (lat == null || lon == null) return null;

    return (lat, lon);
  }

  Map<String, dynamic> _fallbackAddressFromCoordinates(double lat, double lon) {
    return {
      'logradouro': 'Localizacao atual',
      'numero': '',
      'bairro': '',
      'cidade': '',
      'estado': '',
      'cep': '',
      'lat': lat,
      'lng': lon,
    };
  }

  /// Parser auxiliar para transformar o JSON complexo do Google em um map simples.
  Map<String, dynamic> _parseGoogleComponents(List<dynamic> components) {
    String logradouro = '';
    String numero = '';
    String bairro = '';
    String cidade = '';
    String estado = '';
    String cep = '';

    for (var c in components) {
      final types = (c['types'] as List).cast<String>();
      final val = c['long_name'];
      final shortVal = c['short_name'];

      if (types.contains('route')) logradouro = val;
      if (types.contains('street_number')) numero = val;
      if (types.contains('neighborhood') && bairro.isEmpty) bairro = val;
      if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        bairro = val;
      }
      if (types.contains('locality') && cidade.isEmpty) cidade = val;
      if (types.contains('administrative_area_level_2') && cidade.isEmpty) {
        cidade = val;
      }
      if (types.contains('administrative_area_level_1')) {
        estado = shortVal;
      }
      if (types.contains('postal_code')) cep = val;
    }

    return {
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
    };
  }

  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _cachedPosition != null &&
          _isCacheFresh(_cachedPositionAt, _positionCacheTtl)) {
        return _cachedPosition;
      }

      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: GPS service is disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Permission denied forever');
        return null;
      }

      if (!forceRefresh) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _cachedPosition = lastKnown;
          _cachedPositionAt = DateTime.now();
          return lastKnown;
        }
      }

      final current = await Geolocator.getCurrentPosition();
      _cachedPosition = current;
      _cachedPositionAt = DateTime.now();
      return current;
    } catch (e) {
      debugPrint('LocationService: Error getting location: $e');
      return null;
    }
  }

  bool _isCacheFresh(DateTime? cachedAt, Duration ttl) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) <= ttl;
  }

  String _buildCoordinateKey(double lat, double lon) {
    final latRounded = lat.toStringAsFixed(4);
    final lonRounded = lon.toStringAsFixed(4);
    return '$latRounded,$lonRounded';
  }
}

class _TimedCacheEntry<T> {
  final T value;
  final DateTime cachedAt;

  const _TimedCacheEntry({required this.value, required this.cachedAt});
}
