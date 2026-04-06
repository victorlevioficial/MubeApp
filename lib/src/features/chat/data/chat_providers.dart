import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';
import 'chat_repository.dart';

/// Stream de todas as conversas do usuário logado.
final userConversationsProvider =
    StreamProvider.autoDispose<List<ConversationPreview>>((ref) {
      final userId =
          ref.watch(currentUserIdProvider) ??
          ref.read(authRepositoryProvider).currentUser?.uid;
      if (userId == null || userId.isEmpty) return Stream.value([]);

      final repository = ref.read(chatRepositoryProvider);
      return repository.getUserConversations(userId);
    });

final userAcceptedConversationsProvider =
    StreamProvider.autoDispose<List<ConversationPreview>>((ref) {
      final userId =
          ref.watch(currentUserIdProvider) ??
          ref.read(authRepositoryProvider).currentUser?.uid;
      if (userId == null || userId.isEmpty) return Stream.value([]);

      final repository = ref.read(chatRepositoryProvider);
      return repository.getUserAcceptedConversations(userId);
    });

final userPendingConversationsProvider =
    StreamProvider.autoDispose<List<ConversationPreview>>((ref) {
      final userId =
          ref.watch(currentUserIdProvider) ??
          ref.read(authRepositoryProvider).currentUser?.uid;
      if (userId == null || userId.isEmpty) return Stream.value([]);

      final repository = ref.read(chatRepositoryProvider);
      return repository.getUserPendingConversations(userId);
    });

/// Conversas filtradas: Apenas MatchPoint
final matchConversationsProvider =
    Provider.autoDispose<AsyncValue<List<ConversationPreview>>>((ref) {
      final allAsync = ref.watch(userConversationsProvider);
      return allAsync.whenData((list) {
        return list.where((c) => c.type == 'matchpoint').toList();
      });
    });

/// Conversas filtradas: Apenas Diretas (não-matchpoint)
final directConversationsProvider =
    Provider.autoDispose<AsyncValue<List<ConversationPreview>>>((ref) {
      final allAsync = ref.watch(userConversationsProvider);
      return allAsync.whenData((list) {
        return list.where((c) => c.type != 'matchpoint').toList();
      });
    });

/// Stream de mensagens de uma conversa específica.
final conversationMessagesProvider = StreamProvider.autoDispose
    .family<List<Message>, String>((ref, id) {
      final repository = ref.read(chatRepositoryProvider);
      return repository.getMessages(id);
    });

final conversationMessagesSnapshotProvider = StreamProvider.autoDispose
    .family<QuerySnapshot<Map<String, dynamic>>, String>((ref, id) {
      final repository = ref.read(chatRepositoryProvider);
      return repository.getMessagesSnapshot(id);
    });

final conversationStreamProvider = StreamProvider.autoDispose
    .family<DocumentSnapshot, String>((ref, id) {
      final repository = ref.read(chatRepositoryProvider);
      return repository.getConversationStream(id);
    });
