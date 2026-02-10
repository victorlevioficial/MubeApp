import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/analytics/analytics_provider.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../../../core/typedefs.dart';
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
      await _analytics?.logEvent(
        name: 'login',
        parameters: {'method': 'email'},
      );

      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      // Log analytics event for login error
      await _analytics?.logEvent(
        name: 'login_error',
        parameters: {
          'method': 'email',
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      return Left(AuthFailure(message: e.message ?? 'Authentication failed'));
    } catch (e) {
      await _analytics?.logEvent(
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
    try {
      final user = await _dataSource.registerWithEmailAndPassword(
        email,
        password,
      );
      if (user != null) {
        // Send email verification
        await _dataSource.sendEmailVerification();

        final appUser = AppUser(
          uid: user.uid,
          email: email,
          cadastroStatus: RegistrationStatus.pending,
          createdAt: FieldValue.serverTimestamp(),
        );
        await _dataSource.saveUserProfile(appUser);

        // Log analytics event for successful registration
        await _analytics?.logEvent(
          name: 'user_registration',
          parameters: {'method': 'email', 'user_type': 'pending'},
        );

        // Set user ID for analytics
        await _analytics?.setUserId(user.uid);
      }
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      // Log analytics event for registration error
      await _analytics?.logEvent(
        name: 'registration_error',
        parameters: {
          'method': 'email',
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      return Left(AuthFailure(message: e.message ?? 'Registration failed'));
    } catch (e) {
      await _analytics?.logEvent(
        name: 'registration_error',
        parameters: {
          'method': 'email',
          'error_code': 'unknown',
          'error_message': e.toString(),
        },
      );
      return Left(AuthFailure(message: e.toString()));
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

  Future<void> reloadUser() async {
    await _dataSource.reloadUser();
  }

  bool get isCurrentUserEmailVerified {
    return _dataSource.currentUser?.emailVerified ?? false;
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

      await _analytics?.setUserId(user.uid);
      await _analytics?.logEvent(name: 'login', parameters: {'method': method});

      if (isNewUser) {
        await _analytics?.logEvent(
          name: 'user_registration',
          parameters: {'method': method, 'user_type': 'pending'},
        );
      }

      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      await _analytics?.logEvent(
        name: 'login_error',
        parameters: {
          'method': method,
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
        },
      );
      return Left(AuthFailure(message: e.message ?? 'Authentication failed'));
    } catch (e) {
      await _analytics?.logEvent(
        name: 'login_error',
        parameters: {
          'method': method,
          'error_code': 'unknown',
          'error_message': e.toString(),
        },
      );
      return Left(AuthFailure(message: e.toString()));
    }
  }

  Future<bool> _ensureUserProfileExists(User user) async {
    final existingProfile = await _dataSource.fetchUserProfile(user.uid);
    if (existingProfile != null) {
      return false;
    }

    final email = user.email;
    if (email == null || email.isEmpty) {
      throw Exception('A conta social não retornou um e-mail válido.');
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
  return ref.watch(authRepositoryProvider).authStateChanges();
}

/// Stream provider for the current user's profile data from Firestore.
///
/// Returns `null` if the user is not authenticated or profile doesn't exist.
@riverpod
Stream<AppUser?> currentUserProfile(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(authRepositoryProvider).watchUser(user.uid);
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
