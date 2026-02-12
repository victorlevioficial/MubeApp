import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/match_card.dart';

void main() {
  group('MatchCard', () {
    const testUser = AppUser(
      uid: 'user-1',
      email: 'test@example.com',
      nome: 'João Silva',
      tipoPerfil: AppUserType.professional,
      dadosProfissional: {
        'nomeArtistico': 'João Rock',
        'funcoes': ['Guitarrista', 'Vocalista'],
      },
      matchpointProfile: {
        'musicalGenres': ['rock', 'pop'],
      },
      foto: 'https://example.com/photo.jpg',
    );

    testWidgets('renders with user artistic name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.text('João Rock'), findsOneWidget);
    });

    testWidgets('renders with user real name when no artistic name', (
      WidgetTester tester,
    ) async {
      const userWithoutArtisticName = AppUser(
        uid: 'user-2',
        email: 'test2@example.com',
        nome: 'Maria Santos',
        tipoPerfil: AppUserType.professional,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: userWithoutArtisticName, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Maria Santos'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: testUser, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(MatchCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders genre compatibility badge when genres match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              user: testUser,
              onTap: () {},
              currentUserGenres: const ['rock', 'jazz'],
            ),
          ),
        ),
      );

      expect(find.text('1 gênero em comum'), findsOneWidget);
    });

    testWidgets('renders multiple genres compatibility', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              user: testUser,
              onTap: () {},
              currentUserGenres: const ['rock', 'pop', 'jazz'],
            ),
          ),
        ),
      );

      expect(find.text('2 gêneros em comum'), findsOneWidget);
    });

    testWidgets('does not render compatibility badge when no genres match', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(
              user: testUser,
              onTap: () {},
              currentUserGenres: const ['jazz', 'classical'],
            ),
          ),
        ),
      );

      expect(find.textContaining('gênero'), findsNothing);
    });

    testWidgets('renders subtitle with roles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Guitarrista • Vocalista'), findsOneWidget);
    });

    testWidgets('renders default subtitle for professional without roles', (
      WidgetTester tester,
    ) async {
      const userWithoutRoles = AppUser(
        uid: 'user-3',
        email: 'test3@example.com',
        nome: 'Sem Funções',
        tipoPerfil: AppUserType.professional,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: userWithoutRoles, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Músico Profissional'), findsOneWidget);
    });

    testWidgets('renders band subtitle for band type', (
      WidgetTester tester,
    ) async {
      const bandUser = AppUser(
        uid: 'band-1',
        email: 'band@test.com',
        nome: 'Banda Teste',
        tipoPerfil: AppUserType.band,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: bandUser, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Banda'), findsOneWidget);
    });

    testWidgets('renders studio subtitle for studio type', (
      WidgetTester tester,
    ) async {
      const studioUser = AppUser(
        uid: 'studio-1',
        email: 'studio@test.com',
        nome: 'Studio Teste',
        tipoPerfil: AppUserType.studio,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: studioUser, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Estúdio'), findsOneWidget);
    });

    testWidgets('renders tags', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      // Tags are derived from user data
      expect(find.byType(Wrap), findsWidgets);
    });

    testWidgets('has gradient overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      final positioned = tester.widget<Positioned>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Positioned &&
              widget.child is Container &&
              (widget.child as Container).decoration is BoxDecoration,
        ),
      );

      final container = positioned.child as Container;
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
    });

    testWidgets('has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect.borderRadius, isNotNull);
    });

    testWidgets('renders without photo placeholder when no photo', (
      WidgetTester tester,
    ) async {
      const userWithoutPhoto = AppUser(
        uid: 'user-4',
        email: 'test4@example.com',
        nome: 'Sem Foto',
        tipoPerfil: AppUserType.professional,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchCard(user: userWithoutPhoto, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('handles null onTap gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MatchCard(user: testUser, onTap: null)),
        ),
      );

      expect(find.byType(MatchCard), findsOneWidget);
    });
  });
}
