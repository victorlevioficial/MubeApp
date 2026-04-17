import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/errors/failure_mapper.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:mube/src/utils/app_performance_tracker.dart';

import '../domain/conversation_preview.dart';
import '../domain/message.dart';
import 'chat_access_resolver.dart';

part 'chat_conversations_repository.dart';
part 'chat_messages_repository.dart';
part 'chat_requests_repository.dart';

const int _defaultMessagesPageSize = 50;
const Duration _securityContextRefreshCooldown = Duration(seconds: 4);
const String _requestStatusAccepted = 'accepted';
const String _requestStatusPending = 'pending';
const String _requestStatusRejected = 'rejected';

/// Repository para gerenciar conversas e mensagens no Firestore.
class ChatRepository extends _ChatRepositoryBase
    with
        _ChatConversationsRepository,
        _ChatMessagesRepository,
        _ChatRequestsRepository {
  ChatRepository(
    super.firestore, {
    super.analytics,
    super.authRepository,
    super.chatAccessResolver,
  });
}

class _ChatRepositoryBase {
  final FirebaseFirestore _firestore;
  final AnalyticsService? _analytics;
  final AuthRepository? _authRepository;
  final ChatAccessResolver _chatAccessResolver;
  DateTime? _lastSecurityContextRefreshAt;

  _ChatRepositoryBase(
    this._firestore, {
    AnalyticsService? analytics,
    AuthRepository? authRepository,
    ChatAccessResolver? chatAccessResolver,
  }) : _analytics = analytics,
       _authRepository = authRepository,
       _chatAccessResolver =
           chatAccessResolver ?? ChatAccessResolver(_firestore);

  Failure _mapFailure(Object error, StackTrace stackTrace) =>
      mapExceptionToFailure(error, stackTrace);

