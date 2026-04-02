import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';

import '../core/errors/failures.dart';
import '../core/typedefs.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/account_deletion_provider.dart';
import '../features/onboarding/providers/notification_permission_prompt_provider.dart';
import '../features/splash/providers/splash_provider.dart';
import '../utils/app_logger.dart';
import '../utils/app_performance_tracker.dart';
import 'route_paths.dart';

/// Handles authentication and onboarding redirect logic.
///
/// This class encapsulates all navigation guards, making the router
/// configuration cleaner and the logic easier to test.
class AuthGuard {
  final Ref _ref;
  bool _isRecoveringProfileAccess = false;
  DateTime? _lastProfileRecoveryAt;
  Stopwatch? _profileWaitStopwatch;
  String? _profileWaitPath;
  String? _deferredPublicPathDuringSplash;
  static const Duration _profileRecoveryCooldown = Duration(seconds: 4);

  AuthGuard(this._ref);

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
      _rememberDeferredPublicPathIfNeeded(state.uri);
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

    // Not logged in - redirect to register (first-time users expect signup)
    if (!isLoggedIn) {
      _finishProfileWaitIfNeeded(status: 'signed_out', path: currentPath);
      if (currentPath == RoutePaths.splash) {
        final deferredPublicPath = _consumeDeferredPublicPathIfAny();
        if (deferredPublicPath != null) {
          _log(
            'Unauthenticated on splash with deferred public path - '
            'redirecting to $deferredPublicPath',
          );
          return deferredPublicPath;
        }
        return RoutePaths.register;
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
    _log('Unauthenticated - redirecting to register');
    return RoutePaths.register;
  }

  /// Handles redirect logic for authenticated users based on profile status.
  Future<String?> _handleAuthenticated(
    String currentPath,
    AsyncValue<dynamic> userProfileAsync,
  ) async {
    final isDeletingAccount = _ref.read(accountDeletionInProgressProvider);
    final authRepository = _ref.read(authRepositoryProvider);

    // Email verification can be opened from authenticated flows (e.g. chat send gate).
    // Keep this route accessible to avoid redirect collisions with imperative push().
    if (currentPath == RoutePaths.emailVerification) {
      return null;
    }

    if (userProfileAsync.hasError) {
      _finishProfileWaitIfNeeded(status: 'error', path: currentPath);
      if (isDeletingAccount) {
        _log(
          'Profile stream error during account deletion - skipping recovery',
        );
        return null;
      }

      final error = userProfileAsync.error;
      _log('Profile stream error: $error');

      final failureMessage = error.toString();
      if (_isPermissionRelatedFailure(failureMessage)) {
        _signalWarning(
          'Permission-related profile stream error. '
          'path=$currentPath failure=$failureMessage',
        );
        return _recoverPermissionRelatedProfileAccess(
          currentPath,
          reason: 'profile-stream',
        );
      }

      if (_isAuthFlowRoute(currentPath)) return null;
      return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
    }

    // Profile not loaded yet.
    if (userProfileAsync.isLoading || !userProfileAsync.hasValue) {
      _startProfileWaitIfNeeded(currentPath);
      if (currentPath == RoutePaths.splash) {
        final deferredPublicPath = _consumeDeferredPublicPathIfAny();
        if (deferredPublicPath != null) {
          _log(
            'Profile loading on splash - redirecting to deferred public path',
          );
          return deferredPublicPath;
        }
        _log('Profile loading on splash - redirecting optimistically to feed');
        return RoutePaths.feed;
      }
      // Keep auth-flow routes inline so signup/login doesn't bounce to splash.
      if (_isAuthFlowRoute(currentPath)) {
        _log('Profile loading on auth route - waiting inline');
        return null;
      }
      _log('Profile loading on current route - waiting inline');
      return null;
    }

    // Recover from inconsistent state: Auth user exists but profile document
    // was not created (for example, previous permission failures).
    if (userProfileAsync.value == null) {
      if (isDeletingAccount) {
        _log(
          'Profile missing during account deletion - waiting for auth sign out',
        );
        return null;
      }

      _log('Profile missing for authenticated user - attempting recovery');
      final recoveryResult = await authRepository
          .ensureCurrentUserProfileExists();

      if (recoveryResult.isLeft()) {
        final failure = recoveryResult.fold(
          (failure) => failure,
          (_) => throw StateError('Expected a profile recovery failure'),
        );
        final failureMessage = _describeFailure(failure);
        _log('Profile recovery failed: $failureMessage');

        if (_isPermissionRelatedFailure(failureMessage)) {
          _signalWarning(
            'Permission-related profile creation failure. '
            'path=$currentPath failure=$failureMessage',
          );
          return _recoverPermissionRelatedProfileAccess(
            currentPath,
            reason: 'profile-create',
            afterRefresh: () => authRepository.ensureCurrentUserProfileExists(),
          );
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
    _finishProfileWaitIfNeeded(status: 'resolved', path: currentPath);

    // We have a fully loaded user profile. If they are on Splash, route them based on onboarding.
    if (currentPath == RoutePaths.splash) {
      if (user.isTipoPendente) return RoutePaths.onboarding;
      if (user.isPerfilPendente) return RoutePaths.onboardingForm;
      final completedRedirect = await _guardCompletedUser(RoutePaths.splash);
      if (completedRedirect == RoutePaths.feed || completedRedirect == null) {
        final deferredPublicPath = _consumeDeferredPublicPathIfAny();
        if (deferredPublicPath != null) {
          _log(
            'Authenticated on splash with deferred public path - '
            'redirecting to $deferredPublicPath',
          );
          return deferredPublicPath;
        }
      }
      return completedRedirect;
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

  void _startProfileWaitIfNeeded(String currentPath) {
    if (_profileWaitStopwatch != null) return;
    _profileWaitPath = currentPath;
    _profileWaitStopwatch = AppPerformanceTracker.startSpan(
      'auth.guard.profile_wait',
      data: {'path': currentPath},
    );
  }

  void _finishProfileWaitIfNeeded({
    required String status,
    required String path,
  }) {
    final stopwatch = _profileWaitStopwatch;
    if (stopwatch == null) return;

    AppPerformanceTracker.finishSpan(
      'auth.guard.profile_wait',
      stopwatch,
      data: {'status': status, 'path': _profileWaitPath ?? path},
    );
    _profileWaitStopwatch = null;
    _profileWaitPath = null;
  }

  Future<String?> _recoverPermissionRelatedProfileAccess(
    String currentPath, {
    required String reason,
    FutureResult<Unit> Function()? afterRefresh,
  }) async {
    final authRepository = _ref.read(authRepositoryProvider);
    final now = DateTime.now();

    if (_isRecoveringProfileAccess) {
      _log('Profile recovery already in progress ($reason)');
      return _redirectForProfileRecovery(currentPath);
    }

    if (_lastProfileRecoveryAt != null &&
        now.difference(_lastProfileRecoveryAt!) < _profileRecoveryCooldown) {
      _log('Skipping profile recovery during cooldown ($reason)');
      return _redirectForProfileRecovery(currentPath);
    }

    _isRecoveringProfileAccess = true;
    _lastProfileRecoveryAt = now;

    try {
      _signalWarning(
        'Attempting permission-related profile recovery. '
        'reason=$reason path=$currentPath',
      );

      final refreshResult = await authRepository.refreshSecurityContext();
      if (refreshResult.isLeft()) {
        final failure = refreshResult.fold(
          (failure) => failure,
          (_) => throw StateError('Expected a refresh failure'),
        );
        final failureDescription = _describeFailure(failure);
        _signalWarning(
          'Session refresh failed during profile recovery. '
          'reason=$reason path=$currentPath failure=$failureDescription',
        );
        return _handleProfileRecoveryFailure(
          currentPath,
          authRepository,
          failure,
        );
      }

      if (afterRefresh != null) {
        final followUpResult = await afterRefresh();
        if (followUpResult.isLeft()) {
          final failure = followUpResult.fold(
            (failure) => failure,
            (_) => throw StateError('Expected a profile recovery failure'),
          );
          final failureDescription = _describeFailure(failure);
          _signalWarning(
            'Profile recovery follow-up failed. '
            'reason=$reason path=$currentPath failure=$failureDescription',
          );
          return _handleProfileRecoveryFailure(
            currentPath,
            authRepository,
            failure,
          );
        }
      }

      _ref.invalidate(currentUserProfileProvider);
      _signalWarning(
        'Permission-related profile recovery requested successfully. '
        'reason=$reason path=$currentPath',
      );
      return _redirectForProfileRecovery(currentPath);
    } finally {
      _isRecoveringProfileAccess = false;
    }
  }

  Future<String?> _handleProfileRecoveryFailure(
    String currentPath,
    AuthRepository authRepository,
    Failure failure,
  ) async {
    if (_shouldForceSignOutAfterRecoveryFailure(authRepository, failure)) {
      _signalError(
        'Signing out after terminal profile recovery failure. '
        'path=$currentPath failure=${_describeFailure(failure)}',
      );
      await authRepository.signOut();
      return RoutePaths.login;
    }

    _signalWarning(
      'Profile recovery failed without terminal sign-out. '
      'path=$currentPath failure=${_describeFailure(failure)}',
    );
    return _redirectForProfileRecovery(currentPath);
  }

  String? _redirectForProfileRecovery(String currentPath) {
    if (_isAuthFlowRoute(currentPath)) return null;
    return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
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
    final permissionPromptState = _ref.read(
      notificationPermissionPromptProvider,
    );

    if (permissionPromptState.isLoading) {
      _log('Notification permission state loading - waiting on current route');
      return null;
    }

    if (permissionPromptState.hasError) {
      _signalWarning(
        'Notification permission state unavailable. '
        'path=$currentPath error=${permissionPromptState.error}',
      );
    }

    final hasShownPermission = permissionPromptState.asData?.value ?? false;

    if (!hasShownPermission) {
      if (currentPath == RoutePaths.notificationPermission) return null;
      _log('Redirecting to notification permission screen');
      return RoutePaths.notificationPermission;
    }

    // Allow user to stay on notification permission screen even if already shown
    // but typically they will navigate away by clicking a button.
    if (currentPath == RoutePaths.notificationPermission) return null;

    final isLegalRoute =
        currentPath == RoutePaths.legal ||
        currentPath.startsWith('${RoutePaths.legal}/');

    final shouldRedirectToFeed =
        currentPath.startsWith(RoutePaths.onboarding) ||
        _isAuthFlowRoute(currentPath) ||
        currentPath == RoutePaths.splash;

    if (shouldRedirectToFeed && !isLegalRoute) {
      _log('Completed user on restricted route - redirecting to feed');
      return RoutePaths.feed;
    }
    return null;
  }

  /// Debug-only logging.
  void _log(String message) {
    AppLogger.debug('[AuthGuard] $message');
  }

  void _signalWarning(String message) {
    final formatted = '[AuthGuard] $message';
    _log(message);
    AppLogger.setCustomKey('auth_guard_last_event', formatted);
    if (!kDebugMode) {
      AppLogger.warning(formatted);
    }
  }

  void _signalError(String message) {
    final formatted = '[AuthGuard] $message';
    _log(message);
    AppLogger.setCustomKey('auth_guard_last_event', formatted);
    if (!kDebugMode) {
      AppLogger.error(formatted);
    }
  }

  bool _isPermissionRelatedFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('permission-denied') ||
        normalized.contains('permission denied') ||
        normalized.contains('insufficient permissions') ||
        normalized.contains('cloud_firestore/permission-denied');
  }

  String _describeFailure(Failure failure) {
    return [
      failure.message,
      failure.debugMessage ?? '',
    ].where((part) => part.isNotEmpty).join(' ');
  }

  bool _shouldForceSignOutAfterRecoveryFailure(
    AuthRepository authRepository,
    Failure failure,
  ) {
    if (authRepository.currentUser == null) return true;

    final normalized = [
      failure.message,
      failure.debugMessage ?? '',
    ].join(' ').toLowerCase();

    return normalized.contains('session-expired') ||
        normalized.contains('user-token-expired') ||
        normalized.contains('invalid-user-token') ||
        normalized.contains('user-disabled');
  }

  void _rememberDeferredPublicPathIfNeeded(Uri uri) {
    final path = uri.path;
    if (path == RoutePaths.splash || !RoutePaths.isPublic(path)) {
      return;
    }
    _deferredPublicPathDuringSplash = uri.toString();
    _log(
      'Deferring public path until splash finishes: '
      '$_deferredPublicPathDuringSplash',
    );
  }

  String? _consumeDeferredPublicPathIfAny() {
    final deferredPath = _deferredPublicPathDuringSplash;
    if (deferredPath == null) return null;

    final parsedPath = Uri.parse(deferredPath).path;
    _deferredPublicPathDuringSplash = null;

    if (!RoutePaths.isPublic(parsedPath) || parsedPath == RoutePaths.splash) {
      return null;
    }
    return deferredPath;
  }
}
