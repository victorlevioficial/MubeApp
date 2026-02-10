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
import 'package:mube/src/features/auth/presentation/email_verification_screen.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>(), MockSpec<User>()])
import 'email_verification_screen_test.mocks.dart';

void main() {
  setUpAll(() {
    provideDummy<Either<Failure, Unit>>(const Right(unit));
  });

  group('EmailVerificationScreen', () {
    late MockAuthRepository mockAuthRepository;
    late MockUser mockUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUser = MockUser();

      // Default mock behavior
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.emailVerified).thenReturn(false);
      when(mockAuthRepository.currentUser).thenReturn(mockUser);
      when(
        mockAuthRepository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(mockUser));
    });

    Widget createTestWidget() {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const EmailVerificationScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) =>
                const Scaffold(body: Text('Login Page')),
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
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Verifique seu email'), findsOneWidget);
      });

      testWidgets('mostra email do usuário', (tester) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);
        const testEmail = 'usuario@teste.com';
        when(mockUser.email).thenReturn(testEmail);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text(testEmail), findsOneWidget);
      });

      testWidgets('mostra mensagem informativa sobre verificação', (
        tester,
      ) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(
          find.text('Enviamos um link de verificação para'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Clique no link no email para verificar sua conta e continuar.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('mostra botão de reenviar email', (tester) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Reenviar email'), findsOneWidget);
      });

      testWidgets('mostra botão "Já verifiquei meu email"', (tester) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Já verifiquei meu email'), findsOneWidget);
      });

      testWidgets('mostra opção de sair e usar outra conta', (tester) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);
        when(
          mockAuthRepository.signOut(),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Sair e usar outra conta'), findsOneWidget);
      });

      testWidgets('mostra ícone de email', (tester) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.byIcon(Icons.mark_email_unread_outlined), findsOneWidget);
      });

      testWidgets('mostra seção de informação sobre spam', (tester) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Não recebeu o email?'), findsOneWidget);
        expect(
          find.textContaining('Verifique sua pasta de spam'),
          findsOneWidget,
        );
      });
    });

    group('Interações', () {
      testWidgets('botão reenviar chama controller quando pressionado', (
        tester,
      ) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);
        when(
          mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Right(unit));

        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Act
        await tester.tap(find.text('Reenviar email'));
        await tester.pump();

        // Assert
        verify(mockAuthRepository.sendEmailVerification()).called(1);
      });

      testWidgets('botão "Já verifiquei" chama checkVerificationStatus', (
        tester,
      ) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);

        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Act - scroll to find the button and tap it
        await tester.ensureVisible(find.text('Já verifiquei meu email'));
        await tester.tap(
          find.text('Já verifiquei meu email'),
          warnIfMissed: false,
        );
        await tester.pump();

        // Assert
        verify(mockAuthRepository.isEmailVerified()).called(1);
      });

      testWidgets(
        'botão sair chama signOut do repository e navega para login',
        (tester) async {
          // Arrange
          when(
            mockAuthRepository.isEmailVerified(),
          ).thenAnswer((_) async => false);
          when(
            mockAuthRepository.signOut(),
          ).thenAnswer((_) async => const Right(unit));

          await tester.pumpWidget(createTestWidget());
          // Use pump instead of pumpAndSettle due to infinite animations/timers
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Act - scroll to find the button and tap it
          await tester.ensureVisible(find.text('Sair e usar outra conta'));
          await tester.tap(
            find.text('Sair e usar outra conta'),
            warnIfMissed: false,
          );
          // Use pump instead of pumpAndSettle due to infinite animations/timers
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Assert
          verify(mockAuthRepository.signOut()).called(1);
          expect(find.text('Login Page'), findsOneWidget);
        },
      );
    });

    group('Estados', () {
      testWidgets('mostra mensagem de sucesso quando email é enviado', (
        tester,
      ) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);
        when(
          mockAuthRepository.sendEmailVerification(),
        ).thenAnswer((_) async => const Right(unit));

        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Act
        await tester.tap(find.text('Reenviar email'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Complete the async operation
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('Email reenviado com sucesso!'), findsOneWidget);
      });

      testWidgets('mostra email padrão quando usuário é null', (tester) async {
        // Arrange
        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => false);
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget());
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Assert
        expect(find.text('seu email'), findsOneWidget);
      });
    });

    group('Navegação', () {
      testWidgets('redireciona quando email é verificado', (tester) async {
        // Arrange
        final verifiedUser = MockUser();
        when(verifiedUser.email).thenReturn('test@example.com');
        when(verifiedUser.emailVerified).thenReturn(true);

        when(
          mockAuthRepository.isEmailVerified(),
        ).thenAnswer((_) async => true);
        when(
          mockAuthRepository.authStateChanges(),
        ).thenAnswer((_) => Stream.value(verifiedUser));

        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const EmailVerificationScreen(),
            ),
            GoRoute(
              path: '/onboarding',
              builder: (context, state) =>
                  const Scaffold(body: Text('Onboarding Page')),
            ),
          ],
        );

        // Act
        await tester.pumpWidget(
          ProviderScope(
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
          ),
        );
        // Use pump instead of pumpAndSettle due to infinite animations/timers
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Wait for the polling timer to fire and check verification (3 seconds)
        await tester.pump(const Duration(seconds: 3));
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - should navigate to onboarding
        expect(find.text('Onboarding Page'), findsOneWidget);
      });
    });
  });
}
