import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/app_user.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._firestore);

  // Stream de mudanças no Auth State
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // Pegar usuário atual
  User? get currentUser => _auth.currentUser;

  // Login
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Cadastro (Cria no Auth e no Firestore)
  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // 1. Criar no Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;

    if (user != null) {
      // 2. Criar Documento Inicial no Firestore
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        cadastroStatus: 'tipo_pendente', // Status Inicial
        createdAt: FieldValue.serverTimestamp(),
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toJson());
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Buscar dados do perfil
  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return AppUser.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Atualizar dados do usuário (Onboarding/Edit Profile)
  Future<void> updateUser(AppUser user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toJson(), SetOptions(merge: true));
  }

  // Excluir Conta (Arquivar e Deletar)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 1. Copiar dados para 'deleted_users' (Arquivo Morto)
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final userData = userDoc.data()!;
      userData['deletedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('deleted_users').doc(user.uid).set(userData);
    }

    // 2. Deletar do 'users' (Coleção Ativa)
    await _firestore.collection('users').doc(user.uid).delete();

    // 3. Deletar do Auth
    // Isso pode lançar 'requires-recent-login', deve ser tratado na UI/Controller
    await user.delete();
  }
}

// Providers
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
}

@Riverpod(keepAlive: true)
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

// Provider do AppUser atual (dados do Firestore)
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
