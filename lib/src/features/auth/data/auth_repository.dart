import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/typedefs.dart';
import '../domain/app_user.dart';
import 'auth_remote_data_source.dart';

part 'auth_repository.g.dart';

/// Manages user authentication and Firestore profile data using the Result pattern.
class AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepository(this._dataSource);

  Stream<User?> authStateChanges() => _dataSource.authStateChanges();

  User? get currentUser => _dataSource.currentUser;

  /// Signs in a user. Returns [Right(Unit)] on success or [Left(AuthFailure)].
  FutureResult<Unit> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      await _dataSource.signInWithEmailAndPassword(email, password);
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: e.message ?? 'Authentication failed'));
    } catch (e) {
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
        final appUser = AppUser(
          uid: user.uid,
          email: email,
          cadastroStatus: RegistrationStatus.pending,
          createdAt: FieldValue.serverTimestamp(),
        );
        await _dataSource.saveUserProfile(appUser);
      }
      return const Right(unit);
    } on FirebaseAuthException catch (e) {
      return Left(AuthFailure(message: e.message ?? 'Registration failed'));
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  FutureResult<Unit> signOut() async {
    try {
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
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final dataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepository(dataSource);
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
