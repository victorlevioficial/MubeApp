import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import 'chat_repository.dart';

/// Provides the total count of unread messages for the current user.
///
/// Listens to the [userConversationsProvider] stream and sums up the 'unreadCount' field
/// of each conversation preview.
///
/// Returns 0 if no user is logged in or if there are no unread messages.
final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) {
    return Stream.value(0);
  }

  return ref.watch(chatRepositoryProvider).getUserConversations(user.uid).map((
    previews,
  ) {
    int count = 0;
    for (final preview in previews) {
      if (preview.unreadCount > 0) {
        count++;
      }
    }
    return count;
  });
});
