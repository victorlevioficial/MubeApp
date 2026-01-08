/// Centralized route path constants to avoid magic strings.
abstract final class RoutePaths {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Onboarding routes
  static const String onboarding = '/onboarding';
  static const String onboardingForm = '/onboarding/form';

  // Main app routes (inside shell)
  static const String feed = '/feed';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String addresses = '/settings/addresses';
  static const String editAddress = '/settings/address';

  // Dev routes
  static const String gallery = '/gallery';

  /// Routes that don't require authentication.
  static const Set<String> publicRoutes = {splash, login, register, gallery};

  /// Check if a path is a public route.
  static bool isPublic(String path) => publicRoutes.contains(path);
}
