import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_command_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_outbox_store.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_action_result.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLegacyMatchpointRepository extends Fake
    implements MatchpointRepository {
  FutureResult<MatchpointActionResult> Function({
    required String targetUserId,
    required String type,
  })?
  onSubmitAction;

  @override
  FutureResult<MatchpointActionResult> submitAction({
    required String targetUserId,
    required String type,
  }) async {
    return onSubmitAction!(targetUserId: targetUserId, type: type);
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late _FakeLegacyMatchpointRepository legacyRepository;
  late MatchpointSwipeOutboxStore outboxStore;
  late FirestoreMatchpointSwipeCommandRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    firestore = FakeFirebaseFirestore();
    legacyRepository = _FakeLegacyMatchpointRepository()
      ..onSubmitAction = ({required targetUserId, required type}) async =>
          Right(
            MatchpointActionResult(
              success: true,
              isMatch: false,
              remainingLikes: 49,
            ),
          );
    outboxStore = MatchpointSwipeOutboxStore(SharedPreferences.getInstance);
    repository = FirestoreMatchpointSwipeCommandRepository(
      firestore,
      outboxStore,
      LegacyMatchpointSwipeCommandRepository(legacyRepository),
    );
  });

  group('FirestoreMatchpointSwipeCommandRepository', () {
    test('submit persists a pending command and returns accepted', () async {
      final command = MatchpointSwipeCommand(
        sourceUserId: 'user-1',
        targetUserId: 'target-1',
        action: MatchpointSwipeAction.like,
        createdAt: DateTime(2026, 4, 8, 12),
        idempotencyKey: 'cmd-1',
      );

      final result = await repository.submit(command);

      expect(result.isRight(), isTrue);
      final commandResult = result.getRight().toNullable()!;
      expect(commandResult.status, MatchpointSwipeCommandStatus.accepted);
      expect(commandResult.commandId, 'cmd-1');

      final snapshot = await firestore
          .collection(FirestoreCollections.matchpointCommands)
          .doc('cmd-1')
          .get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['user_id'], 'user-1');
      expect(snapshot.data()!['target_user_id'], 'target-1');
      expect(snapshot.data()!['action'], 'like');
      expect(snapshot.data()!['status'], 'pending');
      expect(snapshot.data()!['idempotency_key'], 'cmd-1');
    });

    test(
      'awaitResult returns processed command when backend completes',
      () async {
        const commandId = 'cmd-2';
        final command = MatchpointSwipeCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-2',
          action: MatchpointSwipeAction.like,
          createdAt: DateTime(2026, 4, 8, 12, 5),
          idempotencyKey: commandId,
        );
        await firestore
            .collection(FirestoreCollections.matchpointCommands)
            .doc(commandId)
            .set({
              'user_id': 'user-1',
              'target_user_id': 'target-2',
              'action': 'like',
              'status': 'processing',
            });

        unawaited(
          Future<void>(() async {
            await Future<void>.delayed(Duration.zero);
            await firestore
                .collection(FirestoreCollections.matchpointCommands)
                .doc(commandId)
                .update({
                  'status': 'completed',
                  'result': {
                    'targetUserId': 'target-2',
                    'action': 'like',
                    'isMatch': true,
                    'conversationId': 'conversation-2',
                    'remainingLikes': 41,
                  },
                });
          }),
        );

        final result = await repository.awaitResult(
          command,
          commandId: commandId,
        );

        expect(result.isRight(), isTrue);
        final commandResult = result.getRight().toNullable()!;
        expect(commandResult.status, MatchpointSwipeCommandStatus.processed);
        expect(commandResult.isMatch, isTrue);
        expect(commandResult.conversationId, 'conversation-2');
        expect(commandResult.remainingLikes, 41);
      },
    );

    test('awaitResult maps failed command into a failure', () async {
      const commandId = 'cmd-3';
      final command = MatchpointSwipeCommand(
        sourceUserId: 'user-1',
        targetUserId: 'target-3',
        action: MatchpointSwipeAction.dislike,
        createdAt: DateTime(2026, 4, 8, 12, 10),
        idempotencyKey: commandId,
      );
      await firestore
          .collection(FirestoreCollections.matchpointCommands)
          .doc(commandId)
          .set({
            'user_id': 'user-1',
            'target_user_id': 'target-3',
            'action': 'dislike',
            'status': 'processing',
          });

      unawaited(
        Future<void>(() async {
          await Future<void>.delayed(Duration.zero);
          await firestore
              .collection(FirestoreCollections.matchpointCommands)
              .doc(commandId)
              .update({
                'status': 'failed',
                'error': {
                  'code': 'resource-exhausted',
                  'message': 'Limite diário atingido',
                },
              });
        }),
      );

      final result = await repository.awaitResult(
        command,
        commandId: commandId,
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), isA<QuotaExceededFailure>());
    });

    test(
      'awaitResult returns accepted immediately when completion listener is disabled',
      () async {
        const commandId = 'cmd-4';
        final repository = FirestoreMatchpointSwipeCommandRepository(
          firestore,
          outboxStore,
          LegacyMatchpointSwipeCommandRepository(legacyRepository),
          enableCompletionListenerOverride: false,
        );
        final command = MatchpointSwipeCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-4',
          action: MatchpointSwipeAction.like,
          createdAt: DateTime(2026, 4, 8, 12, 20),
          idempotencyKey: commandId,
        );
        await firestore
            .collection(FirestoreCollections.matchpointCommands)
            .doc(commandId)
            .set({
              'user_id': 'user-1',
              'target_user_id': 'target-4',
              'action': 'like',
              'status': 'processing',
            });

        final result = await repository.awaitResult(
          command,
          commandId: commandId,
        );

        expect(result.isRight(), isTrue);
        final commandResult = result.getRight().toNullable()!;
        expect(commandResult.status, MatchpointSwipeCommandStatus.accepted);
        expect(commandResult.commandId, commandId);
        expect(commandResult.isProcessed, isFalse);
      },
    );

    test(
      'submit stores command in local outbox when immediate submission is disabled',
      () async {
        final repository = FirestoreMatchpointSwipeCommandRepository(
          firestore,
          outboxStore,
          LegacyMatchpointSwipeCommandRepository(legacyRepository),
          bypassImmediateSubmissionOverride: true,
        );
        final command = MatchpointSwipeCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-5',
          action: MatchpointSwipeAction.like,
          createdAt: DateTime(2026, 4, 8, 12, 30),
          idempotencyKey: 'cmd-5',
        );

        final result = await repository.submit(command);
        final snapshot = await firestore
            .collection(FirestoreCollections.matchpointCommands)
            .doc('cmd-5')
            .get();

        expect(result.isRight(), isTrue);
        expect(snapshot.exists, isFalse);
        final pending = await outboxStore.load('user-1');
        expect(pending, hasLength(1));
        expect(pending.single.commandId, 'cmd-5');
        expect(pending.single.command.targetUserId, 'target-5');
      },
    );

    test('flushPending drains local outbox into Firestore', () async {
      await outboxStore.enqueue(
        userId: 'user-1',
        entry: PersistedMatchpointSwipeCommand(
          commandId: 'cmd-6',
          command: MatchpointSwipeCommand(
            sourceUserId: 'user-1',
            targetUserId: 'target-6',
            action: MatchpointSwipeAction.dislike,
            createdAt: DateTime(2026, 4, 8, 12, 35),
            idempotencyKey: 'cmd-6',
          ),
        ),
      );

      await repository.flushPending(userId: 'user-1');

      final snapshot = await firestore
          .collection(FirestoreCollections.matchpointCommands)
          .doc('cmd-6')
          .get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['action'], 'dislike');
      expect(await outboxStore.load('user-1'), isEmpty);
    });
  });
}
