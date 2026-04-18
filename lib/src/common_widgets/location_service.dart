import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../features/address/domain/address_search_result.dart';
import '../features/address/domain/resolved_address.dart';
import '../utils/app_logger.dart';

typedef LocationRequestHandler =
    Future<http.Response> Function(String url, {Map<String, String>? headers});

typedef CurrentPositionLoader =
    Future<Position> Function({required bool forceRefresh});

enum LocationServiceErrorCode {
  apiKeyMissing,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  quotaExceeded,
  requestFailed,
}

class LocationServiceException implements Exception {
  const LocationServiceException(this.code, this.message);

  final LocationServiceErrorCode code;
  final String message;

  @override
  String toString() => 'LocationServiceException($code, $message)';
}

class LocationService {
  LocationService({
    LocationRequestHandler? requestHandler,
    CurrentPositionLoader? positionLoader,
  }) : _requestHandler = requestHandler,
       _positionLoader = positionLoader;

  static String get googleApiKey => AppConfig.effectiveGoogleMapsApiKey;
  static bool get isConfigured => googleApiKey.isNotEmpty;

  static const Duration _positionCacheTtl = Duration(minutes: 2);
  static const Duration _reverseGeocodeCacheTtl = Duration(minutes: 10);
  static const Duration _searchCacheTtl = Duration(minutes: 5);
  static const Duration _placeDetailsCacheTtl = Duration(minutes: 30);

  static Position? _cachedPosition;
  static DateTime? _cachedPositionAt;
  static final Map<String, _TimedCacheEntry<ResolvedAddress>>
  _reverseGeocodeCache = {};
  static final Map<String, _TimedCacheEntry<List<AddressSearchResult>>>
  _searchCache = {};
  static final Map<String, _TimedCacheEntry<ResolvedAddress>>
  _googlePlaceDetailsCache = {};

  final LocationRequestHandler? _requestHandler;
  final CurrentPositionLoader? _positionLoader;

  Future<http.Response> _makeRequest(
    String url, {
    Map<String, String>? headers,
  }) async {
    if (_requestHandler != null) {
      return _requestHandler(url, headers: headers);
    }

    if (kIsWeb && kDebugMode) {
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      return http.get(Uri.parse(proxyUrl), headers: headers);
    }
    return http.get(Uri.parse(url), headers: headers);
  }

  Future<List<AddressSearchResult>> searchAddress(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.length < 3) return const [];
    _ensureConfigured();

    final queryKey = normalizedQuery.toLowerCase();
    final cachedSearch = _searchCache[queryKey];
    if (_isCacheFresh(cachedSearch?.cachedAt, _searchCacheTtl)) {
      return List<AddressSearchResult>.from(cachedSearch!.value);
    }

