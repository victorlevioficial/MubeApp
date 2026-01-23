import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

export 'pump_app.dart';

/// Common test utilities and mocks.

/// A simple fake navigator observer for testing navigation.
class FakeNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];
  final List<Route<dynamic>> poppedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    poppedRoutes.add(route);
  }
}

/// Creates a test provider container with optional overrides.
ProviderContainer createTestContainer({List<dynamic> overrides = const []}) {
  return ProviderContainer(overrides: overrides.cast());
}

/// A simple mock user for testing.
class MockUserData {
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'password123';
  static const String testUid = 'test-uid-12345';
  static const String testName = 'Test User';
}

/// Finder helpers for common widgets.
extension AppCommonFinders on CommonFinders {
  /// Finds a widget by its semantic label.
  Finder bySemanticsLabel(String label) => find.bySemanticsLabel(label);

  /// Finds a TextFormField by its label text.
  Finder textFieldByLabel(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(TextFormField));
}
