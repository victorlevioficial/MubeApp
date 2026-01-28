import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';

/// Interface for raw feed data access
abstract class FeedRemoteDataSource {
  Future<QuerySnapshot<Map<String, dynamic>>> getNearbyUsers({
    required int limit,
  });

  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByType({
    required String type,
    required int limit,
    DocumentSnapshot? startAfter,
  });

  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByCategory({
    required String category,
    required int limit,
    DocumentSnapshot? startAfter,
  });

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid);

  Future<QuerySnapshot<Map<String, dynamic>>> getGeohashNeighbors({
    required List<String> neighbors,
    String? filterType,
    String? category,
  });

  Future<QuerySnapshot<Map<String, dynamic>>> getMainFeed({
    String? filterType,
    required int limit,
    DocumentSnapshot? startAfter,
  });

  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByIds(List<String> ids);
}

class FeedRemoteDataSourceImpl implements FeedRemoteDataSource {
  final FirebaseFirestore _firestore;

  FeedRemoteDataSourceImpl(this._firestore);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getNearbyUsers({
    required int limit,
  }) {
    return _firestore
        .collection(FirestoreCollections.users)
        .where(
          FirestoreFields.registrationStatus,
          isEqualTo: RegistrationStatus.complete,
        )
        .where(
          FirestoreFields.profileType,
          whereIn: [
            ProfileType.professional,
            ProfileType.band,
            ProfileType.studio,
          ],
        )
        .limit(limit)
        .get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByType({
    required String type,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    var query = _firestore
        .collection(FirestoreCollections.users)
        .where(
          FirestoreFields.registrationStatus,
          isEqualTo: RegistrationStatus.complete,
        )
        .where(FirestoreFields.profileType, isEqualTo: type)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByCategory({
    required String category,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    var query = _firestore
        .collection(FirestoreCollections.users)
        .where(
          FirestoreFields.registrationStatus,
          isEqualTo: RegistrationStatus.complete,
        )
        .where(FirestoreFields.profileType, isEqualTo: ProfileType.professional)
        .where(
          '${FirestoreFields.professional}.${FirestoreFields.category}',
          isEqualTo: category,
        )
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _firestore.collection(FirestoreCollections.users).doc(uid).get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getGeohashNeighbors({
    required List<String> neighbors,
    String? filterType,
    String? category,
  }) {
    var query = _firestore
        .collection(FirestoreCollections.users)
        .where(
          FirestoreFields.registrationStatus,
          isEqualTo: RegistrationStatus.complete,
        )
        .where(FirestoreFields.geohash, whereIn: neighbors);

    if (filterType != null && filterType.isNotEmpty) {
      query = query.where(FirestoreFields.profileType, isEqualTo: filterType);
    } else {
      query = query.where(
        FirestoreFields.profileType,
        whereIn: [
          ProfileType.professional,
          ProfileType.band,
          ProfileType.studio,
        ],
      );
    }

    if (category != null && category.isNotEmpty) {
      query = query.where(
        '${FirestoreFields.professional}.${FirestoreFields.category}',
        isEqualTo: category,
      );
    }

    return query.get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getMainFeed({
    String? filterType,
    required int limit,
    DocumentSnapshot? startAfter,
  }) {
    var query = _firestore
        .collection(FirestoreCollections.users)
        .where(
          FirestoreFields.registrationStatus,
          isEqualTo: RegistrationStatus.complete,
        );

    if (filterType != null &&
        filterType.isNotEmpty &&
        filterType != 'Perto de mim') {
      query = query.where(FirestoreFields.profileType, isEqualTo: filterType);
    } else if (filterType != 'Perto de mim') {
      query = query.where(
        FirestoreFields.profileType,
        whereIn: [
          ProfileType.professional,
          ProfileType.band,
          ProfileType.studio,
        ],
      );
    }

    if (limit > 0) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.get();
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getUsersByIds(List<String> ids) {
    if (ids.isEmpty) {
      return Future.value(
        _firestore
            .collection(FirestoreCollections.users)
            .where(FieldPath.documentId, whereIn: ['dummy'])
            .get(),
      ); // Return empty snapshot
    }

    // Firestore 'whereIn' supports up to 30 items (previously 10)
    // For safety and MVP, we limit to 30 or handle basic list.
    // If > 30, we should arguably loop, but for MVP let's slice or simple fetch.
    final limitedIds = ids.take(30).toList();

    return _firestore
        .collection(FirestoreCollections.users)
        .where(FieldPath.documentId, whereIn: limitedIds)
        .get();
  }
}

final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>((ref) {
  return FeedRemoteDataSourceImpl(FirebaseFirestore.instance);
});
