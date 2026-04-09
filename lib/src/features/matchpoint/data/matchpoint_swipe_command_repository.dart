import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command_result.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

import 'matchpoint_repository.dart';
import 'matchpoint_swipe_outbox_store.dart';

abstract class MatchpointSwipeCommandRepository {
  FutureResult<MatchpointSwipeCommandResult> submit(
    MatchpointSwipeCommand command,
  );

  FutureResult<MatchpointSwipeCommandResult> awaitResult(
    MatchpointSwipeCommand command, {
    required String commandId,
    Duration timeout = const Duration(seconds: 12),
  });

  Future<void> flushPending({required String userId});
}

class LegacyMatchpointSwipeCommandRepository
    implements MatchpointSwipeCommandRepository {
  final MatchpointRepository _legacyRepository;

  LegacyMatchpointSwipeCommandRepository(this._legacyRepository);

  @override
  FutureResult<MatchpointSwipeCommandResult> submit(
    MatchpointSwipeCommand command,
  ) async {
    final result = await _legacyRepository.submitAction(
      targetUserId: command.targetUserId,
      type: command.action.value,
    );

    return result.map(
      (actionResult) => MatchpointSwipeCommandResult.fromLegacyAction(
        command: command,
        actionResult: actionResult,
      ),
    );
  }

  @override
  FutureResult<MatchpointSwipeCommandResult> awaitResult(
    MatchpointSwipeCommand command, {
    required String commandId,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    return Right(
      MatchpointSwipeCommandResult(
        targetUserId: command.targetUserId,
        action: command.action,
        status: MatchpointSwipeCommandStatus.accepted,
        commandId: commandId,
      ),
    );
  }

  @override
  Future<void> flushPending({required String userId}) async {}
}

class FirestoreMatchpointSwipeCommandRepository
    implements MatchpointSwipeCommandRepository {
  static const _defaultTimeout = Duration(seconds: 12);

  final FirebaseFirestore _firestore;
  final LegacyMatchpointSwipeCommandRepository _fallbackRepository;
  final MatchpointSwipeOutboxStore _outboxStore;
  final Uuid _uuid;
  final bool? _enableCompletionListenerOverride;
  final bool? _bypassImmediateSubmissionOverride;

  FirestoreMatchpointSwipeCommandRepository(
    this._firestore,
    this._outboxStore,
    this._fallbackRepository, {
    Uuid? uuid,
    bool? enableCompletionListenerOverride,
    bool? bypassImmediateSubmissionOverride,
  }) : _uuid = uuid ?? const Uuid(),
       _enableCompletionListenerOverride = enableCompletionListenerOverride,
       _bypassImmediateSubmissionOverride = bypassImmediateSubmissionOverride;

  CollectionReference<Map<String, dynamic>> get _commands =>
      _firestore.collection(FirestoreCollections.matchpointCommands);

  static bool shouldListenForCommandCompletion({
    bool isReleaseMode = kReleaseMode,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return !(isReleaseMode && !isWeb && resolvedPlatform == TargetPlatform.iOS);
  }

  static bool shouldBypassImmediateSubmission({
    bool isReleaseMode = kReleaseMode,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return isReleaseMode && !isWeb && resolvedPlatform == TargetPlatform.iOS;
  }

  bool get _shouldListenForCommandCompletion =>
      _enableCompletionListenerOverride ?? shouldListenForCommandCompletion();

  bool get _shouldBypassImmediateSubmission =>
      _bypassImmediateSubmissionOverride ?? shouldBypassImmediateSubmission();

  @override
  FutureResult<MatchpointSwipeCommandResult> submit(
    MatchpointSwipeCommand command,
  ) async {
    final commandId = _resolveCommandId(command);
    if (_shouldBypassImmediateSubmission) {
      return _enqueueLocally(command, commandId: commandId);
    }

    try {
      await _submitToFirestore(command, commandId: commandId);

      return Right(
        MatchpointSwipeCommandResult(
          targetUserId: command.targetUserId,
          action: command.action,
          status: MatchpointSwipeCommandStatus.accepted,
          commandId: commandId,
        ),
      );
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to enqueue MatchPoint command in Firestore. Falling back to legacy callable.',
        error,
        stackTrace,
        false,
      );
      return _fallbackRepository.submit(command);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Unexpected error while enqueueing MatchPoint command. Falling back to legacy callable.',
        error,
        stackTrace,
        false,
      );
      return _fallbackRepository.submit(command);
    }
  }

  FutureResult<MatchpointSwipeCommandResult> _enqueueLocally(
    MatchpointSwipeCommand command, {
    required String commandId,
  }) async {
    try {
      await _outboxStore.enqueue(
        userId: command.sourceUserId,
        entry: PersistedMatchpointSwipeCommand(
          commandId: commandId,
          command: command.copyWith(idempotencyKey: commandId),
        ),
      );

      AppLogger.info(
        'MatchPoint swipe stored in local outbox: action=${command.action.value} '
        'target=${command.targetUserId} commandId=$commandId',
      );
      return Right(
        MatchpointSwipeCommandResult(
          targetUserId: command.targetUserId,
          action: command.action,
          status: MatchpointSwipeCommandStatus.accepted,
          commandId: commandId,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to store MatchPoint swipe in local outbox.',
        error,
        stackTrace,
        false,
      );
      return Left(
        ServerFailure(
          message:
              'Nao foi possivel registrar sua acao agora. Tente novamente.',
          originalError: error,
        ),
      );
    }
  }

  @override
  FutureResult<MatchpointSwipeCommandResult> awaitResult(
    MatchpointSwipeCommand command, {
    required String commandId,
    Duration timeout = _defaultTimeout,
  }) async {
    if (!_shouldListenForCommandCompletion) {
      return Right(
        MatchpointSwipeCommandResult(
          targetUserId: command.targetUserId,
          action: command.action,
          status: MatchpointSwipeCommandStatus.accepted,
          commandId: commandId,
        ),
      );
    }

    final docRef = _commands.doc(commandId);

    try {
      final result = await docRef
          .snapshots()
          .map((snapshot) => _parseSnapshot(snapshot, command, commandId))
          .firstWhere((parsed) => parsed != null)
          .timeout(timeout);

      return result!;
    } on TimeoutException {
      return Right(
        MatchpointSwipeCommandResult(
          targetUserId: command.targetUserId,
          action: command.action,
          status: MatchpointSwipeCommandStatus.accepted,
          commandId: commandId,
        ),
      );
    } on FirebaseException catch (error) {
      return Left(_mapFirestoreFailure(error));
    } catch (error) {
      return Left(
        ServerFailure(
          message: 'Nao foi possivel acompanhar sua acao agora.',
          originalError: error,
        ),
      );
    }
  }

  @override
  Future<void> flushPending({required String userId}) async {
    final pendingCommands = await _outboxStore.load(userId);
    if (pendingCommands.isEmpty) return;

    AppLogger.info(
      'MatchPoint outbox pending flush count=${pendingCommands.length} uid=$userId',
    );

    for (final entry in pendingCommands) {
      try {
        await _submitToFirestore(entry.command, commandId: entry.commandId);
        await _outboxStore.remove(userId: userId, commandId: entry.commandId);
      } on FirebaseException catch (error, stackTrace) {
        AppLogger.warning(
          'Failed to flush MatchPoint outbox command to Firestore.',
          error,
          stackTrace,
          false,
        );
        return;
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Unexpected error while flushing MatchPoint outbox command.',
          error,
          stackTrace,
          false,
        );
        return;
      }
    }
  }

  String _resolveCommandId(MatchpointSwipeCommand command) {
    final explicitId = command.idempotencyKey?.trim();
    if (explicitId != null && explicitId.isNotEmpty) {
      return explicitId;
    }
    return _uuid.v4();
  }

  Future<void> _submitToFirestore(
    MatchpointSwipeCommand command, {
    required String commandId,
  }) {
    return _commands.doc(commandId).set({
      'user_id': command.sourceUserId,
      'target_user_id': command.targetUserId,
      'action': command.action.value,
      'status': 'pending',
      'client_created_at': Timestamp.fromDate(command.createdAt),
      'idempotency_key': command.idempotencyKey ?? commandId,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Either<Failure, MatchpointSwipeCommandResult>? _parseSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    MatchpointSwipeCommand command,
    String commandId,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return const Left(
        ServerFailure(message: 'Comando do MatchPoint nao encontrado.'),
      );
    }

    final status = (data['status'] as String?)?.trim().toLowerCase();
    if (status == 'pending' || status == 'processing' || status == null) {
      return null;
    }

    if (status == 'failed') {
      return Left(_mapCommandFailure(data['error']));
    }

    final resultMap = _asMap(data['result']);
    return Right(
      MatchpointSwipeCommandResult(
        targetUserId:
            (resultMap['targetUserId'] as String?) ?? command.targetUserId,
        action: _parseAction(
          resultMap['action'] as String?,
          fallback: command.action,
        ),
        status: MatchpointSwipeCommandStatus.processed,
        commandId: commandId,
        isMatch: resultMap['isMatch'] == true,
        matchId: resultMap['matchId'] as String?,
        conversationId: resultMap['conversationId'] as String?,
        remainingLikes: resultMap['remainingLikes'] as int?,
        message: resultMap['message'] as String?,
      ),
    );
  }

  MatchpointSwipeAction _parseAction(
    String? rawAction, {
    required MatchpointSwipeAction fallback,
  }) {
    switch (rawAction) {
      case 'like':
        return MatchpointSwipeAction.like;
      case 'dislike':
        return MatchpointSwipeAction.dislike;
      default:
        return fallback;
    }
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key.toString(), nestedValue),
      );
    }
    return const <String, dynamic>{};
  }

  Failure _mapCommandFailure(Object? rawError) {
    final error = _asMap(rawError);
    final code = (error['code'] as String?)?.trim().toLowerCase() ?? '';
    final message =
        (error['message'] as String?)?.trim() ??
        'Nao foi possivel registrar sua acao agora. Tente novamente.';

    switch (code) {
      case 'resource-exhausted':
        return QuotaExceededFailure.dailyLikes();
      case 'unauthenticated':
        return AuthFailure.sessionExpired();
      case 'permission-denied':
        return PermissionFailure.firestore();
      default:
        return ServerFailure(message: message, debugMessage: code);
    }
  }

  Failure _mapFirestoreFailure(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return PermissionFailure.firestore();
      case 'unauthenticated':
        return AuthFailure.sessionExpired();
      default:
        return ServerFailure(
          message:
              'Nao foi possivel registrar sua acao agora. Tente novamente.',
          debugMessage: error.code,
          originalError: error,
        );
    }
  }
}

final matchpointSwipeCommandRepositoryProvider =
    Provider<MatchpointSwipeCommandRepository>((ref) {
      final legacyRepository = LegacyMatchpointSwipeCommandRepository(
        ref.read(matchpointRepositoryProvider),
      );

      return FirestoreMatchpointSwipeCommandRepository(
        ref.read(firebaseFirestoreProvider),
        ref.read(matchpointSwipeOutboxStoreProvider),
        legacyRepository,
      );
    });