  Map<String, dynamic>? _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String? _readNonEmptyString(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _firstNonEmptyString(
    List<Object?> values, {
    required String fallback,
  }) {
    for (final value in values) {
      final normalized = _readNonEmptyString(value);
      if (normalized != null) return normalized;
    }
    return fallback;
  }

  String _conversationTypeFromData(
    Map<String, dynamic>? data, {
    String fallback = 'direct',
  }) {
    return _readNonEmptyString(data?['type']) ?? fallback;
  }

  String _normalizeConversationType(
    String? type, {
    String fallback = 'direct',
  }) {
    return _readNonEmptyString(type) ?? fallback;
  }

  String _requestStatusFromData(
    Map<String, dynamic>? data, {
    String fallback = _requestStatusAccepted,
  }) {
    final normalized = _readNonEmptyString(data?['requestStatus']);
    if (normalized == _requestStatusPending ||
        normalized == _requestStatusRejected ||
        normalized == _requestStatusAccepted) {
      return normalized!;
    }
    return fallback;
  }

  int _requestCycleFromData(Map<String, dynamic>? data) {
    final value = data?['requestCycle'];
    if (value is num) return value.toInt();
    return 0;
  }

  String? _requestSenderIdFromData(Map<String, dynamic>? data) {
    return _readNonEmptyString(data?['requestSenderId']);
  }

  String? _requestRecipientIdFromData(Map<String, dynamic>? data) {
    return _readNonEmptyString(data?['requestRecipientId']);
  }

  String? _buildShortPersonName(Object? rawName) {
    final normalized = _readNonEmptyString(rawName);
    if (normalized == null) return null;

    final parts = normalized.split(RegExp(r'\s+'));
    if (parts.length <= 2) return normalized;

    const connectors = {'de', 'da', 'do', 'dos', 'das', 'e'};
    final takeCount = connectors.contains(parts[1].toLowerCase()) ? 3 : 2;
    return parts.take(takeCount).join(' ');
  }

  String _displayNameFromUserData(Map<String, dynamic>? data) {
    final professionalData = _asMap(data?['profissional']);
    final bandData = _asMap(data?['banda']);
    final studioData = _asMap(data?['estudio']);
    final contractorData = _asMap(data?['contratante']);
    final profileType = _readNonEmptyString(data?['tipo_perfil']);

    switch (profileType) {
      case 'profissional':
        return _firstNonEmptyString([
          professionalData?['nomeArtistico'],
          data?['nome'],
        ], fallback: 'Profissional');
      case 'banda':
        return _firstNonEmptyString([
          bandData?['nomeBanda'],
          bandData?['nomeArtistico'],
          bandData?['nome'],
          data?['nome'],
        ], fallback: 'Banda');
      case 'estudio':
        return _firstNonEmptyString([
          studioData?['nomeEstudio'],
          studioData?['nomeArtistico'],
          studioData?['nome'],
          data?['nome'],
        ], fallback: 'Estudio');
      case 'contratante':
        return _firstNonEmptyString([
          contractorData?['nomeExibicao'],
          _buildShortPersonName(data?['nome']),
          data?['nome'],
        ], fallback: 'Contratante');
      default:
        return _firstNonEmptyString([
          professionalData?['nomeArtistico'],
          bandData?['nomeBanda'],
          studioData?['nomeEstudio'],
          data?['nome'],
        ], fallback: 'Usuario');
    }
  }

  String _normalizedErrorMessage(Object error) {
    if (error is FirebaseException) {
      return [
        error.plugin,
        error.code,
        error.message ?? '',
        error.toString(),
      ].join(' ').toLowerCase();
    }

    if (error is PlatformException) {
      return [
        error.code,
        error.message ?? '',
        error.details?.toString() ?? '',
        error.toString(),
      ].join(' ').toLowerCase();
    }

    return error.toString().toLowerCase();
  }

  bool _isSecurityContextFailure(Object error) {
    final normalized = _normalizedErrorMessage(error);
    return normalized.contains('permission-denied') ||
        normalized.contains('permission denied') ||
        normalized.contains('unauthenticated') ||
        normalized.contains('failed-precondition') ||
        normalized.contains('failed precondition') ||
        (normalized.contains('app check') &&
            normalized.contains('channel-error'));
  }

  Future<bool> _refreshSecurityContextForRetry(
    Object error,
    StackTrace stackTrace, {
    required String operationLabel,
  }) async {
    final authRepository = _authRepository;
    if (authRepository == null || !_isSecurityContextFailure(error)) {
      return false;
    }

    final now = DateTime.now();
    if (_lastSecurityContextRefreshAt != null &&
        now.difference(_lastSecurityContextRefreshAt!) <
            _securityContextRefreshCooldown) {
      AppLogger.warning(
        'Chat Firestore security retry skipped during cooldown: '
        '$operationLabel',
        error,
        stackTrace,
        false,
      );
      return false;
    }

    _lastSecurityContextRefreshAt = now;
    AppLogger.setCustomKey('chat_security_retry_operation', operationLabel);
    AppLogger.setCustomKey(
      'chat_security_retry_error_type',
      error.runtimeType.toString(),
    );
    AppLogger.warning(
      'Chat Firestore security context failure on $operationLabel. '
      'Atualizando sessao e tentando novamente.',
      error,
      stackTrace,
      false,
    );

    final refreshResult = await authRepository.refreshSecurityContext();
    return refreshResult.fold(
      (failure) {
        AppLogger.warning(
          'Chat Firestore security context refresh failed: '
          '$operationLabel (${failure.debugMessage ?? failure.runtimeType})',
          failure,
          stackTrace,
          false,
        );
        return false;
      },
      (_) {
        AppLogger.info(
          'Chat Firestore security context refresh succeeded for '
          '$operationLabel.',
        );
        return true;
      },
    );
  }

  Future<T> _runWithSecurityContextRecovery<T>(
    Future<T> Function() operation, {
    required String operationLabel,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      final didRefresh = await _refreshSecurityContextForRetry(
        error,
        stackTrace,
        operationLabel: operationLabel,
      );
      if (!didRefresh) rethrow;
      return operation();
    }
  }

  Future<void> _commitBatchWithSecurityContextRecovery(
    void Function(WriteBatch batch) buildBatch, {
    required String operationLabel,
  }) {
    // Firestore batches are single-use. Recreate them on each retry attempt.
    return _runWithSecurityContextRecovery(() async {
      final batch = _firestore.batch();
      buildBatch(batch);
      await batch.commit();
    }, operationLabel: operationLabel);
  }

  Stream<T> _watchWithSecurityContextRecovery<T>(
    Stream<T> Function() createStream, {
    required String operationLabel,
  }) async* {
    var hasRetriedAfterRefresh = false;

    while (true) {
      try {
        yield* createStream();
        return;
      } catch (error, stackTrace) {
        if (hasRetriedAfterRefresh) {
          rethrow;
        }

        final didRefresh = await _refreshSecurityContextForRetry(
          error,
          stackTrace,
          operationLabel: operationLabel,
        );
        if (!didRefresh) {
          rethrow;
        }

        hasRetriedAfterRefresh = true;
      }
    }
  }

  Future<_UserPreviewInfo> _getUserPreviewInfo(String uid) async {
    final snapshot = await _runWithSecurityContextRecovery(
      () => _firestore.collection('users').doc(uid).get(),
      operationLabel: 'load_user_preview',
    );
    final data = _asMap(snapshot.data());
    return _UserPreviewInfo(
      displayName: _displayNameFromUserData(data),
      photoUrl: _readNonEmptyString(data?['foto']),
    );
  }

  Future<_UserPreviewInfo> _getUserPreviewInfoSafe(String uid) async {
    try {
      return await _getUserPreviewInfo(uid);
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Chat: failed to fetch user preview info for $uid',
        e,
        stackTrace,
      );
      return const _UserPreviewInfo(displayName: 'Usuario', photoUrl: null);
    }
  }

