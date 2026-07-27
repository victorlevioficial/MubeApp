import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';
import 'package:mube/src/design_system/foundations/theme/app_theme.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/bands/data/invites_repository.dart';
import 'package:mube/src/features/feed/presentation/widgets/feed_header.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';
import 'package:mube/src/features/onboarding/presentation/flows/onboarding_band_flow.dart';
import 'package:mube/src/features/onboarding/presentation/flows/onboarding_studio_flow.dart';
import 'package:mube/src/features/profile/presentation/edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/test_fakes.dart';

class _FakeInvitesRepository extends Fake implements InvitesRepository {
  @override
  Stream<List<Map<String, dynamic>>> getIncomingInvites(String uid) {
    return Stream.value(const []);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('impeccable profile completion visual inspection', (
    tester,
  ) async {
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }

    final professionalUser = _professionalUser();

    await _pumpEditProfile(tester, professionalUser);
    await _screenshot(binding, tester, '01_edit_profile_profile_tab');

    await tester.tap(find.text('Mídia'));
    await tester.pumpAndSettle();
    await _screenshot(binding, tester, '02_edit_profile_media_tab');

    await tester.tap(find.text('Links'));
    await tester.pumpAndSettle();
    await _screenshot(binding, tester, '03_edit_profile_links_tab');

    await _pumpFeedHeader(tester, professionalUser);
    await _screenshot(binding, tester, '04_feed_header_improvements');

    await _pumpBandStep2(tester);
    await _screenshot(binding, tester, '05_onboarding_band_genres_empty');

    await _pumpStudioStep2(tester);
    await _screenshot(binding, tester, '06_onboarding_studio_services_empty');
  });
}

Future<void> _pumpEditProfile(WidgetTester tester, AppUser user) async {
  final authRepository = FakeAuthRepository(
    initialUser: FakeFirebaseUser(uid: user.uid, email: user.email),
  )..appUser = user;

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        appConfigProvider.overrideWith((ref) async => const AppConfig()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: const EditProfileScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpFeedHeader(WidgetTester tester, AppUser user) async {
  final authRepository = FakeAuthRepository(
    initialUser: FakeFirebaseUser(uid: user.uid, email: user.email),
  )..appUser = user;

  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
        invitesRepositoryProvider.overrideWithValue(_FakeInvitesRepository()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              FeedHeader(currentUser: user),
              const SliverToBoxAdapter(child: SizedBox(height: 600)),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpBandStep2(WidgetTester tester) async {
  await tester.pumpWidget(
    _VisualApp(
      child: OnboardingBandFlow(
        user: _baseUser(AppUserType.band, uid: 'band-visual'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Lia Responsavel');
  await tester.enterText(find.byType(TextFormField).at(1), 'Banda Aurora');
  await tester.enterText(find.byType(TextFormField).at(2), '(21) 99999-9999');
  await _advanceOnboardingStep(tester);
}

Future<void> _pumpStudioStep2(WidgetTester tester) async {
  await tester.pumpWidget(
    _VisualApp(
      child: OnboardingStudioFlow(
        user: _baseUser(AppUserType.studio, uid: 'studio-visual'),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextFormField).at(0), 'Rafa Responsavel');
  await tester.enterText(find.byType(TextFormField).at(1), 'Mube Studio');
  await tester.enterText(find.byType(TextFormField).at(2), '(11) 99999-9999');
  await _advanceOnboardingStep(tester);
}

Future<void> _advanceOnboardingStep(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  await tester.pumpAndSettle();

  final continueButton = find.widgetWithText(AppButton, 'Continuar');
  await tester.ensureVisible(continueButton);
  await tester.pumpAndSettle();
  await tester.tap(continueButton);
  await tester.pumpAndSettle();

  expect(find.text('Etapa 2 de 3'), findsOneWidget);
}

Future<void> _screenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}

AppUser _professionalUser() {
  return const AppUser(
    uid: 'professional-visual',
    email: 'visual@mube.app',
    cadastroStatus: 'concluido',
    tipoPerfil: AppUserType.professional,
    nome: 'Victor Silva',
    username: 'victorgroove',
    location: {
      'logradouro': 'Rua Augusta',
      'bairro': 'Consolacao',
      'cidade': 'Sao Paulo',
      'estado': 'SP',
      'lat': -23.56,
      'lng': -46.65,
    },
    dadosProfissional: {
      'nomeArtistico': 'Victor Groove',
      'celular': '(11) 99999-9999',
      'categorias': ['singer'],
      'funcoes': ['lead_vocal'],
      'generosMusicais': ['rock'],
    },
  );
}

AppUser _baseUser(AppUserType type, {required String uid}) {
  return AppUser(
    uid: uid,
    email: '$uid@mube.app',
    cadastroStatus: 'perfil_pendente',
    tipoPerfil: type,
    nome: 'Usuario Visual',
  );
}

class _VisualApp extends StatelessWidget {
  const _VisualApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(initialUser: FakeFirebaseUser(uid: 'visual-user')),
        ),
        appConfigProvider.overrideWith((ref) async => const AppConfig()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: child,
      ),
    );
  }
}
