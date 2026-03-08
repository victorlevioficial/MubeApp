import 'review_type.dart';

class GigReviewOpportunity {
  final String gigId;
  final String gigTitle;
  final String reviewedUserId;
  final String reviewedUserName;
  final String? reviewedUserPhoto;
  final ReviewType reviewType;

  const GigReviewOpportunity({
    required this.gigId,
    required this.gigTitle,
    required this.reviewedUserId,
    required this.reviewedUserName,
    this.reviewedUserPhoto,
    required this.reviewType,
  });
}
