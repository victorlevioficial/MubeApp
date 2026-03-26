import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/design_system/components/data_display/user_avatar.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/gigs/domain/compensation_type.dart';
import 'package:mube/src/features/gigs/domain/gig.dart';
import 'package:mube/src/features/gigs/domain/gig_date_mode.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';
import 'package:mube/src/features/gigs/domain/gig_review.dart';
import 'package:mube/src/features/gigs/domain/gig_status.dart';
import 'package:mube/src/features/gigs/domain/gig_type.dart';
import 'package:mube/src/features/gigs/domain/review_type.dart';
import 'package:mube/src/features/gigs/presentation/providers/gig_streams.dart';
import 'package:mube/src/features/profile/presentation/public_profile_screen.dart';
import 'package:mube/src/features/profile/presentation/widgets/profile_hero_header.dart';
import 'package:mube/src/routing/route_paths.dart';

import '../../../../helpers/pump_app.dart';
import '../../../../helpers/test_data.dart';
import '../../../../helpers/test_fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepository;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
  });

  Future<void> pumpPublicProfile(
    WidgetTester tester,
    AppUser user, {
    AppUser? currentUser,
    PublicProfileMetrics? metrics,
    List<GigReview> reviews = const <GigReview>[],
    List<Gig> openGigs = const <Gig>[],
    Map<String, AppUser> reviewAuthors = const <String, AppUser>{},
  }) async {
    fakeAuthRepository.appUser = user;
    final reviewerIdsKey = encodeGigUserIdsKey(
      reviews.map((review) => review.reviewerId),
    );

    await tester.pumpApp(
      PublicProfileScreen(profileRef: user.uid),
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        currentUserProfileProvider.overrideWith(
          (ref) => Stream.value(currentUser ?? user),
        ),
        publicProfileMetricsProvider(user.uid).overrideWith(
          (ref) async => metrics ?? (averageRating: null, reviewCount: 0),
        ),
        userReviewsProvider(
          user.uid,
        ).overrideWith((ref) => Stream.value(reviews)),
        publicCreatorOpenGigsProvider(
          user.uid,
        ).overrideWith((ref) => Stream.value(openGigs)),
        if (reviewerIdsKey.isNotEmpty)
          gigUsersByStableIdsProvider(
            reviewerIdsKey,
          ).overrideWith((ref) async => reviewAuthors),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
  }

  void setTestViewport(
    WidgetTester tester, {
    required Size physicalSize,
    double devicePixelRatio = 1.0,
    double topPadding = 0,
  }) {
    tester.view.physicalSize = physicalSize;
    tester.view.devicePixelRatio = devicePixelRatio;
    tester.view.padding = FakeViewPadding(top: topPadding);
    tester.view.viewPadding = FakeViewPadding(top: topPadding);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
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

  testWidgets('shows venue details for a public contractor profile', (
    tester,
  ) async {
    const contractor = AppUser(
      uid: 'contractor-venue-uid',
      email: 'contractor@example.com',
      nome: 'Casa Azul',
      tipoPerfil: AppUserType.contractor,
      cadastroStatus: 'concluido',
      foto: 'https://example.com/avatar.jpg',
      dadosContratante: {
        'nomeExibicao': 'Casa Azul',
        'isPublic': true,
        'venueType': 'bar',
        'comodidades': ['stage', 'sound_system'],
      },
    );

    await pumpPublicProfile(
      tester,
      contractor,
      currentUser: TestData.user(uid: 'viewer-1'),
    );

    expect(find.text('Tipo de Local'), findsOneWidget);
    expect(find.text('Bar'), findsOneWidget);
    expect(find.text('Comodidades'), findsOneWidget);
    expect(find.text('Palco'), findsOneWidget);
    expect(find.text('Sistema de Som'), findsOneWidget);
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
        userReviewsProvider(
          professional.uid,
        ).overrideWith((ref) => Stream.value(const <GigReview>[])),
        publicCreatorOpenGigsProvider(
          professional.uid,
        ).overrideWith((ref) => Stream.value(const <Gig>[])),
      ],
    );

    await tester.pump();
    expect(find.text('Ainda sem avaliações públicas.'), findsNothing);

    metricsCompleter.complete((averageRating: 4.5, reviewCount: 3));
    await tester.pumpAndSettle();

    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('3 avaliações recebidas'), findsOneWidget);
  });

  testWidgets('shows written review comments inside reputation card', (
    tester,
  ) async {
    const professional = AppUser(
      uid: 'professional-reviews-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'instrumentos': ['Guitarra'],
      },
    );
    const reviewer = AppUser(
      uid: 'reviewer-1',
      email: 'reviewer@example.com',
      nome: 'Ana Sessions',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {'nomeArtistico': 'Ana Sessions'},
    );
    const reviews = <GigReview>[
      GigReview(
        id: 'review-1',
        gigId: 'gig-1',
        reviewerId: 'reviewer-1',
        reviewedUserId: 'professional-reviews-uid',
        rating: 5,
        comment: 'Muito profissional e pontual.',
        reviewType: ReviewType.creatorToParticipant,
      ),
    ];

    await pumpPublicProfile(
      tester,
      professional,
      metrics: (averageRating: 5.0, reviewCount: 1),
      reviews: reviews,
      reviewAuthors: const {'reviewer-1': reviewer},
    );

    expect(find.text('Avaliações'), findsOneWidget);
    expect(find.text('Muito profissional e pontual.'), findsOneWidget);
  });

  testWidgets('shows public handle and shareable link in hero', (tester) async {
    const professional = AppUser(
      uid: 'professional-handle-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      username: 'victorlevi',
      dadosProfissional: {
        'instrumentos': ['Guitarra'],
      },
    );

    await pumpPublicProfile(tester, professional);

    expect(find.text('@victorlevi'), findsOneWidget);
    expect(find.text('mubeapp.com.br/@victorlevi'), findsNothing);
  });

  testWidgets('shows share action next to message button on public profile', (
    tester,
  ) async {
    const professional = AppUser(
      uid: 'professional-no-handle-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      username: 'sessionplayer',
      dadosProfissional: {
        'instrumentos': ['Guitarra'],
      },
    );
    const viewer = AppUser(
      uid: 'viewer-uid',
      email: 'viewer@example.com',
      nome: 'Viewer',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'instrumentos': ['Baixo'],
      },
    );

    await pumpPublicProfile(tester, professional, currentUser: viewer);

    expect(find.byIcon(Icons.share_outlined), findsOneWidget);
    expect(find.text('Iniciar Conversa'), findsOneWidget);
  });

  testWidgets('keeps compact hero centered and below top actions on iPhone', (
    tester,
  ) async {
    setTestViewport(tester, physicalSize: const Size(393, 852), topPadding: 44);

    const professional = AppUser(
      uid: 'professional-ios-layout-uid',
      email: 'professional@example.com',
      nome: 'Hygor Tomaz',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      location: {'cidade': 'Rio de Janeiro', 'estado': 'Rio de Janeiro'},
      favoritesCount: 19,
      dadosProfissional: {
        'nomeArtistico': 'Hygor Tomaz',
        'instrumentos': ['Guitarra'],
      },
    );

    await pumpPublicProfile(tester, professional);

    final backButtonBottom = tester.getRect(find.byTooltip('Voltar')).bottom;
    final headerTop = tester.getRect(find.byType(ProfileHeroHeader)).top;
    final avatarCenterX = tester.getCenter(find.byType(UserAvatar)).dx;
    final titleCenterX = tester.getCenter(find.text('Hygor Tomaz')).dx;

    expect(headerTop, greaterThan(backButtonBottom));
    expect((avatarCenterX - titleCenterX).abs(), lessThan(2));
    expect(find.text('Rio de Janeiro, RJ'), findsOneWidget);
  });

  testWidgets('opens all reviews sheet from reputation section', (
    tester,
  ) async {
    const professional = AppUser(
      uid: 'professional-sheet-uid',
      email: 'professional@example.com',
      nome: 'Professional',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {
        'instrumentos': ['Guitarra'],
      },
    );
    const reviewer = AppUser(
      uid: 'reviewer-1',
      email: 'reviewer@example.com',
      nome: 'Ana Sessions',
      tipoPerfil: AppUserType.professional,
      cadastroStatus: 'concluido',
      dadosProfissional: {'nomeArtistico': 'Ana Sessions'},
    );
    const reviews = <GigReview>[
      GigReview(
        id: 'review-1',
        gigId: 'gig-1',
        reviewerId: 'reviewer-1',
        reviewedUserId: 'professional-sheet-uid',
        rating: 5,
        comment: 'Muito profissional e pontual.',
        reviewType: ReviewType.creatorToParticipant,
      ),
      GigReview(
        id: 'review-2',
        gigId: 'gig-2',
        reviewerId: 'reviewer-1',
        reviewedUserId: 'professional-sheet-uid',
        rating: 4,
        reviewType: ReviewType.creatorToParticipant,
      ),
    ];

    await pumpPublicProfile(
      tester,
      professional,
      metrics: (averageRating: 4.5, reviewCount: 2),
      reviews: reviews,
      reviewAuthors: const {'reviewer-1': reviewer},
    );

    await tester.scrollUntilVisible(
      find.text('Ver todas'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Ver todas'));
    await tester.pumpAndSettle();

    expect(find.text('Todas as avaliações'), findsOneWidget);
    expect(find.text('Sem comentário escrito.'), findsOneWidget);
  });
}
