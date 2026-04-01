import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/routing/route_paths.dart';

void main() {
  group('RoutePaths', () {
    test('splash path is root', () {
      expect(RoutePaths.splash, '/');
    });

    test('public routes contains expected paths', () {
      expect(RoutePaths.publicRoutes, contains(RoutePaths.splash));
      expect(RoutePaths.publicRoutes, contains(RoutePaths.login));
      expect(RoutePaths.publicRoutes, contains(RoutePaths.register));
      expect(RoutePaths.publicRoutes, contains(RoutePaths.gallery));
    });

    test('isPublic returns true for public routes', () {
      expect(RoutePaths.isPublic('/'), true);
      expect(RoutePaths.isPublic('/login'), true);
      expect(RoutePaths.isPublic('/register'), true);
      expect(RoutePaths.isPublic('/gallery'), true);
      expect(RoutePaths.isPublic('/legal/termsOfUse'), true);
      expect(RoutePaths.isPublic('/@mubeoficial'), true);
      expect(RoutePaths.isPublic('/profile/user-1'), true);
      expect(RoutePaths.isPublic('/user/user-1'), true);
    });

    test('isPublic returns false for protected routes', () {
      expect(RoutePaths.isPublic('/feed'), false);
      expect(RoutePaths.isPublic('/@'), false);
      expect(RoutePaths.isPublic('/profile'), false);
      expect(RoutePaths.isPublic('/profile/edit'), false);
      expect(RoutePaths.isPublic('/onboarding'), false);
      expect(RoutePaths.isPublic('/onboarding/form'), false);
      expect(RoutePaths.isPublic(RoutePaths.storyCreate), false);
      expect(RoutePaths.isPublic(RoutePaths.storyViewer), false);
      expect(RoutePaths.isPublic(RoutePaths.storyViewers), false);
    });

    test('onboarding form path starts with onboarding', () {
      expect(RoutePaths.onboardingForm.startsWith(RoutePaths.onboarding), true);
    });

    test('all paths start with /', () {
      expect(RoutePaths.splash.startsWith('/'), true);
      expect(RoutePaths.login.startsWith('/'), true);
      expect(RoutePaths.register.startsWith('/'), true);
      expect(RoutePaths.onboarding.startsWith('/'), true);
      expect(RoutePaths.onboardingForm.startsWith('/'), true);
      expect(RoutePaths.feed.startsWith('/'), true);
      expect(RoutePaths.gigs.startsWith('/'), true);
      expect(RoutePaths.profile.startsWith('/'), true);
      expect(RoutePaths.profileEdit.startsWith('/'), true);
      expect(RoutePaths.gallery.startsWith('/'), true);
      expect(RoutePaths.storyCreate.startsWith('/'), true);
      expect(RoutePaths.storyViewer.startsWith('/'), true);
      expect(RoutePaths.storyViewers.startsWith('/'), true);
    });

    test('gig helper routes build expected paths', () {
      expect(RoutePaths.gigCreate, '/gigs/create');
      expect(RoutePaths.gigDetailById('gig-1'), '/gigs/gig-1');
      expect(RoutePaths.gigApplicantsById('gig-1'), '/gigs/gig-1/applicants');
      expect(
        RoutePaths.gigReviewById('gig-1', 'user-1'),
        '/gigs/gig-1/review/user-1',
      );
    });

    test('story helper routes build expected paths', () {
      expect(RoutePaths.storyCreate, '/stories/create');
      expect(RoutePaths.storyViewer, '/stories/viewer');
      expect(RoutePaths.storyViewerById('story-1'), '/stories/viewer/story-1');
      expect(RoutePaths.storyViewers, '/stories/viewers');
      expect(
        RoutePaths.storyViewersById('story-1'),
        '/stories/viewers/story-1',
      );
    });

    test('public profile share helpers build expected paths', () {
      expect(
        RoutePaths.publicProfileSharePathById('user-1'),
        '/profile/user-1',
      );
      expect(
        RoutePaths.publicProfileByUsername('Mube.Oficial'),
        '/@mube.oficial',
      );
      expect(
        RoutePaths.publicProfileSharePath(
          uid: 'user-1',
          username: 'Mube.Oficial',
        ),
        '/@mube.oficial',
      );
      expect(
        RoutePaths.publicProfileShareUrl(
          uid: 'user-1',
          username: 'Mube.Oficial',
        ),
        'https://mubeapp.com.br/@mube.oficial',
      );
      expect(
        RoutePaths.publicProfileShareUrlById('user-1'),
        'https://mubeapp.com.br/profile/user-1',
      );
    });
  });
}
