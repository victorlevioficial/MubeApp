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
    });

    test('isPublic returns false for protected routes', () {
      expect(RoutePaths.isPublic('/feed'), false);
      expect(RoutePaths.isPublic('/profile'), false);
      expect(RoutePaths.isPublic('/profile/edit'), false);
      expect(RoutePaths.isPublic('/onboarding'), false);
      expect(RoutePaths.isPublic('/onboarding/form'), false);
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
      expect(RoutePaths.profile.startsWith('/'), true);
      expect(RoutePaths.profileEdit.startsWith('/'), true);
      expect(RoutePaths.gallery.startsWith('/'), true);
    });
  });
}
