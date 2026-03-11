import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/errors/failure_mapper.dart';
import '../../../core/errors/firestore_resilience.dart';
import '../../../core/providers/firebase_providers.dart';
import '../domain/ticket_model.dart';

part 'support_repository.g.dart';

@Riverpod(keepAlive: true)
SupportRepository supportRepository(Ref ref) {
  return SupportRepository(ref.read(firebaseFirestoreProvider));
}

class SupportRepository {
  static const FirestoreResilience _firestoreResilience = FirestoreResilience(
    'SupportRepository',
  );

  final FirebaseFirestore _firestore;

  SupportRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _ticketsCollection =>
      _firestore.collection('tickets');

  Future<void> createTicket(Ticket ticket) async {
    await _firestoreResilience.run(
      () => _ticketsCollection.doc(ticket.id).set(ticket.toJson()),
      operationLabel: 'create_ticket',
      onFinalError: (error) => mapExceptionToFailure(error),
    );
  }

  Stream<List<Ticket>> watchUserTickets(String userId) {
    return _firestoreResilience.watch(
      () => _ticketsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Ticket.fromJson(doc.data()))
                .toList(),
          ),
      operationLabel: 'watch_user_tickets',
      onFinalError: (error) => mapExceptionToFailure(error),
    );
  }

  Future<List<Ticket>> getUserTickets(String userId) async {
    final snapshot = await _firestoreResilience.run(
      () => _ticketsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get(),
      operationLabel: 'get_user_tickets',
      onFinalError: (error) => mapExceptionToFailure(error),
    );

    return snapshot.docs.map((doc) => Ticket.fromJson(doc.data())).toList();
  }
}
