import 'message.dart';

/// Preserves messages that left a fixed-size live window after newer
/// messages arrived, without resurrecting messages deleted inside the window.
List<Message> preserveShiftedChatWindow({
  required List<Message> previousLatest,
  required List<Message> nextLatest,
  required List<Message> olderMessages,
}) {
  if (previousLatest.isEmpty || nextLatest.isEmpty) return olderMessages;

  final nextIds = nextLatest.map((message) => message.id).toSet();
  final knownOlderIds = olderMessages.map((message) => message.id).toSet();
  final nextOldestTimestamp = nextLatest.last.createdAt;

  final shiftedOut = previousLatest
      .where((message) {
        if (nextIds.contains(message.id) ||
            knownOlderIds.contains(message.id)) {
          return false;
        }

        return message.createdAt.compareTo(nextOldestTimestamp) < 0;
      })
      .toList(growable: false);

  if (shiftedOut.isEmpty) return olderMessages;
  return <Message>[...shiftedOut, ...olderMessages];
}
