import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/l10n/generated/app_localizations.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/settings/presentation/settings_screen.dart';

import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('does not expose incomplete language or theme preferences', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    addTearDown(authRepository.dispose);
    final user = TestData.user(
      uid: 'user-1',
      tipoPerfil: AppUserType.professional,
    );
    authRepository.emitUser(FakeFirebaseUser(uid: user.uid, email: user.email));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream<AppUser?>.value(user),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editar Perfil'), findsOneWidget);
    expect(find.text('Idioma do app'), findsNothing);
    expect(find.text('App language'), findsNothing);
    expect(find.text('Tema do app'), findsNothing);
    expect(find.text('App theme'), findsNothing);
  });
}
