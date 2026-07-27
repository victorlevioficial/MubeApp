import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mube/main.dart' as app;
import 'package:mube/src/app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts the app with the standard integration binding', (
    tester,
  ) async {
    final originalFlutterErrorHandler = FlutterError.onError;
    final originalPlatformErrorHandler = PlatformDispatcher.instance.onError;
    final originalErrorWidgetBuilder = ErrorWidget.builder;

    try {
      app.main();
      // The production app contains continuous animations, so pump a bounded
      // startup window instead of waiting for the frame scheduler to go idle.
      await tester.pump();
      for (var attempt = 0; attempt < 20; attempt++) {
        if (find.byType(MubeApp).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 250));
      }

      // Authentication state is intentionally not assumed here. This smoke
      // test verifies that the production entrypoint boots with the standard
      // integration binding.
      expect(find.byType(MubeApp), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      FlutterError.onError = originalFlutterErrorHandler;
      PlatformDispatcher.instance.onError = originalPlatformErrorHandler;
      ErrorWidget.builder = originalErrorWidgetBuilder;
    }
  });
}
