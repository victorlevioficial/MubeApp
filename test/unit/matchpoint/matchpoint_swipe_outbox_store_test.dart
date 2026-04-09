import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_outbox_store.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MatchpointSwipeOutboxStore store;

  MatchpointSwipeCommand buildCommand({
    required String sourceUserId,
    required String targetUserId,
    required MatchpointSwipeAction action,
    required DateTime createdAt,
    String? idempotencyKey,
  }) {
    return MatchpointSwipeCommand(
      sourceUserId: sourceUserId,
      targetUserId: targetUserId,
      action: action,
      createdAt: createdAt,
      idempotencyKey: idempotencyKey,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = MatchpointSwipeOutboxStore(SharedPreferences.getInstance);
  });

  test('enqueue and load keep commands scoped by user', () async {
    await store.enqueue(
      userId: 'user-1',
      entry: PersistedMatchpointSwipeCommand(
        commandId: 'cmd-1',
        command: buildCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-1',
          action: MatchpointSwipeAction.like,
          createdAt: DateTime.utc(2026, 4, 8, 12),
          idempotencyKey: 'cmd-1',
        ),
      ),
    );
    await store.enqueue(
      userId: 'user-2',
      entry: PersistedMatchpointSwipeCommand(
        commandId: 'cmd-2',
        command: buildCommand(
          sourceUserId: 'user-2',
          targetUserId: 'target-2',
          action: MatchpointSwipeAction.dislike,
          createdAt: DateTime.utc(2026, 4, 8, 12, 5),
          idempotencyKey: 'cmd-2',
        ),
      ),
    );

    final user1Pending = await store.load('user-1');
    final user2Pending = await store.load('user-2');

    expect(user1Pending, hasLength(1));
    expect(user1Pending.single.commandId, 'cmd-1');
    expect(user2Pending, hasLength(1));
    expect(user2Pending.single.commandId, 'cmd-2');
  });

  test('enqueue replaces duplicate command ids', () async {
    await store.enqueue(
      userId: 'user-1',
      entry: PersistedMatchpointSwipeCommand(
        commandId: 'cmd-1',
        command: buildCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-1',
          action: MatchpointSwipeAction.like,
          createdAt: DateTime.utc(2026, 4, 8, 12),
        ),
      ),
    );
    await store.enqueue(
      userId: 'user-1',
      entry: PersistedMatchpointSwipeCommand(
        commandId: 'cmd-1',
        command: buildCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-9',
          action: MatchpointSwipeAction.dislike,
          createdAt: DateTime.utc(2026, 4, 8, 12, 10),
        ),
      ),
    );

    final pending = await store.load('user-1');
    expect(pending, hasLength(1));
    expect(pending.single.command.targetUserId, 'target-9');
    expect(pending.single.command.action, MatchpointSwipeAction.dislike);
  });

  test('remove clears persisted command', () async {
    await store.enqueue(
      userId: 'user-1',
      entry: PersistedMatchpointSwipeCommand(
        commandId: 'cmd-1',
        command: buildCommand(
          sourceUserId: 'user-1',
          targetUserId: 'target-1',
          action: MatchpointSwipeAction.like,
          createdAt: DateTime.utc(2026, 4, 8, 12),
        ),
      ),
    );

    await store.remove(userId: 'user-1', commandId: 'cmd-1');

    expect(await store.load('user-1'), isEmpty);
  });
}
