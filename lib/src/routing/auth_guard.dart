import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/splash/providers/splash_provider.dart';
import 'route_paths.dart';

/// Handles authentication and onboarding redirect logic.
///
/// This class encapsulates all navigation guards, making the router
/// configuration cleaner and the logic easier to test.
class AuthGuard {
  final Ref _ref;

  const AuthGuard(this._ref);

  /// Determines if a redirect is needed based on auth and profile state.
  ///
  /// Returns:
  /// - `null` if no redirect is needed (allow navigation)
  /// - A path string if redirect is required
  String? redirect(BuildContext context, GoRouterState state) {
    final currentPath = state.uri.path;

    final authState = _ref.read(authStateChangesProvider);
    final userProfileAsync = _ref.read(currentUserProfileProvider);
    final splashFinished = _ref.read(splashFinishedProvider);

    // If splash timer is not finished or auth is loading, remain on splash
    if (!splashFinished || authState.isLoading) {
      if (currentPath == RoutePaths.splash) {
        _log('Splash or Auth loading - waiting on splash screen');
        return null; // Pass-through
      }
      // If we are anywhere else, let them load where they are (like link from email)
      // or force them to splash? Forcing to splash is safer.
      // But if they clicked a deep link, we don't want to lose it.
      // For now, let's just let splash screen be the entry. If not splash, let's wait inline if not auth.
      // Actually go_router initialLocation is '/', so it will hit splash first.
      return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
    }

    final isLoggedIn = authState.value != null;

    _log(
      'path: $currentPath, auth: ${isLoggedIn ? authState.value?.email : 'null'}',
    );

    // Not logged in - redirect to login
    if (!isLoggedIn) {
      if (currentPath == RoutePaths.splash) {
        return RoutePaths.login;
      }
      return _handleUnauthenticated(currentPath);
    }

    // Logged in - check profile and onboarding status
    return _handleAuthenticated(currentPath, userProfileAsync);
  }

  /// Handles redirect logic for unauthenticated users.
  String? _handleUnauthenticated(String currentPath) {
    if (RoutePaths.isPublic(currentPath)) {
      _log('Unauthenticated on public route - allowing');
      return null;
    }
    _log('Unauthenticated - redirecting to login');
    return RoutePaths.login;
  }

  /// Handles redirect logic for authenticated users based on profile status.
  String? _handleAuthenticated(
    String currentPath,
    AsyncValue<dynamic> userProfileAsync,
  ) {
    // Check if email is verified first
    final authRepo = _ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;

    // If user is logged in but email is not verified, redirect to verification screen
    if (currentUser != null && !currentUser.emailVerified) {
      if (currentPath == RoutePaths.emailVerification) {
        return null; // Already on verification screen
      }
      _log('Email not verified - redirecting to verification');
      return RoutePaths.emailVerification;
    }

    // Profile not loaded yet - stay on splash if returning from startup
    if (userProfileAsync.isLoading ||
        !userProfileAsync.hasValue ||
        userProfileAsync.value == null) {
      if (currentPath == RoutePaths.splash) {
        _log('Profile loading - waiting on splash');
        return null; // Stay on splash
      }
      // If they are on another screen (e.g. login) and profile is loading, redirect to splash to wait
      return RoutePaths.splash;
    }

    final user = userProfileAsync.value!;

    // We have a fully loaded user profile. If they are on Splash, route them based on onboarding.
    if (currentPath == RoutePaths.splash) {
      if (user.isTipoPendente) return RoutePaths.onboarding;
      if (user.isPerfilPendente) return RoutePaths.onboardingForm;
      return RoutePaths.feed;
    }

    // Check onboarding status for current navigation
    if (user.isTipoPendente) {
      return _guardOnboardingType(currentPath);
    }

    if (user.isPerfilPendente) {
      return _guardOnboardingForm(currentPath);
    }

    if (user.isCadastroConcluido) {
      return _guardCompletedUser(currentPath);
    }

    return null;
  }

  /// User needs to select type - keep on onboarding type screen.
  String? _guardOnboardingType(String currentPath) {
    if (currentPath == RoutePaths.onboarding) return null;
    _log('Type pending - redirecting to onboarding');
    return RoutePaths.onboarding;
  }

  /// User needs to complete profile - keep on onboarding form.
  String? _guardOnboardingForm(String currentPath) {
    if (currentPath == RoutePaths.onboardingForm) return null;
    _log('Profile pending - redirecting to onboarding form');
    return RoutePaths.onboardingForm;
  }

  /// User completed registration - redirect away from auth/onboarding screens.
  String? _guardCompletedUser(String currentPath) {
    final shouldRedirectToFeed =
        currentPath.startsWith(RoutePaths.onboarding) ||
        (RoutePaths.isPublic(currentPath) && currentPath != RoutePaths.gallery);

    if (shouldRedirectToFeed) {
      _log('Completed user on restricted route - redirecting to feed');
      return RoutePaths.feed;
    }
    return null;
  }

  /// Debug-only logging.
  void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'AuthGuard');
    }
  }
}
