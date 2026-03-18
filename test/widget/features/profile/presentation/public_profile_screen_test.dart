import 'dart:async';

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
      PublicProfileScreen(profileRef: user.uid),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith((ref) => Stream.value(user)),
        publicProfileMetricsProvider(
          user.uid,
        ).overrideWith((ref) async => (averageRating: null, reviewCount: 0)),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('hides contractor personal gender from public profile', (
    tester,
  ) async {
    const contractor = AppUser(
      uid: 'contractor-uid',
      email: 'contractor@example.com',
      nome: 'Event Organizer',
      tipoPerfil: AppUserType.contractor,
      cadastroStatus: 'concluido',
      dadosContratante: {'genero': 'Feminino'},
    );
    await pumpPublicProfile(tester, contractor);

    expect(find.text('Gênero'), findsNothing);
    expect(find.text('Feminino'), findsNothing);
    expect(find.text('Estilo Musical Preferido'), findsNothing);
  });

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

  testWidgets('shows music links section when profile has streaming links', (
    tester,
  ) async {
    const professional = AppUser(
      uid: 'professional-links-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'instrumentos': ['Guitarra'],
      },
      musicLinks: {
        'spotify': 'https://open.spotify.com/artist/test',
        'deezer': 'https://www.deezer.com/artist/test',
      },
    );

    await pumpPublicProfile(tester, professional);

    expect(find.text('Ouça nas plataformas'), findsOneWidget);
    expect(find.byTooltip('Spotify'), findsOneWidget);
    expect(find.byTooltip('Deezer'), findsOneWidget);
  });

  testWidgets('highlights remote recording for music production profiles', (
    tester,
  ) async {
    const professional = AppUser(
      uid: 'professional-remote-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'categorias': ['production'],
        'funcoes': ['Produtor Musical'],
        'fazGravacaoRemota': true,
      },
    );

    await pumpPublicProfile(tester, professional);

    expect(find.text('Disponibilidade'), findsOneWidget);
    expect(find.text('Gravação remota'), findsOneWidget);
  });

  testWidgets('does not show music links section when map is empty', (
    tester,
  ) async {
    const band = AppUser(
      uid: 'band-no-links-uid',
      email: 'band@example.com',
      nome: 'Band',
      tipoPerfil: AppUserType.band,
      cadastroStatus: 'concluido',
      dadosBanda: {
        'generosMusicais': ['Rock'],
      },
    );

    await pumpPublicProfile(tester, band);

    expect(find.text('Ouça nas plataformas'), findsNothing);
  });

  testWidgets('shows music links even when type-specific map is missing', (
    tester,
  ) async {
    const professional = AppUser(
      uid: 'professional-legacy-links-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      musicLinks: {'spotify': 'https://open.spotify.com/artist/test'},
    );

    await pumpPublicProfile(tester, professional);

    expect(find.text('Ouça nas plataformas'), findsOneWidget);
    expect(find.byTooltip('Spotify'), findsOneWidget);
  });

  testWidgets('keeps skeleton until profile metrics resolve', (tester) async {
    const professional = AppUser(
      uid: 'professional-metrics-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'instrumentos': ['Guitarra'],
      },
    );
    final metricsCompleter = Completer<PublicProfileMetrics>();

    fakeAuthRepository.appUser = professional;

    await tester.pumpApp(
      PublicProfileScreen(profileRef: professional.uid),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(professional),
        ),
        publicProfileMetricsProvider(
          professional.uid,
        ).overrideWith((ref) => metricsCompleter.future),
      ],
    );

    await tester.pump();
    expect(find.text('Sem avaliacoes ainda'), findsNothing);

    metricsCompleter.complete((averageRating: 4.5, reviewCount: 3));
    await tester.pumpAndSettle();

    expect(find.text('4.5 (3)'), findsOneWidget);
  });
}
