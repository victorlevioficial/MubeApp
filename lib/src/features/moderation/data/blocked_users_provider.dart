import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/firestore_constants.dart';
import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/firestore_resilience.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/data/auth_repository.dart';

const _firestoreResilience = FirestoreResilience('BlockedUsersProvider');

/// Provides a list of blocked user IDs for the current user.
final blockedUsersProvider = StreamProvider<List<String>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).value;
  if (authUser == null) return Stream.value([]);
  final firestore = ref.watch(firebaseFirestoreProvider);

  return _firestoreResilience.watch(
    () => firestore
        .collection(FirestoreCollections.users)
        .doc(authUser.uid)
        .collection(FirestoreCollections.blocked)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList()),
    operationLabel: 'watch_blocked_users',
    onFinalError: (error) => mapExceptionToFailure(error),
  );
});
