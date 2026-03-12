import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/analytics/analytics_provider.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/typedefs.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/app_performance_tracker.dart';
import '../../../utils/auth_exception_handler.dart';
import '../domain/app_user.dart';
import 'auth_remote_data_source.dart';

part 'auth_repository.g.dart';

/// Manages user authentication and Firestore profile data using the Result pattern.
class AuthRepository {
  final AuthRemoteDataSource _dataSource;
  final AnalyticsService? _analytics;

  AuthRepository(this._dataSource, {AnalyticsService? analytics})
    : _analytics = analytics;

  Stream<User?> authStateChanges() => _dataSource.authStateChanges();

  User? get currentUser => _dataSource.currentUser;

  /// Signs in a user. Returns [Right(Unit)] on success or [Left(AuthFailure)].
  FutureResult<Unit> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _dataSource.signInWithEmailAndPassword(email, password);

      // Log analytics event for successful login
      _logAnalyticsEvent(name: 'login', parameters: {'method': 'email'});

      return const Right(unit);
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.warning(
        'Email login failed: code=${e.code} message=${e.message ?? 'Unknown error'}',
        e,
        stackTrace,
        false,
      );
      // Log analytics event for login error
      _logAnalyticsEvent(
        name: 'login_error',
        parameters: {
          'method': 'email',
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      return Left(
        AuthFailure(message: AuthExceptionHandler.handleException(e)),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Email login failed with unexpected error',
        e,
        stackTrace,
        false,
      );
      _logAnalyticsEvent(
        name: 'login_error',
        parameters: {
          'method': 'email',
          'error_code': 'unknown',
          'error_message': e.toString(),
        },
      );
      return Left(AuthFailure(message: e.toString()));
    }
  }

