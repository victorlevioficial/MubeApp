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

  Future<void> pumpPublicProfile(WidgetTester tester, AppUser user) async {
    fakeAuthRepository.appUser = user;

    await tester.pumpApp(
      PublicProfileScreen(uid: user.uid),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

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
      await pumpPublicProfile(tester, contractor);

      expect(find.text('Gênero'), findsOneWidget);
      expect(find.text('Feminino'), findsOneWidget);
      expect(find.text('Estilo Musical Preferido'), findsNothing);
    },
  );

  testWidgets('does not show instagram for professional', (tester) async {
    const professional = AppUser(
      uid: 'professional-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'instagram': '@session.player',
        'instrumentos': ['Guitarra'],
      },
    );

    await pumpPublicProfile(tester, professional);

    expect(find.text('Instagram'), findsNothing);
    expect(find.text('@session.player'), findsNothing);
  });

  testWidgets('does not show instagram for band', (tester) async {
    const band = AppUser(
      uid: 'band-uid',
      email: 'band@example.com',
      nome: 'Band',
      tipoPerfil: AppUserType.band,
      cadastroStatus: 'concluido',
      dadosBanda: {
        'instagram': 'instagram.com/the.band',
        'generosMusicais': ['Rock'],
      },
    );

    await pumpPublicProfile(tester, band);

    expect(find.text('Instagram'), findsNothing);
    expect(find.text('@the.band'), findsNothing);
  });

  testWidgets('does not show instagram for studio', (tester) async {
    const studio = AppUser(
      uid: 'studio-uid',
      email: 'studio@example.com',
      nome: 'Studio',
      tipoPerfil: AppUserType.studio,
      cadastroStatus: 'concluido',
      dadosEstudio: {
        'instagram': 'studio.session',
        'services': ['Mixagem'],
      },
    );

    await pumpPublicProfile(tester, studio);

    expect(find.text('Instagram'), findsNothing);
    expect(find.text('@studio.session'), findsNothing);
  });

  testWidgets('does not show instagram for contractor', (tester) async {
    const contractor = AppUser(
      uid: 'contractor-uid',
      email: 'contractor@example.com',
      nome: 'Event Organizer',
      tipoPerfil: AppUserType.contractor,
      cadastroStatus: 'concluido',
      dadosContratante: {'instagram': 'instagram.com/event.house'},
    );

    await pumpPublicProfile(tester, contractor);

    expect(find.text('Instagram'), findsNothing);
    expect(find.text('@event.house'), findsNothing);
  });
}
