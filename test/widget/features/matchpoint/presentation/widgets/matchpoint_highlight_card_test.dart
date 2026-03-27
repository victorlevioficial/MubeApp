import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/matchpoint/presentation/widgets/matchpoint_highlight_card.dart';

void main() {
  Widget createSubject({required AppUser? user, VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: MatchpointHighlightCard(user: user, onTap: onTap ?? () {}),
      ),
    );
  }

  group('MatchpointHighlightCard', () {
    testWidgets('renders active state for active eligible users', (
      tester,
    ) async {
      const user = AppUser(
        uid: 'professional-1',
        email: 'artist@mube.com',
        tipoPerfil: AppUserType.professional,
        dadosProfissional: {
          'categorias': ['instrumentalist'],
        },
        matchpointProfile: {'is_active': true},
      );

      await tester.pumpWidget(createSubject(user: user));

      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.text('MatchPoint'), findsOneWidget);
      expect(find.text('Abrir MatchPoint'), findsOneWidget);
      expect(
        find.text(
          'Continue explorando perfis, matches e o historico da sua rede.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders pending setup state for eligible inactive users', (
      tester,
    ) async {
      const user = AppUser(
        uid: 'professional-2',
        email: 'artist@mube.com',
        tipoPerfil: AppUserType.professional,
        dadosProfissional: {
          'categorias': ['singer'],
        },
      );

      await tester.pumpWidget(createSubject(user: user));

      expect(find.text('MatchPoint'), findsOneWidget);
      expect(find.text('Ativar MatchPoint'), findsOneWidget);
      expect(
        find.text(
          'Ative seu perfil para entrar no fluxo de descoberta por compatibilidade.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders locked state for ineligible users and fires callback', (
      tester,
    ) async {
      var tapped = false;
      const user = AppUser(
        uid: 'contractor-1',
        email: 'contractor@mube.com',
        tipoPerfil: AppUserType.contractor,
      );

      await tester.pumpWidget(
        createSubject(user: user, onTap: () => tapped = true),
      );

      expect(find.text('MatchPoint'), findsOneWidget);
      expect(find.text('Ver detalhes'), findsOneWidget);
      expect(
        find.text(
          'Disponivel para perfis Profissional e Banda. Abra a area para ver como a feature funciona.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Ver detalhes'));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
