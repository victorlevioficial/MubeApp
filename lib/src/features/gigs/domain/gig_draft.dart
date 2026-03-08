import 'package:freezed_annotation/freezed_annotation.dart';

import 'compensation_type.dart';
import 'gig_date_mode.dart';
import 'gig_location_type.dart';
import 'gig_type.dart';

part 'gig_draft.freezed.dart';

@freezed
abstract class GigDraft with _$GigDraft {
  const factory GigDraft({
    required String title,
    required String description,
    required GigType gigType,
    required GigDateMode dateMode,
    DateTime? gigDate,
    required GigLocationType locationType,
    Map<String, dynamic>? location,
    String? geohash,
    @Default([]) List<String> genres,
    @Default([]) List<String> requiredInstruments,
    @Default([]) List<String> requiredCrewRoles,
    @Default([]) List<String> requiredStudioServices,
    required int slotsTotal,
    required CompensationType compensationType,
    int? compensationValue,
  }) = _GigDraft;

  const GigDraft._();

  bool get requiresFixedDate => dateMode == GigDateMode.fixedDate;
}

@freezed
abstract class GigUpdate with _$GigUpdate {
  const factory GigUpdate({
    String? title,
    String? description,
    GigType? gigType,
    GigDateMode? dateMode,
    DateTime? gigDate,
    @Default(false) bool clearGigDate,
    GigLocationType? locationType,
    Map<String, dynamic>? location,
    String? geohash,
    @Default(false) bool clearLocation,
    List<String>? genres,
    List<String>? requiredInstruments,
    List<String>? requiredCrewRoles,
    List<String>? requiredStudioServices,
    int? slotsTotal,
    CompensationType? compensationType,
    int? compensationValue,
    @Default(false) bool clearCompensationValue,
  }) = _GigUpdate;
}

@freezed
abstract class GigReviewDraft with _$GigReviewDraft {
  const factory GigReviewDraft({
    required String gigId,
    required String reviewedUserId,
    required int rating,
    String? comment,
  }) = _GigReviewDraft;
}
