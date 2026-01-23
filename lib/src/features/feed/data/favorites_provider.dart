import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/feed_item.dart';

part 'favorites_provider.g.dart';

/// ============================================================================
/// SISTEMA DE LIKES - ARQUITETURA PROFISSIONAL
/// ============================================================================
///
/// Estrutura no Firestore:
///
/// likes/{likeId}
///   ├── fromUserId: String (quem deu o like)
///   ├── toUserId: String (quem recebeu o like)
///   └── createdAt: Timestamp
///
/// Onde likeId = "${fromUserId}_${toUserId}" (garante unicidade/idempotência)
///
/// users/{userId}
///   └── favoriteCount: int (atualizado atomicamente via transação)
///
/// ============================================================================

/// Controller para gerenciar likes do usuário logado.
///
/// Usa documentos individuais na coleção `likes/` com ID composto,
/// garantindo operações idempotentes e sem duplicação.
@riverpod
class LikesController extends _$LikesController {
  @override
  FutureOr<Set<String>> build() async {
    // Observar mudanças no usuário para invalidar estado no logout
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    if (user == null) {
      return {};
    }

    return _loadUserLikes(user.uid);
  }

  /// Carrega todos os IDs que o usuário atual curtiu
  Future<Set<String>> _loadUserLikes(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('likes')
          .where('fromUserId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['toUserId'] as String)
          .toSet();
    } catch (e) {
      debugPrint('Erro ao carregar likes: $e');
      return {};
    }
  }

  /// Alterna o estado de like de forma atômica e idempotente.
  /// Retorna true se o item está agora curtido, false se não está.
  Future<bool> toggleLike(String targetUserId) async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      debugPrint('toggleLike: usuário não logado');
      return false;
    }

    final currentUserId = user.uid;

    // Prevenir auto-like
    if (currentUserId == targetUserId) {
      debugPrint('toggleLike: usuário tentou curtir a si mesmo');
      return false;
    }

    final likeDocId = '${currentUserId}_$targetUserId';
    final likeRef = FirebaseFirestore.instance
        .collection('likes')
        .doc(likeDocId);
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(targetUserId);

    try {
      // Usar transação para garantir atomicidade
      final result = await FirebaseFirestore.instance.runTransaction<bool>((
        transaction,
      ) async {
        final likeDoc = await transaction.get(likeRef);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Usuário alvo não existe');
        }

        final currentCount = userDoc.data()?['favoriteCount'] ?? 0;

        if (likeDoc.exists) {
          // Remover like
          transaction.delete(likeRef);
          transaction.update(userRef, {
            'favoriteCount': (currentCount - 1).clamp(0, 999999),
          });
          return false;
        } else {
          // Adicionar like
          transaction.set(likeRef, {
            'fromUserId': currentUserId,
            'toUserId': targetUserId,
            'createdAt': FieldValue.serverTimestamp(),
          });
          transaction.update(userRef, {'favoriteCount': currentCount + 1});
          return true;
        }
      });

      // Atualizar estado local
      final currentSet = state.asData?.value ?? {};
      if (result) {
        state = AsyncData({...currentSet, targetUserId});
      } else {
        state = AsyncData({...currentSet}..remove(targetUserId));
      }

      return result;
    } catch (e) {
      debugPrint('Erro em toggleLike: $e');
      // Em caso de erro, forçar recarregamento do estado
      ref.invalidateSelf();
      rethrow;
    }
  }

  /// Verifica se um item está curtido (leitura local, sem rede)
  bool isLiked(String targetUserId) {
    return state.asData?.value.contains(targetUserId) ?? false;
  }
}

// =============================================================================
// PROVIDERS DE CONVENIÊNCIA
// =============================================================================

/// Verifica se um item específico está curtido pelo usuário atual.
/// Otimizado para reconstruir apenas quando este ID específico muda.
@riverpod
bool isLiked(Ref ref, String targetUserId) {
  final likesState = ref.watch(likesControllerProvider);
  return likesState.asData?.value.contains(targetUserId) ?? false;
}

/// Retorna a quantidade de likes que o usuário atual deu.
@riverpod
int userLikesCount(Ref ref) {
  final likesState = ref.watch(likesControllerProvider);
  return likesState.asData?.value.length ?? 0;
}

/// Provider para carregar a lista completa de perfis curtidos pelo usuário.
/// Usado na tela "Meus Favoritos".
///
/// autoDispose: cache é limpo quando a tela fecha, garantindo shimmer ao reabrir.
/// Busca da subcoleção users/{uid}/favorites/ (onde feed_favorite_service salva)
/// e depois carrega dados completos de cada perfil da coleção users/.
final likedProfilesProvider = FutureProvider.autoDispose<List<FeedItem>>((
  ref,
) async {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return [];

  // Buscar IDs dos favoritos da subcoleção correta
  final favoritesSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .orderBy('createdAt', descending: true)
      .get();

  if (favoritesSnapshot.docs.isEmpty) return [];

  // Carregar dados completos de cada perfil favorito
  final items = await Future.wait(
    favoritesSnapshot.docs.map((favDoc) async {
      final targetId = favDoc.data()['targetId'] as String? ?? favDoc.id;

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          return FeedItem.fromFirestore(
            userDoc.data()!,
            userDoc.id,
          ).copyWith(isFavorited: true);
        }
        return null;
      } catch (e) {
        debugPrint('Erro ao carregar perfil $targetId: $e');
        return null;
      }
    }),
  );

  return items.whereType<FeedItem>().toList();
});
