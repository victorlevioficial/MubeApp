import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mube/src/features/auth/data/auth_repository.dart';
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

  Widget createSubject({required AppUserType userType}) {
    final user = TestData.user(uid: 'user-1', tipoPerfil: userType);

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
    });

    testWidgets('renders "Minhas Bandas" for non-band user', (tester) async {
      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minhas Bandas'), findsOneWidget);
      expect(find.text('Gerenciar Banda'), findsNothing);
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

      await tester.tap(find.text('Meus Endereços'));
      await tester.pumpAndSettle();

      expect(find.text('Address Screen'), findsOneWidget);
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

    testWidgets('confirming logout calls signOut', (tester) async {
      // We set current user initially
      fakeAuthRepository.emitUser(
        FakeFirebaseUser(uid: 'user-1', email: 't@t.com'),
      );

      await tester.pumpWidget(
        createSubject(userType: AppUserType.professional),
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
  });
}
