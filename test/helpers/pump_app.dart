import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extension to simplify widget testing with Riverpod.
extension PumpApp on WidgetTester {
  /// Pumps the widget with MaterialApp and ProviderScope.
  ///
  /// Example:
  /// ```dart
  /// await tester.pumpApp(const MyWidget());
  /// ```
  Future<void> pumpApp(Widget widget) async {
    await pumpWidget(
      ProviderScope(
        child: MaterialApp(home: widget, theme: ThemeData.dark()),
      ),
    );
  }

  /// Pumps the widget and waits for all animations/futures to settle.
  Future<void> pumpAppAndSettle(Widget widget) async {
    await pumpApp(widget);
    await pumpAndSettle();
  }
}
