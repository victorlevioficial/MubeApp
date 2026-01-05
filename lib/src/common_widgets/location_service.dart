import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  // TODO: Substitua pela sua chave REAL copiada do Google Cloud Console
  static const String _googleApiKey = 'AIzaSyDV5N_ybY5dPkE2T0Dl4JCqaAlGxte2WU0';

  static String get googleApiKey => _googleApiKey;

  static const String _placesUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  /// Helper para fazer requisições HTTP lidando com CORS na Web
  Future<http.Response> _makeRequest(String url) async {
    if (kIsWeb) {
      // Usa um proxy para contornar o bloqueio CORS do navegador durante desenvolvimento
      // Nota: Em produção web, o ideal seria ter um backend próprio fazendo essa chamada.
      // 'corsproxy.io' costuma ser mais robusto para URLs longas com query params
      final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(url)}';
      return await http.get(Uri.parse(proxyUrl));
    }
    return await http.get(Uri.parse(url));
  }

  /// Busca endereço (Autocomplete)
  /// Retorna lista de sugestões com {description, place_id}
  Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    if (query.length < 3) return [];

    // Components=country:br limita a busca ao Brasil
    final urlString =
        '$_placesUrl?input=$query&components=country:br&language=pt_BR&key=$_googleApiKey';

    try {
      final response = await _makeRequest(urlString);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions']);
        } else {
          debugPrint(
            'Google API Error: ${data['status']} - ${data['error_message']}',
          );
        }
      }
    } catch (e) {
      debugPrint('Erro busca Google: $e');
    }
    return [];
  }

  /// Pega detalhes do lugar pelo ID (Rua, CEP, Cidade...)
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final urlString =
        '$_detailsUrl?place_id=$placeId&fields=address_component,geometry&key=$_googleApiKey';

    try {
      final response = await _makeRequest(urlString);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final map = _parseGoogleComponents(result['address_components']);

          if (result['geometry'] != null &&
              result['geometry']['location'] != null) {
            map['lat'] = result['geometry']['location']['lat'];
            map['lng'] = result['geometry']['location']['lng'];
          }
          return map;
        }
      }
    } catch (e) {
      debugPrint('Erro details Google: $e');
    }
    return null;
  }

  /// Pega endereço por Coordenadas (Reverse Geocoding)
  Future<Map<String, dynamic>?> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    final urlString =
        '$_geocodeUrl?latlng=$lat,$lon&language=pt_BR&key=$_googleApiKey';

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
          return map;
        }
      }
    } catch (e) {
      debugPrint('Erro geocode Google: $e');
    }
    return null;
  }

  /// Parser auxiliar para transformar o JSON complexo do Google em um Map simples
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
      if (types.contains('sublocality') ||
          types.contains('sublocality_level_1')) {
        bairro = val;
      }
      if (types.contains('administrative_area_level_2')) cidade = val;
      if (types.contains('administrative_area_level_1')) {
        estado = shortVal; // SP, RJ...
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

  Future<Position?> getCurrentPosition() async {
    // Mesma lógica de antes...
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }
}
