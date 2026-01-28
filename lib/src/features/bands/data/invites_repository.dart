import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invites_repository.g.dart';

@Riverpod(keepAlive: true)
InvitesRepository invitesRepository(Ref ref) {
  return InvitesRepository(
    // FirebaseFunctions.instance,
    FirebaseFirestore.instance,
  );
}

class InvitesRepository {
  // final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  InvitesRepository(/*this._functions,*/ this._firestore);

  /// Sends an invite to a user to join a band.
  Future<void> sendInvite({
    required String bandId,
    required String targetUid,
    required String targetName,
    required String targetPhoto,
    required String targetInstrument,
  }) async {
    try {
      // 1. Get Band Info (to show in invite)
      final bandDoc = await _firestore.collection('users').doc(bandId).get();
      if (!bandDoc.exists) throw Exception('Banda não encontrada');
      final bandData = bandDoc.data()!;

      // 2. Create Invite Doc
      await _firestore.collection('invites').add({
        'band_id': bandId,
        'band_name':
            bandData['nome'] ?? bandData['displayName'] ?? 'Banda sem nome',
        'band_photo': bandData['foto'] ?? '',
        'target_uid': targetUid,
        'target_name': targetName,
        'target_photo': targetPhoto,
        'target_instrument': targetInstrument,
        'sender_uid': bandId, // Assuming admin is sending from band account
        'status': 'pendente',
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erro ao enviar convite: $e');
    }
  }

  /// Responds to an invite (accept/decline).
  Future<void> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    try {
      final inviteRef = _firestore.collection('invites').doc(inviteId);
      final inviteDoc = await inviteRef.get();

      if (!inviteDoc.exists) throw Exception('Convite não encontrado');

      if (accept) {
        final data = inviteDoc.data()!;
        final bandId = data['band_id'];
        final userId = data['target_uid'];

        // 1. Add user to Band's members list
        // Note: For MVP we do client-side array updates. Real app should use Cloud Function or Transactions.
        await _firestore.collection('users').doc(bandId).update({
          'members': FieldValue.arrayUnion([userId]),
        });

        // 2. Update Invite Status
        await inviteRef.update({'status': 'aceito'});
      } else {
        // Decline
        await inviteRef.update({'status': 'recusado'});
      }
    } catch (e) {
      throw Exception('Erro ao responder convite: $e');
    }
  }

  /// Streams pending invites for a specific user.
  Stream<List<Map<String, dynamic>>> getIncomingInvites(String uid) {
    return _firestore
        .collection('invites')
        .where('target_uid', isEqualTo: uid)
        .where('status', isEqualTo: 'pendente')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Include doc ID
            return data;
          }).toList();
        });
  }

  /// Streams sent invites from a specific band (for admin view).
  Stream<List<Map<String, dynamic>>> getSentInvites(String bandId) {
    return _firestore
        .collection('invites')
        .where('band_id', isEqualTo: bandId)
        .where('status', isEqualTo: 'pendente')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // Include doc ID
            return data;
          }).toList();
        });
  }

  /// Streams bands where the user is a member.
  Stream<List<Map<String, dynamic>>> getUserBands(String uid) {
    return _firestore
        .collection('users')
        .where('members', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Removes the user from a band's member list.
  Future<void> leaveBand({required String bandId, required String uid}) async {
    try {
      await _firestore.collection('users').doc(bandId).update({
        'members': FieldValue.arrayRemove([uid]),
      });
    } catch (e) {
      throw Exception('Erro ao sair da banda: $e');
    }
  }

  /// Cancels a sent invite (deletes the document).
  Future<void> cancelInvite(String inviteId) async {
    try {
      await _firestore.collection('invites').doc(inviteId).delete();
    } catch (e) {
      throw Exception('Erro ao cancelar convite: $e');
    }
  }
}

@riverpod
Stream<int> pendingInviteCount(Ref ref, String uid) {
  return ref
      .watch(invitesRepositoryProvider)
      .getIncomingInvites(uid)
      .map((invites) => invites.length);
}

final userBandsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, uid) {
      return ref.watch(invitesRepositoryProvider).getUserBands(uid);
    });

final sentInvitesProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, bandId) {
      return ref.watch(invitesRepositoryProvider).getSentInvites(bandId);
    });
