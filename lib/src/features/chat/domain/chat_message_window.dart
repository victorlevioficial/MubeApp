import 'package:intl/intl.dart';

import 'chat_conversation_rules.dart';
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

/// Joins the live window with older pages, newest first, without duplicates.
List<Message> mergeChatMessageWindows({
  required List<Message> latestMessages,
  required List<Message> olderMessages,
}) {
  final merged = <Message>[];
  final seenIds = <String>{};
  for (final message in [...latestMessages, ...olderMessages]) {
    if (seenIds.add(message.id)) merged.add(message);
  }
  return merged;
}

/// Whether a date separator goes above [messages] at [index].
///
/// [messages] is ordered newest first, so the separator shows when the next
/// (older) message is from another day, and always above the oldest message.
bool shouldShowChatDateSeparator(List<Message> messages, int index) {
  if (index >= messages.length) return false;
  if (index == messages.length - 1) return true;

  final currentDate = messages[index].createdAt.toDate().toLocal();
  final olderDate = messages[index + 1].createdAt.toDate().toLocal();
  return !isSameCalendarDay(currentDate, olderDate);
}

/// "Hoje", "Ontem" or `dd/MM/yyyy` for a date separator.
String formatChatDateSeparatorLabel(DateTime dateTime, {DateTime? now}) {
  final target = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final dayDiff = today.difference(target).inDays;

  if (dayDiff == 0) return 'Hoje';
  if (dayDiff == 1) return 'Ontem';

  return DateFormat('dd/MM/yyyy').format(target);
}
