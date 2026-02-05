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

  // ===========================================================================
  // API KEYS (from environment)
  // ===========================================================================

  /// Google Vision API Key for content moderation
  /// Set via: --dart-define=GOOGLE_VISION_API_KEY=xxx
  static const String googleVisionApiKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
    defaultValue: '',
  );

  /// Google Maps API Key for location services
  /// Set via: --dart-define=GOOGLE_MAPS_API_KEY=xxx
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

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
    if (googleMapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
    }
    return '$_placesUrl?input=$query&components=country:$country&language=pt_BR&key=$googleMapsApiKey';
  }

  /// Builds the Place Details URL
  static String buildPlaceDetailsUrl(String placeId) {
    if (googleMapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
    }
    return '$_detailsUrl?place_id=$placeId&fields=address_component,geometry&key=$googleMapsApiKey';
  }

  /// Builds the Geocoding URL
  static String buildGeocodeUrl(String address) {
    if (googleMapsApiKey.isEmpty) {
      throw StateError(
        'GOOGLE_MAPS_API_KEY not set. '
        'Run with: --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
    }
    return '$_geocodeUrl?address=$address&key=$googleMapsApiKey';
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  /// Checks if all required API keys are configured
  static bool get hasRequiredKeys {
    return googleVisionApiKey.isNotEmpty && googleMapsApiKey.isNotEmpty;
  }

  /// Validates configuration and throws if invalid
  static void validate() {
    if (googleVisionApiKey.isEmpty) {
      throw StateError(
        'Missing GOOGLE_VISION_API_KEY. '
        'Please configure environment variables.',
      );
    }
    if (googleMapsApiKey.isEmpty) {
      throw StateError(
        'Missing GOOGLE_MAPS_API_KEY. '
        'Please configure environment variables.',
      );
    }
  }
}
