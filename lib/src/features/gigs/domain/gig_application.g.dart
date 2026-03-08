// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GigApplication _$GigApplicationFromJson(Map<String, dynamic> json) =>
    _GigApplication(
      id: json['id'] as String,
      gigId: json['gigId'] as String,
      applicantId: json['applicant_id'] as String,
      message: json['message'] as String,
      status: $enumDecode(_$ApplicationStatusEnumMap, json['status']),
      appliedAt: json['applied_at'] == null
          ? null
          : DateTime.parse(json['applied_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
      gigTitle: json['gigTitle'] as String?,
      gigType: $enumDecodeNullable(_$GigTypeEnumMap, json['gigType']),
      gigStatus: $enumDecodeNullable(_$GigStatusEnumMap, json['gigStatus']),
      creatorId: json['creatorId'] as String?,
    );

Map<String, dynamic> _$GigApplicationToJson(_GigApplication instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gigId': instance.gigId,
      'applicant_id': instance.applicantId,
      'message': instance.message,
      'status': _$ApplicationStatusEnumMap[instance.status]!,
      'applied_at': instance.appliedAt?.toIso8601String(),
      'responded_at': instance.respondedAt?.toIso8601String(),
      'gigTitle': instance.gigTitle,
      'gigType': _$GigTypeEnumMap[instance.gigType],
      'gigStatus': _$GigStatusEnumMap[instance.gigStatus],
      'creatorId': instance.creatorId,
    };

const _$ApplicationStatusEnumMap = {
  ApplicationStatus.pending: 'pending',
  ApplicationStatus.accepted: 'accepted',
  ApplicationStatus.rejected: 'rejected',
  ApplicationStatus.gigCancelled: 'gig_cancelled',
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
