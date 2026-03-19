import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/l10n/generated/app_localizations.dart';
import 'package:mube/src/core/providers/app_display_preferences_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthRepository fakeAuthRepository;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    fakeAuthRepository = FakeAuthRepository();
    final user = TestData.user(
      uid: 'user-1',
      tipoPerfil: AppUserType.professional,
    );
    fakeAuthRepository.emitUser(
      FakeFirebaseUser(uid: user.uid, email: user.email),
    );
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream<AppUser?>.value(user),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    fakeAuthRepository.dispose();
  });

  Widget createSubject() {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, child) {
          final displayPreferences = ref.watch(appDisplayPreferencesProvider);

          return MaterialApp(
            locale: displayPreferences.locale ?? const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale == null) {
                return const Locale('pt');
              }

              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }

              return const Locale('pt');
            },
            home: const SettingsScreen(),
          );
        },
      ),
    );
  }

  group('SettingsScreen display preferences', () {
    testWidgets('renders current language preference and hides theme option', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(appLocaleCodePreferenceKey, 'en');
      await prefs.setString(appThemeModePreferenceKey, ThemeMode.dark.name);

      container.invalidate(appDisplayPreferencesProvider);

      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('App language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('App theme'), findsNothing);
      expect(find.text('Always dark'), findsNothing);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Profile type'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('updates language preference from settings', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Idioma do app'));
      await tester.tap(find.text('Idioma do app'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();

      expect(
        container.read(appDisplayPreferencesProvider).locale,
        const Locale('en'),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(appLocaleCodePreferenceKey), 'en');
      expect(find.text('App language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('does not render theme preference in settings', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Tema do app'), findsNothing);
      expect(find.text('Sempre escuro'), findsNothing);
      expect(find.text('App theme'), findsNothing);
      expect(find.text('Always dark'), findsNothing);
    });
  });
}
