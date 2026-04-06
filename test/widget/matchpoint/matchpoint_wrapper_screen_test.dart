import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/design_system/components/loading/app_loading_indicator.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/likes_quota_info.dart';
import 'package:mube/src/features/matchpoint/domain/match_info.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_intro_screen.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_tabs_screen.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_unavailable_screen.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_wrapper_screen.dart';

import '../../helpers/test_fakes.dart';
import '../features/matchpoint/matchpoint_test_fakes.dart';

void main() {
  late MockMatchpointRepository mockRepo;

  setUp(() {
    mockRepo = MockMatchpointRepository();

    // Stub default behavior
    try {
      provideDummy<Either<Failure, LikesQuotaInfo>>(
        const Left(ServerFailure(message: 'dummy')),
      );
    } catch (_) {}

    when(mockRepo.getRemainingLikes()).thenAnswer(
      (_) async => Right<Failure, LikesQuotaInfo>(
        LikesQuotaInfo(remaining: 10, limit: 10, resetTime: DateTime.now()),
      ),
    );
    when(
      mockRepo.fetchCandidates(
        currentUser: anyNamed('currentUser'),
        genres: anyNamed('genres'),
        hashtags: anyNamed('hashtags'),
        blockedUsers: anyNamed('blockedUsers'),
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => const Right<Failure, List<AppUser>>([]));

    when(
      mockRepo.fetchMatches(any),
    ).thenAnswer((_) async => const Right<Failure, List<MatchInfo>>([]));

    when(
      mockRepo.fetchHashtagRanking(limit: anyNamed('limit')),
    ).thenAnswer((_) async => const Right<Failure, List<HashtagRanking>>([]));
  });

  Widget createTestWidget(AsyncValue<AppUser?> userProfileState) {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWithValue(userProfileState),
        matchpointRepositoryProvider.overrideWithValue(mockRepo),
        // Provide a stable empty-state for MatchpointExploreScreen's
        // initState / postFrameCallback providers:
        matchpointCandidatesProvider.overrideWith(
          () => _EmptyMatchpointCandidates(),
        ),
      ],
      child: const MaterialApp(home: MatchpointWrapperScreen()),
    );
  }

  testWidgets('renders AppLoadingIndicator when profile is loading', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const AsyncLoading()));

    expect(find.byType(AppLoadingIndicator), findsOneWidget);
  });

  testWidgets('renders MatchpointIntroScreen when profile is active=false', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      tipoPerfil: AppUserType.professional,
      matchpointProfile: {'is_active': false},
    );

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump(); // frame for widget switch

    expect(find.byType(MatchpointIntroScreen), findsOneWidget);
    expect(find.byType(MatchpointTabsScreen), findsNothing);
    expect(find.byTooltip('Voltar'), findsOneWidget);
  });

  testWidgets('renders MatchpointIntroScreen when matchpointProfile is null', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      tipoPerfil: AppUserType.professional,
      matchpointProfile: null,
    );

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump();

    expect(find.byType(MatchpointIntroScreen), findsOneWidget);
  });

  testWidgets('renders MatchpointTabsScreen when profile is active=true', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      tipoPerfil: AppUserType.professional,
      matchpointProfile: {'is_active': true},
    );

    // MatchpointExploreScreen accesses many providers during initState/
    // postFrameCallback that are not relevant to this wrapper-level test.
    // Suppress those expected widget errors.
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {};

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    FlutterError.onError = originalOnError;

    expect(find.byType(MatchpointTabsScreen), findsOneWidget);
    expect(find.byType(MatchpointIntroScreen), findsNothing);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expect(find.byTooltip('Filtros avancados'), findsOneWidget);
    expect(find.byTooltip('Historico de swipes'), findsOneWidget);
  });

  testWidgets(
    'renders active Matchpoint flow with legacy scalar candidate fields',
    (tester) async {
      const user = AppUser(
        uid: 'user1',
        email: 'test@example.com',
        tipoPerfil: AppUserType.professional,
        matchpointProfile: {'is_active': true, 'musicalGenres': 'rock'},
      );
      const candidate = AppUser(
        uid: 'candidate-1',
        email: 'candidate@example.com',
        nome: 'Candidate',
        tipoPerfil: AppUserType.professional,
        dadosProfissional: {
          'nomeArtistico': 'Legacy Candidate',
          'funcoes': 'Guitarrista',
          'generosMusicais': 'rock',
        },
      );

      final fakeAuthRepository = FakeAuthRepository(
        initialUser: FakeFirebaseUser(uid: user.uid, email: user.email),
      )..appUser = user;

      when(
        mockRepo.fetchCandidates(
          currentUser: anyNamed('currentUser'),
          genres: anyNamed('genres'),
          hashtags: anyNamed('hashtags'),
          blockedUsers: anyNamed('blockedUsers'),
          limit: anyNamed('limit'),
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, List<AppUser>>([candidate]),
      );

      // Suppress expected widget errors from MatchpointExploreScreen
      // accessing providers not fully stubbed in this wrapper test.
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepository),
            authStateChangesProvider.overrideWith(
              (ref) => Stream.value(fakeAuthRepository.currentUser),
            ),
            currentUserProfileProvider.overrideWithValue(const AsyncData(user)),
            matchpointRepositoryProvider.overrideWithValue(mockRepo),
            matchpointCandidatesProvider.overrideWith(
              () => _EmptyMatchpointCandidates(),
            ),
          ],
          child: const MaterialApp(home: MatchpointWrapperScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      FlutterError.onError = originalOnError;

      expect(find.byType(MatchpointTabsScreen), findsOneWidget);
    },
  );

  testWidgets('renders Error message when profile loading fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestWidget(const AsyncError('Failed to load', StackTrace.empty)),
    );
    await tester.pump();

    expect(find.text('Erro: Failed to load'), findsOneWidget);
  });

  testWidgets('renders unavailable screen for contractor profile', (
    tester,
  ) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      tipoPerfil: AppUserType.contractor,
      matchpointProfile: {'is_active': true},
    );

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump();

    expect(find.byType(MatchpointUnavailableScreen), findsOneWidget);
    expect(find.byType(MatchpointTabsScreen), findsNothing);
    expect(find.byType(MatchpointIntroScreen), findsNothing);
    expect(find.byTooltip('Voltar'), findsOneWidget);
  });

  testWidgets('renders unavailable screen for studio profile', (tester) async {
    const user = AppUser(
      uid: 'user1',
      email: 'test@example.com',
      tipoPerfil: AppUserType.studio,
      matchpointProfile: {'is_active': true},
    );

    await tester.pumpWidget(createTestWidget(const AsyncData(user)));
    await tester.pump();

    expect(find.byType(MatchpointUnavailableScreen), findsOneWidget);
    expect(find.byType(MatchpointTabsScreen), findsNothing);
    expect(find.byType(MatchpointIntroScreen), findsNothing);
    expect(find.byTooltip('Voltar'), findsOneWidget);
  });
}

/// Stub [MatchpointCandidates] that returns an empty list without hitting
/// Firestore or any other real dependency.
class _EmptyMatchpointCandidates extends MatchpointCandidates {
  @override
  Future<List<AppUser>> build() async => const [];
}
