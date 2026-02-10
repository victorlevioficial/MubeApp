import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/app.dart' show scaffoldMessengerKey;

/// Extension to simplify widget testing with Riverpod.
extension PumpApp on WidgetTester {
  /// Pumps the widget with MaterialApp and ProviderScope.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpApp(const MyWidget());
  /// ```
  Future<void> pumpApp(
    Widget widget, {
    List<dynamic> overrides = const [],
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides.cast(),
        child: MaterialApp(
          home: widget,
          theme: ThemeData.dark(),
          scaffoldMessengerKey: scaffoldMessengerKey,
        ),
      ),
    );
  }

  /// Pumps the widget and waits for all animations/futures to settle.
  Future<void> pumpAppAndSettle(Widget widget) async {
    await pumpApp(widget);
    await pumpAndSettle();
  }
}
