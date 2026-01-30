import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../../auth/data/auth_repository.dart';

/// Provides a list of blocked user IDs for the current user.
final blockedUsersProvider = StreamProvider<List<String>>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .doc(user.uid)
      .collection(FirestoreCollections.blocked)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});
