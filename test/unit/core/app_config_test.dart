import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('should have empty API keys when not configured', () {
      // When running without dart-define, keys should be empty
      expect(AppConfig.googleVisionApiKey, isEmpty);
      expect(AppConfig.googleMapsApiKey, isEmpty);
    });

    test('hasRequiredKeys should return false when keys are empty', () {
      expect(AppConfig.hasRequiredKeys, isFalse);
    });

    test('validate should throw when API keys are not set', () {
      expect(
        () => AppConfig.validate(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('GOOGLE_VISION_API_KEY'),
          ),
        ),
      );
    });

    group('URL Builders', () {
      test('visionApiUrl should throw when key is empty', () {
        expect(
          () => AppConfig.visionApiUrl,
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOOGLE_VISION_API_KEY'),
            ),
          ),
        );
      });

      test('buildPlacesUrl should throw when key is empty', () {
        expect(
          () => AppConfig.buildPlacesUrl('query'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOOGLE_MAPS_API_KEY'),
            ),
          ),
        );
      });

      test('buildPlaceDetailsUrl should throw when key is empty', () {
        expect(
          () => AppConfig.buildPlaceDetailsUrl('placeId'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOOGLE_MAPS_API_KEY'),
            ),
          ),
        );
      });

      test('buildGeocodeUrl should throw when key is empty', () {
        expect(
          () => AppConfig.buildGeocodeUrl('address'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOOGLE_MAPS_API_KEY'),
            ),
          ),
        );
      });
    });
  });
}
