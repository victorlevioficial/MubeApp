import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/domain/band_activation_rules.dart';
import 'package:mube/src/features/profile/presentation/profile_screen.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  Widget createSubject(AppUser user) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  Widget createRouterSubject(AppUser user, GoRouter router) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets(
    'shows draft activation banner for band with less than 2 members',
    (tester) async {
      final user = TestData.bandUser().copyWith(
        tipoPerfil: AppUserType.band,
        status: profileDraftStatus,
        members: const ['member-1'],
      );
      fakeAuthRepository.appUser = user;

      await tester.pumpWidget(createSubject(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('rascunho'), findsOneWidget);
      expect(find.text('1 de 2 integrantes confirmados'), findsOneWidget);
      expect(find.text('Adicionar integrantes'), findsOneWidget);
    },
  );

  testWidgets(
    'does not show draft activation banner for active band with enough members',
    (tester) async {
      final user = TestData.bandUser().copyWith(
        tipoPerfil: AppUserType.band,
        status: profileActiveStatus,
        members: const ['member-1', 'member-2'],
      );
      fakeAuthRepository.appUser = user;

      await tester.pumpWidget(createSubject(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('rascunho'), findsNothing);
      expect(find.text('Adicionar integrantes'), findsNothing);
    },
  );

  testWidgets(
    'shows draft activation banner when active band falls below threshold',
    (tester) async {
      final user = TestData.bandUser().copyWith(
        tipoPerfil: AppUserType.band,
        status: profileActiveStatus,
        members: const ['member-1'],
      );
      fakeAuthRepository.appUser = user;

      await tester.pumpWidget(createSubject(user));
      await tester.pumpAndSettle();

      expect(find.textContaining('rascunho'), findsOneWidget);
      expect(find.text('1 de 2 integrantes confirmados'), findsOneWidget);
    },
  );

  testWidgets('does not show draft activation banner for active professional', (
    tester,
  ) async {
    final user = TestData.user(
      tipoPerfil: AppUserType.professional,
      status: profileActiveStatus,
    );
    fakeAuthRepository.appUser = user;

    await tester.pumpWidget(createSubject(user));
    await tester.pumpAndSettle();

    expect(find.textContaining('rascunho'), findsNothing);
    expect(find.text('Adicionar integrantes'), findsNothing);
  });

  testWidgets(
    'opens edit profile with push so the route can be popped safely',
    (tester) async {
      final user = TestData.user(
        tipoPerfil: AppUserType.professional,
        status: profileActiveStatus,
      );
      fakeAuthRepository.appUser = user;

      final router = GoRouter(
        initialLocation: '/profile',
        routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RoutePaths.profileEdit,
            builder: (context, state) =>
                const Scaffold(body: Text('Edit Profile Page')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(createRouterSubject(user, router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Editar Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile Page'), findsOneWidget);
      expect(router.canPop(), true);
    },
  );

  testWidgets('renders legacy scalar profile fields without crashing', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'legacy-professional-uid',
      email: 'legacy@example.com',
      nome: 'Legacy Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'categorias': 'production',
        'instrumentos': 'bass_synth',
        'generosMusicais': 'mpb',
        'funcoes': 'audiovisual_motion_design',
      },
    );
    fakeAuthRepository.appUser = user;

    await tester.pumpWidget(createSubject(user));
    await tester.pumpAndSettle();

    expect(find.text('Produção Musical'), findsOneWidget);
    expect(find.text('Bass Synth'), findsOneWidget);
    expect(find.text('MPB'), findsOneWidget);
    expect(find.text('Motion Design'), findsOneWidget);
  });
}
