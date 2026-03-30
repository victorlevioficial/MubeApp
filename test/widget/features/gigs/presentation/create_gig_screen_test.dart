import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/design_system/components/buttons/app_button.dart';
import 'package:mube/src/features/gigs/data/gig_repository.dart';
import 'package:mube/src/features/gigs/domain/gig_draft.dart';
import 'package:mube/src/features/gigs/presentation/screens/create_gig_screen.dart';

class _RecordingGigRepository extends Fake implements GigRepository {
  int createGigCalls = 0;

  @override
  Future<String> createGig(GigDraft draft) async {
    createGigCalls += 1;
    return 'gig-1';
  }
}

void main() {
  testWidgets('shows explicit date validation feedback before publishing', (
    tester,
  ) async {
    final repository = _RecordingGigRepository();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWith((ref) async => const AppConfig()),
          gigRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: scaffoldMessengerKey,
          home: const CreateGigScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).at(0), 'Procuro baixista');
    await tester.enterText(
      find.byType(EditableText).at(1),
      'Show teste com repertorio fechado e passagem de som completa.',
    );

    await tester.dragUntilVisible(
      find.byType(AppButton),
      find.byType(ListView),
      const Offset(0, -400),
    );
    final publishButton = tester.widget<AppButton>(find.byType(AppButton));
    publishButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(find.text('Selecione a data da gig.'), findsWidgets);
    expect(repository.createGigCalls, 0);
  });
}
