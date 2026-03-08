import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/compensation_type.dart';
import '../../domain/gig_filters.dart';
import '../../domain/gig_location_type.dart';

part 'gig_filters_controller.g.dart';

@riverpod
class GigFiltersController extends _$GigFiltersController {
  @override
  GigFilters build() => const GigFilters();

  void updateFilters(GigFilters next) {
    state = next;
  }

  void clearFilters() {
    state = state.clearFilters();
  }

  void setLocationFilter(List<GigLocationType> next) {
    state = state.copyWith(locationTypes: next);
  }

  void setCompensationFilter(List<CompensationType> next) {
    state = state.copyWith(compensationTypes: next);
  }
}
