import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/analytics/analytics_provider.dart';
import '../design_system/components/navigation/main_scaffold.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/domain/app_user.dart';
import '../features/auth/domain/user_type.dart';
import '../features/auth/presentation/email_verification_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/bands/presentation/manage_members_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/chat/presentation/conversations_screen.dart';
import '../features/favorites/presentation/favorites_screen.dart';
import '../features/favorites/presentation/received_favorites_screen.dart';
import '../features/feed/domain/feed_section.dart';
import '../features/feed/presentation/feed_list_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/gallery/presentation/design_system_gallery_screen.dart';
import '../features/gigs/domain/gig.dart';
import '../features/gigs/presentation/screens/create_gig_screen.dart';
import '../features/gigs/presentation/screens/gig_applicants_screen.dart';
import '../features/gigs/presentation/screens/gig_detail_screen.dart';
import '../features/gigs/presentation/screens/gig_review_screen.dart';
import '../features/gigs/presentation/screens/gigs_screen.dart';
import '../features/gigs/presentation/screens/my_applications_screen.dart';
import '../features/gigs/presentation/screens/my_gigs_screen.dart';
import '../features/legal/presentation/legal_detail_screen.dart';
import '../features/matchpoint/presentation/screens/matchpoint_setup_wizard_screen.dart';
import '../features/matchpoint/presentation/screens/matchpoint_wrapper_screen.dart';
import '../features/matchpoint/presentation/screens/swipe_history_screen.dart';
import '../features/notifications/presentation/notification_list_screen.dart';
import '../features/onboarding/presentation/notification_permission_screen.dart';
import '../features/onboarding/presentation/onboarding_form_screen.dart';
import '../features/onboarding/presentation/onboarding_type_screen.dart';
import '../features/onboarding/providers/notification_permission_prompt_provider.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/invites_screen.dart';
import '../features/profile/presentation/public_profile_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/settings/presentation/addresses_screen.dart';
import '../features/settings/presentation/blocked_users_screen.dart';
import '../features/settings/presentation/privacy_settings_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/splash/providers/splash_provider.dart';
import '../features/support/domain/ticket_model.dart';
import '../features/support/presentation/create_ticket_screen.dart';
import '../features/support/presentation/dropdown_stability_comparison_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/support/presentation/ticket_detail_screen.dart';
import '../features/support/presentation/ticket_list_screen.dart';
import '../utils/app_logger.dart';
import 'auth_guard.dart';
import 'route_paths.dart';

/// Notifier to trigger router refresh when auth/profile state changes.
class _GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

typedef _ProfileRedirectState = ({
  bool hasError,
  bool isLoading,
  String? cadastroStatus,
  String? uid,
});

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Main router provider.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _GoRouterRefreshNotifier();
  final authGuard = AuthGuard(ref);
  final analyticsObserver = ref.read(analyticsServiceProvider).getObserver();

  // Listen to state changes to trigger route re-evaluation
  ref.listen(authStateChangesProvider, (_, _) => notifier.notify());
  ref.listen(
    currentUserProfileProvider.select(_profileRedirectStateForRouting),
    (_, _) => notifier.notify(),
  );
  ref.listen(splashFinishedProvider, (_, _) => notifier.notify());
  ref.listen(notificationPermissionPromptProvider, (_, _) => notifier.notify());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: AppLogger.verboseLoggingEnabled,
    refreshListenable: notifier,
    redirect: authGuard.redirect,
    observers: [analyticsObserver],
    routes: _buildRoutes(ref),
  );
});

_ProfileRedirectState _profileRedirectStateForRouting(
  AsyncValue<AppUser?> asyncProfile,
) {
  final profile = asyncProfile.asData?.value;
  return (
    isLoading: asyncProfile.isLoading,
    hasError: asyncProfile.hasError,
    uid: profile?.uid,
    cadastroStatus: profile?.cadastroStatus,
  );
}

