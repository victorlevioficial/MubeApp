import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/l10n/generated/app_localizations.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:mube/src/features/settings/presentation/privacy_settings_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late FakeChatRepository fakeChatRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    fakeChatRepository = FakeChatRepository();
  });

  AppUser buildContractorUser({required bool hasPhoto, bool isPublic = false}) {
    return TestData.user(
      uid: 'contractor-1',
      nome: 'Event Organizer',
      tipoPerfil: AppUserType.contractor,
      foto: hasPhoto ? 'https://example.com/avatar.jpg' : null,
    ).copyWith(
      dadosContratante: {'nomeExibicao': 'Casa Azul', 'isPublic': isPublic},
      privacySettings: const {'visible_in_home': false, 'chat_open': false},
      matchpointProfile: const {'is_active': false},
      blockedUsers: const ['legacy-blocked-user'],
    );
  }

  Widget createSubject({
    required AppUser user,
    List<String> blockedIds = const ['remote-blocked-user'],
  }) {
    fakeAuthRepository.appUser = user;

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        chatRepositoryProvider.overrideWithValue(fakeChatRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        blockedUsersProvider.overrideWith((ref) => Stream.value(blockedIds)),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: scaffoldMessengerKey,
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PrivacySettingsScreen(),
      ),
    );
  }

  group('PrivacySettingsScreen', () {
    testWidgets(
      'shows contractor public profile toggle and hides legacy controls',
      (tester) async {
        await tester.pumpWidget(
          createSubject(user: buildContractorUser(hasPhoto: true)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Privacidade e Visibilidade'), findsOneWidget);
        expect(find.text('Perfil p\u00FAblico'), findsOneWidget);
        expect(find.text('Aparecer na Home e Busca'), findsNothing);
        expect(find.text('Ativar MatchPoint'), findsNothing);
        expect(find.text('Chat p\u00FAblico'), findsOneWidget);
        expect(find.text('Usu\u00E1rios Bloqueados'), findsOneWidget);
      },
    );

    testWidgets('requires a profile photo before enabling public profile', (
      tester,
    ) async {
      final user = buildContractorUser(hasPhoto: false);

      await tester.pumpWidget(createSubject(user: user));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Perfil p\u00FAblico'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Adicione uma foto de perfil antes de ativar o perfil p\u00FAblico.',
        ),
        findsOneWidget,
      );
      expect(fakeAuthRepository.lastUpdatedUser, isNull);
    });

    testWidgets('saves contractor public profile flag when photo exists', (
      tester,
    ) async {
      final user = buildContractorUser(hasPhoto: true);

      await tester.pumpWidget(createSubject(user: user));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Perfil p\u00FAblico'),
      );
      await tester.pumpAndSettle();

      expect(
        fakeAuthRepository.lastUpdatedUser?.dadosContratante?['isPublic'],
        isTrue,
      );
      expect(find.text('Perfil p\u00FAblico atualizado.'), findsOneWidget);
    });
  });
}
