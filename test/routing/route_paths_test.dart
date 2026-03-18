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
    });

    test('onboarding form path starts with onboarding', () {
      expect(RoutePaths.onboardingForm.startsWith(RoutePaths.onboarding), true);
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
