import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/login_screen.dart';
import 'package:mube/src/features/auth/presentation/register_screen.dart';

import '../../helpers/firebase_mocks.dart';
import '../../helpers/firebase_test_config.dart';

@GenerateNiceMocks([MockSpec<AuthRemoteDataSource>()])
import 'auth_flow_test.mocks.dart';

void main() {
  setUpAll(() async => await setupFirebaseCoreMocks());

  group('Auth Flow Integration Tests', () {
    late MockAuthRemoteDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockAuthRemoteDataSource();

      // Globals stubs
      when(mockDataSource.currentUser).thenReturn(null);
      when(
        mockDataSource.authStateChanges(),
      ).thenAnswer((_) => const Stream.empty());
      when(mockDataSource.signOut()).thenAnswer((_) async {});

      // Clean start
      scaffoldMessengerKey.currentState?.clearSnackBars();
    });

    Future<void> pumpTestWidget(
      WidgetTester tester,
      Widget widget, {
      List<dynamic> overrides = const [],
      bool useGoRouter = false,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1080, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final authRepo = AuthRepository(mockDataSource);
      final allOverrides = [
        authRepositoryProvider.overrideWithValue(authRepo),
        ...overrides,
      ];

      if (useGoRouter) {
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => widget),
            GoRoute(
              path: '/register',
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: allOverrides.cast(),
            child: MaterialApp.router(
              routerConfig: router,
              theme: ThemeData.dark(),
              scaffoldMessengerKey: scaffoldMessengerKey,
            ),
          ),
        );
      } else {
        await tester.pumpWidget(
          ProviderScope(
            overrides: allOverrides.cast(),
            child: MaterialApp(
              home: widget,
              theme: ThemeData.dark(),
              scaffoldMessengerKey: scaffoldMessengerKey,
            ),
          ),
        );
      }
      await tester.pumpAndSettle();
    }

    group('Login Flow', () {
      testWidgets('should show validation errors', (tester) async {
        await pumpTestWidget(tester, const LoginScreen());
        final btnFinder = find.byKey(const Key('login_button'));
        await tester.tap(btnFinder);
        await tester.pump();

        expect(find.text('Digite seu e-mail'), findsOneWidget);
        expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      });

      testWidgets('should successfully login', (tester) async {
        when(
          mockDataSource.signInWithEmailAndPassword(any, any),
        ).thenAnswer((_) async {});
        await pumpTestWidget(tester, const LoginScreen());

        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );

        final btnFinder = find.byKey(const Key('login_button'));
        await tester.tap(btnFinder);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        verify(
          mockDataSource.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          ),
        ).called(1);
      });

      testWidgets('should show error on login failure', (tester) async {
        when(mockDataSource.signInWithEmailAndPassword(any, any)).thenThrow(
          FirebaseAuthException(code: 'user-not-found', message: 'Not found'),
        );

        await pumpTestWidget(tester, const LoginScreen());
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'err@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );

        final btnFinder = find.byKey(const Key('login_button'));

        await tester.tap(btnFinder);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        // It shows 'Ocorreu um erro inesperado' because next.error is a String (failure.message)
        expect(
          find.textContaining('Ocorreu um erro inesperado'),
          findsOneWidget,
        );
      });
    });

    group('Registration Flow', () {
      testWidgets('should successfully register', (tester) async {
        final mockUser = MockUser(uid: 'u1');
        when(
          mockDataSource.registerWithEmailAndPassword(any, any),
        ).thenAnswer((_) async => mockUser);
        when(mockDataSource.saveUserProfile(any)).thenAnswer((_) async {});

        await pumpTestWidget(tester, const RegisterScreen());

        await tester.enterText(
          find.byKey(const Key('register_email_input')),
          'ok@test.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_input')),
          'password123',
        );
        await tester.enterText(
          find.byKey(const Key('register_confirm_password_input')),
          'password123',
        );

        final btnFinder = find.byKey(const Key('register_button'));
        await tester.tap(btnFinder);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        verify(
          mockDataSource.registerWithEmailAndPassword(
            'ok@test.com',
            'password123',
          ),
        ).called(1);
      });
    });

    group('Navigation', () {
      testWidgets('should navigate between login and register', (tester) async {
        await pumpTestWidget(tester, const LoginScreen(), useGoRouter: true);

        final registerLink = find.byKey(const Key('register_link'));
        await tester.tap(registerLink);
        await tester.pumpAndSettle();
        expect(find.text('Criar Conta'), findsWidgets);

        final loginLink = find.byKey(const Key('login_link'));
        await tester.tap(loginLink);
        await tester.pumpAndSettle();
        expect(find.text('Bem-vindo de volta'), findsWidgets);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle network error', (tester) async {
        when(mockDataSource.signInWithEmailAndPassword(any, any)).thenThrow(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Net Error',
          ),
        );

        await pumpTestWidget(tester, const LoginScreen());

        // Populate fields to pass validation
        await tester.enterText(
          find.byKey(const Key('email_input')),
          'test@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );

        final btnFinder = find.byKey(const Key('login_button'));

        await tester.tap(btnFinder);
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(
          find.textContaining('Ocorreu um erro inesperado'),
          findsOneWidget,
        );
      });

      testWidgets('should trim email', (tester) async {
        when(
          mockDataSource.signInWithEmailAndPassword(any, any),
        ).thenAnswer((_) async {});

        await pumpTestWidget(tester, const LoginScreen());
        await tester.enterText(
          find.byKey(const Key('email_input')),
          '  trim@test.com  ',
        );
        await tester.enterText(
          find.byKey(const Key('password_input')),
          'password123',
        );

        final btnFinder = find.byKey(const Key('login_button'));
        await tester.ensureVisible(btnFinder);
        await tester.tap(btnFinder);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        verify(
          mockDataSource.signInWithEmailAndPassword(
            'trim@test.com',
            'password123',
          ),
        ).called(1);
      });
    });
  });
}
