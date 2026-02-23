import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../constants/firestore_constants.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/geohash_helper.dart';
import '../domain/app_user.dart';

/// Interface for raw data access
abstract class AuthRemoteDataSource {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<User?> registerWithEmailAndPassword(String email, String password);
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<void> saveUserProfile(AppUser user);
  Future<void> updateUserProfile(AppUser user);
  Future<AppUser?> fetchUserProfile(String uid);
  Stream<AppUser?> watchUserProfile(String uid);
  Future<void> signOut();
  Future<void> deleteAccount(String uid);
  Future<List<AppUser>> fetchUsersByIds(List<String> uids);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> reloadUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static const Set<String> _blockedClientUpdateKeys = {
    'status',
    'report_count',
    'report_count_total',
    'suspended_until',
    'suspension_end_date',
    'daily_likes_count',
    'last_like_date',
    'daily_swipes_count',
    'last_swipe_date',
    'total_likes_sent',
    'total_dislikes_sent',
    'likeCount',
    'favorites_count',
    'members',
    'private_stats',
    'plan',
  };

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
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      return _auth.signInWithPopup(provider);
    }

    await GoogleSignIn.instance.initialize();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'operation-not-supported',
        message: 'Google Sign-In não é suportado nesta plataforma.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Falha ao obter token de autenticação do Google.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);

    return _auth.signInWithCredential(credential);
  }

  @override
  Future<UserCredential> signInWithApple() async {
    final appleProvider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    if (kIsWeb) {
      return _auth.signInWithPopup(appleProvider);
    }

    return _auth.signInWithProvider(appleProvider);
  }

  @override
  Future<void> saveUserProfile(AppUser user) async {
    final data = _prepareUserData(user);
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(data);
  }

  @override
  Future<void> updateUserProfile(AppUser user) async {
    final data = _prepareUserData(user, forUpdate: true);
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  /// Prepara os dados do usuário adicionando geohash automaticamente
  Map<String, dynamic> _prepareUserData(
    AppUser user, {
    bool forUpdate = false,
  }) {
    final data = user.toFirestore();

    if (forUpdate) {
      for (final key in _blockedClientUpdateKeys) {
        data.remove(key);
      }
      // Avoid noisy writes/denied updates for null fields.
      data.removeWhere((_, value) => value == null);
    }

    // Adiciona geohash automaticamente se tiver localização
    if (user.location != null &&
        user.location!['lat'] != null &&
        user.location!['lng'] != null) {
      try {
        final lat = (user.location!['lat'] as num).toDouble();
        final lng = (user.location!['lng'] as num).toDouble();
        final geohash = GeohashHelper.encode(lat, lng, precision: 5);
        data['geohash'] = geohash;
        AppLogger.info('📍 Geohash gerado: $geohash para usuário ${user.uid}');
      } catch (e) {
        AppLogger.warning('⚠️ Erro ao gerar geohash: $e');
      }
    }

    return data;
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

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});
