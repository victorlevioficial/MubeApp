import 'package:firebase_database/firebase_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';
import 'chat_repository.dart';

part 'chat_providers.g.dart';

/// Provider simples do ChatRepository (singleton)
@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) {
  return ChatRepository(
    database: FirebaseDatabase.instance,
    authRepository: ref.watch(authRepositoryProvider),
  );
}

/// Stream de conversas do usuário autenticado
///
/// Ordenado por lastMessageTime (repository já ordena)
/// Limitado a 100 conversas
@riverpod
Stream<List<ConversationPreview>> userConversationsStream(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref.watch(chatRepositoryProvider).getUserConversations(user.uid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
}

/// Stream de mensagens de uma conversa específica
///
/// Limitado a 50 mensagens (repository já ordena)
@riverpod
Stream<List<Message>> messagesStream(Ref ref, String conversationId) {
  return ref.watch(chatRepositoryProvider).getMessages(conversationId);
}

/// Future provider para readUntil do outro usuário
///
/// Carregado uma única vez ao entrar no chat
/// Usado para calcular status ✓✓ na UI
@riverpod
Future<int> readUntil(Ref ref, String conversationId, String otherUserId) {
  return ref
      .watch(chatRepositoryProvider)
      .getReadUntil(conversationId: conversationId, otherUserId: otherUserId);
}
