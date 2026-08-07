import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/splash/presentation/splash_screen.dart';
import 'package:mube/src/features/splash/providers/app_bootstrap_provider.dart';
import 'package:mube/src/features/splash/providers/splash_provider.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('shows the retry fallback when bootstrap stalls', (
      tester,
    ) async {
      // A bootstrap that never settles stands in for a device with no
      // connectivity, which is when users would otherwise stare at a frozen
      // logo with no way out.
      final stalledBootstrap = Completer<void>();
      addTearDown(() {
        if (!stalledBootstrap.isCompleted) stalledBootstrap.complete();
      });

      await tester.pumpApp(
        const SplashScreen(),
        overrides: [
          appCheckBootstrapperProvider.overrideWithValue(
            () => stalledBootstrap.future,
          ),
        ],
      );
      await tester.pump();

      expect(find.text('Tentar novamente'), findsNothing);

      await tester.pump(const Duration(seconds: 11));

      expect(
        find.text('O app está demorando mais que o esperado.'),
        findsOneWidget,
      );
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
    });

    testWidgets('opens the splash gate once bootstrap times out', (
      tester,
    ) async {
      final stalledBootstrap = Completer<void>();
      addTearDown(() {
        if (!stalledBootstrap.isCompleted) stalledBootstrap.complete();
      });

      await tester.pumpApp(
        const SplashScreen(),
        overrides: [
          appCheckBootstrapperProvider.overrideWithValue(
            () => stalledBootstrap.future,
          ),
        ],
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));

      // Bootstrap caps itself at 10s and hands control back rather than
      // blocking forever, so routing is free to leave the splash route.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SplashScreen)),
      );
      expect(container.read(splashFinishedProvider), isTrue);
    });
  });
}
