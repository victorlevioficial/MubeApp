import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';

void main() {
  test('uses no-op analytics in tests without initializing Firebase', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(analyticsServiceProvider),
      isA<NoopAnalyticsService>(),
    );
  });
}
