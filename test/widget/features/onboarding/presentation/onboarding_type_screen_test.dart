import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(find.text('Profissional'), findsOneWidget);
      expect(find.text('Estúdio'), findsOneWidget);
      expect(find.text('Banda'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('continue button without selection shows warning', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Scroll to make "Continuar" visible
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();

      // Tap Continue without selecting any type
      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // No user update should have occurred
      expect(fakeAuthRepo.lastUpdatedUser, isNull);
    });

    testWidgets('selecting type enables continue and submits', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tap "Profissional"
      await tester.tap(find.text('Profissional'));
      await tester.pump();

      // Scroll to make "Continuar" visible and tap
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify the controller called updateUser with the correct type
      expect(fakeAuthRepo.lastUpdatedUser, isNotNull);
      expect(fakeAuthRepo.lastUpdatedUser!.tipoPerfil?.id, 'profissional');
    });

    testWidgets('selecting Contratante submits correct type', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contratante'));
      await tester.pump();

      // Scroll to make "Continuar" visible and tap
      await tester.ensureVisible(find.text('Continuar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(fakeAuthRepo.lastUpdatedUser, isNotNull);
      expect(fakeAuthRepo.lastUpdatedUser!.tipoPerfil?.id, 'contratante');
    });
  });
}

