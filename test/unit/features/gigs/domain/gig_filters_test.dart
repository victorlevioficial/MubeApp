import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/gigs/domain/gig_filters.dart';
import 'package:mube/src/features/gigs/domain/gig_location_type.dart';

void main() {
  group('GigFilters', () {
    test('default filters are not active', () {
      expect(const GigFilters().hasActiveFilters, isFalse);
    });

    test('marks filters as active when non-default values are set', () {
      const filters = GigFilters(
        term: 'baterista',
        locationTypes: [GigLocationType.remote],
        onlyMine: true,
      );

      expect(filters.hasActiveFilters, isTrue);
    });

    test('clearFilters resets to the default state', () {
      const filters = GigFilters(
        term: 'rock',
        onlyOpenSlots: false,
      );

      expect(filters.clearFilters(), const GigFilters());
      expect(filters.clearFilters().hasActiveFilters, isFalse);
    });
  });
}
