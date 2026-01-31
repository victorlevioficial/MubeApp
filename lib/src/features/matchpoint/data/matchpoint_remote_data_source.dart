import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

import '../../../constants/firestore_constants.dart';

abstract class MatchpointRemoteDataSource {
  Future<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> excludedUserIds, // Blocked users
    int limit = 50,
  });
  Future<void> saveInteraction({
    required String currentUserId,
    required String targetUserId,
    required String type, // 'like' or 'dislike'
  });
  Future<List<String>> fetchExistingInteractions(String currentUserId);
  Future<bool> checkMutualLike(String currentUserId, String targetUserId);
  Future<void> createMatch(String currentUserId, String targetUserId);
}

class MatchpointRemoteDataSourceImpl implements MatchpointRemoteDataSource {
  final FirebaseFirestore _firestore;

  MatchpointRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<AppUser>> fetchCandidates({
    required String currentUserId,
    required List<String> genres,
    required List<String> excludedUserIds,
    int limit = 20,
  }) async {
    // 1. Basic filtering in Firestore
    Query query = _firestore.collection(FirestoreCollections.users);

    // Active users only
    query = query.where(
      '${FirestoreFields.matchpointProfile}.${FirestoreFields.isActive}',
      isEqualTo: true,
    );

    // Filter by Genre (Array Contains Any)
    if (genres.isNotEmpty) {
      query = query.where(
        '${FirestoreFields.matchpointProfile}.${FirestoreFields.musicalGenres}',
        arrayContainsAny: genres
            .take(10)
            .toList(), // Limit 10 for 'in/array-contains-any'
      );
    }

    final snapshot = await query.limit(limit).get();

    // 2. Map to AppUser and filter blocked users
    return snapshot.docs
        .where(
          (doc) => doc.id != currentUserId && !excludedUserIds.contains(doc.id),
        )
        .map((doc) => AppUser.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> saveInteraction({
    required String currentUserId,
    required String targetUserId,
    required String type,
  }) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(currentUserId)
        .collection(FirestoreCollections.interactions)
        .doc(targetUserId)
        .set({
          FirestoreFields.type: type,
          FirestoreFields.timestamp: FieldValue.serverTimestamp(),
          FirestoreFields.targetId: targetUserId,
        });
  }

  @override
  Future<List<String>> fetchExistingInteractions(String currentUserId) async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .doc(currentUserId)
        .collection(FirestoreCollections.interactions)
        .where(FirestoreFields.type, whereIn: ['like', 'dislike'])
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<bool> checkMutualLike(
    String currentUserId,
    String targetUserId,
  ) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(targetUserId)
        .collection(FirestoreCollections.interactions)
        .doc(currentUserId)
        .get();

    return doc.exists && doc.data()?[FirestoreFields.type] == 'like';
  }

  @override
  Future<void> createMatch(String currentUserId, String targetUserId) async {
    // Create atomic Match document
    // In MVP, we do this client-side transactionally or just unsafe write.
    // Ideal: Cloud Function trigger on 'interactions' write.
    // For now, we write to 'matches' collection.

    final matchRef = _firestore.collection(FirestoreCollections.matches).doc();

    await matchRef.set({
      'users': [currentUserId, targetUserId],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
    });
  }
}

final matchpointRemoteDataSourceProvider = Provider<MatchpointRemoteDataSource>(
  (ref) {
    return MatchpointRemoteDataSourceImpl(FirebaseFirestore.instance);
  },
);
