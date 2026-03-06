import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../utils/app_check_refresh_coordinator.dart';
import '../../../utils/app_logger.dart';

part 'invites_repository.g.dart';

@Riverpod(keepAlive: true)
InvitesRepository invitesRepository(Ref ref) {
  return InvitesRepository(
    ref.read(firebaseFunctionsProvider),
    ref.read(firebaseFirestoreProvider),
    auth: ref.read(firebaseAuthProvider),
    appCheck: ref.read(firebaseAppCheckProvider),
  );
}

class InvitesRepository {
  static const Duration _forcedAppCheckRefreshCooldown = Duration(minutes: 2);
  static const Duration _throttledAppCheckBackoff = Duration(minutes: 10);
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final app_check.FirebaseAppCheck _appCheck;

  InvitesRepository(
    this._functions,
    this._firestore, {
    required FirebaseAuth auth,
    required app_check.FirebaseAppCheck appCheck,
  }) : _auth = auth,
       _appCheck = appCheck;

  String _readMessage(dynamic data, String fallback) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }

  bool _isRecoverableFunctionsError(FirebaseFunctionsException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code == 'unauthenticated') return true;

    final mentionsAppCheck = message.contains('app check');
    return mentionsAppCheck &&
        (code == 'failed-precondition' || code == 'permission-denied');
  }

  Future<void> _refreshFunctionSecurityContext() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        await currentUser.getIdToken(true);
        await currentUser.reload();
      } catch (error, stack) {
        AppLogger.warning(
          'Falha ao atualizar token do FirebaseAuth antes do retry de convite',
          error,
          stack,
          false,
        );
      }
    }

    await AppCheckRefreshCoordinator.ensureValidToken(
      _appCheck,
      operationLabel: 'retry de convite de banda',
      forcedRefreshCooldown: _forcedAppCheckRefreshCooldown,
      throttledBackoff: _throttledAppCheckBackoff,
    );
  }

  Future<HttpsCallableResult<dynamic>> _callFunctionWithRecovery(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    final callable = _functions.httpsCallable(functionName);

    try {
      return await callable.call(data);
    } on FirebaseFunctionsException catch (error) {
      if (!_isRecoverableFunctionsError(error)) rethrow;

      AppLogger.warning(
        '$functionName retornou ${error.code}. Atualizando contexto de seguranca e tentando novamente.',
      );
      await _refreshFunctionSecurityContext();
      return await callable.call(data);
    }
  }

  Exception _mapFunctionsError(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is FirebaseFunctionsException) {
      final serverMessage = error.message?.trim();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        return Exception(serverMessage);
      }
    }

    return Exception(fallbackMessage);
  }

  /// Sends an invite to a user to join a band.
  Future<String> sendInvite({
    required String bandId,
    required String targetUid,
    required String targetName,
    required String targetPhoto,
    required String targetInstrument,
  }) async {
    try {
      final result = await _callFunctionWithRecovery(
        'manageBandInvite',
        data: {
          'action': 'send',
          'bandId': bandId,
          'targetUid': targetUid,
          'targetName': targetName,
          'targetPhoto': targetPhoto,
          'targetInstrument': targetInstrument,
        },
      );
      return _readMessage(result.data, 'Convite enviado');
    } on FirebaseFunctionsException catch (error) {
      AppLogger.warning(
        'manageBandInvite falhou ao enviar convite: ${error.code}',
        error,
        error.stackTrace,
      );
      throw _mapFunctionsError(
        error,
        fallbackMessage: 'Não foi possível enviar o convite agora.',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Erro inesperado ao enviar convite da banda $bandId para $targetUid',
        e,
        stack,
      );
      throw Exception('Não foi possível enviar o convite agora.');
    }
  }

  /// Responds to an invite (accept/decline).
  Future<String> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    try {
      final result = await _callFunctionWithRecovery(
        'manageBandInvite',
        data: {'action': accept ? 'accept' : 'decline', 'inviteId': inviteId},
      );
      return _readMessage(
        result.data,
        accept ? 'Convite aceito' : 'Convite recusado',
      );
    } on FirebaseFunctionsException catch (error) {
      throw _mapFunctionsError(
        error,
        fallbackMessage: accept
            ? 'Não foi possível aceitar o convite agora.'
            : 'Não foi possível recusar o convite agora.',
      );
    } catch (e) {
      throw Exception(
        accept
            ? 'Não foi possível aceitar o convite agora.'
            : 'Não foi possível recusar o convite agora.',
      );
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
  Future<String> leaveBand({
    required String bandId,
    required String uid,
  }) async {
    try {
      final result = await _callFunctionWithRecovery(
        'leaveBand',
        data: {'bandId': bandId, 'userId': uid},
      );
      return _readMessage(result.data, 'Membro removido da banda');
    } on FirebaseFunctionsException catch (error) {
      throw _mapFunctionsError(
        error,
        fallbackMessage: 'Não foi possível atualizar a banda agora.',
      );
    } catch (e) {
      throw Exception('Não foi possível atualizar a banda agora.');
    }
  }

  /// Cancels a sent invite (deletes the document).
  Future<String> cancelInvite(String inviteId) async {
    try {
      final result = await _callFunctionWithRecovery(
        'manageBandInvite',
        data: {'action': 'cancel', 'inviteId': inviteId},
      );
      return _readMessage(result.data, 'Convite cancelado');
    } on FirebaseFunctionsException catch (error) {
      throw _mapFunctionsError(
        error,
        fallbackMessage: 'Não foi possível cancelar o convite agora.',
      );
    } catch (e) {
      throw Exception('Não foi possível cancelar o convite agora.');
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
