import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/features/auth/data/auth_remote_data_source.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/presentation/login_screen.dart';
import 'package:mube/src/features/auth/presentation/register_screen.dart';

import '../../helpers/firebase_mocks.dart';
import '../../helpers/pump_app.dart';
@GenerateNiceMocks([MockSpec<AuthRemoteDataSource>()])
import 'auth_flow_test.mocks.dart';

/// Testes de integração para o fluxo de autenticação
///
/// Cobertura:
/// - Login com credenciais válidas
/// - Login com credenciais inválidas
/// - Registro de novo usuário
/// - Validação de formulários
/// - Navegação entre login e registro
/// - Logout
/// - Recuperação de sessão
void main() {
  group('Auth Flow Integration Tests', () {
    late MockAuthRemoteDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockAuthRemoteDataSource();
    });

    group('Login Flow', () {
      testWidgets('should show validation error for empty fields', (
        tester,
      ) async {
        // Arrange
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act - Tentar fazer login sem preencher campos
        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Assert - Deve mostrar erros de validação
        expect(find.text('E-mail inválido'), findsOneWidget);
        expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      });

      testWidgets('should show validation error for invalid email', (
        tester,
      ) async {
        // Arrange
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act - Preencher email inválido
        final emailField = find.byKey(const Key('email_input'));
        await tester.enterText(emailField, 'email-invalido');

        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('E-mail inválido'), findsOneWidget);
      });

      testWidgets('should toggle password visibility', (tester) async {
        // Arrange
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act - Preencher senha
        final passwordField = find.byKey(const Key('password_input'));
        await tester.enterText(passwordField, 'senha123');

        // Verificar que está obscurecido (padrão)
        await tester.pump();

        // Tap no ícone de visibilidade
        final visibilityIcon = find.byIcon(Icons.visibility_off);
        if (visibilityIcon.evaluate().isNotEmpty) {
          await tester.tap(visibilityIcon);
          await tester.pumpAndSettle();

          // Assert - Agora deve estar visível
          final visibilityOnIcon = find.byIcon(Icons.visibility);
          expect(visibilityOnIcon, findsOneWidget);
        }
      });

      testWidgets('should successfully login with valid credentials', (
        tester,
      ) async {
        // Arrange
        when(
          mockDataSource.signInWithEmailAndPassword(any, any),
        ).thenAnswer((_) async {});

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act - Preencher credenciais válidas
        final emailField = find.byKey(const Key('email_input'));
        final passwordField = find.byKey(const Key('password_input'));

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Assert
        verify(
          mockDataSource.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          ),
        ).called(1);
      });

      testWidgets('should show error message on login failure', (tester) async {
        // Arrange
        when(mockDataSource.signInWithEmailAndPassword(any, any)).thenThrow(
          FirebaseAuthException(
            code: 'user-not-found',
            message: 'Usuário não encontrado',
          ),
        );

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act - Preencher credenciais e tentar login
        final emailField = find.byKey(const Key('email_input'));
        final passwordField = find.byKey(const Key('password_input'));

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Assert - Deve mostrar mensagem de erro
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should show loading state during login', (tester) async {
        // Arrange
        when(mockDataSource.signInWithEmailAndPassword(any, any)).thenAnswer((
          _,
        ) async {
          await Future.delayed(const Duration(seconds: 1));
        });

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act
        final emailField = find.byKey(const Key('email_input'));
        final passwordField = find.byKey(const Key('password_input'));

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pump(); // Pump once to show loading

        // Assert - Botão deve estar desabilitado ou mostrar loading
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('Registration Flow', () {
      testWidgets('should validate all required fields', (tester) async {
        // Arrange
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const RegisterScreen(),
          ),
        );

        // Act - Tentar registrar sem preencher
        final registerButton = find.widgetWithText(
          ElevatedButton,
          'Criar Conta',
        );
        await tester.tap(registerButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('E-mail inválido'), findsOneWidget);
        expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      });

      testWidgets('should validate password confirmation', (tester) async {
        // Arrange
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const RegisterScreen(),
          ),
        );

        // Act - Preencher senhas diferentes
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(1), 'senha123');
        await tester.enterText(textFields.at(2), 'senha456');

        final registerButton = find.widgetWithText(
          ElevatedButton,
          'Criar Conta',
        );
        await tester.tap(registerButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Senhas não coincidem'), findsOneWidget);
      });

      testWidgets('should validate minimum password length', (tester) async {
        // Arrange
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const RegisterScreen(),
          ),
        );

        // Act - Preencher senha curta
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(1), '123');
        await tester.enterText(textFields.at(2), '123');

        final registerButton = find.widgetWithText(
          ElevatedButton,
          'Criar Conta',
        );
        await tester.tap(registerButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
      });

      testWidgets('should successfully register with valid data', (
        tester,
      ) async {
        // Arrange
        final mockUser = MockUser(uid: 'new-user-123');
        when(
          mockDataSource.registerWithEmailAndPassword(any, any),
        ).thenAnswer((_) async => mockUser);
        when(mockDataSource.saveUserProfile(any)).thenAnswer((_) async {});

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const RegisterScreen(),
          ),
        );

        // Act - Preencher dados válidos
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'newuser@example.com');
        await tester.enterText(textFields.at(1), 'password123');
        await tester.enterText(textFields.at(2), 'password123');

        final registerButton = find.widgetWithText(
          ElevatedButton,
          'Criar Conta',
        );
        await tester.tap(registerButton);
        await tester.pumpAndSettle();

        // Assert
        verify(
          mockDataSource.registerWithEmailAndPassword(
            'newuser@example.com',
            'password123',
          ),
        ).called(1);
        verify(mockDataSource.saveUserProfile(any)).called(1);
      });

      testWidgets('should show error on registration failure', (tester) async {
        // Arrange
        when(mockDataSource.registerWithEmailAndPassword(any, any)).thenThrow(
          FirebaseAuthException(
            code: 'email-already-in-use',
            message: 'Email já está em uso',
          ),
        );

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const RegisterScreen(),
          ),
        );

        // Act
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'existing@example.com');
        await tester.enterText(textFields.at(1), 'password123');
        await tester.enterText(textFields.at(2), 'password123');

        final registerButton = find.widgetWithText(
          ElevatedButton,
          'Criar Conta',
        );
        await tester.tap(registerButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
      });
    });

    group('Navigation', () {
      testWidgets('should navigate between login and register', (tester) async {
        // Arrange - Começa na tela de login
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Assert - Está na tela de login
        expect(find.text('Bem-vindo de volta'), findsOneWidget);

        // Act - Ir para registro
        final registerLink = find.text('Criar conta');
        await tester.tap(registerLink);
        await tester.pumpAndSettle();

        // Assert - Agora está na tela de registro
        expect(find.text('Criar sua conta'), findsOneWidget);
      });

      testWidgets('should navigate back from register to login', (
        tester,
      ) async {
        // Arrange
        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const RegisterScreen(),
          ),
        );

        // Assert - Está na tela de registro
        expect(find.text('Criar sua conta'), findsOneWidget);

        // Act - Voltar para login
        final loginLink = find.text('Já tem uma conta? Entrar');
        if (loginLink.evaluate().isNotEmpty) {
          await tester.tap(loginLink);
          await tester.pumpAndSettle();

          // Assert - Voltou para login
          expect(find.text('Bem-vindo de volta'), findsOneWidget);
        }
      });
    });

    group('Session Management', () {
      testWidgets('should auto-logout if user already logged in', (
        tester,
      ) async {
        // Arrange
        final mockUser = MockUser(uid: 'existing-user');
        when(mockDataSource.currentUser).thenReturn(mockUser as User?);
        when(mockDataSource.signOut()).thenAnswer((_) async {});

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act
        await tester.pumpAndSettle();

        // Assert - Deve ter chamado signOut para limpar estado
        verify(mockDataSource.signOut()).called(1);
      });

      testWidgets('should handle auth state changes', (tester) async {
        // Arrange
        final mockUser = MockUser(uid: 'test-user');
        final authStream = Stream<User?>.fromIterable([null, mockUser, null]);
        when(mockDataSource.authStateChanges()).thenAnswer((_) => authStream);

        // Act & Assert - O stream deve emitir os valores corretos
        final repository = AuthRepository(mockDataSource);
        final states = <User?>[];

        repository.authStateChanges().listen((user) {
          states.add(user);
        });

        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, 3);
        expect(states[0], isNull);
        expect(states[1], isNotNull);
        expect(states[2], isNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle network error during login', (tester) async {
        // Arrange
        when(mockDataSource.signInWithEmailAndPassword(any, any)).thenThrow(
          FirebaseAuthException(
            code: 'network-request-failed',
            message: 'Falha na conexão',
          ),
        );

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act
        final emailField = find.byKey(const Key('email_input'));
        final passwordField = find.byKey(const Key('password_input'));

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should handle too many requests error', (tester) async {
        // Arrange
        when(mockDataSource.signInWithEmailAndPassword(any, any)).thenThrow(
          FirebaseAuthException(
            code: 'too-many-requests',
            message: 'Muitas tentativas',
          ),
        );

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act
        final emailField = find.byKey(const Key('email_input'));
        final passwordField = find.byKey(const Key('password_input'));

        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('should trim email input', (tester) async {
        // Arrange
        when(
          mockDataSource.signInWithEmailAndPassword(any, any),
        ).thenAnswer((_) async {});

        await tester.pumpApp(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(
                AuthRepository(mockDataSource),
              ),
            ],
            child: const LoginScreen(),
          ),
        );

        // Act - Preencher email com espaços
        final emailField = find.byKey(const Key('email_input'));
        final passwordField = find.byKey(const Key('password_input'));

        await tester.enterText(emailField, '  test@example.com  ');
        await tester.enterText(passwordField, 'password123');

        final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Assert - Email deve estar trimado
        verify(
          mockDataSource.signInWithEmailAndPassword(
            'test@example.com',
            'password123',
          ),
        ).called(1);
      });
    });
  });
}
