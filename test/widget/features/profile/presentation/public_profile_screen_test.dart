import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/profile/presentation/public_profile_screen.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  testWidgets(
    'shows personal gender for contractor instead of musical genre label',
    (tester) async {
      const contractor = AppUser(
        uid: 'contractor-uid',
        email: 'contractor@example.com',
        nome: 'Event Organizer',
        tipoPerfil: AppUserType.contractor,
        cadastroStatus: 'concluido',
        dadosContratante: {'genero': 'Feminino'},
      );
      fakeAuthRepository.appUser = contractor;

      await tester.pumpApp(
        const PublicProfileScreen(uid: 'contractor-uid'),
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(contractor),
          ),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Gênero'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);
      expect(find.text('Estilo Musical Preferido'), findsNothing);
    },
  );

  testWidgets('shows instagram for contractor when available', (tester) async {
    const contractor = AppUser(
      uid: 'contractor-uid',
      email: 'contractor@example.com',
      nome: 'Event Organizer',
      tipoPerfil: AppUserType.contractor,
      cadastroStatus: 'concluido',
      dadosContratante: {'instagram': 'instagram.com/event.house'},
    );
    fakeAuthRepository.appUser = contractor;

    await tester.pumpApp(
      const PublicProfileScreen(uid: 'contractor-uid'),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(contractor),
        ),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('@event.house'), findsOneWidget);
  });
}
