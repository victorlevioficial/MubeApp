import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common_widgets/mube_app_bar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../data/chat_providers.dart';
import 'widgets/chat_input_field.dart';
import 'widgets/message_bubble.dart';

/// Tela de chat individual
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _hasMarkedAsRead = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Chama markAsRead uma única vez quando mensagens carregam
  Future<void> _markAsReadOnce(List messages) async {
    if (_hasMarkedAsRead || messages.isEmpty) return;

    _hasMarkedAsRead = true;

    final lastMessageTime = messages.last.timestamp as int;

    try {
      await ref
          .read(chatRepositoryProvider)
          .markAsRead(
            conversationId: widget.conversationId,
            lastMessageTime: lastMessageTime,
          );
    } catch (e) {
      debugPrint('Erro ao marcar como lida: $e');
    }
  }

  /// Auto-scroll para o final da lista
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _handleSendMessage(String text) async {
    await ref
        .read(chatRepositoryProvider)
        .sendMessage(
          conversationId: widget.conversationId,
          text: text,
          destinatarioId: widget.otherUserId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      messagesStreamProvider(widget.conversationId),
    );
    final readUntilAsync = ref.watch(
      readUntilProvider(widget.conversationId, widget.otherUserId),
    );

    // Obter UID do usuário autenticado
    final authState = ref.watch(authStateChangesProvider);
    final currentUserId = authState.value?.uid;

    // Buscar perfil real do outro usuário do Firestore para ter nome correto
    final otherUserProfileAsync = ref.watch(
      userProfileProvider(widget.otherUserId),
    );

    final displayName = otherUserProfileAsync.when(
      data: (profile) {
        if (profile == null) return widget.otherUserName;
        // Usar o nome artístico se disponível, senão o nome comum
        switch (profile.tipoPerfil) {
          case null:
            return profile.nome ?? widget.otherUserName;
          default:
            final artisticName =
                profile.dadosProfissional?['nomeArtistico'] as String? ??
                profile.dadosBanda?['nome'] as String? ??
                profile.dadosEstudio?['nome'] as String? ??
                profile.dadosContratante?['nome'] as String?;
            return artisticName ?? profile.nome ?? widget.otherUserName;
        }
      },
      loading: () => widget.otherUserName,
      error: (_, __) => widget.otherUserName,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MubeAppBar(title: displayName),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                // Marcar como lida uma única vez
                _markAsReadOnce(messages);

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma mensagem ainda.\nEnvie a primeira!',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // Auto-scroll ao receber novas mensagens
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;

                    // Calcular se mensagem foi lida (apenas para minhas mensagens)
                    final isRead = readUntilAsync.when(
                      data: (readUntil) => readUntil >= message.timestamp,
                      loading: () => false,
                      error: (_, __) => false,
                    );

                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      isRead: isRead && isMe,
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        'Erro ao carregar mensagens',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        error.toString(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Campo de entrada
          ChatInputField(onSend: _handleSendMessage),
        ],
      ),
    );
  }
}
