import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';
import 'chat_repository.dart';

/// Stream de todas as conversas do usuário logado.
final userConversationsProvider = StreamProvider<List<ConversationPreview>>((
  ref,
) {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null) return Stream.value([]);

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getUserConversations(user.uid);
});

/// Conversas filtradas: Apenas MatchPoint
final matchConversationsProvider =
    Provider<AsyncValue<List<ConversationPreview>>>((ref) {
      final allAsync = ref.watch(userConversationsProvider);
      return allAsync.whenData((list) {
        return list.where((c) => c.type == 'matchpoint').toList();
      });
    });

/// Conversas filtradas: Apenas Diretas (não-matchpoint)
final directConversationsProvider =
    Provider<AsyncValue<List<ConversationPreview>>>((ref) {
      final allAsync = ref.watch(userConversationsProvider);
      return allAsync.whenData((list) {
        return list.where((c) => c.type != 'matchpoint').toList();
      });
    });

/// Stream de mensagens de uma conversa específica.
final conversationMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, id) {
      final repository = ref.watch(chatRepositoryProvider);
      return repository.getMessages(id);
    });

final conversationStreamProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot, String>((ref, id) {
      final repository = ref.watch(chatRepositoryProvider);
      return repository.getConversationStream(id);
    });
