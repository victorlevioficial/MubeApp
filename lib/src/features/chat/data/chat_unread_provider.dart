import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'chat_providers.dart';

/// Total de conversas com mensagens não lidas.
///
/// Deriva do stream já compartilhado por [userConversationsProvider] para evitar
/// um segundo listener redundante em `conversationPreviews`.
final unreadMessagesCountProvider = Provider<int>((ref) {
  final previews = ref.watch(userConversationsProvider).value ?? const [];
  var count = 0;
  for (final preview in previews) {
    if (preview.unreadCount > 0) {
      count++;
    }
  }
  return count;
});
