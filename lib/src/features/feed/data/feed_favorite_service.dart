import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/feed_item.dart';

part 'feed_favorite_service.g.dart';

/// Service responsável pela lógica de escrita e leitura de favoritos (V8).
///
/// Arquitetura:
/// - Escrita: Transaction (Atômica).
/// - Leitura status: Stream doc `users/{meuId}/favorites/{targetId}`.
/// - Leitura contador: Stream doc `users/{targetId}` field `favoriteCount`.
class FeedFavoriteService {
  final FirebaseFirestore _firestore;

  FeedFavoriteService(this._firestore);

  /// Alterna o favorito de forma atômica.
  ///
  /// Se existir: Remove doc e decrementa contador.
  /// Se não existir: Cria doc (com metadados denormalizados) e incrementa contador.
  Future<void> toggleFavorite({
    required String meuId,
    required FeedItem target,
  }) async {
    final targetId = target.uid;
    final favoriteRef = _firestore
        .collection('users')
        .doc(meuId)
        .collection('favorites')
        .doc(targetId);

    final targetRef = _firestore.collection('users').doc(targetId);

    await _firestore.runTransaction((transaction) async {
      final favoriteDoc = await transaction.get(favoriteRef);
      // Otimização: ler apenas para garantir que existe, sem baixar todo o payload se possível
      // Mas em clients SDK precisa ler o documento.
      final targetDoc = await transaction.get(targetRef);

      if (!targetDoc.exists) {
        throw Exception('Usuário alvo não encontrado.');
      }

      if (favoriteDoc.exists) {
        // Remover favorito
        transaction.delete(favoriteRef);
        transaction.update(targetRef, {
          'favoriteCount': FieldValue.increment(-1),
        });
      } else {
        // Adicionar favorito
        transaction.set(favoriteRef, {
          'createdAt': FieldValue.serverTimestamp(),
          'targetId': targetId,
          'targetName': target.displayName,
          'targetPhoto': target.foto ?? '',
          'targetRole': target.categoria ?? target.tipoPerfil,
          'targetGenres': target.generosMusicais,
          // V8.2 Rich UI Data (Denormalization)
          'targetSkills': target.skills,
          'targetLocation': target.location,
        });

        transaction.update(targetRef, {
          'favoriteCount': FieldValue.increment(1),
        });
      }
    });
  }

  /// Stream que monitora se eu curti este alvo.
  /// Retorna true sse o documento de favorito existir.
  Stream<bool> isFavoritedStream({
    required String meuId,
    required String targetId,
  }) {
    return _firestore
        .collection('users')
        .doc(meuId)
        .collection('favorites')
        .doc(targetId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Stream que monitora o contador global de favoritos deste alvo.
  Stream<int> favoriteCountStream({required String targetId}) {
    return _firestore.collection('users').doc(targetId).snapshots().map((doc) {
      if (!doc.exists) return 0;
      final data = doc.data();
      if (data == null) return 0;
      return (data['favoriteCount'] as int?) ?? 0;
    });
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

@Riverpod(keepAlive: true)
FeedFavoriteService feedFavoriteService(Ref ref) {
  return FeedFavoriteService(FirebaseFirestore.instance);
}

/// Provider family para verificar se um item é favorito.
@riverpod
Stream<bool> isFavorited(Ref ref, String targetId) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return Stream.value(false);

  final service = ref.watch(feedFavoriteServiceProvider);
  return service.isFavoritedStream(meuId: user.uid, targetId: targetId);
}

/// Provider family para observar a contagem de favoritos de um item.
@riverpod
Stream<int> favoriteCount(Ref ref, String targetId) {
  final service = ref.watch(feedFavoriteServiceProvider);
  return service.favoriteCountStream(targetId: targetId);
}
