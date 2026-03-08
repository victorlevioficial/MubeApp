// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Gig _$GigFromJson(Map<String, dynamic> json) => _Gig(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  gigType: $enumDecode(_$GigTypeEnumMap, json['gig_type']),
  status: $enumDecode(_$GigStatusEnumMap, json['status']),
  dateMode: $enumDecode(_$GigDateModeEnumMap, json['date_mode']),
  gigDate: json['gig_date'] == null
      ? null
      : DateTime.parse(json['gig_date'] as String),
  locationType: $enumDecode(_$GigLocationTypeEnumMap, json['location_type']),
  location: json['location'] as Map<String, dynamic>?,
  geohash: json['geohash'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  requiredInstruments:
      (json['required_instruments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  requiredCrewRoles:
      (json['required_crew_roles'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  requiredStudioServices:
      (json['required_studio_services'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  slotsTotal: (json['slots_total'] as num).toInt(),
  slotsFilled: (json['slots_filled'] as num?)?.toInt() ?? 0,
  compensationType: $enumDecode(
    _$CompensationTypeEnumMap,
    json['compensation_type'],
  ),
  compensationValue: (json['compensation_value'] as num?)?.toInt(),
  creatorId: json['creator_id'] as String,
  applicantCount: (json['applicant_count'] as num?)?.toInt() ?? 0,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
);

Map<String, dynamic> _$GigToJson(_Gig instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'gig_type': _$GigTypeEnumMap[instance.gigType]!,
  'status': _$GigStatusEnumMap[instance.status]!,
  'date_mode': _$GigDateModeEnumMap[instance.dateMode]!,
  'gig_date': instance.gigDate?.toIso8601String(),
  'location_type': _$GigLocationTypeEnumMap[instance.locationType]!,
  'location': instance.location,
  'geohash': instance.geohash,
  'genres': instance.genres,
  'required_instruments': instance.requiredInstruments,
  'required_crew_roles': instance.requiredCrewRoles,
  'required_studio_services': instance.requiredStudioServices,
  'slots_total': instance.slotsTotal,
  'slots_filled': instance.slotsFilled,
  'compensation_type': _$CompensationTypeEnumMap[instance.compensationType]!,
  'compensation_value': instance.compensationValue,
  'creator_id': instance.creatorId,
  'applicant_count': instance.applicantCount,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'expires_at': instance.expiresAt?.toIso8601String(),
};

const _$GigTypeEnumMap = {
  GigType.liveShow: 'show_ao_vivo',
  GigType.privateEvent: 'evento_privado',
  GigType.recording: 'gravacao',
  GigType.rehearsalJam: 'ensaio_jam',
  GigType.other: 'outro',
};

const _$GigStatusEnumMap = {
  GigStatus.open: 'open',
  GigStatus.closed: 'closed',
  GigStatus.expired: 'expired',
  GigStatus.cancelled: 'cancelled',
};

const _$GigDateModeEnumMap = {
  GigDateMode.fixedDate: 'fixed_date',
  GigDateMode.toBeArranged: 'to_be_arranged',
  GigDateMode.unspecified: 'unspecified',
};

const _$GigLocationTypeEnumMap = {
  GigLocationType.onsite: 'presencial',
  GigLocationType.remote: 'remoto',
};

const _$CompensationTypeEnumMap = {
  CompensationType.fixed: 'fixed',
  CompensationType.negotiable: 'negotiable',
  CompensationType.volunteer: 'volunteer',
  CompensationType.toBeDefined: 'tbd',
};
