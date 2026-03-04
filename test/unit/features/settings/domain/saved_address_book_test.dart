import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/address/domain/resolved_address.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/settings/domain/saved_address.dart';
import 'package:mube/src/features/settings/domain/saved_address_book.dart';

void main() {
  group('SavedAddressBook', () {
    SavedAddress address(
      String id, {
      bool isPrimary = false,
      String street = 'Rua Augusta',
      String number = '1500',
    }) {
      return SavedAddress(
        id: id,
        logradouro: street,
        numero: number,
        bairro: 'Consolacao',
        cidade: 'Sao Paulo',
        estado: 'SP',
        cep: '01310-100',
        lat: -23.56,
        lng: -46.65,
        isPrimary: isPrimary,
      );
    }

    test('addAsPrimary demotes previous addresses and promotes new one', () {
      final existing = [address('addr-1', isPrimary: true), address('addr-2')];
      final newAddress = const ResolvedAddress(
        logradouro: 'Av Paulista',
        numero: '1000',
        bairro: 'Bela Vista',
        cidade: 'Sao Paulo',
        estado: 'SP',
        cep: '01311-100',
        lat: -23.57,
        lng: -46.66,
      ).toSavedAddress(id: 'addr-3');

      final updated = SavedAddressBook.addAsPrimary(existing, newAddress);

      expect(updated.first.id, 'addr-3');
      expect(updated.first.isPrimary, isTrue);
      expect(updated.where((item) => item.isPrimary).length, 1);
    });

    test('delete promotes the next address when primary is removed', () {
      final existing = [address('addr-1', isPrimary: true), address('addr-2')];

      final updated = SavedAddressBook.delete(existing, existing.first);

      expect(updated, hasLength(1));
      expect(updated.first.id, 'addr-2');
      expect(updated.first.isPrimary, isTrue);
    });

    test('delete throws when trying to remove the last address', () {
      final existing = [address('addr-1', isPrimary: true)];

      expect(
        () => SavedAddressBook.delete(existing, existing.first),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Pelo menos 1 endereço deve permanecer salvo.',
          ),
        ),
      );
    });

    test('syncUser updates legacy location from primary address', () {
      const user = AppUser(uid: 'user-1', email: 'test@example.com');
      final addresses = [address('addr-1', isPrimary: true), address('addr-2')];

      final updatedUser = SavedAddressBook.syncUser(user, addresses);

      expect(updatedUser.addresses.first.id, 'addr-1');
      expect(updatedUser.location?['logradouro'], 'Rua Augusta');
      expect(updatedUser.location?['lat'], -23.56);
      expect(updatedUser.location?['lng'], -46.65);
    });

    test('effectiveAddresses migrates legacy location when list is empty', () {
      const user = AppUser(
        uid: 'user-1',
        email: 'test@example.com',
        location: {
          'logradouro': 'Rua Augusta',
          'numero': '1500',
          'bairro': 'Consolacao',
          'cidade': 'Sao Paulo',
          'estado': 'SP',
          'lat': -23.56,
          'lng': -46.65,
        },
      );

      final addresses = SavedAddressBook.effectiveAddresses(user);

      expect(addresses, hasLength(1));
      expect(addresses.first.isPrimary, isTrue);
      expect(addresses.first.logradouro, 'Rua Augusta');
    });
  });
}
