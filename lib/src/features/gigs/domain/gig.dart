import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'compensation_type.dart';
import 'gig_date_mode.dart';
import 'gig_location_type.dart';
import 'gig_status.dart';
import 'gig_type.dart';

part 'gig.freezed.dart';
part 'gig.g.dart';

@freezed
abstract class Gig with _$Gig {
  const factory Gig({
    required String id,
    required String title,
    required String description,
    @JsonKey(name: 'gig_type') required GigType gigType,
    @JsonKey(name: 'status') required GigStatus status,
    @JsonKey(name: 'date_mode') required GigDateMode dateMode,
    @JsonKey(name: 'gig_date') DateTime? gigDate,
    @JsonKey(name: 'location_type') required GigLocationType locationType,
    Map<String, dynamic>? location,
    String? geohash,
    @Default([]) List<String> genres,
    @JsonKey(name: 'required_instruments')
    @Default([])
    List<String> requiredInstruments,
    @JsonKey(name: 'required_crew_roles')
    @Default([])
    List<String> requiredCrewRoles,
    @JsonKey(name: 'required_studio_services')
    @Default([])
    List<String> requiredStudioServices,
    @JsonKey(name: 'slots_total') required int slotsTotal,
    @JsonKey(name: 'slots_filled') @Default(0) int slotsFilled,
    @JsonKey(name: 'compensation_type')
    required CompensationType compensationType,
    @JsonKey(name: 'compensation_value') int? compensationValue,
    @JsonKey(name: 'creator_id') required String creatorId,
    @JsonKey(name: 'applicant_count') @Default(0) int applicantCount,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'expires_at') DateTime? expiresAt,
  }) = _Gig;

  const Gig._();

  factory Gig.fromJson(Map<String, dynamic> json) => _$GigFromJson(json);

  factory Gig.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Gig(
      id: doc.id,
      title: (data['title'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      gigType: _parseGigType(data['gig_type'] as String?),
      status: _parseGigStatus(data['status'] as String?),
      dateMode: _parseGigDateMode(data['date_mode'] as String?),
      gigDate: _readDateTime(data['gig_date']),
      locationType: _parseGigLocationType(data['location_type'] as String?),
      location: data['location'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(data['location'] as Map<String, dynamic>)
          : null,
      geohash: data['geohash'] as String?,
      genres: _readStringList(data['genres']),
      requiredInstruments: _readStringList(data['required_instruments']),
      requiredCrewRoles: _readStringList(data['required_crew_roles']),
      requiredStudioServices: _readStringList(data['required_studio_services']),
      slotsTotal: (data['slots_total'] as num?)?.toInt() ?? 1,
      slotsFilled: (data['slots_filled'] as num?)?.toInt() ?? 0,
      compensationType: _parseCompensationType(
        data['compensation_type'] as String?,
      ),
      compensationValue: (data['compensation_value'] as num?)?.toInt(),
      creatorId: (data['creator_id'] as String? ?? '').trim(),
      applicantCount: (data['applicant_count'] as num?)?.toInt() ?? 0,
      createdAt: _readDateTime(data['created_at']),
      updatedAt: _readDateTime(data['updated_at']),
      expiresAt: _readDateTime(data['expires_at']),
    );
  }

  int get availableSlots {
    final remaining = slotsTotal - slotsFilled;
    return remaining < 0 ? 0 : remaining;
  }

  bool get isFull => availableSlots <= 0;

  bool get isExpiredByDate {
    if (dateMode != GigDateMode.fixedDate || gigDate == null) return false;
    return gigDate!.isBefore(DateTime.now());
  }

  bool get canEditAllFields => applicantCount == 0 && status == GigStatus.open;

  bool get canEditDescriptionOnly =>
      applicantCount > 0 && status == GigStatus.open;

  String get displayCompensation {
    switch (compensationType) {
      case CompensationType.fixed:
        final value = compensationValue;
        if (value == null) return 'Cache fixo';
        return 'R\$ $value';
      case CompensationType.negotiable:
        return 'A negociar';
      case CompensationType.volunteer:
        return 'Voluntario';
      case CompensationType.toBeDefined:
        return 'A definir';
    }
  }
}

DateTime? _readDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

GigType _parseGigType(String? value) {
  return GigType.values.firstWhere(
    (item) => item.toJsonValue() == value,
    orElse: () => GigType.other,
  );
}

GigStatus _parseGigStatus(String? value) {
  return GigStatus.values.firstWhere(
    (item) => item.toJsonValue() == value,
    orElse: () => GigStatus.open,
  );
}

GigDateMode _parseGigDateMode(String? value) {
  return GigDateMode.values.firstWhere(
    (item) => item.toJsonValue() == value,
    orElse: () => GigDateMode.unspecified,
  );
}

GigLocationType _parseGigLocationType(String? value) {
  return GigLocationType.values.firstWhere(
    (item) => item.toJsonValue() == value,
    orElse: () => GigLocationType.onsite,
  );
}

CompensationType _parseCompensationType(String? value) {
  return CompensationType.values.firstWhere(
    (item) => item.toJsonValue() == value,
    orElse: () => CompensationType.toBeDefined,
  );
}

extension _GigEnumJson on Object {
  String toJsonValue() {
    final annotation = (this as dynamic).toString();
    switch (this) {
      case GigType.liveShow:
        return 'show_ao_vivo';
      case GigType.privateEvent:
        return 'evento_privado';
      case GigType.recording:
        return 'gravacao';
      case GigType.rehearsalJam:
        return 'ensaio_jam';
      case GigType.other:
        return 'outro';
      case GigStatus.open:
        return 'open';
      case GigStatus.closed:
        return 'closed';
      case GigStatus.expired:
        return 'expired';
      case GigStatus.cancelled:
        return 'cancelled';
      case GigDateMode.fixedDate:
        return 'fixed_date';
      case GigDateMode.toBeArranged:
        return 'to_be_arranged';
      case GigDateMode.unspecified:
        return 'unspecified';
      case GigLocationType.onsite:
        return 'presencial';
      case GigLocationType.remote:
        return 'remoto';
      case CompensationType.fixed:
        return 'fixed';
      case CompensationType.negotiable:
        return 'negotiable';
      case CompensationType.volunteer:
        return 'volunteer';
      case CompensationType.toBeDefined:
        return 'tbd';
      default:
        return annotation;
    }
  }
}
