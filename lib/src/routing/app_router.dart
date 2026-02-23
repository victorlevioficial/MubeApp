import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/analytics/analytics_provider.dart';
import '../design_system/components/navigation/main_scaffold.dart';
import '../features/admin/presentation/maintenance_screen.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/user_type.dart';
import '../features/auth/presentation/email_verification_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/bands/presentation/manage_members_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/chat/presentation/conversations_screen.dart';
import '../features/developer/presentation/developer_tools_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/feed/domain/feed_section.dart';
import '../features/feed/presentation/feed_list_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/gallery/presentation/design_system_gallery_screen.dart';
import '../features/legal/presentation/legal_detail_screen.dart';
import '../features/matchpoint/presentation/screens/matchpoint_setup_wizard_screen.dart';
import '../features/matchpoint/presentation/screens/matchpoint_wrapper_screen.dart';
import '../features/matchpoint/presentation/screens/swipe_history_screen.dart';
import '../features/notifications/presentation/notification_list_screen.dart';
import '../features/onboarding/presentation/onboarding_form_screen.dart';
import '../features/onboarding/presentation/onboarding_type_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/invites_screen.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/domain/saved_address.dart';
import '../features/settings/presentation/addresses_screen.dart';
import '../features/settings/presentation/blocked_users_screen.dart';
import '../features/settings/presentation/edit_address_screen.dart';
import '../features/settings/presentation/privacy_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/support/domain/ticket_model.dart';
import '../features/support/presentation/create_ticket_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/support/presentation/ticket_detail_screen.dart';
import '../features/support/presentation/ticket_list_screen.dart';
import 'auth_guard.dart';
import 'route_paths.dart';

/// Notifier to trigger router refresh when auth/profile state changes.
class _GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Main router provider.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _GoRouterRefreshNotifier();
  final authGuard = AuthGuard(ref);
  final analyticsObserver = ref.read(analyticsServiceProvider).getObserver();

  // Listen to state changes to trigger route re-evaluation
  ref.listen(authStateChangesProvider, (_, _) => notifier.notify());
  ref.listen(currentUserProfileProvider, (_, _) => notifier.notify());

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: authGuard.redirect,
    observers: [analyticsObserver],
    routes: _buildRoutes(ref),
  );
});

