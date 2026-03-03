import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/address/domain/resolved_address.dart';
import 'package:mube/src/features/onboarding/presentation/onboarding_form_provider.dart';
import 'package:mube/src/features/onboarding/presentation/steps/onboarding_address_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('selected state keeps final action out of the summary screen', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(onboardingFormProvider.notifier)
        .updateResolvedAddress(
          const ResolvedAddress(
            logradouro: 'Rua Augusta',
            numero: '1500',
            bairro: 'Consolacao',
            cidade: 'Sao Paulo',
            estado: 'SP',
            cep: '01305-100',
            lat: -23.55052,
            lng: -46.633308,
          ),
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: OnboardingAddressStep(onNext: () async {}, onBack: () {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Revise no mapa para finalizar'), findsOneWidget);
    expect(find.text('Revisar no mapa e finalizar'), findsOneWidget);
    expect(find.text('Finalizar'), findsNothing);
  });

  testWidgets(
    'confirming address succeeds when onboarding unmounts after submit',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(onboardingFormProvider.notifier)
          .updateResolvedAddress(
            const ResolvedAddress(
              logradouro: 'Rua Augusta',
              numero: '1500',
              bairro: 'Consolacao',
              cidade: 'Sao Paulo',
              estado: 'SP',
              cep: '01305-100',
              lat: -23.55052,
              lng: -46.633308,
            ),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: _UnmountOnSubmitHarness()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revisar no mapa e finalizar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar endereco'), findsOneWidget);

      await tester.tap(find.text('Finalizar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('submit-finished'), findsOneWidget);
      expect(find.text('Confirmar endereco'), findsNothing);
    },
  );
}

class _UnmountOnSubmitHarness extends StatefulWidget {
  const _UnmountOnSubmitHarness();

  @override
  State<_UnmountOnSubmitHarness> createState() =>
      _UnmountOnSubmitHarnessState();
}

class _UnmountOnSubmitHarnessState extends State<_UnmountOnSubmitHarness> {
  bool _showStep = true;

  Future<void> _handleNext() async {
    setState(() => _showStep = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _showStep
          ? OnboardingAddressStep(onNext: _handleNext, onBack: () {})
          : const Center(child: Text('submit-finished')),
    );
  }
}