  bool _isPendingForUser(
    Map<String, dynamic>? conversationData,
    String userId,
  ) {
    return _requestStatusFromData(conversationData) == _requestStatusPending &&
        _requestRecipientIdFromData(conversationData) == userId;
  }

  int _resolvePendingRequestCycle({
    required Map<String, dynamic>? conversationData,
    required String senderId,
    required String recipientId,
  }) {
    final currentStatus = _requestStatusFromData(conversationData);
    final currentCycle = _requestCycleFromData(conversationData);
    final currentSenderId = _requestSenderIdFromData(conversationData);
    final currentRecipientId = _requestRecipientIdFromData(conversationData);

    if (currentStatus == _requestStatusPending &&
        currentSenderId == senderId &&
        currentRecipientId == recipientId) {
      return currentCycle > 0 ? currentCycle : 1;
    }

    return currentCycle > 0 ? currentCycle + 1 : 1;
  }

  Map<String, dynamic> _buildAcceptedRequestFields({
    required Map<String, dynamic>? conversationData,
  }) {
    return {
      'requestStatus': _requestStatusAccepted,
      'requestRecipientId': null,
      'requestSenderId': null,
      'requestCycle': _requestCycleFromData(conversationData),
      'requestUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildPendingRequestFields({
    required Map<String, dynamic>? conversationData,
    required String senderId,
    required String recipientId,
  }) {
    return {
      'requestStatus': _requestStatusPending,
      'requestRecipientId': recipientId,
      'requestSenderId': senderId,
      'requestCycle': _resolvePendingRequestCycle(
        conversationData: conversationData,
        senderId: senderId,
        recipientId: recipientId,
      ),
      'requestUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildRejectedRequestFields({
    required Map<String, dynamic>? conversationData,
    required String senderId,
    required String recipientId,
  }) {
    return {
      'requestStatus': _requestStatusRejected,
      'requestRecipientId': recipientId,
      'requestSenderId': senderId,
      'requestCycle': _requestCycleFromData(conversationData),
      'requestUpdatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildPreviewPayload({
    required String otherUserId,
    required String otherUserName,
    required String? otherUserPhoto,
    required String? lastMessageText,
    required Object? lastMessageAt,
    required String? lastSenderId,
    required Object unreadCount,
    required String type,
    required bool isPending,
    int? requestCycle,
  }) {
    return {
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhoto': otherUserPhoto,
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt,
      'lastSenderId': lastSenderId,
      'unreadCount': unreadCount,
      'updatedAt': FieldValue.serverTimestamp(),
      'type': type,
      'isPending': isPending,
      'requestCycle': requestCycle,
    };
  }

  /// Calcula conversationId deterministico (uidMenor_uidMaior).
  String getConversationId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }
}

class _UserPreviewInfo {
  const _UserPreviewInfo({required this.displayName, required this.photoUrl});

  final String displayName;
  final String? photoUrl;
}

class ChatParticipantPreview {
  const ChatParticipantPreview({
    required this.displayName,
    required this.photoUrl,
  });

  final String displayName;
  final String? photoUrl;
}

class MessagesPage {
  const MessagesPage({
    required this.messages,
    required this.lastVisibleDoc,
    required this.hasMore,
  });

  final List<Message> messages;
  final DocumentSnapshot<Map<String, dynamic>>? lastVisibleDoc;
  final bool hasMore;
}

/// Provider para ChatRepository.
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final analytics = ref.read(analyticsServiceProvider);
  return ChatRepository(
    ref.read(firebaseFirestoreProvider),
    analytics: analytics,
    authRepository: ref.read(authRepositoryProvider),
    chatAccessResolver: ref.read(chatAccessResolverProvider),
  );
});
