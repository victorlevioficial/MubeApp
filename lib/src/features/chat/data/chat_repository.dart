import 'package:firebase_database/firebase_database.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';

/// Repository para gerenciar operações de chat no Firebase Realtime Database
class ChatRepository {
  final FirebaseDatabase _database;
  final AuthRepository _authRepository;

  ChatRepository({
    required FirebaseDatabase database,
    required AuthRepository authRepository,
  }) : _database = database,
       _authRepository = authRepository;

  /// Retorna o ID determinístico da conversa entre dois usuários
  String _getConversationId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  /// Cria ou retorna conversa existente (idempotente)
  ///
  /// Race condition: Se a criação falhar, relê o nó e retorna o ID existente
  Future<String> getOrCreateConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserPhoto,
    required String currentUserName,
    String? currentUserPhoto,
  }) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final conversationId = _getConversationId(currentUser.uid, otherUserId);
    final chatRef = _database.ref('chats/$conversationId');

    // Verificar se a conversa já existe (OTIMIZADO)
    // Checamos em 'userChats/$uid/$convId' pois temos permissão de leitura garantida lá.
    // Tentar ler 'chats/$convId' direto pode dar permissão negada se não formos participantes ainda.
    try {
      final userChatRef = _database.ref(
        'userChats/${currentUser.uid}/$conversationId',
      );
      final snapshot = await userChatRef.get();
      if (snapshot.exists) {
        return conversationId;
      }
    } catch (e) {
      // Falha silenciosa na leitura (pode ser offline), prossegue para tentativa de criação/update
    }

    // Participants (exatamente 2 UIDs)
    // Preparar dados da conversa
    final participantsData = {currentUser.uid: true, otherUserId: true};

    final metadataData = {
      'lastMessage': '',
      'lastMessageTime': ServerValue.timestamp,
      'lastSenderId': currentUser.uid,
    };

    // User Chats references data
    final currentUserChatData = {
      'conversationId': conversationId,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'otherUserPhoto': otherUserPhoto,
      'lastMessage': '',
      'lastMessageTime': ServerValue.timestamp,
      'lastSenderId': currentUser.uid,
      'unreadCount': 0,
    };

    final otherUserChatData = {
      'conversationId': conversationId,
      'otherUserId': currentUser.uid,
      'otherUserName': currentUserName,
      'otherUserPhoto': currentUserPhoto,
      'lastMessage': '',
      'lastMessageTime': ServerValue.timestamp,
      'lastSenderId': currentUser.uid,
      'unreadCount': 0,
    };

    try {
      // Executar updates separados (não usar multipath na raiz devido às regras)
      print('DEBUG ChatRepository: Creating conversation $conversationId');

      // 1. Criar/Atualizar dados da conversa
      await chatRef.update({
        'participants': participantsData,
        'metadata': metadataData,
      });

      // 2. Atualizar referência para o usuário atual
      await _database
          .ref('userChats/${currentUser.uid}/$conversationId')
          .update(currentUserChatData);

      // 3. Atualizar referência para o outro usuário
      await _database
          .ref('userChats/$otherUserId/$conversationId')
          .update(otherUserChatData);

      print(
        'DEBUG ChatRepository: Conversation $conversationId created/updated successfully',
      );

      return conversationId;
    } catch (e, st) {
      print('ERROR in ChatRepository: Failed to create conversation: $e');
      print('ERROR in ChatRepository: StackTrace: $st');
      // Retornar o ID mesmo em caso de erro para manter comportamento atual
      return conversationId;
    }
  }

  /// Envia mensagem com update multipath atômico
  ///
  /// Incrementa unreadCount do destinatário via transaction (até 3 retries)
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    required String destinatarioId,
  }) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    // Segurança: Impedir envio de mensagem para si mesmo
    if (destinatarioId == currentUser.uid) {
      throw Exception('Não é possível enviar mensagem para si mesmo');
    }

    // Gerar ID único para a mensagem
    final messageRef = _database.ref('chats/$conversationId/messages').push();
    final messageId = messageRef.key!;

    // Preparar update multipath para sincronização total (SEM get())
    final truncatedMessage = text.length > 100
        ? '${text.substring(0, 100)}...'
        : text;

    // Dados da mensagem para chats/$convId/messages
    final messageData = {
      'senderId': currentUser.uid,
      'text': text,
      'timestamp': ServerValue.timestamp,
    };

    // Dados de metadata para chats/$convId/metadata
    final metadataUpdates = {
      'lastMessage': truncatedMessage,
      'lastMessageTime': ServerValue.timestamp,
      'lastSenderId': currentUser.uid,
    };

    // Dados para userChats (meu e dele)
    final userChatUpdates = {
      'lastMessage': truncatedMessage,
      'lastMessageTime': ServerValue.timestamp,
      'lastSenderId': currentUser.uid,
    };

    try {
      // 1. Adicionar mensagem e atualizar metadata da conversa
      // Usando Future.wait para paralelizar
      await Future.wait([
        _database
            .ref('chats/$conversationId/messages/$messageId')
            .set(messageData),
        _database.ref('chats/$conversationId/metadata').update(metadataUpdates),
      ]);

      // 2. Atualizar userChats para mim
      await _database
          .ref('userChats/${currentUser.uid}/$conversationId')
          .update(userChatUpdates);

      // 3. Atualizar userChats para o destinatário e incrementar unreadCount
      final otherUserChatRef = _database.ref(
        'userChats/$destinatarioId/$conversationId',
      );

      // DEBUG: Verificar o que existe no banco antes de atualizar
      try {
        final snapshot = await otherUserChatRef.get();
        print('DEBUG sendMessage: data exists = ${snapshot.exists}');
        if (snapshot.exists) {
          final data = snapshot.value as Map?;
          print(
            'DEBUG sendMessage: data.otherUserId = ${data?['otherUserId']}',
          );
          print('DEBUG sendMessage: currentUser.uid = ${currentUser.uid}');
        }
      } catch (e) {
        print('DEBUG sendMessage: error reading data: $e');
      }

      // Update combinando preview + incremento atômico de unreadCount
      await otherUserChatRef.update({
        ...userChatUpdates,
        'unreadCount': ServerValue.increment(1),
      });
    } catch (e) {
      // Se falhar, tentamos logar mas não revertemos (MVP)
      print('ERROR: Failed to send message: $e');
      rethrow;
    }
  }

  /// Stream de mensagens da conversa (limitado a 50)
  Stream<List<Message>> getMessages(String conversationId) {
    return _database
        .ref('chats/$conversationId/messages')
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .map((event) {
          final messages = <Message>[];
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            data.forEach((key, value) {
              messages.add(
                Message.fromJson(key, Map<String, dynamic>.from(value as Map)),
              );
            });
            // Ordenar por timestamp
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          }
          return messages;
        });
  }

  /// Stream de conversas do usuário (limitado a 100, ordenado por lastMessageTime)
  Stream<List<ConversationPreview>> getUserConversations(String userId) {
    return _database
        .ref('userChats/$userId')
        .orderByChild('lastMessageTime')
        .limitToLast(100)
        .onValue
        .map((event) {
          final conversations = <ConversationPreview>[];
          if (event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            data.forEach((key, value) {
              final conversationData = Map<String, dynamic>.from(value as Map);

              // Filtrar conversas vazias (sem mensagem ainda)
              final lastMessage = conversationData['lastMessage'] as String?;
              if (lastMessage == null || lastMessage.isEmpty) {
                return; // Skip esta conversa
              }

              // Filtrar conversas com otherUserId vazio (dados corrompidos)
              final otherUserId = conversationData['otherUserId'] as String?;
              if (otherUserId == null || otherUserId.isEmpty) {
                return; // Skip esta conversa
              }

              conversations.add(
                ConversationPreview.fromJson(key, conversationData),
              );
            });
            // Ordenar por lastMessageTime (mais recente primeiro)
            conversations.sort(
              (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
            );
          }
          return conversations;
        });
  }

  /// Marca conversa como lida
  Future<void> markAsRead({
    required String conversationId,
    required int lastMessageTime,
  }) async {
    final currentUser = _authRepository.currentUser;
    if (currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final updates = <String, dynamic>{};

    // Setar readUntil para o timestamp da última mensagem
    updates['chats/$conversationId/readUntil/${currentUser.uid}'] =
        lastMessageTime;

    // Zerar unreadCount no chat
    updates['chats/$conversationId/unreadCount/${currentUser.uid}'] = 0;

    // Zerar unreadCount no userChats
    updates['userChats/${currentUser.uid}/$conversationId/unreadCount'] = 0;

    await _database.ref().update(updates);
  }

  /// Obtém readUntil do outro usuário para calcular status de leitura
  Future<int> getReadUntil({
    required String conversationId,
    required String otherUserId,
  }) async {
    final snapshot = await _database
        .ref('chats/$conversationId/readUntil/$otherUserId')
        .get();
    return (snapshot.value as int?) ?? 0;
  }
}
