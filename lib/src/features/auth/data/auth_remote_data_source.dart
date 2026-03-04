import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
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
  Future<void> refreshSecurityContext();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final app_check.FirebaseAppCheck _appCheck;
  static const String _functionsRegion = 'southamerica-east1';
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

  AuthRemoteDataSourceImpl(
    this._auth,
    this._firestore, {
    FirebaseFunctions? functions,
    app_check.FirebaseAppCheck? appCheck,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: _functionsRegion),
       _appCheck = appCheck ?? app_check.FirebaseAppCheck.instance;

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
    final data = _prepareUserData(user, forCreate: true);
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
    bool forCreate = false,
    bool forUpdate = false,
  }) {
    final data = user.toFirestore();

    if (forCreate || forUpdate) {
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
    final docRef = _firestore.collection(FirestoreCollections.users).doc(uid);

    return (() async* {
      try {
        final cachedDoc = await docRef.get(
          const GetOptions(source: Source.cache),
        );
        if (cachedDoc.exists && cachedDoc.data() != null) {
          yield AppUser.fromJson(cachedDoc.data()!);
        }
      } on FirebaseException catch (error, stack) {
        AppLogger.debug(
          'Perfil em cache indisponivel para $uid: ${error.code}',
        );
        AppLogger.debug(stack.toString());
      }

      yield* docRef.snapshots(includeMetadataChanges: true).map((doc) {
        if (doc.exists && doc.data() != null) {
          return AppUser.fromJson(doc.data()!);
        }
        return null;
      });
    })();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  bool _isRecoverableFunctionsError(FirebaseFunctionsException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code == 'unauthenticated') return true;

    final mentionsAppCheck = message.contains('app check');
    return mentionsAppCheck &&
        (code == 'failed-precondition' || code == 'permission-denied');
  }

  Future<void> _refreshFunctionSecurityContext() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await currentUser.getIdToken(true);
      } catch (error, stack) {
        AppLogger.warning(
          'Falha ao atualizar token do FirebaseAuth antes do retry da Cloud Function',
          error,
          stack,
        );
      }
    }

    try {
      await _appCheck.getToken(true);
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao atualizar token do App Check antes do retry da Cloud Function',
        error,
        stack,
      );
    }
  }

  Future<HttpsCallableResult<dynamic>> _callFunctionWithRecovery(
    String functionName, {
    Object? data,
  }) async {
    final callable = _functions.httpsCallable(functionName);

    try {
      return await callable.call(data);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRecoverableFunctionsError(error)) rethrow;

      AppLogger.warning(
        '$functionName retornou ${error.code}. Atualizando contexto de seguranca e tentando novamente.',
      );
      await _refreshFunctionSecurityContext();
      return await callable.call(data);
    }
  }

  Exception _mapDeleteAccountFunctionError(FirebaseFunctionsException error) {
    switch (error.code.toLowerCase()) {
      case 'not-found':
        return Exception(
          'Servico de exclusao indisponivel. Verifique a Cloud Function deleteAccount em $_functionsRegion.',
        );
      case 'unauthenticated':
        return Exception(
          'Sua sessao expirou. Entre novamente antes de excluir a conta.',
        );
      case 'permission-denied':
      case 'failed-precondition':
        if ((error.message ?? '').toLowerCase().contains('app check')) {
          return Exception(
            'Falha na validacao de seguranca do app. Atualize o aplicativo e tente novamente.',
          );
        }
        return Exception(
          'A exclusao da conta foi bloqueada pelo servidor. Tente novamente em instantes.',
        );
      case 'internal':
        return Exception(
          'O servidor nao conseguiu excluir a conta agora. Tente novamente em instantes.',
        );
      default:
        return Exception(
          error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'Erro inesperado ao excluir a conta.',
        );
    }
  }

  @override
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw Exception('No matching auth user');
    }

    try {
      final result = await _callFunctionWithRecovery('deleteAccount');

      final data = result.data;
      final success = data is Map<Object?, Object?> && data['success'] == true;
      if (!success) {
        throw Exception('Failed to delete account from server');
      }

      // After successful server-side deletion, sign out the client
      await signOut();
    } on FirebaseFunctionsException catch (error, stack) {
      AppLogger.error(
        'Error calling deleteAccount function in $_functionsRegion:',
        error,
        stack,
      );
      throw _mapDeleteAccountFunctionError(error);
    } catch (e) {
      AppLogger.error('Error calling deleteAccount function:', e);
      throw Exception('Error deleting account: $e');
    }
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

  @override
  Future<void> refreshSecurityContext() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'Nenhum usuario autenticado disponivel para refresh.',
      );
    }

    await currentUser.getIdToken(true);
    await currentUser.reload();

    try {
      await _appCheck.getToken(true);
    } catch (error, stack) {
      AppLogger.warning(
        'Falha ao atualizar token do App Check durante refresh de sessao',
        error,
        stack,
      );
    }
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
    functions: FirebaseFunctions.instanceFor(
      region: AuthRemoteDataSourceImpl._functionsRegion,
    ),
    appCheck: app_check.FirebaseAppCheck.instance,
  );
});
