import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/foundations/tokens/app_spacing.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/match_profile_preview_sheet.dart';

void main() {
  group('MatchProfilePreviewSheet', () {
    const professionalUser = AppUser(
      uid: 'user-1',
      email: 'test@example.com',
      nome: 'Jo\u00E3o Silva',
      tipoPerfil: AppUserType.professional,
      bio: 'M\u00FAsico apaixonado por rock e blues',
      dadosProfissional: {
        'nomeArtistico': 'Jo\u00E3o Rock',
        'funcoes': ['Guitarrista', 'Vocalista'],
        'instrumentos': ['Guitarra', 'Viol\u00E3o', 'Baixo'],
        'generosMusicais': ['Rock', 'Blues', 'Pop'],
      },
      matchpointProfile: {
        'hashtags': ['#rock_brasil', '#guitar_hero'],
        'musicalGenres': ['Rock', 'Blues'],
      },
    );

    const bandUser = AppUser(
      uid: 'band-1',
      email: 'band@test.com',
      nome: 'Banda Teste',
      tipoPerfil: AppUserType.band,
      bio: 'Uma banda de rock incr\u00EDvel',
      dadosBanda: {
        'nomeBanda': 'Os Rockeiros',
        'generosMusicais': ['Rock', 'Metal'],
      },
    );

    const studioUser = AppUser(
      uid: 'studio-1',
      email: 'studio@test.com',
      nome: 'Studio XYZ',
      tipoPerfil: AppUserType.studio,
      dadosEstudio: {
        'nomeEstudio': 'Studio XYZ',
        'studioType': 'commercial',
        'services': ['Grava\u00E7\u00E3o', 'Mixagem', 'Masteriza\u00E7\u00E3o'],
      },
    );

    const studioUserWithNestedBio = AppUser(
      uid: 'studio-2',
      email: 'studio-bio@test.com',
      nome: 'Studio Bio',
      tipoPerfil: AppUserType.studio,
      dadosEstudio: {
        'nomeEstudio': 'Studio Bio',
        'bio': 'Bio do estudio salva nos dados internos',
      },
    );

    const minimalUser = AppUser(
      uid: 'user-min',
      email: 'min@test.com',
      nome: 'Usu\u00E1rio M\u00EDnimo',
      tipoPerfil: AppUserType.professional,
    );

    Future<void> openSheet(
      WidgetTester tester,
      AppUser user, {
      MediaQueryData mediaQueryData = const MediaQueryData(
        size: Size(400, 900),
      ),
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: mediaQueryData,
              child: Scaffold(
                body: ElevatedButton(
                  onPressed: () => MatchProfilePreviewSheet.show(context, user),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    Future<void> scrollDown(WidgetTester tester, {double delta = 500}) async {
      final listFinder = find.byType(ListView);
      if (listFinder.evaluate().isNotEmpty) {
        await tester.drag(listFinder.first, Offset(0, -delta));
        await tester.pumpAndSettle();
      }
    }

    testWidgets('renders professional name and type', (tester) async {
      await openSheet(tester, professionalUser);

      expect(find.text('Jo\u00E3o Rock'), findsOneWidget);
      expect(find.text('M\u00FAsico'), findsOneWidget);
    });

    testWidgets('renders bio when available', (tester) async {
      await openSheet(tester, professionalUser);

      expect(find.text('Sobre'), findsOneWidget);
      expect(
        find.text('M\u00FAsico apaixonado por rock e blues'),
        findsOneWidget,
      );
    });

    testWidgets('renders nested bio for studio profiles', (tester) async {
      await openSheet(tester, studioUserWithNestedBio);

      expect(find.text('Sobre'), findsOneWidget);
      expect(
        find.text('Bio do estudio salva nos dados internos'),
        findsOneWidget,
      );
    });

    testWidgets('does not render bio section when bio is null', (tester) async {
      await openSheet(tester, minimalUser);

      expect(find.text('Sobre'), findsNothing);
    });

    testWidgets('renders instruments for professional', (tester) async {
      await openSheet(tester, professionalUser);
      await scrollDown(tester);

      expect(find.text('Instrumentos', skipOffstage: false), findsOneWidget);
      expect(find.text('Guitarra', skipOffstage: false), findsOneWidget);
    });

    testWidgets('renders roles for professional', (tester) async {
      await openSheet(tester, professionalUser);
      await scrollDown(tester);

      expect(
        find.text('Fun\u00E7\u00F5es T\u00E9cnicas', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('renders genres for professional', (tester) async {
      await openSheet(tester, professionalUser);
      await scrollDown(tester);

      expect(
        find.text('G\u00EAneros Musicais', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('renders hashtags from matchpoint profile', (tester) async {
      await openSheet(tester, professionalUser);
      await scrollDown(tester, delta: 300);

      expect(find.text('Hashtags', skipOffstage: false), findsOneWidget);
      expect(find.text('#rock_brasil', skipOffstage: false), findsOneWidget);
      expect(find.text('#guitar_hero', skipOffstage: false), findsOneWidget);
    });

    testWidgets('uses safe area and keeps bottom breathing room', (
      tester,
    ) async {
      await openSheet(
        tester,
        professionalUser,
        mediaQueryData: const MediaQueryData(
          size: Size(400, 900),
          viewPadding: EdgeInsets.only(bottom: 28),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView).first);
      final padding = listView.padding! as EdgeInsets;
      expect(find.byType(SafeArea), findsWidgets);
      expect(padding.bottom, AppSpacing.s24);
    });

    testWidgets('does not render hashtags when none exist', (tester) async {
      await openSheet(tester, minimalUser);

      expect(find.text('Hashtags'), findsNothing);
    });

    testWidgets('renders band details correctly', (tester) async {
      await openSheet(tester, bandUser);

      expect(find.text('Os Rockeiros'), findsOneWidget);
      expect(find.text('Banda'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders studio details correctly', (tester) async {
      await openSheet(tester, studioUser);
      await scrollDown(tester);

      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Comercial'), findsOneWidget);
    });

    testWidgets('does NOT render "Iniciar Conversa" button', (tester) async {
      await openSheet(tester, professionalUser);

      expect(find.text('Iniciar Conversa'), findsNothing);
      expect(find.text('Enviar Mensagem'), findsNothing);
    });

    testWidgets('has close button', (tester) async {
      await openSheet(tester, professionalUser);

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('closes on close button tap', (tester) async {
      await openSheet(tester, professionalUser);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Jo\u00E3o Rock'), findsNothing);
    });

    testWidgets('renders subtitle with roles', (tester) async {
      await openSheet(tester, professionalUser);

      expect(find.text('Guitarrista \u2022 Vocalista'), findsOneWidget);
    });

    testWidgets('renders initials fallback when user has no photo', (
      tester,
    ) async {
      await openSheet(tester, minimalUser);

      // minimalUser is a professional without nomeArtistico, so displayName
      // falls back to 'Profissional' → initials 'P'.
      expect(find.text('P'), findsOneWidget);
    });

    testWidgets('does not show gallery when empty', (tester) async {
      await openSheet(tester, minimalUser);

      expect(find.text('Galeria'), findsNothing);
    });
  });
}
