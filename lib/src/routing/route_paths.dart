import '../utils/public_username.dart';

/// Centralized route path constants to avoid magic strings.
abstract final class RoutePaths {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/verify-email';

  // Onboarding routes
  static const String onboarding = '/onboarding';
  static const String onboardingForm = '/onboarding/form';
  static const String notificationPermission = '/onboarding/notifications';

  // Main app routes (inside shell)
  static const String feed = '/feed';
  static const String search = '/search';
  static const String gigs = '/gigs';
  static const String chat = '/chat';
  static const String settings = '/settings';
  static const String settingsMyGigs = '/settings/my-gigs';
  static const String settingsMyApplications = '/settings/my-applications';
  static const String addresses = '/settings/addresses';
  static const String privacySettings = '/settings/privacy';
  static const String blockedUsers = '/settings/blocked-users';
  static const String receivedFavorites = '/settings/received-favorites';
  static const String favorites = '/favorites';
  static const String matchpoint = '/matchpoint';
  static const String matchpointWizard = '/matchpoint/wizard';
  static const String matchpointHistory = '/matchpoint/history';
  static const String legal = '/legal';
  static const String support = '/settings/support';
  static const String supportCreate = 'create-ticket'; // relative to support
  static const String supportTickets = 'my-tickets'; // relative to support
  static const String supportDropdownCompare =
      'dropdown-compare'; // relative to support
  static const String supportTicketDetail =
      'ticket/:ticketId'; // relative to supportTickets
  static const List<String> _shellRouteRoots = <String>[
    feed,
    search,
    gigs,
    chat,
    settings,
  ];

  static const String gallery = '/gallery';
  static const String feedList = '/feed/list';

  /// Routes that don't require authentication.
  static const Set<String> publicRoutes = {
    splash,
    login,
    register,
    forgotPassword,
    gallery,
    legal,
  };

  static const List<String> _publicRoutePrefixes = <String>['$legal/'];
  static const Set<String> _reservedProfileRouteSegments = <String>{
    'edit',
    'invites',
    'manage-members',
  };

  /// Check if a path is a public route.
  // Profile routes
  static const String profile = '/profile';
  static const String publicProfile = '/user';
  static const String publicProfileHandleRoute = '/@:username';
  static const String profileEdit = '/profile/edit';
  static const String invites = '/profile/invites';
  static const String manageMembers = '/profile/manage-members';
  static const String conversation = '/conversation';
  static const String notifications = '/notifications';
  static const String gigCreate = '/gigs/create';

  static String publicProfileById(String uid) => '$publicProfile/$uid';
  static String publicProfileByUsername(String username) =>
      '/${publicUsernameHandle(username)}';
  static String publicProfileSharePathById(String uid) => '$profile/$uid';
  static String publicProfileSharePath({
    required String uid,
    String? username,
  }) {
    final normalizedUsername = normalizedPublicUsernameOrNull(username);
    if (normalizedUsername != null &&
        isValidPublicUsername(normalizedUsername)) {
      return publicProfileByUsername(normalizedUsername);
    }
    return publicProfileSharePathById(uid);
  }

  static String publicProfileShareUrlById(String uid) => Uri(
    scheme: 'https',
    host: 'mubeapp.com.br',
    path: publicProfileSharePathById(uid),
  ).toString();
  static String publicProfileShareUrl({
    required String uid,
    String? username,
  }) =>
      'https://mubeapp.com.br${publicProfileSharePath(uid: uid, username: username)}';
  static String gigDetailById(String gigId) => '$gigs/$gigId';
  static String gigApplicantsById(String gigId) =>
      '${gigDetailById(gigId)}/applicants';
  static String gigReviewById(String gigId, String userId) =>
      '${gigDetailById(gigId)}/review/$userId';

  static String conversationById(String conversationId) =>
      '$conversation/$conversationId';

  static String supportCreatePath() => '$support/$supportCreate';

  static String supportTicketsPath() => '$support/$supportTickets';

  static String supportTicketDetailById(String ticketId) =>
      '${supportTicketsPath()}/ticket/$ticketId';

  static String legalDetail(String type) => '$legal/$type';

  static bool isShellBranchPath(String path) {
    final normalizedPath = Uri.parse(path).path;
    return _shellRouteRoots.any(
      (root) =>
          normalizedPath == root || normalizedPath.startsWith('$root/'),
    );
  }

  /// Extra key used to pass avatar Hero tags across profile navigations.
  static const String avatarHeroTagExtraKey = 'avatarHeroTag';

  static bool isPublic(String path) =>
      publicRoutes.contains(path) ||
      _isPublicHandlePath(path) ||
      _isPublicProfilePath(path) ||
      _publicRoutePrefixes.any((prefix) => path.startsWith(prefix));

  static bool _isPublicHandlePath(String path) {
    final segments = Uri.parse(path).pathSegments;
    if (segments.length != 1) {
      return false;
    }

    final segment = segments.first;
    if (!segment.startsWith('@') || segment.length <= 1) {
      return false;
    }

    return validatePublicUsername(segment.substring(1), allowEmpty: false) ==
        null;
  }

  static bool _isPublicProfilePath(String path) {
    final segments = Uri.parse(path).pathSegments;
    if (segments.length != 2) {
      return false;
    }

    final root = segments.first;
    final identifier = segments.last;
    if (identifier.isEmpty) {
      return false;
    }

    if (root == publicProfile.replaceFirst('/', '')) {
      return true;
    }

    if (root != profile.replaceFirst('/', '')) {
      return false;
    }

    return !_reservedProfileRouteSegments.contains(identifier);
  }
}
