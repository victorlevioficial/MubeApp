import 'package:freezed_annotation/freezed_annotation.dart';

import 'compensation_type.dart';
import 'gig_location_type.dart';
import 'gig_status.dart';
import 'gig_type.dart';

part 'gig_filters.freezed.dart';

@freezed
abstract class GigFilters with _$GigFilters {
  const factory GigFilters({
    @Default('') String term,
    @Default([GigStatus.open]) List<GigStatus> statuses,
    @Default([]) List<GigType> gigTypes,
    @Default([]) List<GigLocationType> locationTypes,
    @Default([]) List<CompensationType> compensationTypes,
    @Default([]) List<String> genres,
    @Default([]) List<String> requiredInstruments,
    @Default([]) List<String> requiredCrewRoles,
    @Default([]) List<String> requiredStudioServices,
    @Default(true) bool onlyOpenSlots,
    @Default(false) bool onlyMine,
  }) = _GigFilters;

  const GigFilters._();

  bool get hasActiveFilters =>
      term.trim().isNotEmpty ||
      gigTypes.isNotEmpty ||
      locationTypes.isNotEmpty ||
      compensationTypes.isNotEmpty ||
      genres.isNotEmpty ||
      requiredInstruments.isNotEmpty ||
      requiredCrewRoles.isNotEmpty ||
      requiredStudioServices.isNotEmpty ||
      onlyMine ||
      !onlyOpenSlots ||
      !(statuses.length == 1 && statuses.first == GigStatus.open);

  GigFilters clearFilters() => const GigFilters();
}
