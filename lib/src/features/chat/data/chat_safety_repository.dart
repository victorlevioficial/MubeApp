import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../utils/app_check_refresh_coordinator.dart';
import '../../../utils/app_logger.dart';

final chatSafetyRepositoryProvider = Provider<ChatSafetyRepository>((ref) {
  return ChatSafetyRepository(
    ref.read(firebaseFunctionsProvider),
    auth: ref.read(firebaseAuthProvider),
    appCheck: ref.read(firebaseAppCheckProvider),
  );
});

class ChatSafetyRepository {
  static const Duration _forcedAppCheckRefreshCooldown = Duration(minutes: 2);
  static const Duration _throttledAppCheckBackoff = Duration(minutes: 10);

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  final app_check.FirebaseAppCheck _appCheck;

  ChatSafetyRepository(
    this._functions, {
    required FirebaseAuth auth,
    required app_check.FirebaseAppCheck appCheck,
  }) : _auth = auth,
       _appCheck = appCheck;

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
          'Falha ao atualizar token antes do retry do log de chat safety',
          error,
          stack,
          false,
        );
      }
    }

    await AppCheckRefreshCoordinator.ensureValidToken(
      _appCheck,
      operationLabel: 'retry do log de chat safety',
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
        '$functionName retornou ${error.code}. Atualizando contexto e tentando novamente.',
      );
      await _refreshFunctionSecurityContext();
      return await callable.call(data);
    }
  }

  Future<void> logPreSendWarning({
    required String conversationId,
    required String text,
    required List<String> clientPatterns,
    required List<String> clientChannels,
    required String severity,
  }) async {
    try {
      await _callFunctionWithRecovery(
        'logChatPreSendWarning',
        data: {
          'conversationId': conversationId,
          'text': text,
          'clientPatterns': clientPatterns,
          'clientChannels': clientChannels,
          'severity': severity,
        },
      );
    } on FirebaseFunctionsException catch (error, stack) {
      AppLogger.warning(
        'Falha ao registrar pre-send warning do chat: ${error.code}',
        error,
        stack,
        false,
      );
    } catch (error, stack) {
      AppLogger.warning(
        'Falha inesperada ao registrar pre-send warning do chat',
        error,
        stack,
        false,
      );
    }
  }
}
