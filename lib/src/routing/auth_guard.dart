import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_repository.dart';
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

    // 1. Always allow splash screen
    if (currentPath == RoutePaths.splash) {
      _log('Splash screen - allowing pass-through');
      return null;
    }

    final authState = _ref.read(authStateChangesProvider);
    final userProfileAsync = _ref.read(currentUserProfileProvider);
    final isLoggedIn = authState.value != null;

    _log(
      'path: $currentPath, auth: ${isLoggedIn ? authState.value?.email : 'null'}',
    );

    // 2. Not logged in - redirect to login (unless already on public route)
    if (!isLoggedIn) {
      return _handleUnauthenticated(currentPath);
    }

    // 3. Logged in - check onboarding status
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
    // Profile not loaded yet - don't redirect
    if (!userProfileAsync.hasValue || userProfileAsync.value == null) {
      _log('Profile loading - waiting');
      return null;
    }

    final user = userProfileAsync.value!;

    // Check onboarding status using domain model methods
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
        RoutePaths.isPublic(currentPath) && currentPath != RoutePaths.gallery;

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
