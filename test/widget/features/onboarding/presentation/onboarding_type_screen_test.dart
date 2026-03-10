import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/onboarding/presentation/onboarding_type_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
  });

  Widget createSubject() {
    final user = TestData.user(uid: 'user-1', nome: 'New User');
    fakeAuthRepo.appUser = user;

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: const MaterialApp(home: OnboardingTypeScreen()),
    );
  }

  group('OnboardingTypeScreen', () {
    testWidgets('renders all user type options', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo ao Mube!'), findsOneWidget);
      expect(find.text('Como você quer usar a plataforma?'), findsOneWidget);
      expect(find.text('Contratante'), findsOneWidget);
      expect(find.text('Perfil Individual'), findsOneWidget);
      expect(
        find.text(
          'Cantor, instrumentista, DJ, produção musical ou técnica de palco',
        ),
        findsOneWidget,
      );
      expect(find.text('Estúdio'), findsOneWidget);
      expect(find.text('Banda'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('keeps continue button visible on small screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      final buttonRect = tester.getRect(
        find.widgetWithText(AppButton, 'Continuar'),
      );

      expect(buttonRect.top, greaterThan(0));
      expect(buttonRect.bottom, lessThanOrEqualTo(640));
    });

    testWidgets('continue button without selection shows warning', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(fakeAuthRepo.lastUpdatedUser, isNull);
    });

    testWidgets('selecting type enables continue and submits', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Perfil Individual'));
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(fakeAuthRepo.lastUpdatedUser, isNotNull);
      expect(fakeAuthRepo.lastUpdatedUser!.tipoPerfil?.id, 'profissional');
    });

    testWidgets('selecting Banda shows tutorial dialog', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banda'));
      await tester.pumpAndSettle();

      expect(find.text('Como funciona o perfil de banda'), findsOneWidget);
      expect(find.text('Crie o perfil'), findsOneWidget);
      expect(find.text('Convide integrantes'), findsOneWidget);
      expect(
        find.textContaining('quando 2 integrantes aceitarem'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Continuar como banda'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar como banda'));
      await tester.pumpAndSettle();

      expect(find.text('Como funciona o perfil de banda'), findsNothing);
    });

    testWidgets('band dialog keeps actions visible on small screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Banda'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banda'));
      await tester.pumpAndSettle();

      final continueRect = tester.getRect(find.text('Continuar como banda'));
      final cancelRect = tester.getRect(find.text('Escolher outro tipo'));

      expect(continueRect.bottom, lessThanOrEqualTo(640));
      expect(cancelRect.bottom, lessThanOrEqualTo(640));
    });

    testWidgets('canceling band tutorial restores previous selection', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Perfil Individual'));
      await tester.pump();

      await tester.tap(find.text('Banda'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Escolher outro tipo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Escolher outro tipo'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(fakeAuthRepo.lastUpdatedUser, isNotNull);
      expect(fakeAuthRepo.lastUpdatedUser!.tipoPerfil?.id, 'profissional');
    });

    testWidgets('selecting Contratante submits correct type', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Contratante'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contratante'));
      await tester.pump();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(fakeAuthRepo.lastUpdatedUser, isNotNull);
      expect(fakeAuthRepo.lastUpdatedUser!.tipoPerfil?.id, 'contratante');
    });
  });
}
