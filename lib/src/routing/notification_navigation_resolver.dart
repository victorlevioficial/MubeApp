import 'route_paths.dart';

/// Resolves the best route available for a notification payload.
///
/// The app prefers a ready-to-use `route`, but older payloads may only expose
/// typed identifiers such as `gig_id` or `reviewed_user_id`.
String? resolveNotificationRouteFromData(Map<String, dynamic> data) {
  return resolveNotificationRoute(
    route: data['route'],
    type: data['type'],
    gigId: data['gigId'] ?? data['gig_id'],
    reviewedUserId: data['reviewedUserId'] ?? data['reviewed_user_id'],
  );
}

String? resolveNotificationRoute({
  Object? route,
  Object? type,
  Object? gigId,
  Object? reviewedUserId,
}) {
  final directRoute = _readNonEmptyString(route);
  if (directRoute != null) return directRoute;

  final normalizedType = _readNonEmptyString(type);
  switch (normalizedType) {
    case 'band_invite':
      return RoutePaths.invites;
    case 'band_invite_accepted':
      return RoutePaths.manageMembers;
  }

  final normalizedGigId = _readNonEmptyString(gigId);
  if (normalizedGigId == null) return null;

  switch (normalizedType) {
    case 'gig_application':
    case 'gig_new_applicant':
      return RoutePaths.gigApplicantsById(normalizedGigId);
    case 'gig_review_reminder':
      final normalizedReviewedUserId = _readNonEmptyString(reviewedUserId);
      if (normalizedReviewedUserId != null) {
        return RoutePaths.gigReviewById(
          normalizedGigId,
          normalizedReviewedUserId,
        );
      }
      return RoutePaths.gigDetailById(normalizedGigId);
    case 'gig_application_accepted':
    case 'gig_application_rejected':
    case 'gig_cancelled':
    case 'gig_matching':
    case 'gig_opportunity':
    case 'gig_expired':
    case null:
      return RoutePaths.gigDetailById(normalizedGigId);
    default:
      return RoutePaths.gigDetailById(normalizedGigId);
  }
}

String? _readNonEmptyString(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
