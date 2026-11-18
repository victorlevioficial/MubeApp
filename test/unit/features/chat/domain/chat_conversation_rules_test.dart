import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/features/chat/domain/chat_conversation_rules.dart';
import 'package:mube/src/features/chat/domain/chat_message_window.dart';
import 'package:mube/src/features/chat/domain/message.dart';

void main() {
  group('ChatRequestState.fromConversation', () {
    test('defaults to an accepted conversation without data', () {
      final state = ChatRequestState.fromConversation(null);

      expect(state.status, ChatRequestStatus.accepted);
      expect(state.cycle, 0);
      expect(state.senderId, isNull);
      expect(state.recipientId, isNull);
    });

    test('reads a pending request', () {
      final state = ChatRequestState.fromConversation({
        'requestStatus': 'pending',
        'requestCycle': 2,
        'requestSenderId': ' sender ',
        'requestRecipientId': 'recipient',
      });

      expect(state.status, ChatRequestStatus.pending);
      expect(state.cycle, 2);
      expect(state.senderId, 'sender');
      expect(state.isPendingRecipient('recipient'), isTrue);
      expect(state.isPendingRecipient('sender'), isFalse);
      expect(state.isPendingSender('sender'), isTrue);
    });

    test('falls back to accepted for unknown status and blank ids', () {
      final state = ChatRequestState.fromConversation({
        'requestStatus': 'archived',
        'requestCycle': 'two',
        'requestSenderId': '   ',
      });

      expect(state.status, ChatRequestStatus.accepted);
      expect(state.cycle, 0);
      expect(state.senderId, isNull);
    });

    test('asAccepted keeps the cycle and clears the request parties', () {
      final state = ChatRequestState.fromConversation({
        'requestStatus': 'pending',
        'requestCycle': 3,
        'requestSenderId': 'sender',
        'requestRecipientId': 'recipient',
      }).asAccepted();

      expect(state.status, ChatRequestStatus.accepted);
      expect(state.cycle, 3);
      expect(state.senderId, isNull);
      expect(state.isPendingRecipient('recipient'), isFalse);
    });
  });

  group('participants', () {
    test('derives the other uid from a canonical conversation id', () {
      expect(deriveOtherUidFromConversationId('a_b', 'a'), 'b');
      expect(deriveOtherUidFromConversationId('a_b', 'b'), 'a');
      expect(deriveOtherUidFromConversationId('a_b', 'c'), '');
      expect(deriveOtherUidFromConversationId('legacy-id', 'a'), '');
    });

    test('checks membership and resolves the other participant', () {
      final data = <String, dynamic>{
        'participants': ['me', 'other'],
      };

      expect(isConversationParticipant(data, 'me'), isTrue);
      expect(isConversationParticipant(data, 'stranger'), isFalse);
      expect(resolveOtherParticipant(data, 'me'), 'other');
    });

    test('handles missing or malformed participants', () {
      expect(isConversationParticipant(null, 'me'), isFalse);
      expect(isConversationParticipant({'participants': 'me'}, 'me'), isFalse);
      expect(resolveOtherParticipant({'participants': <String>[]}, 'me'), '');
      expect(
        resolveOtherParticipant({
          'participants': ['me', 42],
        }, 'me'),
        '',
      );
    });
  });

  test('hides hidden and rate-limited messages', () {
    expect(isVisibleChatMessage({'text': 'oi'}), isTrue);
    expect(isVisibleChatMessage(null), isFalse);
    expect(isVisibleChatMessage({'hidden': true}), isFalse);
    expect(isVisibleChatMessage({'rate_limited': true}), isFalse);
    expect(isVisibleChatMessage({'moderation_state': 'rate_limited'}), isFalse);
  });

  group('message window', () {
    Message message(String id, DateTime createdAt) => Message(
      id: id,
      senderId: 'user-1',
      text: id,
      createdAt: Timestamp.fromDate(createdAt),
    );

    test('merges live and older messages without duplicates', () {
      final now = DateTime(2026, 11, 18, 12);
      final merged = mergeChatMessageWindows(
        latestMessages: [message('3', now), message('2', now)],
        olderMessages: [message('2', now), message('1', now)],
      );

      expect(merged.map((m) => m.id), ['3', '2', '1']);
    });

    test('shows a separator when the older message is from another day', () {
      final messages = [
        message('today-late', DateTime(2026, 11, 18, 20)),
        message('today-early', DateTime(2026, 11, 18, 8)),
        message('yesterday', DateTime(2026, 11, 17, 22)),
      ];

      expect(shouldShowChatDateSeparator(messages, 0), isFalse);
      expect(shouldShowChatDateSeparator(messages, 1), isTrue);
      expect(shouldShowChatDateSeparator(messages, 2), isTrue);
      expect(shouldShowChatDateSeparator(messages, 3), isFalse);
    });

    test('labels separators as today, yesterday or a date', () {
      final now = DateTime(2026, 11, 18, 9);

      expect(
        formatChatDateSeparatorLabel(DateTime(2026, 11, 18, 23), now: now),
        'Hoje',
      );
      expect(
        formatChatDateSeparatorLabel(DateTime(2026, 11, 17, 1), now: now),
        'Ontem',
      );
      expect(
        formatChatDateSeparatorLabel(DateTime(2026, 11, 2), now: now),
        '02/11/2026',
      );
    });
  });
}
