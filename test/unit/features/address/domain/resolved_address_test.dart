import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/address/domain/resolved_address.dart';

void main() {
  group('ResolvedAddress', () {
    test('toSavedAddress maps all core fields', () {
      const address = ResolvedAddress(
        logradouro: 'Rua Augusta',
        numero: '1500',
        bairro: 'Consolacao',
        cidade: 'Sao Paulo',
        estado: 'SP',
        cep: '01310-100',
        lat: -23.561,
        lng: -46.655,
      );

      final saved = address.toSavedAddress(
        id: 'addr-1',
        nome: 'Casa',
        isPrimary: true,
      );

      expect(saved.id, 'addr-1');
      expect(saved.nome, 'Casa');
      expect(saved.logradouro, 'Rua Augusta');
      expect(saved.numero, '1500');
      expect(saved.bairro, 'Consolacao');
      expect(saved.cidade, 'Sao Paulo');
      expect(saved.estado, 'SP');
      expect(saved.cep, '01310-100');
      expect(saved.lat, -23.561);
      expect(saved.lng, -46.655);
      expect(saved.isPrimary, isTrue);
    });

    test('fromSavedAddress preserves address data', () {
      const source = ResolvedAddress(
        logradouro: 'Av Paulista',
        numero: '1000',
        bairro: 'Bela Vista',
        cidade: 'Sao Paulo',
        estado: 'SP',
        cep: '01310-100',
        lat: -23.56,
        lng: -46.65,
      );

      final roundTrip = ResolvedAddress.fromSavedAddress(
        source.toSavedAddress(id: 'addr-2'),
      );

      expect(roundTrip, source);
    });

    test('canConfirm requires number, coordinates, city and state', () {
      const valid = ResolvedAddress(
        logradouro: 'Rua Augusta',
        numero: '1500',
        bairro: 'Consolacao',
        cidade: 'Sao Paulo',
        estado: 'SP',
        cep: '',
        lat: -23.56,
        lng: -46.65,
      );

      expect(valid.canConfirm, isTrue);

      final missingNumber = valid.copyWith(numero: '');
      expect(missingNumber.canConfirm, isFalse);
      expect(missingNumber.confirmBlockingReason, contains('numero'));

      final missingCoords = valid.copyWith(clearLat: true, clearLng: true);
      expect(missingCoords.canConfirm, isFalse);
      expect(missingCoords.confirmBlockingReason, contains('coordenadas'));
    });
  });
}
