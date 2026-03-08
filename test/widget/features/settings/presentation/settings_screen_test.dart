import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/settings/presentation/settings_screen.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  Widget createSubject({
    required AppUserType userType,
    AppUser? profileUser,
    firebase_auth.User? authUser,
  }) {
    final user =
        profileUser ?? TestData.user(uid: 'user-1', tipoPerfil: userType);
    fakeAuthRepository.emitUser(
      authUser ?? FakeFirebaseUser(uid: user.uid, email: user.email),
    );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SettingsScreen()),
        GoRoute(
          path: '/settings/addresses',
          builder: (context, state) =>
              const Scaffold(body: Text('Address Screen')),
        ),
        GoRoute(
          path: '/profile/edit',
          builder: (context, state) =>
              const Scaffold(body: Text('Edit Profile Screen')),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) =>
              const Scaffold(body: Text('Favorites Screen')),
        ),
        GoRoute(
          path: RoutePaths.invites, // '/invites' usually?
          builder: (context, state) =>
              const Scaffold(body: Text('Invites Screen')),
        ),
        GoRoute(
          path: RoutePaths.privacySettings,
          builder: (context, state) =>
              const Scaffold(body: Text('Privacy Screen')),
        ),
        GoRoute(
          path: RoutePaths.receivedFavorites,
          builder: (context, state) =>
              const Scaffold(body: Text('Received Favorites Screen')),
        ),
        GoRoute(
          path: RoutePaths.support,
          builder: (context, state) =>
              const Scaffold(body: Text('Support Screen')),
        ),
        GoRoute(
          path:
              '${RoutePaths.legal}/termsOfUse', // path might be nested or full
          builder: (context, state) =>
              const Scaffold(body: Text('Terms Screen')),
        ),
        GoRoute(
          path: '${RoutePaths.legal}/privacyPolicy',
          builder: (context, state) =>
              const Scaffold(body: Text('Privacy Policy Screen')),
        ),
        // Add more routes if needed, GoRouter handles unmapped routes with error page usually,
        // but for test we want specifically matched routes.
        // RoutePaths.legal likely '/legal'. So '/legal/termsOfUse'
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('SettingsScreen', () {
    testWidgets('renders common tiles', (tester) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      expect(find.text('Meus Endereços'), findsOneWidget);
      expect(find.text('Editar Perfil'), findsOneWidget);
      expect(find.text('Meus Favoritos'), findsOneWidget);
      expect(find.text('Alterar Senha'), findsOneWidget);
      expect(find.text('Sair da Conta'), findsOneWidget);
      expect(find.text('Tipo de Perfil'), findsOneWidget);
      expect(find.text('Plano free'), findsNothing);
      expect(find.text('Plano Ativo'), findsNothing);
    });

    testWidgets('renders "Minhas Bandas" for non-band user', (tester) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minhas Bandas'), findsOneWidget);
      expect(find.text('Gerenciar Banda'), findsNothing);
    });

    testWidgets('masks Apple relay email in header', (tester) async {
      const relayEmail = '7cc8ngqs6g@privaterelay.appleid.com';

      await tester.pumpWidget(
        createSubject(
          userType: AppUserType.professional,
          profileUser: TestData.user(
            uid: 'user-1',
            tipoPerfil: AppUserType.professional,
            email: relayEmail,
          ),
          authUser: FakeFirebaseUser(
            uid: 'user-1',
            email: relayEmail,
            providerIds: const ['apple.com'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email protegido pela Apple'), findsOneWidget);
      expect(find.text(relayEmail), findsNothing);
    });

    testWidgets('hides password reset for Apple sign-in accounts', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          userType: AppUserType.professional,
          authUser: FakeFirebaseUser(
            uid: 'user-1',
            email: '7cc8ngqs6g@privaterelay.appleid.com',
            providerIds: const ['apple.com'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alterar Senha'), findsNothing);
    });

    testWidgets('renders "Gerenciar Banda" for band user', (tester) async {
      await tester.pumpWidget(createSubject(userType: AppUserType.band));
      await tester.pumpAndSettle();

      expect(find.text('Gerenciar Banda'), findsOneWidget);
      expect(find.text('Minhas Bandas'), findsNothing);
    });

    testWidgets('navigates to Addresses when tapped', (tester) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Meus Endereços'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Meus Endereços'));
      await tester.pumpAndSettle();

      expect(find.text('Address Screen'), findsOneWidget);
    });

    testWidgets('navigates to Terms of Use when tapped', (tester) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Termos de Uso'));
      await tester.tap(find.text('Termos de Uso'));
      await tester.pumpAndSettle();

      expect(find.text('Terms Screen'), findsOneWidget);
    });

    testWidgets('navigates to Privacy Policy when tapped', (tester) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Política de Privacidade'));
      await tester.tap(find.text('Política de Privacidade'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy Screen'), findsOneWidget);
    });

    testWidgets('navigates to received favorites when stats card is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.favorite).first);
      await tester.pumpAndSettle();

      expect(find.text('Received Favorites Screen'), findsOneWidget);
    });

    testWidgets('logout button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sair da Conta'));
      await tester.pumpAndSettle();

      expect(find.text('Sair da Conta'), findsOneWidget);

      await tester.tap(find.text('Sair da Conta'));
      await tester.pumpAndSettle();

      expect(find.text('Sair da conta?'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('delete account button shows confirmation dialog', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      // Scroll to the bottom
      final scrollable = find.byType(Scrollable);
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      final deleteTile = find.text('Excluir Conta');
      expect(deleteTile, findsOneWidget);

      await tester.tap(deleteTile);
      // Explicitly pump several times to ensure dialog shows up
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirming logout calls signOut', (tester) async {
      await tester.pumpWidget(
        createSubject(
          userType: AppUserType.professional,
          authUser: FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Sair da Conta'));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Sair da Conta'));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();

      // In FakeAuthRepository, signOut sets currentUser to null.
      expect(fakeAuthRepository.currentUser, null);
    });

    testWidgets('confirming delete account clears local session', (
      tester,
    ) async {
      await tester.pumpWidget(
        createSubject(
          userType: AppUserType.professional,
          authUser: FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir Conta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.currentUser, null);
    });

    testWidgets('delete account failure keeps local session', (tester) async {
      fakeAuthRepository.shouldFailDeleteAccount = true;

      await tester.pumpWidget(
        createSubject(
          userType: AppUserType.professional,
          authUser: FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.drag(scrollable, const Offset(0, -2000));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir Conta'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Excluir'));
      await tester.pumpAndSettle();

      expect(fakeAuthRepository.currentUser, isNotNull);
    });
  });
}
