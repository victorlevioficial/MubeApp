import '../../../firebase_options.dart';

/// Application configuration constants.
///
/// This class centralizes all environment-specific configuration
/// including API keys, endpoints, and feature flags.
///
/// For sensitive values like API keys, use --dart-define during build:
/// flutter run --dart-define=GOOGLE_VISION_API_KEY=your_key_here
/// flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
class AppConfig {
  const AppConfig._();

  static const String _googleVisionApiKeyFromEnv = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: '',
  );

  static const String _googleMapsApiKeyFromEnv = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // ===========================================================================
  // API KEYS (from environment)
  // ===========================================================================

  /// Google Vision API Key for content moderation
  /// Set via: --dart-define=GOOGLE_VISION_API_KEY=xxx
  static String get googleVisionApiKey =>
      _normalizeApiKey(_googleVisionApiKeyFromEnv);

  /// Google Maps API Key for location services
  /// Set via: --dart-define=GOOGLE_MAPS_API_KEY=xxx
  static String get googleMapsApiKey =>
      _normalizeApiKey(_googleMapsApiKeyFromEnv);

  /// Effective Google Maps key used by location flows.
  ///
  /// Priority:
  /// 1. `GOOGLE_MAPS_API_KEY` provided via `--dart-define`
  /// 2. Firebase API key from `firebase_options.dart` as a runtime fallback
  static String get effectiveGoogleMapsApiKey {
    final fromEnv = googleMapsApiKey;
    if (fromEnv.isNotEmpty) return fromEnv;
    return _firebaseApiKeyFallback;
  }

  // ===========================================================================
  // API ENDPOINTS
  // ===========================================================================

  static const String _visionBaseUrl =
      'https://vision.googleapis.com/v1/images:annotate';
  static const String _placesUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';
  static const String _geocodeUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  // ===========================================================================
  // URL BUILDERS
  // ===========================================================================

  /// Builds the Vision API URL with key
  static String get visionApiUrl {
    if (googleVisionApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_VISION_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_VISION_API_KEY=your_key',
      );
    }
    return '$_visionBaseUrl?key=$googleVisionApiKey';
  }

  /// Builds the Places Autocomplete URL
  static String buildPlacesUrl(String query, {String country = 'br'}) {
    final mapsApiKey = effectiveGoogleMapsApiKey;
    if (mapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
    }

    final uri = Uri.parse(_placesUrl).replace(
      queryParameters: {
        'input': query,
        'components': 'country:$country',
        'language': 'pt-BR',
        'types': 'address',
        'key': mapsApiKey,
      },
    );
    return uri.toString();
  }

  /// Builds the Place Details URL
  static String buildPlaceDetailsUrl(String placeId) {
    final mapsApiKey = effectiveGoogleMapsApiKey;
    if (mapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
    }

    final uri = Uri.parse(_detailsUrl).replace(
      queryParameters: {
        'place_id': placeId,
        'fields': 'address_component,formatted_address,geometry,name',
        'language': 'pt-BR',
        'key': mapsApiKey,
      },
    );
    return uri.toString();
  }

  /// Builds the Geocoding URL
  static String buildGeocodeUrl(String address) {
    final mapsApiKey = effectiveGoogleMapsApiKey;
    if (mapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
    }

    final uri = Uri.parse(_geocodeUrl).replace(
      queryParameters: {
        'address': address,
        'language': 'pt-BR',
        'region': 'BR',
        'key': mapsApiKey,
      },
    );
    return uri.toString();
  }

  /// Builds the Reverse Geocoding URL from coordinates.
  static String buildReverseGeocodeUrl(double lat, double lng) {
    final mapsApiKey = effectiveGoogleMapsApiKey;
    if (mapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
    }

    final uri = Uri.parse(_geocodeUrl).replace(
      queryParameters: {
        'latlng': '$lat,$lng',
        'language': 'pt-BR',
        'region': 'BR',
        'key': mapsApiKey,
      },
    );
    return uri.toString();
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  /// Checks if all required API keys are configured
  static bool get hasRequiredKeys {
    return googleVisionApiKey.isNotEmpty &&
        effectiveGoogleMapsApiKey.isNotEmpty;
  }

  /// Validates configuration and throws if invalid
  static void validate() {
    if (googleVisionApiKey.isEmpty) {
      throw StateError(
        'Missing GOOGLE_VISION_API_KEY. '
        'Please configure environment variables.',
      );
    }
    if (effectiveGoogleMapsApiKey.isEmpty) {
      throw StateError(
        'Missing GOOGLE_MAPS_API_KEY. '
        'Please configure environment variables.',
      );
    }
  }

  static String get _firebaseApiKeyFallback {
    try {
      return _normalizeApiKey(DefaultFirebaseOptions.currentPlatform.apiKey);
    } on UnsupportedError {
      return _normalizeApiKey(DefaultFirebaseOptions.web.apiKey);
    }
  }

  static String _normalizeApiKey(String rawKey) {
    final normalized = rawKey.trim();
    if (normalized.length < 2) return normalized;

    final startsWithQuote =
        normalized.startsWith('"') || normalized.startsWith("'");
    final endsWithQuote = normalized.endsWith('"') || normalized.endsWith("'");
    if (!startsWithQuote || !endsWithQuote) return normalized;

    return normalized.substring(1, normalized.length - 1).trim();
  }
}
