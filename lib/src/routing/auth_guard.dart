import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
    final currentPath = state.uri.path;

    final authState = _ref.read(authStateChangesProvider);
    final userProfileAsync = _ref.read(currentUserProfileProvider);
    final splashFinished = _ref.read(splashFinishedProvider);

    // During initial boot, keep splash as entry point.
    if (!splashFinished) {
      if (currentPath == RoutePaths.splash) {
        _log('Splash loading - waiting on splash screen');
        return null; // Pass-through
      }
      return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
    }

    // After initial boot, avoid forcing a splash redirect on transient auth loading.
    // This prevents register/login flows from bouncing through splash.
    if (authState.isLoading) {
      _log('Auth loading - waiting on current route');
      return null;
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
    return await _handleAuthenticated(currentPath, userProfileAsync);
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
  Future<String?> _handleAuthenticated(
    String currentPath,
    AsyncValue<dynamic> userProfileAsync,
  ) async {
    // Email verification can be opened from authenticated flows (e.g. chat send gate).
    // Keep this route accessible to avoid redirect collisions with imperative push().
    if (currentPath == RoutePaths.emailVerification) {
      return null;
    }

    if (userProfileAsync.hasError) {
      final error = userProfileAsync.error;
      _log('Profile stream error: $error');

      final recoveryResult = await _ref
          .read(authRepositoryProvider)
          .ensureCurrentUserProfileExists();

      if (recoveryResult.isLeft()) {
        final failureMessage = recoveryResult.fold(
          (failure) => failure.message,
          (_) => 'unknown',
        );
        _log('Profile recovery failed after stream error: $failureMessage');

        if (_isPermissionRelatedFailure(failureMessage)) {
          _log('Signing out due to permission-related profile failure');
          await _ref.read(authRepositoryProvider).signOut();
          return RoutePaths.login;
        }

        if (_isAuthFlowRoute(currentPath)) return null;
        return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
      }

      if (_isAuthFlowRoute(currentPath)) return null;
      return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
    }

    // Profile not loaded yet.
    if (userProfileAsync.isLoading || !userProfileAsync.hasValue) {
      if (currentPath == RoutePaths.splash) {
        _log('Profile loading - waiting on splash');
        return null; // Stay on splash
      }
      // Keep auth-flow routes inline so signup/login doesn't bounce to splash.
      if (_isAuthFlowRoute(currentPath)) {
        _log('Profile loading on auth route - waiting inline');
        return null;
      }
      // Outside auth-flow routes, keep previous behavior.
      return RoutePaths.splash;
    }

    // Recover from inconsistent state: Auth user exists but profile document
    // was not created (for example, previous permission failures).
    if (userProfileAsync.value == null) {
      _log('Profile missing for authenticated user - attempting recovery');
      final recoveryResult = await _ref
          .read(authRepositoryProvider)
          .ensureCurrentUserProfileExists();

      if (recoveryResult.isLeft()) {
        final failureMessage = recoveryResult.fold(
          (failure) => failure.message,
          (_) => 'unknown',
        );
        _log('Profile recovery failed: $failureMessage');

        if (_isPermissionRelatedFailure(failureMessage)) {
          _log('Signing out due to permission-related profile failure');
          await _ref.read(authRepositoryProvider).signOut();
          return RoutePaths.login;
        }

        // While recovering/failing for non-permission reasons, keep auth-flow
        // routes inline to avoid splash bounce.
        if (_isAuthFlowRoute(currentPath)) {
          return null;
        }
        return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
      }

      _log('Profile recovery requested successfully');

      // While recovering, keep auth-flow routes inline to avoid splash bounce.
      if (_isAuthFlowRoute(currentPath)) {
        return null;
      }
      // Wait on splash while currentUserProfileProvider receives the new doc.
      return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
    }

    final user = userProfileAsync.value!;

    // We have a fully loaded user profile. If they are on Splash, route them based on onboarding.
    if (currentPath == RoutePaths.splash) {
      if (user.isTipoPendente) return RoutePaths.onboarding;
      if (user.isPerfilPendente) return RoutePaths.onboardingForm;
      return await _guardCompletedUser(RoutePaths.splash);
    }

    // Check onboarding status for current navigation
    if (user.isTipoPendente) {
      return _guardOnboardingType(currentPath);
    }

    if (user.isPerfilPendente) {
      return _guardOnboardingForm(currentPath);
    }

    if (user.isCadastroConcluido) {
      return await _guardCompletedUser(currentPath);
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

  bool _isAuthFlowRoute(String path) {
    return path == RoutePaths.login ||
        path == RoutePaths.register ||
        path == RoutePaths.forgotPassword ||
        path == RoutePaths.emailVerification;
  }

  /// User completed registration - redirect away from auth/onboarding screens.
  Future<String?> _guardCompletedUser(String currentPath) async {
    // Check if we need to show the notification permission screen
    final prefs = await SharedPreferences.getInstance();
    final hasShownPermission =
        prefs.getBool('notification_permission_shown') ?? false;

    if (!hasShownPermission) {
      if (currentPath == RoutePaths.notificationPermission) return null;
      _log('Redirecting to notification permission screen');
      return RoutePaths.notificationPermission;
    }

    // Allow user to stay on notification permission screen even if already shown
    // but typically they will navigate away by clicking a button.
    if (currentPath == RoutePaths.notificationPermission) return null;

    final shouldRedirectToFeed =
        currentPath.startsWith(RoutePaths.onboarding) ||
        (RoutePaths.isPublic(currentPath) &&
            currentPath != RoutePaths.gallery) ||
        currentPath == RoutePaths.splash;

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

  bool _isPermissionRelatedFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('permission-denied') ||
        normalized.contains('permission denied') ||
        normalized.contains('insufficient permissions') ||
        normalized.contains('cloud_firestore/permission-denied');
  }
}
