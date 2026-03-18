import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/l10n/generated/app_localizations.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
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

  AppUser buildUser({
    Map<String, dynamic>? privacySettings,
    Map<String, dynamic>? matchpointProfile,
    List<String>? blockedUsers,
  }) {
    return TestData.user(uid: 'user-1').copyWith(
      privacySettings:
          privacySettings ??
          const {'visible_in_home': true, 'chat_open': false},
      matchpointProfile: matchpointProfile ?? const {'is_active': false},
      blockedUsers: blockedUsers ?? const ['legacy-blocked-user'],
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
    testWidgets('renders privacy controls and blocked users count', (
      tester,
    ) async {
      await tester.pumpWidget(createSubject(user: buildUser()));
      await tester.pumpAndSettle();

      expect(find.text('Privacidade e Visibilidade'), findsOneWidget);
      expect(find.text('Aparecer na Home e Busca'), findsOneWidget);
      expect(find.text('Ativar MatchPoint'), findsOneWidget);
      expect(find.text('Chat público'), findsOneWidget);
      expect(find.text('Usuários Bloqueados'), findsOneWidget);
      expect(find.text('2 usuários'), findsOneWidget);
    });

    testWidgets('updates home visibility preference', (tester) async {
      await tester.pumpWidget(createSubject(user: buildUser()));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Aparecer na Home e Busca'),
      );
      await tester.pumpAndSettle();

      expect(
        fakeAuthRepository.lastUpdatedUser?.privacySettings['visible_in_home'],
        isFalse,
      );
    });

    testWidgets(
      'enabling public chat reevaluates pending conversations and shows success',
      (tester) async {
        await tester.pumpWidget(createSubject(user: buildUser()));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(SwitchListTile, 'Chat público'));
        await tester.pumpAndSettle();

        expect(
          fakeAuthRepository.lastUpdatedUser?.privacySettings['chat_open'],
          isTrue,
        );
        expect(
          fakeChatRepository.reevaluatePendingConversationsForRecipientCalls,
          1,
        );
        expect(find.text('Privacidade do chat atualizada.'), findsOneWidget);
      },
    );
  });
}
