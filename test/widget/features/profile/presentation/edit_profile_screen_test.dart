import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';
import 'package:mube/src/design_system/foundations/tokens/app_spacing.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/profile/presentation/edit_profile_screen.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  const contractorUser = AppUser(
    uid: 'contractor-1',
    email: 'contractor@example.com',
    cadastroStatus: 'concluido',
    tipoPerfil: AppUserType.contractor,
    nome: 'Victor Levi',
    username: 'victorlevi',
    dadosContratante: <String, dynamic>{},
  );

  Finder usernameField() => find.byWidgetPredicate(
    (widget) =>
        widget is TextFormField &&
        widget.controller?.text == contractorUser.publicUsername,
  );
  Finder usernameInput() => find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.controller?.text == contractorUser.publicUsername,
  );

  AppButton saveButton(WidgetTester tester) =>
      tester.widget<AppButton>(find.byType(AppButton));

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeAuthRepository.appUser = contractorUser;
  });

  tearDown(() {
    fakeAuthRepository.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(
      const EditProfileScreen(),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(contractorUser),
        ),
        appConfigProvider.overrideWith((ref) async => const AppConfig()),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('blocks save when the typed username is already taken', (
    tester,
  ) async {
    fakeAuthRepository.publicUsernameAvailable = false;

    await pumpScreen(tester);

    await tester.enterText(usernameField(), 'mube.oficial');
    await tester.pump();

    expect(find.text('Verificando disponibilidade...'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(
      find.text('Esse @usuario ja esta em uso. Escolha outro.'),
      findsOneWidget,
    );
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('enables save after confirming the username is available', (
    tester,
  ) async {
    fakeAuthRepository.publicUsernameAvailable = true;

    await pumpScreen(tester);

    await tester.enterText(usernameField(), 'mube.oficial');
    await tester.pump();
    expect(saveButton(tester).onPressed, isNull);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('@mube.oficial disponivel.'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'shows a visible @ prefix with compact spacing in username field',
    (tester) async {
      await pumpScreen(tester);

      final field = tester.widget<TextField>(usernameInput());
      final decoration = field.decoration;

      expect(decoration?.prefixText, isNull);
      expect(decoration?.prefixIcon, isA<Padding>());
      expect(decoration?.prefixIconConstraints?.minWidth, 0);
      expect(decoration?.prefixIconConstraints?.minHeight, 0);

      final prefix = decoration!.prefixIcon! as Padding;
      expect(
        prefix.padding,
        const EdgeInsets.only(left: AppSpacing.s16, right: AppSpacing.s8),
      );
      expect((prefix.child! as Text).data, '@');
    },
  );
}