Map<String, dynamic>? _stringMapExtra(Object? extra) {
  if (extra == null) return null;
  if (extra is Map<String, dynamic>) return extra;
  if (extra is! Map) return null;

  final normalized = <String, dynamic>{};
  for (final entry in extra.entries) {
    final key = entry.key;
    if (key is String) {
      normalized[key] = entry.value;
    }
  }

  return normalized.isEmpty ? null : normalized;
}

Page<void> _buildPublicProfilePage(BuildContext context, GoRouterState state) {
  final uid = state.pathParameters['uid'];
  final username = state.pathParameters['username'];
  final profileRef = username != null ? '@$username' : uid!;
  String? avatarHeroTag;
  final extra = state.extra;
  if (extra is Map<Object?, Object?>) {
    final rawTag = extra[RoutePaths.avatarHeroTagExtraKey];
    if (rawTag is String && rawTag.isNotEmpty) {
      avatarHeroTag = rawTag;
    }
  }

  return NoTransitionPage(
    key: state.pageKey,
    child: PublicProfileScreen(
      profileRef: profileRef,
      avatarHeroTag: avatarHeroTag,
    ),
  );
}

/// Builds the route tree. Separated for readability.
List<RouteBase> _buildRoutes(Ref ref) {
  return [
    // Root alias route indicating the initial app loading.
    GoRoute(
      path: RoutePaths.splash,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
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
        GoRoute(
          path: 'notifications',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const NotificationPermissionScreen(),
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
        // Gigs tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.gigs,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: GigsScreen()),
              routes: [
                GoRoute(
                  path: 'create',
                  pageBuilder: (context, state) {
                    final initialGig = state.extra;
                    return NoTransitionPage(
                      key: state.pageKey,
                      child: CreateGigScreen(
                        initialGig: initialGig is Gig ? initialGig : null,
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: ':gigId',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: GigDetailScreen(
                      gigId: state.pathParameters['gigId']!,
                    ),
                  ),
                  routes: [
                    GoRoute(
                      path: 'applicants',
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: GigApplicantsScreen(
                          gigId: state.pathParameters['gigId']!,
                        ),
                      ),
                    ),
                    GoRoute(
                      path: 'review/:userId',
                      pageBuilder: (context, state) {
                        final extra = state.extra as Map<String, dynamic>?;
                        return NoTransitionPage(
                          key: state.pageKey,
                          child: GigReviewScreen(
                            gigId: state.pathParameters['gigId']!,
                            userId: state.pathParameters['userId']!,
                            userName: extra?['userName'] as String?,
                            userPhoto: extra?['userPhoto'] as String?,
                            gigTitle: extra?['gigTitle'] as String?,
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
        // Chat tab
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
        // Account hub tab
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
                  path: 'my-gigs',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const MyGigsScreen(),
                  ),
                ),
                GoRoute(
                  path: 'my-applications',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const MyApplicationsScreen(),
                  ),
                ),
                GoRoute(
                  path: 'addresses',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const AddressesScreen(),
                  ),
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
                  path: 'received-favorites',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const ReceivedFavoritesScreen(),
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
                      path: RoutePaths.supportDropdownCompare,
                      pageBuilder: (context, state) => NoTransitionPage(
                        key: state.pageKey,
                        child: const DropdownStabilityComparisonScreen(),
                      ),
                    ),
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
      path: RoutePaths.publicProfileHandleRoute,
      pageBuilder: _buildPublicProfilePage,
    ),
    GoRoute(
      path: '${RoutePaths.publicProfile}/:uid',
      pageBuilder: _buildPublicProfilePage,
    ),

    // Chat Conversation Screen (Top-level to hide bottom bar)
    GoRoute(
      path: '${RoutePaths.conversation}/:conversationId',
      pageBuilder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final extra = _stringMapExtra(state.extra);
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
      path: RoutePaths.profileEdit,
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

    // Shared public profile alias used by mubeapp.com.br/profile/:uid links.
    GoRoute(
      path: '${RoutePaths.profile}/:uid',
      pageBuilder: _buildPublicProfilePage,
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
