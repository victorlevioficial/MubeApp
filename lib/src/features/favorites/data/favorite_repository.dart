import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_repository.g.dart';

class FavoriteRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FavoriteRepository(this._firestore, this._auth);

  /// Retorna o UID do usuário atual ou lança erro se não autenticado
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');
    return user.uid;
  }

  /// Carrega os IDs dos itens favoritados pelo usuário
  Future<Set<String>> loadFavorites() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_uid)
          .collection('favorites')
          .get();

      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      // Em caso de erro (ex: offline), retorna vazio ou lança
      // Por enquanto, log e retorna vazio para não quebrar UI
      print('Erro ao carregar favoritos: $e');
      return {};
    }
  }

  /// Carrega a contagem de likes de um item específico (global)
  Future<int> getLikeCount(String targetId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(targetId).get();
      if (doc.exists) {
        return (doc.data()?['likeCount'] as int?) ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Adiciona um favorito (com transaction para contador global)
  Future<void> addFavorite(String targetId) async {
    final userRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(targetId);

    // Atualizar o contador na mesma coleção de onde lemos (users)
    final targetUserRef = _firestore.collection('users').doc(targetId);

    return _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final targetUserDoc = await transaction.get(targetUserRef);

      if (userDoc.exists) return; // Já favoritado

      // 1. Adiciona na lista do usuário
      transaction.set(userRef, {'favoritedAt': FieldValue.serverTimestamp()});

      // 2. Incrementa contador global no doc do usuário-alvo (não em 'profiles')
      if (targetUserDoc.exists) {
        transaction.update(targetUserRef, {
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  /// Remove um favorito (com transaction para contador global)
  Future<void> removeFavorite(String targetId) async {
    final userRef = _firestore
        .collection('users')
        .doc(_uid)
        .collection('favorites')
        .doc(targetId);

    final targetUserRef = _firestore.collection('users').doc(targetId);

    return _firestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      final targetUserDoc = await transaction.get(targetUserRef);

      if (!userDoc.exists) return; // Já removido

      // 1. Remove da lista do usuário
      transaction.delete(userRef);

      // 2. Decrementa contador global
      if (targetUserDoc.exists) {
        final currentCount = (targetUserDoc.data()?['likeCount'] as int?) ?? 0;
        if (currentCount > 0) {
          transaction.update(targetUserRef, {
            'likeCount': FieldValue.increment(-1),
          });
        }
      }
    });
  }
}

@Riverpod(keepAlive: true)
FavoriteRepository favoriteRepository(Ref ref) {
  return FavoriteRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
}
