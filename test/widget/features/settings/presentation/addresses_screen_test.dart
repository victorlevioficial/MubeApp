import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/l10n/generated/app_localizations.dart';

import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/settings/domain/saved_address.dart';
import 'package:mube/src/features/settings/domain/saved_address_book.dart';
import 'package:mube/src/features/settings/presentation/addresses_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  SavedAddress address({
    required String id,
    required String nome,
    required bool isPrimary,
  }) {
    return SavedAddress(
      id: id,
      nome: nome,
      logradouro: 'Rua $nome',
      numero: '100',
      bairro: 'Centro',
      cidade: 'Sao Paulo',
      estado: 'SP',
      cep: '01000-000',
      lat: -23.5505,
      lng: -46.6333,
      isPrimary: isPrimary,
    );
  }

  Widget createSubject({required List<SavedAddress> addresses}) {
    final user = TestData.user(
      uid: 'user-1',
    ).copyWith(addresses: addresses, location: null);

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: const MaterialApp(
        locale: Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AddressesScreen(),
      ),
    );
  }

  group('AddressesScreen', () {
    testWidgets('renders overview and saved address cards', (tester) async {
      await tester.pumpWidget(
        createSubject(
          addresses: [
            address(id: 'addr-1', nome: 'Casa', isPrimary: true),
            address(id: 'addr-2', nome: 'Estudio', isPrimary: false),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gerenciar endereços'), findsOneWidget);
      expect(find.text('2 de 5 endereços salvos'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Estudio'), findsOneWidget);
      expect(find.text('Endereço principal'), findsOneWidget);
      expect(find.text('Usar minha localização atual'), findsOneWidget);
    });

    testWidgets('renders empty state when user has no saved addresses', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(addresses: const []));
      await tester.pumpAndSettle();

      expect(find.text('Nenhum endereço salvo'), findsOneWidget);
      expect(find.text('Adicionar primeiro endereço'), findsOneWidget);
    });

    testWidgets('disables add button when max number of addresses is reached', (
      tester,
    ) async {
      final addresses = List.generate(
        SavedAddressBook.maxAddresses,
        (index) => address(
          id: 'addr-$index',
          nome: 'Endereco $index',
          isPrimary: index == 0,
        ),
      );

      await tester.pumpWidget(createSubject(addresses: addresses));
      await tester.pumpAndSettle();

      const label = 'Limite de ${SavedAddressBook.maxAddresses} endereços';
      expect(find.text(label), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, label),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('does not allow deleting the last saved address', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          addresses: [address(id: 'addr-1', nome: 'Casa', isPrimary: true)],
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byIcon(Icons.delete_outline_rounded));
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Excluir endereco?'), findsNothing);
    });
  });
}
