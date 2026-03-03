import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/onboarding/presentation/flows/onboarding_studio_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('step 2 shows studio type before services and requires it', (
    tester,
  ) async {
    final user = TestData.user(tipoPerfil: AppUserType.studio, nome: 'Victor');

    await tester.pumpApp(OnboardingStudioFlow(user: user));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Victor Responsavel',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'Mube Studio');
    await tester.enterText(find.byType(TextFormField).at(2), '(11) 99999-9999');
    await tester.enterText(find.byType(TextFormField).at(3), '@mubestudio');

    await tester.ensureVisible(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Tipo de Estudio *'), findsOneWidget);
    expect(find.text('Servicos *'), findsOneWidget);

    final typeOffset = tester.getTopLeft(find.text('Tipo de Estudio *'));
    final servicesOffset = tester.getTopLeft(find.text('Servicos *'));
    expect(typeOffset.dy, lessThan(servicesOffset.dy));

    await tester.ensureVisible(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Selecione o tipo do estudio'), findsOneWidget);
  });
}
