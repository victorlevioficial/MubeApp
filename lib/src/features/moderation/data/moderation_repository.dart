import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failures.dart';
import '../../../core/typedefs.dart';

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(FirebaseFirestore.instance);
});

class ModerationRepository {
  final FirebaseFirestore _firestore;

  ModerationRepository(this._firestore);

  /// Reports a user.
  FutureResult<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _firestore.collection(FirestoreCollections.reports).add({
        'reporter_user_id': reporterId,
        'reported_item_id': reportedUserId,
        'reported_item_type': 'user',
        'reason': reason,
        'description': description,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao enviar denúncia: $e'));
    }
  }

  /// Blocks a user.
  FutureResult<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      final userRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId);
      final blockedRef = userRef
          .collection(FirestoreCollections.blocked)
          .doc(blockedUserId);

      final batch = _firestore.batch();

      // Fonte nova (subcoleção)
      batch.set(blockedRef, {
        'blockedUserId': blockedUserId,
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // Fonte legada (array no documento) para compatibilidade com listas já existentes.
      batch.update(userRef, {
        'blocked_users': FieldValue.arrayUnion([blockedUserId]),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao bloquear usuário: $e'));
    }
  }

  /// Unblocks a user.
  FutureResult<void> unblockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    try {
      final userRef = _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId);
      final blockedRef = userRef
          .collection(FirestoreCollections.blocked)
          .doc(blockedUserId);

      final batch = _firestore.batch();
      batch.delete(blockedRef);
      batch.update(userRef, {
        'blocked_users': FieldValue.arrayRemove([blockedUserId]),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao desbloquear usuário: $e'));
    }
  }
}
