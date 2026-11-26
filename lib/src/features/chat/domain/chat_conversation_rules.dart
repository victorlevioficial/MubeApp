/// Pure rules about a 1:1 conversation document and its messages.
///
/// Kept free of Flutter and Firestore types so they can be unit tested and
/// reused outside the chat screen.
library;

/// Status values stored in `conversations/{id}.requestStatus`.
abstract final class ChatRequestStatus {
  static const accepted = 'accepted';
  static const pending = 'pending';
  static const rejected = 'rejected';

  static const values = {accepted, pending, rejected};
}

/// Message-request state of a conversation, as read from its document.
class ChatRequestState {
  final String status;
  final int cycle;
  final String? senderId;
  final String? recipientId;

  const ChatRequestState({
    this.status = ChatRequestStatus.accepted,
    this.cycle = 0,
    this.senderId,
    this.recipientId,
  });

  static const accepted = ChatRequestState();

  /// Reads the request fields, falling back to an accepted conversation when
  /// the document is missing or holds unexpected values.
  factory ChatRequestState.fromConversation(Map<String, dynamic>? data) {
    final rawStatus = data?['requestStatus'];
    final rawCycle = data?['requestCycle'];
    return ChatRequestState(
      status:
          rawStatus is String && ChatRequestStatus.values.contains(rawStatus)
          ? rawStatus
          : ChatRequestStatus.accepted,
      cycle: rawCycle is num ? rawCycle.toInt() : 0,
      senderId: _readOptionalString(data?['requestSenderId']),
      recipientId: _readOptionalString(data?['requestRecipientId']),
    );
  }

  bool get isPending => status == ChatRequestStatus.pending;

  /// Whether [uid] received a request they have not accepted yet, and so
  /// cannot reply.
  bool isPendingRecipient(String uid) => isPending && recipientId == uid;

  /// Whether [uid] already sent a request that is still waiting.
  bool isPendingSender(String uid) => isPending && senderId == uid;

  /// Same cycle, with the request accepted locally before the backend
  /// confirms it.
  ChatRequestState asAccepted() => ChatRequestState(cycle: cycle);
}

String? _readOptionalString(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

/// Derives the other participant from a canonical `uidA_uidB` conversation id.
///
/// Returns an empty string when the id is not canonical or does not contain
/// [myUid].
String deriveOtherUidFromConversationId(String conversationId, String myUid) {
  final parts = conversationId.split('_');
  if (parts.length != 2) return '';
  if (parts[0] == myUid) return parts[1];
  if (parts[1] == myUid) return parts[0];
  return '';
}

/// Whether [uid] is listed in the conversation's `participants`.
bool isConversationParticipant(Object? conversationData, String uid) {
  final participants = _participantsOf(conversationData);
  return participants != null && participants.contains(uid);
}

/// The first participant that is not [myUid], or an empty string.
String resolveOtherParticipant(Object? conversationData, String myUid) {
  final participants = _participantsOf(conversationData);
  if (participants == null) return '';
  for (final participant in participants) {
    if (participant is String && participant != myUid) return participant;
  }
  return '';
}

List<Object?>? _participantsOf(Object? conversationData) {
  if (conversationData is! Map<String, dynamic>) return null;
  final participants = conversationData['participants'];
  return participants is List ? participants : null;
}

/// Whether a message document should be shown: hidden and rate-limited
/// messages stay out of the conversation.
bool isVisibleChatMessage(Map<String, dynamic>? data) {
  if (data == null) return false;
  return data['hidden'] != true &&
      data['rate_limited'] != true &&
      data['moderation_state'] != 'rate_limited';
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
