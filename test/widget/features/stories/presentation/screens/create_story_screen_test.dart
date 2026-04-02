import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/design_system/foundations/tokens/app_colors.dart';
import 'package:mube/src/features/stories/presentation/controllers/story_compose_controller.dart';
import 'package:mube/src/features/stories/presentation/screens/create_story_screen.dart';

import '../../../../../helpers/pump_app.dart';

class _TestStoryComposeController extends StoryComposeController {
  _TestStoryComposeController(this._initialState);

  final StoryComposeState _initialState;

  @override
  StoryComposeState build() => _initialState;
}

void main() {
  group('CreateStoryScreen', () {
    testWidgets('renders the minimal initial compose state', (tester) async {
      await tester.pumpApp(const CreateStoryScreen());
      await tester.pump();

      expect(find.text('Novo story'), findsOneWidget);
      expect(find.text('Escolha uma foto ou video.'), findsOneWidget);
      expect(find.text('MIDIA'), findsNothing);
      expect(find.text('PREVIEW'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Sem midia selecionada'),
        250,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sem midia selecionada'), findsOneWidget);
      expect(find.text('Seu story vai aparecer aqui'), findsOneWidget);
      expect(find.text('Legenda'), findsNothing);

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, AppColors.background);
    });

    testWidgets('shows publish progress when a story is being sent', (
      tester,
    ) async {
      await tester.pumpApp(
        const CreateStoryScreen(),
        overrides: [
          storyComposeControllerProvider.overrideWith(
            () => _TestStoryComposeController(
              const StoryComposeState(
                isPublishing: true,
                publishProgress: 0.58,
                publishStatus: 'Enviando story',
              ),
            ),
          ),
        ],
      );
      await tester.pump();

      expect(find.text('Enviando story'), findsOneWidget);
      expect(find.text('58%'), findsOneWidget);

      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, 0.58);
    });
  });
}
