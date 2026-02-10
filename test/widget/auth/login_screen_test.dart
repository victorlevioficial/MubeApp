import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/l10n/generated/app_localizations.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/login_screen.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>(), MockSpec<User>()])
import 'login_screen_test.mocks.dart';

void main() {
  setUpAll(() {
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('LoginScreen', () {
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();

      // Default mock behavior
      when(mockAuthRepository.currentUser).thenReturn(null);
      when(
        mockAuthRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(null));
    });

    Widget createTestWidget() {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('Home Page')),
          ),
          GoRoute(
            path: '/forgot-password',
            builder: (context, state) =>
                const Scaffold(body: Text('Forgot Password Page')),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) =>
                const Scaffold(body: Text('Register Page')),
          ),
        ],
      );

      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt'), Locale('en')],
          locale: const Locale('pt'),
          routerConfig: router,
          theme: ThemeData.dark(),
        ),
      );
    }

    group('Renderização', () {
      testWidgets('renderiza tela com título correto', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Bem-vindo de volta'), findsOneWidget);
      });

      testWidgets('mostra subtítulo correto', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Entre para gerenciar sua carreira musical'),
          findsOneWidget,
        );
      });

      testWidgets('mostra campo de email', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('E-mail'), findsOneWidget);
        expect(find.byKey(const Key('email_input')), findsOneWidget);
      });

      testWidgets('mostra campo de senha', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Senha'), findsOneWidget);
        expect(find.byKey(const Key('password_input')), findsOneWidget);
      });

      testWidgets('mostra botão de login', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(const Key('login_button')), findsOneWidget);
        expect(find.text('Entrar'), findsOneWidget);
      });

      testWidgets('mostra botão de login com Google', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(const Key('google_login_button')), findsOneWidget);
      });

      testWidgets('mostra botão de login com Apple', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byKey(const Key('apple_login_button')), findsOneWidget);
      });

      testWidgets('mostra link "Esqueceu a senha?"', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Esqueceu a senha?'), findsOneWidget);
      });

      testWidgets('mostra link "Criar conta"', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Não tem uma conta? '), findsOneWidget);
        expect(find.text('Crie agora'), findsOneWidget);
      });

      testWidgets('mostra divisor "Ou entre com"', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Ou entre com'), findsOneWidget);
      });
    });

    group('Validação', () {
      testWidgets('valida email inválido', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter invalid email
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'invalid-email',
        );
        await tester.pump();

        // Tap login button
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert - validation error should appear
        expect(find.text('E-mail inválido'), findsOneWidget);
      });

      testWidgets('valida senha vazia', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid email but no password
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.pump();

        // Tap login button
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert - validation error should appear
        expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      });

      testWidgets('valida senha com menos de 6 caracteres', (tester) async {
        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid email but short password
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.enterText(find.byKey(const Key('password_input')), '123');
        await tester.pump();

        // Tap login button
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert - validation error should appear
        expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      });
    });

    group('Interações', () {
      testWidgets('botão de login chama controller quando pressionado', (
        tester,
      ) async {
        // Arrange
        when(
          mockAuthRepository.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          ),
        ).thenAnswer((_) async => const Right(unit));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid credentials
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );
        await tester.pump();

        // Act
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert
        verify(
          mockAuthRepository.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          ),
        ).called(1);
      });

      testWidgets('link "Esqueceu a senha?" navega para tela correta', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.text('Esqueceu a senha?'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Forgot Password Page'), findsOneWidget);
      });

      testWidgets('link "Crie agora" navega para tela de registro', (
        tester,
      ) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act - scroll to ensure the link is visible
        await tester.ensureVisible(find.text('Crie agora'));
        await tester.tap(find.text('Crie agora'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Register Page'), findsOneWidget);
      });

      testWidgets('botão Google dispara login social', (tester) async {
        // Arrange
        when(
          mockAuthRepository.signInWithGoogle(),
        ).thenAnswer((_) async => const Right(unit));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.ensureVisible(
          find.byKey(const Key('google_login_button')),
        );
        await tester.tap(find.byKey(const Key('google_login_button')));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthRepository.signInWithGoogle()).called(1);
      });

      testWidgets('botão Apple dispara login social', (tester) async {
        // Arrange
        when(
          mockAuthRepository.signInWithApple(),
        ).thenAnswer((_) async => const Right(unit));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act
        await tester.ensureVisible(find.byKey(const Key('apple_login_button')));
        await tester.tap(find.byKey(const Key('apple_login_button')));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAuthRepository.signInWithApple()).called(1);
      });
    });

    group('Estados', () {
      testWidgets('mostra loading quando estado é loading', (tester) async {
        // Arrange
        final completer = Completer<Either<Failure, Unit>>();
        when(
          mockAuthRepository.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          ),
        ).thenAnswer((_) => completer.future);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid credentials
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );
        await tester.pump();

        // Act
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pump();

        // Assert - should show loading indicator (CircularProgressIndicator inside button)
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Cleanup - complete the future to avoid pending timer
        completer.complete(const Right(unit));
        await tester.pumpAndSettle();
      });

      testWidgets('mostra mensagem de erro quando login falha', (tester) async {
        // Arrange
        when(
          mockAuthRepository.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          ),
        ).thenAnswer(
          (_) async =>
              const Left(AuthFailure(message: 'Credenciais inválidas')),
        );

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter valid credentials
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );
        await tester.pump();

        // Act
        await tester.tap(find.byKey(const Key('login_button')));
        await tester.pumpAndSettle();

        // Assert - error should be shown in snackbar (the handler converts to a generic message)
        expect(
          find.text('Ocorreu um erro inesperado. Tente novamente.'),
          findsOneWidget,
        );
      });

      testWidgets(
        'controller atualiza estado para sucesso quando login é bem-sucedido',
        (tester) async {
          // Arrange
          when(
            mockAuthRepository.signInWithEmailAndPassword(
              'test@example.com',
              'password123',
            ),
          ).thenAnswer((_) async => const Right(unit));

          await tester.pumpWidget(createTestWidget());
          await tester.pumpAndSettle();

          // Enter valid credentials
          await tester.enterText(
            find.byKey(const Key('email_input')),
            'test@example.com',
          );
          await tester.enterText(
            find.byKey(const Key('password_input')),
            'password123',
          );
          await tester.pump();

          // Act
          await tester.tap(find.byKey(const Key('login_button')));
          await tester.pumpAndSettle();

          // Assert - verify that the repository was called (success state means login worked)
          verify(
            mockAuthRepository.signInWithEmailAndPassword(
              'test@example.com',
              'password123',
            ),
          ).called(1);

          // The login screen doesn't navigate automatically - the auth guard/router handles that
          // So we just verify the login was successful by checking no error is shown
          expect(
            find.text('Ocorreu um erro inesperado. Tente novamente.'),
            findsNothing,
          );
        },
      );
    });
  });
}
