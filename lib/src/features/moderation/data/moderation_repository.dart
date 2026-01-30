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
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
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
      // Add to user's blocked collection
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection(FirestoreCollections.blocked)
          .doc(blockedUserId)
          .set({
            'blockedUserId': blockedUserId,
            'blockedAt': FieldValue.serverTimestamp(),
          });

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
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(currentUserId)
          .collection(FirestoreCollections.blocked)
          .doc(blockedUserId)
          .delete();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao desbloquear usuário: $e'));
    }
  }
}
