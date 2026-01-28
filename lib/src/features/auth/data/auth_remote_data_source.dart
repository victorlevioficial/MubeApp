import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../domain/app_user.dart';

/// Interface for raw data access
abstract class AuthRemoteDataSource {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<User?> registerWithEmailAndPassword(String email, String password);
  Future<void> saveUserProfile(AppUser user);
  Future<void> updateUserProfile(AppUser user);
  Future<AppUser?> fetchUserProfile(String uid);
  Stream<AppUser?> watchUserProfile(String uid);
  Future<void> signOut();
  Future<void> deleteAccount(String uid);
  Future<List<AppUser>> fetchUsersByIds(List<String> uids);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl(this._auth, this._firestore);

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  @override
  Future<void> saveUserProfile(AppUser user) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(user.toJson());
  }

  @override
  Future<void> updateUserProfile(AppUser user) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<AppUser?> fetchUserProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      return AppUser.fromJson(doc.data()!);
    }
    return null;
  }

  @override
  Stream<AppUser?> watchUserProfile(String uid) {
    return _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return AppUser.fromJson(doc.data()!);
          }
          return null;
        });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw Exception('No matching auth user');
    }

    // Archive
    final userDoc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();
    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data()!;
      userData[FirestoreFields.deletedAt] = FieldValue.serverTimestamp();
      await _firestore
          .collection(FirestoreCollections.deletedUsers)
          .doc(uid)
          .set(userData);
    }

    // Delete Doc
    await _firestore.collection(FirestoreCollections.users).doc(uid).delete();

    // Delete Auth
    await user.delete();
  }

  @override
  Future<List<AppUser>> fetchUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];

    // Firestore limits 'whereIn' to 30 items.
    // For now we assume typical band size < 30.
    // Production app should batch this if needed.
    final query = await _firestore
        .collection(FirestoreCollections.users)
        .where(FieldPath.documentId, whereIn: uids.take(30).toList())
        .get();

    return query.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});