  /// Registers a user. Returns [Right(Unit)] on success.
  FutureResult<Unit> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    User? createdUser;
    try {
      createdUser = await _dataSource.registerWithEmailAndPassword(
        email,
        password,
      );
      if (createdUser == null) {
        return const Left(
          AuthFailure(
            message: 'Não foi possível criar sua conta agora. Tente novamente.',
          ),
        );
      }

      final appUser = AppUser(
        uid: createdUser.uid,
        email: email,
        cadastroStatus: RegistrationStatus.pending,
        createdAt: FieldValue.serverTimestamp(),
      );
      await _dataSource.saveUserProfile(appUser);
      await _sendRegistrationVerificationEmailBestEffort();

      // Log analytics event for successful registration
      _logAnalyticsEvent(
        name: 'user_registration',
        parameters: {'method': 'email', 'user_type': 'pending'},
      );

      // Set user ID for analytics
      _setAnalyticsUserId(createdUser.uid);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      await _rollbackFailedRegistration(createdUser);
      // Log analytics event for registration error
      await _analytics?.logEvent(
        name: 'registration_error',
        parameters: {
          'method': 'email',
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      // Use AuthExceptionHandler to get user-friendly pt-BR message
      return Left(
        AuthFailure(message: AuthExceptionHandler.handleException(e)),
      );
    } catch (e) {
      await _rollbackFailedRegistration(createdUser);
      await _analytics?.logEvent(
        name: 'registration_error',
        parameters: {
          'method': 'email',
          'error_code': 'unknown',
          'error_message': e.toString(),
        },
      );
      return Left(
        AuthFailure(message: AuthExceptionHandler.handleException(e)),
      );
    }
  }

  FutureResult<Unit> signOut() async {
    try {
      // Clear analytics user ID on sign out
      await _analytics?.setUserId(null);

      await _dataSource.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  Stream<AppUser?> watchUser(String uid) => _dataSource.watchUserProfile(uid);

  FutureResult<Unit> updateUser(AppUser user) async {
    try {
      await _dataSource.updateUserProfile(user);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<Unit> deleteAccount() async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) {
        return const Left(AuthFailure(message: 'No user logged in'));
      }

      // Log analytics event before deletion
      await _analytics?.logEvent(
        name: 'account_deleted',
        parameters: {'user_id': uid},
      );

      // Clear analytics user ID
      await _analytics?.setUserId(null);

      await _dataSource.deleteAccount(uid);
      if (_dataSource.currentUser != null) {
        await _dataSource.signOut();
      }
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      // Re-auth required usually
      return Left(AuthFailure(message: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<List<AppUser>> getUsersByIds(List<String> uids) async {
    try {
      final users = await _dataSource.fetchUsersByIds(uids);
      return Right(users);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<Unit> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);

      // Log analytics event
      await _analytics?.logEvent(
        name: 'password_reset_requested',
        parameters: {'email': email},
      );

      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      await _analytics?.logEvent(
        name: 'password_reset_error',
        parameters: {
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      return Left(
        AuthFailure(message: e.message ?? 'Failed to send reset email'),
      );
    } catch (e) {
      await _analytics?.logEvent(
        name: 'password_reset_error',
        parameters: {'error_code': 'unknown', 'error_message': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<Unit> sendEmailVerification() async {
    try {
      await _dataSource.sendEmailVerification();

      // Log analytics event
      await _analytics?.logEvent(name: 'email_verification_sent');

      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      await _analytics?.logEvent(
        name: 'email_verification_error',
        parameters: {
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      return Left(
        AuthFailure(message: e.message ?? 'Failed to send verification email'),
      );
    } catch (e) {
      await _analytics?.logEvent(
        name: 'email_verification_error',
        parameters: {'error_code': 'unknown', 'error_message': e.toString()},
      );
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<bool> isEmailVerified() async {
    return await _dataSource.isEmailVerified();
  }

  /// Verifica o claim `email_verified` presente no ID token usado pelas Rules.
  ///
  /// Use isso para garantir que regras do Firestore que dependem desse claim
  /// já reconhecerão o usuário como verificado.
  Future<bool> hasVerifiedEmailTokenClaim({bool forceRefresh = false}) async {
    final user = _dataSource.currentUser;
    if (user == null) return false;

    final tokenResult = await user.getIdTokenResult(forceRefresh);
    final claim = tokenResult.claims?['email_verified'];
    return claim == true;
  }

  Future<void> reloadUser() async {
    await _dataSource.reloadUser();
  }

  /// Forces a refresh of the client's auth/app-check context.
  ///
  /// This is used by guards and recoverable flows before escalating a transient
  /// permission failure into a full sign-out.
  FutureResult<Unit> refreshSecurityContext() async {
    if (_dataSource.currentUser == null) {
      return Left(AuthFailure.sessionExpired());
    }

    try {
      await _dataSource.refreshSecurityContext();
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      if (_isTerminalSessionRefreshCode(e.code)) {
        return Left(
          AuthFailure(
            message: 'Sua sessão expirou. Faça login novamente.',
            debugMessage: e.code,
            originalError: e,
          ),
        );
      }

      return Left(
        AuthFailure(
          message: AuthExceptionHandler.handleException(e),
          debugMessage: e.code,
          originalError: e,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString(), originalError: e));
    }
  }

  bool get isCurrentUserEmailVerified {
    return _dataSource.currentUser?.emailVerified ?? false;
  }

  /// Ensures the authenticated user has a profile document in Firestore.
  ///
  /// Useful to recover from inconsistent states where Auth user exists
  /// but profile creation failed previously.
  FutureResult<Unit> ensureCurrentUserProfileExists() async {
    try {
      final user = _dataSource.currentUser;
      if (user == null) {
        return const Left(AuthFailure(message: 'No user logged in'));
      }

      await _ensureUserProfileExists(user);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  FutureResult<Unit> signInWithGoogle() async {
    return _signInWithSocialProvider(
      method: 'google',
      signIn: _dataSource.signInWithGoogle,
    );
  }

  FutureResult<Unit> signInWithApple() async {
    return _signInWithSocialProvider(
      method: 'apple',
      signIn: _dataSource.signInWithApple,
    );
  }

  FutureResult<Unit> _signInWithSocialProvider({
    required String method,
    required Future<UserCredential> Function() signIn,
  }) async {
    try {
      final credential = await signIn();
      final user = credential.user;

      if (user == null) {
        return const Left(
          AuthFailure(message: 'Falha ao autenticar com provedor social.'),
        );
      }

      final isNewUser = await _ensureUserProfileExists(user);

      _setAnalyticsUserId(user.uid);
      _logAnalyticsEvent(name: 'login', parameters: {'method': method});

      if (isNewUser) {
        _logAnalyticsEvent(
          name: 'user_registration',
          parameters: {'method': method, 'user_type': 'pending'},
        );
      }

      return const Right(unit);
    } on FirebaseAuthException catch (e, stackTrace) {
      AppLogger.warning(
        'Social login failed ($method): code=${e.code} message=${e.message ?? 'Unknown error'}',
        e,
        stackTrace,
        false,
      );
      _logAnalyticsEvent(
        name: 'login_error',
        parameters: {
          'method': method,
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      return Left(
        AuthFailure(message: AuthExceptionHandler.handleException(e)),
      );
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Social login failed with unexpected error ($method)',
        e,
        stackTrace,
        false,
      );
      _logAnalyticsEvent(
        name: 'login_error',
        parameters: {
          'method': method,
          'error_code': 'unknown',
          'error_message': e.toString(),
        },
      );
      return Left(
        AuthFailure(message: AuthExceptionHandler.handleException(e)),
      );
    }
  }

  Future<void> _sendRegistrationVerificationEmailBestEffort() async {
    try {
      await _dataSource.sendEmailVerification();
    } on FirebaseAuthException catch (error, stack) {
      AppLogger.warning(
        'Falha ao enviar email de verificacao apos cadastro',
        error,
        stack,
      );
      _logAnalyticsEvent(
        name: 'email_verification_error',
        parameters: {
          'error_code': error.code,
          'error_message': error.message ?? 'Unknown error',
          'flow': 'registration',
        },
      );
    } catch (error, stack) {
      AppLogger.warning(
        'Falha inesperada ao enviar email de verificacao apos cadastro',
        error,
        stack,
      );
      _logAnalyticsEvent(
        name: 'email_verification_error',
        parameters: {
          'error_code': 'unknown',
          'error_message': error.toString(),
          'flow': 'registration',
        },
      );
    }
  }

  Future<void> _rollbackFailedRegistration(User? createdUser) async {
    if (createdUser == null) {
      return;
    }

    try {
      await createdUser.delete();
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao reverter usuario criado apos erro no cadastro',
        error,
        stack,
      );
    }

    try {
      await _dataSource.signOut();
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao encerrar sessao apos rollback de cadastro',
        error,
        stack,
      );
    }
  }

  void _logAnalyticsEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    final analytics = _analytics;
    if (analytics == null) return;
    unawaited(
      analytics.logEvent(name: name, parameters: parameters).catchError((_) {}),
    );
  }

  void _setAnalyticsUserId(String userId) {
    final analytics = _analytics;
    if (analytics == null) return;
    unawaited(analytics.setUserId(userId).catchError((_) {}));
  }

  Future<bool> _ensureUserProfileExists(User user) async {
    final existingProfile = await _dataSource.fetchUserProfile(user.uid);
    if (existingProfile != null) {
      return false;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'social-email-missing',
        message: 'A conta social não retornou um e-mail válido.',
      );
    }

    final appUser = AppUser(
      uid: user.uid,
      email: email,
      nome: user.displayName,
      foto: user.photoURL,
      cadastroStatus: RegistrationStatus.pending,
      createdAt: FieldValue.serverTimestamp(),
    );
    await _dataSource.saveUserProfile(appUser);
    return true;
  }

  bool _isTerminalSessionRefreshCode(String code) {
    switch (code.toLowerCase()) {
      case 'session-expired':
      case 'user-token-expired':
      case 'invalid-user-token':
      case 'user-disabled':
        return true;
      default:
        return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  final analytics = ref.read(analyticsServiceProvider);
  return AuthRepository(dataSource, analytics: analytics);
}

/// Stream provider for Firebase Auth state changes.
@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  final stopwatch = AppPerformanceTracker.startSpan('auth.state_stream');
  var firstEvent = true;

  return ref.watch(authRepositoryProvider).authStateChanges().map((user) {
    if (firstEvent) {
      firstEvent = false;
      AppPerformanceTracker.finishSpan(
        'auth.state_stream',
        stopwatch,
        data: {'authenticated': user != null},
      );
    } else {
      AppPerformanceTracker.mark(
        'auth.state_stream.event',
        data: {'authenticated': user != null},
      );
    }
    return user;
  });
}

/// Stream provider for the current user's profile data from Firestore.
///
/// Returns `null` if the user is not authenticated or profile doesn't exist.
@riverpod
Stream<AppUser?> currentUserProfile(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        AppPerformanceTracker.mark(
          'auth.profile_stream.skipped',
          data: {'reason': 'unauthenticated'},
        );
        return Stream.value(null);
      }

      final stopwatch = AppPerformanceTracker.startSpan(
        'auth.profile_stream',
        data: {'uid': user.uid},
      );
      var firstEvent = true;

      return ref.watch(authRepositoryProvider).watchUser(user.uid).map((
        profile,
      ) {
        if (firstEvent) {
          firstEvent = false;
          AppPerformanceTracker.finishSpan(
            'auth.profile_stream',
            stopwatch,
            data: {
              'uid': user.uid,
              'has_profile': profile != null,
              'cadastro_status': profile?.cadastroStatus,
            },
          );
        }
        return profile;
      });
    },
    loading: () => const Stream.empty(),
    error: (_, _) => const Stream.empty(),
  );
}

@riverpod
Future<List<AppUser>> membersList(Ref ref, List<String> uids) async {
  if (uids.isEmpty) return [];
  final result = await ref.watch(authRepositoryProvider).getUsersByIds(uids);
  return result.fold((l) => throw l, (r) => r);
}
