import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/components/data_display/user_avatar.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/search/presentation/widgets/user_card.dart';

void main() {
  group('UserCard', () {
    final testUser = AppUser(
      uid: 'user-1',
      email: 'test@example.com',
      nome: 'João Silva',
      tipoPerfil: AppUserType.professional,
      dadosProfissional: const {'nomeArtistico': 'João Rock'},
      foto: 'https://example.com/photo.jpg',
      location: const {'cidade': 'São Paulo', 'estado': 'SP'},
    );

    testWidgets('renders with user artistic name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.text('João Rock'), findsOneWidget);
    });

    testWidgets('renders with user real name when no artistic name', (
      WidgetTester tester,
    ) async {
      final userWithoutArtisticName = AppUser(
        uid: 'user-2',
        email: 'test2@example.com',
        nome: 'Maria Santos',
        tipoPerfil: AppUserType.professional,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: userWithoutArtisticName, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Maria Santos'), findsOneWidget);
    });

    testWidgets('renders with studio name for studio type', (
      WidgetTester tester,
    ) async {
      final studioUser = AppUser(
        uid: 'studio-1',
        email: 'studio@test.com',
        nome: 'Studio Real Name',
        tipoPerfil: AppUserType.studio,
        dadosEstudio: const {'nomeArtistico': 'Studio Artístico'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: studioUser, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Studio Artístico'), findsOneWidget);
    });

    testWidgets('triggers onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(UserCard));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('renders UserAvatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets('renders profile type label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.text('Profissional'), findsOneWidget);
    });

    testWidgets('renders location when available', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.text('São Paulo, SP'), findsOneWidget);
    });

    testWidgets('does not render location when not available', (
      WidgetTester tester,
    ) async {
      final userWithoutLocation = AppUser(
        uid: 'user-3',
        email: 'test3@example.com',
        nome: 'Sem Localização',
        tipoPerfil: AppUserType.professional,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: userWithoutLocation, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.location_on), findsNothing);
    });

    testWidgets('renders chevron icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('uses Card widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('uses InkWell for tap feedback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: testUser, onTap: () {}),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.shape, isA<RoundedRectangleBorder>());
    });

    testWidgets('handles long names with ellipsis', (
      WidgetTester tester,
    ) async {
      final userWithLongName = AppUser(
        uid: 'user-4',
        email: 'test4@example.com',
        nome: 'Nome Muito Longo Que Deveria Ser Truncado Para Caber No Card',
        tipoPerfil: AppUserType.professional,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(user: userWithLongName, onTap: () {}),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(
        find.text(
          'Nome Muito Longo Que Deveria Ser Truncado Para Caber No Card',
        ),
      );
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('handles null onTap gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: UserCard(user: testUser, onTap: null)),
        ),
      );

      expect(find.byType(UserCard), findsOneWidget);
    });

    testWidgets('renders different profile types correctly', (
      WidgetTester tester,
    ) async {
      final types = [
        (AppUserType.professional, 'Profissional'),
        (AppUserType.band, 'Banda'),
        (AppUserType.studio, 'Estúdio'),
        (AppUserType.contractor, 'Contratante'),
      ];

      for (final (type, label) in types) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UserCard(
                user: AppUser(
                  uid: 'user-$type',
                  email: 'test@example.com',
                  nome: 'Test User',
                  tipoPerfil: type,
                ),
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text(label), findsOneWidget);
      }
    });
  });
}
