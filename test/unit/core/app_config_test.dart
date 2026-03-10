import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('should keep dart-define API keys empty when not configured', () {
      expect(AppConfig.googleVisionApiKey, isEmpty);
      expect(AppConfig.googleMapsApiKey, isEmpty);
    });

    test('effectiveGoogleMapsApiKey should stay empty when not configured', () {
      expect(AppConfig.effectiveGoogleMapsApiKey, isEmpty);
    });

    test('hasRequiredKeys should return false when vision key is empty', () {
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

      test('buildPlacesUrl should throw when maps key is empty', () {
        expect(
          () => AppConfig.buildPlacesUrl('Rua Augusta, 1500'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOOGLE_MAPS_API_KEY'),
            ),
          ),
        );
      });

      test('buildPlaceDetailsUrl should throw when maps key is empty', () {
        expect(
          () => AppConfig.buildPlaceDetailsUrl('place-id-123'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOOGLE_MAPS_API_KEY'),
            ),
          ),
        );
      });

      test('buildGeocodeUrl should throw when maps key is empty', () {
        expect(
          () => AppConfig.buildGeocodeUrl('Av Paulista, 1000'),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('GOOGLE_MAPS_API_KEY'),
            ),
          ),
        );
      });

      test('buildReverseGeocodeUrl should throw when maps key is empty', () {
        expect(
          () => AppConfig.buildReverseGeocodeUrl(-23.55, -46.63),
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
