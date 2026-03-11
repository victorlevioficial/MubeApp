import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/routing/notification_navigation_resolver.dart';
import 'package:mube/src/routing/route_paths.dart';

void main() {
  group('resolveNotificationRouteFromData', () {
    test('prefers the explicit route when it exists', () {
      expect(
        resolveNotificationRouteFromData({
          'type': 'gig_opportunity',
          'route': ' /gigs/gig-123 ',
          'gig_id': 'gig-999',
        }),
        RoutePaths.gigDetailById('gig-123'),
      );
    });

    test('builds applicants route for legacy new applicant payloads', () {
      expect(
        resolveNotificationRouteFromData({
          'type': 'gig_new_applicant',
          'gig_id': 'gig-123',
        }),
        RoutePaths.gigApplicantsById('gig-123'),
      );
    });

    test('builds review route when only gig identifiers are available', () {
      expect(
        resolveNotificationRouteFromData({
          'type': 'gig_review_reminder',
          'gigId': 'gig-123',
          'reviewed_user_id': 'user-456',
        }),
        RoutePaths.gigReviewById('gig-123', 'user-456'),
      );
    });

    test('falls back to band invite routes when route is missing', () {
      expect(
        resolveNotificationRouteFromData({'type': 'band_invite'}),
        RoutePaths.invites,
      );
    });
  });
}
