import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../common_widgets/responsive_shell.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/gallery/presentation/design_system_gallery_screen.dart';
import '../features/onboarding/presentation/onboarding_form_screen.dart';

import '../features/onboarding/presentation/onboarding_type_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../common_widgets/main_scaffold.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';

// Placeholder for screens to avoid errors if files are missing
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(title)));
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _GoRouterRefreshNotifier();

  // Listen to changes to trigger refresh
  ref.listen(authStateChangesProvider, (_, __) => notifier.notify());
  ref.listen(currentUserProfileProvider, (_, __) => notifier.notify());

  return GoRouter(
    initialLocation: '/', // Start at native-like splash
    debugLogDiagnostics: true,
    refreshListenable: notifier, // Refresh router on provider changes
    redirect: (context, state) {
      final authState = ref.read(authStateChangesProvider);
      final userProfileAsync = ref.read(currentUserProfileProvider);

      print('Router Redirect Check:');
      print('Auth State: ${authState.value?.email}');
      print('User Profile Async: $userProfileAsync');
      print('Current Location: ${state.uri.path}');

      final isLoggedIn = authState.value != null;
      final isLoggingIn =
          state.uri.path == '/login' ||
          state.uri.path == '/register' ||
          state.uri.path == '/gallery';

      // 0. Splash Screen (Allow pass-through)
      if (state.uri.path == '/') {
        return null;
      }

      // 1. Não Logado
      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Logado - Checar Status do Cadastro
      if (userProfileAsync.hasValue && userProfileAsync.value != null) {
        final user = userProfileAsync.value!;
        final path = state.uri.path;

        if (user.isTipoPendente) {
          return path == '/onboarding' ? null : '/onboarding';
        }

        if (user.isPerfilPendente) {
          return path == '/onboarding/form' ? null : '/onboarding/form';
        }

        if (user.isCadastroConcluido) {
          if (path.startsWith('/onboarding') || isLoggingIn) {
            return '/feed';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/onboarding',
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
      // Stateful Shell Route for Bottom Navigation (Feed, Profile)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Feed/Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const FeedScreen(),
                ),
              ),
            ],
          ),
          // Branch 2: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
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
        ],
      ),
      GoRoute(
        path: '/gallery',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const DesignSystemGalleryScreen(),
        ),
      ),
    ],
  );
});

class _GoRouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
