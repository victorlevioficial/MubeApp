import 'package:flutter_test/flutter_test.dart';
import 'package:mube/main.dart' as app;
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('test basic navigation and app initialization', ($) async {
    // Start the app
    await app.main();
    await $.pumpAndSettle();

    // Depending on auth state, we might be at Login or Home
    // This test just verifies the app starts and can pump frames.

    // Example: If login screen is shown, check for login button
    // expect($(Key('login_button')), findsOneWidget);

    // For a real professional smoke test, we'd verify the app logo or main container
    expect($(app.MubeApp), findsOneWidget);
  });
}
