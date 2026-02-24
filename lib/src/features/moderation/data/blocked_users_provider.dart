import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../../auth/data/auth_repository.dart';

/// Provides a list of blocked user IDs for the current user.
final blockedUsersProvider = StreamProvider<List<String>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection(FirestoreCollections.users)
      .doc(authUser.uid)
      .collection(FirestoreCollections.blocked)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
});
