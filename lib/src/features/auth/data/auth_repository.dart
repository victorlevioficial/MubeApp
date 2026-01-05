import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/app_user.dart';

part 'auth_repository.g.dart';

/// Manages user authentication and Firestore profile data.
///
/// This repository handles:
/// - Email/password authentication (login, register)
/// - Session state via [authStateChanges]
/// - User profile CRUD operations
/// - Account deletion with data archival
///
/// See also:
/// - [AppUser] for the user data model
/// - [AuthGuard] for route protection based on auth state
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Creates an [AuthRepository] with the given Firebase instances.
  AuthRepository(this._auth, this._firestore);

  /// Stream of authentication state changes.
  ///
  /// Emits `null` when the user signs out.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// The currently authenticated Firebase user, or `null` if signed out.
  User? get currentUser => _auth.currentUser;

  /// Signs in a user with email and password.
  ///
  /// Throws [FirebaseAuthException] if:
  /// - Email is invalid or not registered
  /// - Password is incorrect
  /// - Account is disabled
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Registers a new user with email and password.
  ///
  /// Creates both a Firebase Auth account and a Firestore user document
  /// with initial status `tipo_pendente` (pending type selection).
  ///
  /// Throws [FirebaseAuthException] if:
  /// - Email is already in use
  /// - Password is too weak
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;

    if (user != null) {
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        cadastroStatus: 'tipo_pendente',
        createdAt: FieldValue.serverTimestamp(),
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toJson());
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Watches the user document for real-time updates.
  ///
  /// Returns a stream that emits [AppUser] when data changes,
  /// or `null` if the document doesn't exist.
  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  /// Updates the user profile in Firestore.
  ///
  /// Uses merge mode to only update provided fields.
  Future<void> updateUser(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  /// Deletes the user account permanently.
  ///
  /// This operation:
  /// 1. Archives user data to `deleted_users` collection
  /// 2. Deletes the user document from `users`
  /// 3. Deletes the Firebase Auth account
  ///
  /// Throws [FirebaseAuthException] with code `requires-recent-login`
  /// if the user hasn't signed in recently. Handle this by prompting
  /// for re-authentication.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Archive user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data()!;
      userData['deletedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('deleted_users').doc(user.uid).set(userData);
    }

    // Delete from active collection
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete auth account (may throw requires-recent-login)
    await user.delete();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Provides a singleton [AuthRepository] instance.
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
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
    error: (_, __) => const Stream.empty(),
  );
}
