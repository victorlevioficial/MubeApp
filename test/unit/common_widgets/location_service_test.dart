import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/common_widgets/location_service.dart';
import 'package:mube/src/features/address/domain/address_search_result.dart';

void main() {
  group('LocationService helpers', () {
    test(
      'dedupeSearchResults removes duplicates by place id and main text',
      () {
        final results = [
          const AddressSearchResult(
            placeId: '1',
            description: 'Rua Augusta, 1500, Sao Paulo',
            mainText: 'Rua Augusta, 1500',
            secondaryText: 'Sao Paulo - SP',
          ),
          const AddressSearchResult(
            placeId: '1',
            description: 'Rua Augusta, 1500, Sao Paulo',
            mainText: 'Rua Augusta, 1500',
            secondaryText: 'Sao Paulo - SP',
          ),
          const AddressSearchResult(
            placeId: '2',
            description: 'Rua Augústa, 1500, Sao Paulo',
            mainText: 'Rua Augústa, 1500',
            secondaryText: 'Sao Paulo - SP',
          ),
          const AddressSearchResult(
            placeId: '3',
            description: 'Av Paulista, 1000, Sao Paulo',
            mainText: 'Av Paulista, 1000',
            secondaryText: 'Sao Paulo - SP',
          ),
        ];

        final deduped = LocationService.dedupeSearchResults(results);

        expect(deduped, hasLength(2));
        expect(deduped.first.placeId, '1');
        expect(deduped.last.placeId, '3');
      },
    );

    test(
      'extractHouseNumberFromText returns the first house number-like token',
      () {
        expect(
          LocationService.extractHouseNumberFromText(
            'Rua Augusta, 1500, Sao Paulo',
          ),
          '1500',
        );
        expect(
          LocationService.extractHouseNumberFromText('Av Paulista, s/n'),
          isEmpty,
        );
      },
    );

    test('describeGoogleApiError maps authorization failures', () {
      final message = LocationService.describeGoogleApiError(
        fallback: 'Erro ao buscar endereços.',
        data: const {
          'status': 'REQUEST_DENIED',
          'error_message':
              'This IP, site or mobile application is not authorized to use this API key. Request received from IP address 186.205.4.141, with empty referer',
        },
      );

      expect(
        message,
        'Não foi possível buscar endereço agora. Tente novamente em instantes.',
      );
    });
  });
}
