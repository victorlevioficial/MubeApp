import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../common_widgets/main_scaffold.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/feed/presentation/feed_list_screen.dart';
import '../features/feed/domain/feed_section.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/gallery/presentation/design_system_gallery_screen.dart';
import '../features/onboarding/presentation/onboarding_form_screen.dart';
import '../features/onboarding/presentation/onboarding_type_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/addresses_screen.dart';
import '../features/settings/presentation/edit_address_screen.dart';
import '../features/settings/domain/saved_address.dart';
import '../features/splash/presentation/splash_screen.dart';
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

  // Listen to state changes to trigger route re-evaluation
  ref.listen(authStateChangesProvider, (_, __) => notifier.notify());
  ref.listen(currentUserProfileProvider, (_, __) => notifier.notify());

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: authGuard.redirect,
    routes: _buildRoutes(),
  );
});

/// Builds the route tree. Separated for readability.
List<RouteBase> _buildRoutes() {
  return [
    // Splash (initial loading screen)
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
        // Profile tab
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: RoutePaths.profile,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const ProfileScreen(),
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  pageBuilder: (context, state) => NoTransitionPage(
                    key: state.pageKey,
                    child: const EditProfileScreen(),
                  ),
                ),
              ],
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
                  path: 'address',
                  pageBuilder: (context, state) {
                    final address = state.extra as SavedAddress?;
                    return NoTransitionPage(
                      key: state.pageKey,
                      child: EditAddressScreen(existingAddress: address),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Search screen
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const SearchScreen()),
    ),

    // Dev gallery (design system showcase)
    GoRoute(
      path: RoutePaths.gallery,
      pageBuilder: (context, state) => NoTransitionPage(
        key: state.pageKey,
        child: const DesignSystemGalleryScreen(),
      ),
    ),
  ];
}
