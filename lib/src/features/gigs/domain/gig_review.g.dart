// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_review.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GigReview _$GigReviewFromJson(Map<String, dynamic> json) => _GigReview(
  id: json['id'] as String,
  gigId: json['gig_id'] as String,
  reviewerId: json['reviewer_id'] as String,
  reviewedUserId: json['reviewed_user_id'] as String,
  rating: (json['rating'] as num).toInt(),
  comment: json['comment'] as String?,
  reviewType: $enumDecode(_$ReviewTypeEnumMap, json['review_type']),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$GigReviewToJson(_GigReview instance) =>
    <String, dynamic>{
      'id': instance.id,
      'gig_id': instance.gigId,
      'reviewer_id': instance.reviewerId,
      'reviewed_user_id': instance.reviewedUserId,
      'rating': instance.rating,
      'comment': instance.comment,
      'review_type': _$ReviewTypeEnumMap[instance.reviewType]!,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$ReviewTypeEnumMap = {
  ReviewType.creatorToParticipant: 'creator_to_participant',
  ReviewType.participantToCreator: 'participant_to_creator',
};
