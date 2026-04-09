import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/matchpoint/presentation/controllers/matchpoint_controller.dart';
import 'package:mube/src/features/matchpoint/presentation/screens/matchpoint_explore_screen.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/match_swipe_deck.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/matchpoint_tutorial_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const currentUser = AppUser(
    uid: 'current-user',
    email: 'current@mube.app',
    tipoPerfil: AppUserType.professional,
    matchpointProfile: {
      'musicalGenres': ['rock'],
    },
  );

  const candidate = AppUser(
    uid: 'candidate-1',
    email: 'candidate@mube.app',
    nome: 'Candidate',
    tipoPerfil: AppUserType.professional,
    dadosProfissional: {
      'nomeArtistico': 'Candidate',
      'funcoes': ['Guitarrista'],
      'generosMusicais': ['rock'],
    },
  );

  Future<void> pumpExploreScreen(
    WidgetTester tester, {
    required Map<String, Object> preferences,
    ProviderContainer? container,
  }) async {
    SharedPreferences.setMockInitialValues(preferences);

    final scopedContainer = container ?? ProviderContainer();
    addTearDown(scopedContainer.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scopedContainer,
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(height: 900, child: MatchpointExploreScreen()),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  group('MatchpointExploreScreen', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          currentUserProfileProvider.overrideWithValue(
            const AsyncData(currentUser),
          ),
          matchpointCandidatesProvider.overrideWith(
            () => _FixedMatchpointCandidates([candidate]),
          ),
        ],
      );
    });

    testWidgets('keeps swipe deck gated while tutorial overlay is visible', (
      tester,
    ) async {
      await pumpExploreScreen(
        tester,
        preferences: const {},
        container: container,
      );

      expect(find.byType(MatchpointTutorialOverlay), findsOneWidget);
      expect(find.byType(MatchSwipeDeck), findsNothing);

      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();

      expect(find.byType(MatchpointTutorialOverlay), findsNothing);
      expect(find.byType(MatchSwipeDeck), findsOneWidget);
    });

    testWidgets('renders swipe deck immediately after tutorial was seen', (
      tester,
    ) async {
      await pumpExploreScreen(
        tester,
        preferences: const {'matchpoint_tutorial_seen': true},
        container: container,
      );

      expect(find.byType(MatchpointTutorialOverlay), findsNothing);
      expect(find.byType(MatchSwipeDeck), findsOneWidget);
    });

    testWidgets('keeps the same deck session while queue state toggles', (
      tester,
    ) async {
      await pumpExploreScreen(
        tester,
        preferences: const {'matchpoint_tutorial_seen': true},
        container: container,
      );

      final initialDeck = tester.widget<MatchSwipeDeck>(
        find.byType(MatchSwipeDeck),
      );
      final initialKey = initialDeck.key;

      expect(initialDeck.canUndo, isTrue);

      container
          .read(matchpointSwipeQueueStateProvider.notifier)
          .setPendingActions(1);
      await tester.pump();

      final lockedDeck = tester.widget<MatchSwipeDeck>(
        find.byType(MatchSwipeDeck),
      );
      expect(lockedDeck.canUndo, isFalse);
      expect(lockedDeck.key, equals(initialKey));

      container
          .read(matchpointSwipeQueueStateProvider.notifier)
          .setPendingActions(0);
      await tester.pump();

      final unlockedDeck = tester.widget<MatchSwipeDeck>(
        find.byType(MatchSwipeDeck),
      );
      expect(unlockedDeck.canUndo, isTrue);
      expect(unlockedDeck.key, equals(initialKey));
    });

    testWidgets(
      'creates a fresh deck session when refreshed data repeats the same candidates',
      (tester) async {
        final mutableCandidates = _MutableMatchpointCandidates([candidate]);
        container = ProviderContainer(
          overrides: [
            currentUserProfileProvider.overrideWithValue(
              const AsyncData(currentUser),
            ),
            matchpointCandidatesProvider.overrideWith(() => mutableCandidates),
          ],
        );

        await pumpExploreScreen(
          tester,
          preferences: const {'matchpoint_tutorial_seen': true},
          container: container,
        );

        final initialDeck = tester.widget<MatchSwipeDeck>(
          find.byType(MatchSwipeDeck),
        );
        final initialKey = initialDeck.key;

        mutableCandidates.replaceWithFresh([candidate]);
        await tester.pump();

        final refreshedDeck = tester.widget<MatchSwipeDeck>(
          find.byType(MatchSwipeDeck),
        );
        expect(refreshedDeck.key, isNot(equals(initialKey)));
      },
    );
  });
}

class _FixedMatchpointCandidates extends MatchpointCandidates {
  _FixedMatchpointCandidates(this._candidates);

  final List<AppUser> _candidates;

  @override
  Future<List<AppUser>> build() async => _candidates;
}

class _MutableMatchpointCandidates extends MatchpointCandidates {
  _MutableMatchpointCandidates(List<AppUser> candidates)
    : _candidates = List<AppUser>.of(candidates);

  List<AppUser> _candidates;

  @override
  Future<List<AppUser>> build() async => _candidates;

  void replaceWithFresh(List<AppUser> candidates) {
    _candidates = List<AppUser>.of(candidates);
    state = AsyncData(_candidates);
  }
}
