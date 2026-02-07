import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'invites_repository.g.dart';

@Riverpod(keepAlive: true)
InvitesRepository invitesRepository(Ref ref) {
  return InvitesRepository(
    FirebaseFunctions.instanceFor(region: 'southamerica-east1'),
    FirebaseFirestore.instance,
  );
}

class InvitesRepository {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  InvitesRepository(this._functions, this._firestore);

  /// Sends an invite to a user to join a band.
  Future<void> sendInvite({
    required String bandId,
    required String targetUid,
    required String targetName,
    required String targetPhoto,
    required String targetInstrument,
  }) async {
    try {
      final callable = _functions.httpsCallable('manageBandInvite');
      await callable.call({
        'action': 'send',
        'bandId': bandId,
        'targetUid': targetUid,
        'targetName': targetName,
        'targetPhoto': targetPhoto,
        'targetInstrument': targetInstrument,
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
      final callable = _functions.httpsCallable('manageBandInvite');
      await callable.call({
        'action': accept ? 'accept' : 'decline',
        'inviteId': inviteId,
      });
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
      final callable = _functions.httpsCallable('leaveBand');
      await callable.call({
        'bandId': bandId,
        'userId': uid,
      });
    } catch (e) {
      throw Exception('Erro ao sair da banda: $e');
    }
  }

  /// Cancels a sent invite (deletes the document).
  Future<void> cancelInvite(String inviteId) async {
    try {
      final callable = _functions.httpsCallable('manageBandInvite');
      await callable.call({
        'action': 'cancel',
        'inviteId': inviteId,
      });
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
