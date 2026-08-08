import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';
import 'package:mube/src/design_system/components/buttons/app_social_button.dart';
import 'package:mube/src/design_system/components/chips/app_chip.dart';
import 'package:mube/src/design_system/components/inputs/app_checkbox.dart';
import 'package:mube/src/design_system/components/inputs/app_dropdown_field.dart';
import 'package:mube/src/design_system/components/inputs/app_text_field.dart';
import 'package:mube/src/design_system/components/patterns/full_width_selection_card.dart';
import 'package:mube/src/design_system/components/patterns/onboarding_header.dart';
import 'package:mube/src/design_system/components/patterns/or_divider.dart';

/// Shared components are where layout bugs multiply: one unprotected Row shows
/// up on every screen that uses it. This renders each of them with realistic
/// long Portuguese copy, on the narrowest phone width, at the largest
/// accessibility font scale, and fails on any overflow.
void main() {
  const narrowWidth = 320.0;
  const textScales = <double>[1.0, 1.3, 1.6];

  const longLabel = 'Produção musical, mixagem e masterização completa';

  Future<List<String>> renderAndCollectOverflows(
    WidgetTester tester,
    Widget child, {
    required double textScale,
    double width = narrowWidth,
  }) async {
    final overflows = <String>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exception.toString();
      if (message.contains('overflowed')) {
        overflows.add(message.split('\n').first);
      } else {
        previousOnError?.call(details);
      }
    };

    try {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Center(
                child: SizedBox(width: width, child: child),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    } finally {
      FlutterError.onError = previousOnError;
    }

    return overflows;
  }

  final components = <String, Widget Function()>{
    'AppButton.primary': () =>
        AppButton.primary(text: longLabel, onPressed: () {}),
    'AppButton.outline': () =>
        AppButton.outline(text: longLabel, onPressed: () {}),
    'AppButton with loading': () =>
        AppButton.primary(text: longLabel, onPressed: () {}, isLoading: true),
    'SocialLoginButton.google': () =>
        SocialLoginButton(type: SocialType.google, onPressed: () {}),
    'SocialLoginButton.apple': () =>
        SocialLoginButton(type: SocialType.apple, onPressed: () {}),
    'OrDivider': () => const OrDivider(text: 'Ou cadastre-se com'),
    'AppChip.skill': () => const AppChip(label: longLabel),
    'AppChip.genre': () => const AppChip.genre(label: longLabel),
    'AppChip.filter': () =>
        const AppChip.filter(label: longLabel, isSelected: true),
    'AppCheckbox': () =>
        AppCheckbox(label: longLabel, value: true, onChanged: (_) {}),
    'FullWidthSelectionCard': () => FullWidthSelectionCard(
      icon: Icons.music_note,
      title: longLabel,
      description: 'Cantor, instrumentista, DJ, produção, audiovisual e mais',
      isSelected: true,
      onTap: () {},
    ),
    'OnboardingHeader': () =>
        OnboardingHeader(currentStep: 2, totalSteps: 4, onBack: () {}),
    'AppTextField': () => const AppTextField(
      label: 'Nome artístico usado nas suas publicações',
      hint: 'Digite o nome pelo qual você é conhecido no meio musical',
      prefixIcon: Icon(Icons.person_outline),
    ),
    'AppTextField with counter': () => const AppTextField(
      label: 'Bio',
      hint: 'Conte um pouco sobre a sua trajetória',
      maxLength: 500,
      maxLines: 4,
    ),
    'AppDropdownField': () => AppDropdownField<String>(
      label: 'Selecione o tipo de estúdio que você administra',
      items: const [
        DropdownMenuItem(
          value: 'a',
          child: Text('Estúdio de gravação completo'),
        ),
        DropdownMenuItem(value: 'b', child: Text('Home studio para produção')),
      ],
      onChanged: (_) {},
    ),
  };

  for (final entry in components.entries) {
    group(entry.key, () {
      for (final textScale in textScales) {
        testWidgets('fits ${narrowWidth.toInt()}px at text scale $textScale', (
          tester,
        ) async {
          final overflows = await renderAndCollectOverflows(
            tester,
            entry.value(),
            textScale: textScale,
          );

          expect(
            overflows,
            isEmpty,
            reason: '${entry.key} overflows at scale $textScale: $overflows',
          );
        });
      }
    });
  }
}
