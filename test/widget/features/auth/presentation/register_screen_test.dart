import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/register_controller.dart';
import 'package:mube/src/features/auth/presentation/register_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
  });

  Widget createSubject() {
    final user = TestData.user(uid: 'user-1');
    fakeAuthRepo.appUser = user;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Screen')),
        ),
        GoRoute(
          path: '/legal/termsOfUse',
          builder: (context, state) => const Scaffold(body: Text('Terms Screen')),
        ),
        GoRoute(
          path: '/legal/privacyPolicy',
          builder: (context, state) =>
              const Scaffold(body: Text('Privacy Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('RegisterScreen', () {
    testWidgets('renders correctly with all fields', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Criar Conta'), findsOneWidget);
      expect(find.text('Entre para a comunidade da música'), findsOneWidget);
      expect(find.byKey(const Key('register_email_input')), findsOneWidget);
      expect(find.byKey(const Key('register_password_input')), findsOneWidget);
      expect(find.byKey(const Key('register_confirm_password_input')),
          findsOneWidget);
      expect(find.byKey(const Key('register_button')), findsOneWidget);
    });

    testWidgets('renders social login buttons', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('google_register_button')), findsOneWidget);
      expect(find.byKey(const Key('apple_register_button')), findsOneWidget);
    });

    testWidgets('renders login link', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.text('Já tem uma conta? '), findsOneWidget);
      expect(find.byKey(const Key('login_link')), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('renders legal links', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Termos de Uso'), findsOneWidget);
      expect(find.textContaining('Política de Privacidade'), findsOneWidget);
    });

    testWidgets('shows validation error for empty email', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Tap register button without entering email
      await tester.ensureVisible(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      // Form validation should prevent submission
      expect(fakeAuthRepo.lastUpdatedUser, isNull);
    });

    testWidgets('shows validation error for short password', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(
          find.byKey(const Key('register_email_input')), 'test@example.com');
      await tester.pump();

      // Enter short password
      await tester.enterText(
          find.byKey(const Key('register_password_input')), '123');
      await tester.pump();

      // Enter confirm password
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_input')), '123');
      await tester.pump();

      // Tap register
      await tester.ensureVisible(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      // Form validation should prevent submission
      expect(fakeAuthRepo.lastUpdatedUser, isNull);
    });

    testWidgets('shows validation error for password mismatch', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Enter email
      await tester.enterText(
          find.byKey(const Key('register_email_input')), 'test@example.com');
      await tester.pump();

      // Enter password
      await tester.enterText(
          find.byKey(const Key('register_password_input')), 'password123');
      await tester.pump();

      // Enter different confirm password
      await tester.enterText(
          find.byKey(const Key('register_confirm_password_input')), 'password456');
      await tester.pump();

      // Tap register
      await tester.ensureVisible(find.byKey(const Key('register_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('register_button')));
      await tester.pump();

      // Form validation should prevent submission
      expect(fakeAuthRepo.lastUpdatedUser, isNull);
    });

    testWidgets('navigates to login when login link tapped', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      // Scroll para garantir que o link está visível
      await tester.ensureVisible(find.byKey(const Key('login_link')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_link')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Login Screen'), findsOneWidget);
    });
  });
}