    final response = await _makeRequest(
      AppConfig.buildPlacesUrl(normalizedQuery, country: 'br'),
    );
    if (response.statusCode != 200) {
      throw const LocationServiceException(
        LocationServiceErrorCode.requestFailed,
        'Erro ao buscar enderecos.',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString();
    if (status == 'ZERO_RESULTS') {
      return const [];
    }
    if (status == 'OVER_QUERY_LIMIT') {
      throw const LocationServiceException(
        LocationServiceErrorCode.quotaExceeded,
        'Limite da API do Google atingido.',
      );
    }
    if (status != 'OK') {
      throw LocationServiceException(
        LocationServiceErrorCode.requestFailed,
        _googleErrorMessage(fallback: 'Erro ao buscar enderecos.', data: data),
      );
    }

    final queryNumberHint = extractHouseNumberFromText(normalizedQuery);
    final predictions = List<Map<String, dynamic>>.from(
      data['predictions'] as List? ?? const [],
    );
    final results = dedupeSearchResults(
      predictions.map((prediction) {
        final description = (prediction['description'] ?? '').toString().trim();
        final placeId = (prediction['place_id'] ?? '').toString().trim();
        if (description.isEmpty || placeId.isEmpty) return null;

        final structured = Map<String, dynamic>.from(
          prediction['structured_formatting'] as Map? ?? const {},
        );
        final mainText = (structured['main_text'] ?? '').toString().trim();
        final secondaryText = (structured['secondary_text'] ?? '')
            .toString()
            .trim();
        final numberHint = extractHouseNumberFromText(mainText).isNotEmpty
            ? extractHouseNumberFromText(mainText)
            : queryNumberHint;

        return AddressSearchResult(
          placeId: placeId,
          description: description,
          mainText: mainText.isNotEmpty ? mainText : description,
          secondaryText: secondaryText,
          numberHint: numberHint,
        );
      }).whereType<AddressSearchResult>(),
    );

    _searchCache[queryKey] = _TimedCacheEntry(
      value: List<AddressSearchResult>.from(results),
      cachedAt: DateTime.now(),
    );
    return results;
  }

  Future<ResolvedAddress?> getPlaceDetails(
    String placeId, {
    String? numberHint,
  }) async {
    final normalizedPlaceId = placeId.trim();
    if (normalizedPlaceId.isEmpty) return null;
    _ensureConfigured();

    final cached = _googlePlaceDetailsCache[normalizedPlaceId];
    if (_isCacheFresh(cached?.cachedAt, _placeDetailsCacheTtl)) {
      return _applyNumberHint(cached!.value, numberHint);
    }

    final response = await _makeRequest(
      AppConfig.buildPlaceDetailsUrl(normalizedPlaceId),
    );
    if (response.statusCode != 200) {
      throw const LocationServiceException(
        LocationServiceErrorCode.requestFailed,
        'Erro ao obter detalhes do endereco.',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString();
    if (status == 'OVER_QUERY_LIMIT') {
      throw const LocationServiceException(
        LocationServiceErrorCode.quotaExceeded,
        'Limite da API do Google atingido.',
      );
    }
    if (status == 'REQUEST_DENIED') {
      throw LocationServiceException(
        LocationServiceErrorCode.requestFailed,
        _googleErrorMessage(
          fallback: 'Erro ao obter detalhes do endereco.',
          data: data,
        ),
      );
    }
    if (status != 'OK') {
      return null;
    }

    final result = Map<String, dynamic>.from(
      data['result'] as Map? ?? const {},
    );
    final resolved = _resolvedAddressFromGoogleResult(result);
    if (resolved == null) return null;

    final enriched = _applyNumberHint(
      resolved,
      numberHint ??
          extractHouseNumberFromText(
            (result['formatted_address'] ?? '').toString(),
          ),
    );

    _googlePlaceDetailsCache[normalizedPlaceId] = _TimedCacheEntry(
      value: enriched,
      cachedAt: DateTime.now(),
    );
    return enriched;
  }

  Future<ResolvedAddress?> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    _ensureConfigured();

    final coordinateKey = _buildCoordinateKey(lat, lng);
    final cachedAddress = _reverseGeocodeCache[coordinateKey];
    if (_isCacheFresh(cachedAddress?.cachedAt, _reverseGeocodeCacheTtl)) {
      return cachedAddress!.value;
    }

    final response = await _makeRequest(
      AppConfig.buildReverseGeocodeUrl(lat, lng),
    );
    if (response.statusCode != 200) {
      throw const LocationServiceException(
        LocationServiceErrorCode.requestFailed,
        'Erro ao determinar o endereço da localização atual.',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final status = (data['status'] ?? '').toString();
    if (status == 'ZERO_RESULTS') return null;
    if (status == 'OVER_QUERY_LIMIT') {
      throw const LocationServiceException(
        LocationServiceErrorCode.quotaExceeded,
        'Limite da API do Google atingido.',
      );
    }
    if (status != 'OK') {
      throw LocationServiceException(
        LocationServiceErrorCode.requestFailed,
        _googleErrorMessage(
          fallback: 'Erro ao determinar o endereço da localização atual.',
          data: data,
        ),
      );
    }

    final results = List<Map<String, dynamic>>.from(
      data['results'] as List? ?? const [],
    );
    if (results.isEmpty) return null;

    final resolved = _resolvedAddressFromGoogleResult(
      results.first,
    )?.copyWith(lat: lat, lng: lng);
    if (resolved == null) return null;

    _reverseGeocodeCache[coordinateKey] = _TimedCacheEntry(
      value: resolved,
      cachedAt: DateTime.now(),
    );
    return resolved;
  }

  Future<Position> getCurrentPosition({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh &&
          _cachedPosition != null &&
          _isCacheFresh(_cachedPositionAt, _positionCacheTtl)) {
        return _cachedPosition!;
      }

      if (_positionLoader != null) {
        final current = await _positionLoader(forceRefresh: forceRefresh);
        _cachedPosition = current;
        _cachedPositionAt = DateTime.now();
        return current;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const LocationServiceException(
          LocationServiceErrorCode.serviceDisabled,
          'GPS desativado. Ative o serviço de localização.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          LocationServiceErrorCode.permissionDenied,
          'Permissão de localização negada.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw const LocationServiceException(
          LocationServiceErrorCode.permissionDeniedForever,
          'Permissão de localização negada permanentemente.',
        );
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
    } on LocationServiceException {
      rethrow;
    } catch (error) {
      throw LocationServiceException(
        LocationServiceErrorCode.requestFailed,
        'Erro ao obter localização: $error',
      );
    }
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      AppLogger.error(
        'LocationService called without configured GOOGLE_MAPS_API_KEY',
      );
      throw const LocationServiceException(
        LocationServiceErrorCode.apiKeyMissing,
        'Não foi possível concluir a busca de endereço agora. Tente novamente em instantes.',
      );
    }
  }

  ResolvedAddress? _resolvedAddressFromGoogleResult(
    Map<String, dynamic> result,
  ) {
    final components = List<dynamic>.from(
      result['address_components'] as List? ?? const [],
    );
    final parsed = _parseGoogleComponents(components);

    final geometry = Map<String, dynamic>.from(
      result['geometry'] as Map? ?? const {},
    );
    final location = Map<String, dynamic>.from(
      geometry['location'] as Map? ?? const {},
    );

    final logradouro = parsed['logradouro']!.trim().isNotEmpty
        ? parsed['logradouro']!.trim()
        : (result['name'] ?? '').toString().trim();

    return ResolvedAddress(
      logradouro: logradouro,
      numero: parsed['numero']!.trim(),
      bairro: parsed['bairro']!.trim(),
      cidade: parsed['cidade']!.trim(),
      estado: parsed['estado']!.trim(),
      cep: parsed['cep']!.trim(),
      lat: (location['lat'] as num?)?.toDouble(),
      lng: (location['lng'] as num?)?.toDouble(),
    );
  }

  ResolvedAddress _applyNumberHint(
    ResolvedAddress address,
    String? hintSource,
  ) {
    if (address.numero.trim().isNotEmpty) return address;

    final extracted = extractHouseNumberFromText(hintSource ?? '');
    if (extracted.isEmpty) return address;
    return address.copyWith(numero: extracted);
  }

  Map<String, String> _parseGoogleComponents(List<dynamic> components) {
    var logradouro = '';
    var numero = '';
    var bairro = '';
    var cidade = '';
    var estado = '';
    var cep = '';

    for (final component in components) {
      if (component is! Map) continue;
      final map = Map<String, dynamic>.from(component);
      final types = List<String>.from(map['types'] as List? ?? const []);
      final longName = (map['long_name'] ?? '').toString();
      final shortName = (map['short_name'] ?? '').toString();

      if (types.contains('route')) logradouro = longName;
      if (types.contains('street_number')) numero = longName;
      if (types.contains('neighborhood') && bairro.isEmpty) bairro = longName;
      if ((types.contains('sublocality') ||
              types.contains('sublocality_level_1')) &&
          bairro.isEmpty) {
        bairro = longName;
      }
      if (types.contains('locality') && cidade.isEmpty) cidade = longName;
      if (types.contains('administrative_area_level_2') && cidade.isEmpty) {
        cidade = longName;
      }
      if (types.contains('administrative_area_level_1')) estado = shortName;
      if (types.contains('postal_code')) cep = longName;
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

  @visibleForTesting
  static List<AddressSearchResult> dedupeSearchResults(
    Iterable<AddressSearchResult> results,
  ) {
    final seenPlaceIds = <String>{};
    final seenMainTexts = <String>{};
    final deduped = <AddressSearchResult>[];

    for (final result in results) {
      final placeId = result.placeId.trim();
      if (placeId.isEmpty || !seenPlaceIds.add(placeId)) {
        continue;
      }

      final normalizedMainText = result.normalizedMainText;
      if (normalizedMainText.isNotEmpty &&
          !seenMainTexts.add(normalizedMainText)) {
        continue;
      }

      deduped.add(result);
    }

    return deduped;
  }

  @visibleForTesting
  static String extractHouseNumberFromText(String source) {
    final normalized = source.trim();
    if (normalized.isEmpty) return '';

    final match = RegExp(r'\b\d{1,6}[A-Za-z0-9\-\/]*\b').firstMatch(normalized);
    return match?.group(0) ?? '';
  }

  static bool _isCacheFresh(DateTime? cachedAt, Duration ttl) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) <= ttl;
  }

  static String _buildCoordinateKey(double lat, double lng) {
    final latRounded = lat.toStringAsFixed(4);
    final lngRounded = lng.toStringAsFixed(4);
    return '$latRounded,$lngRounded';
  }

  static String _googleErrorMessage({
    required String fallback,
    required Map<String, dynamic> data,
  }) {
    final message = (data['error_message'] ?? '').toString().trim();
    if (message.isEmpty) return fallback;

    final normalized = message.toLowerCase();
    if (normalized.contains('not authorized to use this api key') ||
        normalized.contains('api project is not authorized')) {
      AppLogger.error(
        'Google Maps API key not authorized for Places/Geocoding',
      );
      return 'Não foi possível buscar endereço agora. Tente novamente em instantes.';
    }
    if (normalized.contains('provided api key is invalid') ||
        normalized.contains('api key is invalid')) {
      AppLogger.error('Google Maps API key is invalid');
      return 'Não foi possível buscar endereço agora. Tente novamente em instantes.';
    }
    return message;
  }

  @visibleForTesting
  static String describeGoogleApiError({
    required String fallback,
    required Map<String, dynamic> data,
  }) {
    return _googleErrorMessage(fallback: fallback, data: data);
  }
}

class _TimedCacheEntry<T> {
  const _TimedCacheEntry({required this.value, required this.cachedAt});

  final T value;
  final DateTime? cachedAt;
}
