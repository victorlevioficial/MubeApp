import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('should keep dart-define API keys empty when not configured', () {
      expect(AppConfig.googleVisionApiKey, isEmpty);
      expect(AppConfig.googleMapsApiKey, isEmpty);
    });

    test('effectiveGoogleMapsApiKey should fallback to Firebase key', () {
      expect(AppConfig.effectiveGoogleMapsApiKey, isNotEmpty);
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

      test('buildPlacesUrl should use effective maps key', () {
        final uri = Uri.parse(AppConfig.buildPlacesUrl('Rua Augusta, 1500'));

        expect(uri.host, 'maps.googleapis.com');
        expect(uri.queryParameters['input'], 'Rua Augusta, 1500');
        expect(uri.queryParameters['components'], 'country:br');
        expect(uri.queryParameters['language'], 'pt-BR');
        expect(uri.queryParameters['types'], 'address');
        expect(uri.queryParameters['key'], AppConfig.effectiveGoogleMapsApiKey);
      });

      test('buildPlaceDetailsUrl should use effective maps key', () {
        final uri = Uri.parse(AppConfig.buildPlaceDetailsUrl('place-id-123'));

        expect(uri.host, 'maps.googleapis.com');
        expect(uri.queryParameters['place_id'], 'place-id-123');
        expect(
          uri.queryParameters['fields'],
          'address_component,formatted_address,geometry,name',
        );
        expect(uri.queryParameters['language'], 'pt-BR');
        expect(uri.queryParameters['key'], AppConfig.effectiveGoogleMapsApiKey);
      });

      test('buildGeocodeUrl should use effective maps key', () {
        final uri = Uri.parse(AppConfig.buildGeocodeUrl('Av Paulista, 1000'));

        expect(uri.host, 'maps.googleapis.com');
        expect(uri.queryParameters['address'], 'Av Paulista, 1000');
        expect(uri.queryParameters['language'], 'pt-BR');
        expect(uri.queryParameters['region'], 'BR');
        expect(uri.queryParameters['key'], AppConfig.effectiveGoogleMapsApiKey);
      });

      test('buildReverseGeocodeUrl should use effective maps key', () {
        final uri = Uri.parse(AppConfig.buildReverseGeocodeUrl(-23.55, -46.63));

        expect(uri.host, 'maps.googleapis.com');
        expect(uri.queryParameters['latlng'], '-23.55,-46.63');
        expect(uri.queryParameters['language'], 'pt-BR');
        expect(uri.queryParameters['region'], 'BR');
        expect(uri.queryParameters['key'], AppConfig.effectiveGoogleMapsApiKey);
      });
    });
  });
}
