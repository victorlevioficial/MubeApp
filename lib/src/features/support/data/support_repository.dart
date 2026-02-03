import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/ticket_model.dart';
import '../../auth/data/auth_repository.dart';

part 'support_repository.g.dart';

@Riverpod(keepAlive: true)
SupportRepository supportRepository(Ref ref) {
  return SupportRepository(FirebaseFirestore.instance);
}

class SupportRepository {
  final FirebaseFirestore _firestore;

  SupportRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _ticketsCollection =>
      _firestore.collection('tickets');

  Future<void> createTicket(Ticket ticket) async {
    await _ticketsCollection.doc(ticket.id).set(ticket.toJson());
  }

  Stream<List<Ticket>> watchUserTickets(String userId) {
    return _ticketsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Ticket.fromJson(doc.data())).toList(),
        );
  }

  Future<List<Ticket>> getUserTickets(String userId) async {
    final snapshot = await _ticketsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('updatedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Ticket.fromJson(doc.data())).toList();
  }
}
