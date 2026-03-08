import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'review_type.dart';

part 'gig_review.freezed.dart';
part 'gig_review.g.dart';

@freezed
abstract class GigReview with _$GigReview {
  const factory GigReview({
    required String id,
    @JsonKey(name: 'gig_id') required String gigId,
    @JsonKey(name: 'reviewer_id') required String reviewerId,
    @JsonKey(name: 'reviewed_user_id') required String reviewedUserId,
    required int rating,
    String? comment,
    @JsonKey(name: 'review_type') required ReviewType reviewType,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _GigReview;

  const GigReview._();

  factory GigReview.fromJson(Map<String, dynamic> json) =>
      _$GigReviewFromJson(json);

  factory GigReview.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GigReview(
      id: doc.id,
      gigId: (data['gig_id'] as String? ?? '').trim(),
      reviewerId: (data['reviewer_id'] as String? ?? '').trim(),
      reviewedUserId: (data['reviewed_user_id'] as String? ?? '').trim(),
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      comment: (data['comment'] as String?)?.trim(),
      reviewType: _parseReviewType(data['review_type'] as String?),
      createdAt: _readReviewDateTime(data['created_at']),
    );
  }
}

DateTime? _readReviewDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

ReviewType _parseReviewType(String? value) {
  return ReviewType.values.firstWhere(
    (item) {
      switch (item) {
        case ReviewType.creatorToParticipant:
          return value == 'creator_to_participant';
        case ReviewType.participantToCreator:
          return value == 'participant_to_creator';
      }
    },
    orElse: () => ReviewType.creatorToParticipant,
  );
}
