import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../utils/app_check_refresh_coordinator.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/geohash_helper.dart';
import '../../../utils/public_username.dart';
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

  /// Persists the final onboarding write that flips
  /// `cadastro_status` to `concluido` and assigns the initial
  /// account `status` ('ativo' or 'rascunho' for bands). The
  /// server-side rules validate that this transition is legal.
  Future<void> completeOnboardingProfile(AppUser user);
  Future<String> updatePublicUsername(String username);
  Future<AppUser?> fetchUserProfile(String uid);
  Future<AppUser?> fetchUserProfileByUsername(String username);
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
  static const Duration _forcedAppCheckRefreshCooldown = Duration(minutes: 2);
  static const Duration _throttledAppCheckBackoff = Duration(minutes: 10);
  static const int _firestoreWhereInLimit = 30;
  static const String _googleServerClientId =
      '798301748829-lrgta4d45h0k1d1o1vbpuhd7447e6121.apps.googleusercontent.com';
  static const String _googleIosClientId =
      '798301748829-oi72iiabk4jjdib7kgu4un3ugjs2a4c5.apps.googleusercontent.com';
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final FirebaseFunctions _publicUsernameFunctions;
  final app_check.FirebaseAppCheck _appCheck;
  Future<void>? _inFlightSecurityContextRefresh;
  bool _googleSignInInitialized = false;
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
    'username',
  };

  AuthRemoteDataSourceImpl(
    this._auth,
    this._firestore, {
    required FirebaseFunctions functions,
    FirebaseFunctions? publicUsernameFunctions,
    required app_check.FirebaseAppCheck appCheck,
  }) : _functions = functions,
       _publicUsernameFunctions = publicUsernameFunctions ?? functions,
       _appCheck = appCheck;

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

    await _ensureGoogleSignInInitialized();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'operation-not-supported',
        message: 'Google Sign-In não é suportado nesta plataforma.',
      );
    }

    final googleUser = await _authenticateWithGoogle();
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

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? _googleIosClientId
          : null,
      serverClientId: _googleServerClientId,
    );
    _googleSignInInitialized = true;
  }

  Future<GoogleSignInAccount> _authenticateWithGoogle() async {
    try {
      return await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      throw _mapGoogleSignInException(error);
    }
  }

  FirebaseAuthException _mapGoogleSignInException(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return FirebaseAuthException(
          code: 'sign-in-cancelled',
          message: 'Login social cancelado.',
        );
      case GoogleSignInExceptionCode.interrupted:
        return FirebaseAuthException(
          code: 'sign-in-interrupted',
          message: 'Login social interrompido.',
        );
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return FirebaseAuthException(
          code: 'google-sign-in-misconfigured',
          message: error.description ?? 'Google Sign-In mal configurado.',
        );
      case GoogleSignInExceptionCode.uiUnavailable:
        return FirebaseAuthException(
          code: 'google-sign-in-unavailable',
          message:
              error.description ??
              'Google Sign-In indisponível neste dispositivo.',
        );
      case GoogleSignInExceptionCode.userMismatch:
      case GoogleSignInExceptionCode.unknownError:
        return FirebaseAuthException(
          code: 'invalid-credential',
          message:
              error.description ?? 'Não foi possível autenticar com o Google.',
        );
    }
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

  @override
  Future<void> completeOnboardingProfile(AppUser user) async {
    final data = _prepareUserData(
      user,
      forUpdate: true,
      allowAccountStatus: true,
    );
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<String> updatePublicUsername(String username) async {
    final normalizedUsername = normalizedPublicUsernameOrNull(username);
    if (normalizedUsername == null) {
      throw Exception('Escolha um @usuario.');
    }

    try {
      try {
        await refreshSecurityContext();
      } catch (e) {
        // Best-effort: setPublicUsername does not enforce App Check on the
        // server, so proceed even when the local token refresh fails.
        AppLogger.warning(
          'Security context refresh failed before setPublicUsername – proceeding anyway',
          e,
        );
      }

      final result = await _callFunctionWithRecovery(
        'setPublicUsername',
        data: {'username': normalizedUsername},
        functions: _publicUsernameFunctions,
      );

      final payload = result.data;
      if (payload is Map<Object?, Object?>) {
        final returnedUsername = normalizedPublicUsernameOrNull(
          payload['username']?.toString(),
        );
        if (returnedUsername != null) {
          return returnedUsername;
        }
      }

      return normalizedUsername;
    } on FirebaseFunctionsException catch (error, stack) {
      AppLogger.error(
        'Error calling setPublicUsername function in $_functionsRegion:',
        error,
        stack,
      );
      throw _mapPublicUsernameFunctionError(error);
    } on FirebaseException catch (error, stack) {
      AppLogger.error(
        'Error calling setPublicUsername function in $_functionsRegion:',
        error,
        stack,
      );
      throw _mapPublicUsernameUnexpectedError(error);
    } catch (error, stack) {
      AppLogger.error(
        'Unexpected error calling setPublicUsername function in $_functionsRegion:',
        error,
        stack,
      );
      throw _mapPublicUsernameUnexpectedError(error);
    }
  }

  /// Prepara os dados do usuário adicionando geohash automaticamente.
  ///
  /// Quando [allowAccountStatus] é true, o campo `status` é preservado
  /// para que a transição final do onboarding (perfil_pendente ->
  /// concluido) possa atribuir 'ativo' ou 'rascunho'. As Firestore Rules
  /// continuam sendo a fonte de verdade que valida a transição.
  Map<String, dynamic> _prepareUserData(
    AppUser user, {
    bool forCreate = false,
    bool forUpdate = false,
    bool allowAccountStatus = false,
  }) {
    final data = user.toFirestore();

    if (forCreate || forUpdate) {
      for (final key in _blockedClientUpdateKeys) {
        if (allowAccountStatus && key == 'status') continue;
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
  Future<AppUser?> fetchUserProfileByUsername(String username) async {
    final normalizedUsername = normalizedPublicUsernameOrNull(username);
    if (normalizedUsername == null) {
      return null;
    }

    final query = await _firestore
        .collection(FirestoreCollections.users)
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return AppUser.fromJson(query.docs.first.data());
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
      }).distinct();
    })();
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();

    if (kIsWeb) {
      return;
    }

    try {
      await _ensureGoogleSignInInitialized();
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.signOut();
      }
    } on GoogleSignInException catch (error, stack) {
      AppLogger.warning(
        'Falha ao encerrar sessao do Google Sign-In',
        error,
        stack,
      );
    } catch (error, stack) {
      AppLogger.warning(
        'Falha inesperada ao encerrar sessao do Google Sign-In',
        error,
        stack,
      );
    }
  }

  bool _isRecoverableFunctionsError(FirebaseFunctionsException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code == 'unauthenticated') return true;

    final mentionsAppCheck = message.contains('app check');
    return mentionsAppCheck &&
        (code == 'failed-precondition' || code == 'permission-denied');
  }

  Future<void> _refreshFunctionSecurityContext() async {
    await refreshSecurityContext();
  }

  Future<HttpsCallableResult<dynamic>> _invokeCallable(
    FirebaseFunctions functions,
    String functionName, {
    Object? data,
  }) {
    final callable = functions.httpsCallable(functionName);
    return callable.call(data);
  }

  Future<HttpsCallableResult<dynamic>> _callFunctionWithRecovery(
    String functionName, {
    Object? data,
    FirebaseFunctions? functions,
  }) async {
    final targetFunctions = functions ?? _functions;

    try {
      return await _invokeCallable(targetFunctions, functionName, data: data);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRecoverableFunctionsError(error)) rethrow;

      AppLogger.warning(
        '$functionName retornou ${error.code}. Atualizando contexto de seguranca e tentando novamente.',
      );
      await _refreshFunctionSecurityContext();
      return await _invokeCallable(targetFunctions, functionName, data: data);
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

  Exception _mapPublicUsernameFunctionError(FirebaseFunctionsException error) {
    final message = error.message?.trim();
    final messageLower = (error.message ?? '').toLowerCase();

    if (messageLower.contains('app check') ||
        messageLower.contains('appcheck')) {
      return Exception(
        'Falha na validacao de seguranca do app. Atualize o aplicativo e tente novamente.',
      );
    }

    switch (error.code.toLowerCase()) {
      case 'invalid-argument':
      case 'already-exists':
      case 'not-found':
        return Exception(
          message?.isNotEmpty == true
              ? message
              : 'Nao foi possivel atualizar o @usuario.',
        );
      case 'unauthenticated':
        return Exception(
          'Sua sessao expirou. Entre novamente antes de alterar o @usuario.',
        );
      case 'permission-denied':
      case 'failed-precondition':
        return Exception(
          'A alteracao do @usuario foi bloqueada pelo servidor. Tente novamente em instantes.',
        );
      default:
        return Exception(
          message?.isNotEmpty == true
              ? message
              : 'Erro inesperado ao atualizar o @usuario.',
        );
    }
  }

  Exception _mapPublicUsernameUnexpectedError(Object error) {
    final rawMessage = error.toString().trim();
    final message = rawMessage.replaceFirst('Exception: ', '').trim();
    final messageLower = message.toLowerCase();

    if (messageLower.contains('app check') ||
        messageLower.contains('appcheck')) {
      return Exception(
        'Falha na validacao de seguranca do app. Atualize o aplicativo e tente novamente.',
      );
    }

    if (messageLower == 'not_found' ||
        messageLower == 'not-found' ||
        messageLower.contains('[firebase_functions/not-found]') ||
        messageLower.contains('firebase_functions/not-found')) {
      return Exception(
        'Servico de @usuario indisponivel. Verifique a Cloud Function setPublicUsername em $_functionsRegion.',
      );
    }

    return Exception(
      message.isNotEmpty ? message : 'Erro inesperado ao atualizar o @usuario.',
    );
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

    final orderedUsersById = <String, AppUser>{};
    final requestedIds = uids.where((id) => id.trim().isNotEmpty).toList();

    for (
      var index = 0;
      index < requestedIds.length;
      index += _firestoreWhereInLimit
    ) {
      final end = (index + _firestoreWhereInLimit < requestedIds.length)
          ? index + _firestoreWhereInLimit
          : requestedIds.length;
      final batchIds = requestedIds.sublist(index, end);

      final query = await _firestore
          .collection(FirestoreCollections.users)
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      for (final doc in query.docs) {
        orderedUsersById[doc.id] = AppUser.fromJson(doc.data());
      }
    }

    return requestedIds
        .map((id) => orderedUsersById[id])
        .whereType<AppUser>()
        .toList(growable: false);
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
    final inFlightRefresh = _inFlightSecurityContextRefresh;
    if (inFlightRefresh != null) {
      return inFlightRefresh;
    }

    final refreshFuture = _performSecurityContextRefresh().whenComplete(() {
      _inFlightSecurityContextRefresh = null;
    });
    _inFlightSecurityContextRefresh = refreshFuture;
    return refreshFuture;
  }

  Future<void> _performSecurityContextRefresh() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'Nenhum usuario autenticado disponivel para refresh.',
      );
    }

    await currentUser.getIdToken(true);
    await currentUser.reload();
    await AppCheckRefreshCoordinator.ensureValidTokenOrThrow(
      _appCheck,
      operationLabel: 'refresh de sessao',
      forcedRefreshCooldown: _forcedAppCheckRefreshCooldown,
      throttledBackoff: _throttledAppCheckBackoff,
    );
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    ref.read(firebaseAuthProvider),
    ref.read(firebaseFirestoreProvider),
    functions: ref.read(firebaseFunctionsProvider),
    appCheck: ref.read(firebaseAppCheckProvider),
  );
});