/// Builds the route tree. Separated for readability.
List<RouteBase> _buildRoutes(Ref ref) {
  return [
    GoRoute(
      path: '/developer-tools',
      builder: (context, state) => const DeveloperToolsScreen(),
    ),

    // Root alias route to avoid rendering a second in-app splash.
    GoRoute(
      path: RoutePaths.splash,
      redirect: (context, state) => RoutePaths.login,
    ),

    // Auth routes
    GoRoute(
      path: RoutePaths.login,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
    ),
    GoRoute(
      path: RoutePaths.register,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const RegisterScreen()),
    ),
    GoRoute(
      path: RoutePaths.forgotPassword,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const ForgotPasswordScreen(),
      ),
    ),
    GoRoute(
      path: RoutePaths.emailVerification,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const EmailVerificationScreen(),
      ),
    ),

    // Onboarding routes
    GoRoute(
      path: RoutePaths.onboarding,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const OnboardingTypeScreen(),
      ),
      routes: [
        GoRoute(
          path: 'form',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const OnboardingFormScreen(),
          ),
        ),
      ],
    ),

    // Main app shell with bottom navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // Feed tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.feed,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const FeedScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'list',
                  pageBuilder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>?;
                    final type =
                        extra?['type'] as FeedSectionType? ??
                        FeedSectionType.artists;
                    return NoTransitionPage(
                      key: state.pageKey,
                      child: FeedListScreen(sectionType: type),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // Search tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.search,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SearchScreen(),
              ),
            ),
          ],
        ),
        // MatchPoint tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.matchpoint,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: MatchpointWrapperScreen()),
              routes: [
                GoRoute(
                  path: 'history',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const SwipeHistoryScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Chat tab (replaced Perfil)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.chat,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const ConversationsScreen(),
              ),
              routes: const [],
            ),
          ],
        ),
        // Settings tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.settings,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'addresses',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const AddressesScreen(),
                  ),
                ),
                GoRoute(
                  path: 'maintenance',
                  redirect: (context, state) =>
                      kDebugMode ? null : RoutePaths.settings,
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const MaintenanceScreen(),
                  ),
                ),
                GoRoute(
                  path: 'address',
                  pageBuilder: (context, state) {
                    final address = state.extra as SavedAddress?;
                    return NoTransitionPage(
                      key: state.pageKey,
                      child: EditAddressScreen(existingAddress: address),
                    );
                  },
                ),
                GoRoute(
                  path: 'privacy',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const PrivacySettingsScreen(),
                  ),
                ),
                GoRoute(
                  path: 'blocked-users',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const BlockedUsersScreen(),
                  ),
                ),
                GoRoute(
                  path: 'support',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const SupportScreen(),
                  ),
                  routes: [
                    GoRoute(
                      path: RoutePaths.supportCreate,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const CreateTicketScreen(),
                      ),
                    ),
                    GoRoute(
                      path: RoutePaths.supportTickets,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const TicketListScreen(),
                      ),
                      routes: [
                        GoRoute(
                          path: RoutePaths.supportTicketDetail,
                          pageBuilder: (context, state) {
                            final ticketId = state.pathParameters['ticketId']!;
                            final ticket = state.extra as Ticket?;
                            return NoTransitionPage(
                              key: state.pageKey,
                              child: TicketDetailScreen(
                                ticketId: ticketId,
                                ticketObj: ticket,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Search screen - Temporarily disabled
    // GoRoute(
    //   path: '/search',
    //   pageBuilder: (context, state) =>
    //       NoTransitionPage(key: state.pageKey, child: const SearchScreen()),
    // ),

    // Favorites screen removed

    // Dev gallery (design system showcase)
    GoRoute(
      path: RoutePaths.gallery,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const DesignSystemGalleryScreen(),
      ),
    ),

    // Public profile view
    GoRoute(
      path: '/user/:uid',
      pageBuilder: (context, state) {
        final uid = state.pathParameters['uid']!;
        return NoTransitionPage(
          key: state.pageKey,
          child: PublicProfileScreen(uid: uid),
        );
      },
    ),

    // Chat Conversation Screen (Top-level to hide bottom bar)
    GoRoute(
      path: '${RoutePaths.conversation}/:conversationId',
      pageBuilder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        // Pass extra data if available
        final extra = state.extra as Map<String, dynamic>?;
        return NoTransitionPage(
          key: state.pageKey,
          child: ChatScreen(
            conversationId: conversationId,
            extra: extra, // Pass extra to ChatScreen
          ),
        );
      },
    ),

    // Edit Profile Route
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const EditProfileScreen(),
      ),
    ),
    GoRoute(
      path: RoutePaths.invites,
      pageBuilder: (context, state) {
        // Smart Redirect: Band -> ManageMembers, Others -> Invites
        final user = ref.read(currentUserProfileProvider).value;
        if (user != null && user.tipoPerfil == AppUserType.band) {
          return NoTransitionPage(
            key: state.pageKey,
            child: const ManageMembersScreen(),
          );
        }
        return NoTransitionPage(
          key: state.pageKey,
          child: const InvitesScreen(),
        );
      },
    ),

    // Manage Members Screen (Still accessible directly if needed, but redirects prefer above)
    GoRoute(
      path: RoutePaths.manageMembers,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const ManageMembersScreen(),
      ),
    ),

    // Favorites Screen
    GoRoute(
      path: RoutePaths.favorites,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const FavoritesScreen()),
    ),
    // MatchPoint Wizard
    GoRoute(
      path: RoutePaths.matchpointWizard,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const MatchpointSetupWizardScreen(),
      ),
    ),

    // Notifications List
    GoRoute(
      path: RoutePaths.notifications,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const NotificationListScreen(),
      ),
    ),
    GoRoute(
      path: '${RoutePaths.legal}/:type',
      builder: (context, state) {
        final typeStr = state.pathParameters['type'];
        final type = LegalDocumentType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => LegalDocumentType.termsOfUse,
        );
        return LegalDetailScreen(type: type);
      },
    ),
  ];
}
