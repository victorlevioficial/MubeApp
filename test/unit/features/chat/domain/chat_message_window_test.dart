import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/chat/domain/chat_message_window.dart';
import 'package:mube/src/features/chat/domain/message.dart';

void main() {
  Message message(String id, int seconds) => Message(
    id: id,
    senderId: 'user-1',
    text: id,
    createdAt: Timestamp.fromMillisecondsSinceEpoch(seconds * 1000),
  );

  test('preserves the old boundary when the live window shifts', () {
    final previous = <Message>[
      message('message-3', 3),
      message('message-2', 2),
      message('message-1', 1),
    ];
    final next = <Message>[
      message('message-4', 4),
      message('message-3', 3),
      message('message-2', 2),
    ];
    final older = <Message>[message('message-0', 0)];

    final result = preserveShiftedChatWindow(
      previousLatest: previous,
      nextLatest: next,
      olderMessages: older,
    );

    expect(result.map((item) => item.id), ['message-1', 'message-0']);
  });

  test('does not resurrect a message removed inside the live window', () {
    final previous = <Message>[
      message('message-3', 3),
      message('message-2', 2),
      message('message-1', 1),
    ];
    final next = <Message>[
      message('message-3', 3),
      message('message-1', 1),
      message('message-0', 0),
    ];

    final result = preserveShiftedChatWindow(
      previousLatest: previous,
      nextLatest: next,
      olderMessages: const [],
    );

    expect(result, isEmpty);
  });

  test('preserves the boundary when messages share a timestamp', () {
    final previous = <Message>[
      message('message-c', 1),
      message('message-b', 1),
      message('message-a', 1),
    ];
    final next = <Message>[
      message('message-d', 1),
      message('message-c', 1),
      message('message-b', 1),
    ];

    final result = preserveShiftedChatWindow(
      previousLatest: previous,
      nextLatest: next,
      olderMessages: const [],
    );

    expect(result.map((item) => item.id), ['message-a']);
  });
}
