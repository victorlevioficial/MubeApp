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
  static const String search = '/search';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String addresses = '/settings/addresses';
  static const String editAddress = '/settings/address';
  static const String maintenance = '/settings/maintenance';
  static const String privacySettings = '/settings/privacy';
  static const String favorites = '/favorites';
  static const String matchpoint = '/matchpoint';
  static const String matchpointWizard = '/matchpoint/wizard';

  // Dev routes
  static const String gallery = '/gallery';

  /// Routes that don't require authentication.
  static const Set<String> publicRoutes = {splash, login, register, gallery};

  /// Check if a path is a public route.
  // Profile routes
  static const String profile = '/profile';
  static const String publicProfile = '/user';
  static const String profileEdit = '/profile/edit';
  static const String invites = '/profile/invites';
  static const String manageMembers = '/profile/manage-members';
  static const String conversation = '/conversation';
  static const String notifications = '/notifications';

  static bool isPublic(String path) => publicRoutes.contains(path);
}
