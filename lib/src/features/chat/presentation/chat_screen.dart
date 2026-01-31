import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_shimmer.dart';
import '../../../common_widgets/mube_app_bar.dart';
import '../../../common_widgets/user_avatar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import '../domain/conversation_preview.dart';
import '../domain/message.dart';

/// Tela de chat 1:1.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final Map<String, dynamic>? extra;

  const ChatScreen({super.key, required this.conversationId, this.extra});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  // Dados do outro usuário (pode vir via extra ou carregado depois)
  late String _otherUserName;
  String? _otherUserPhoto;
  late String _otherUserId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Garante que só roda uma vez
    if (!_isLoading && !mounted) return;

    // Pequeno hack para checar se já inicializamos (se _otherUserId já foi setado)
    try {
      // Se _otherUserId já tiver valor, não precisamos rodar de novo.
      // Porém, como é late, acessar vai jogar erro se não tiver.
      // Então vamos usar uma flag boolean simples.
      if (_initializationDone) return;
    } catch (_) {}

    _initializeData();
    _ensureConversationExists();
    _initializationDone = true;
  }

  bool _initializationDone = false;

  void _initializeData() {
    // Tenta pegar dados passados via navegação (Optimistic UI)
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

    // Tenta pegar do preview cacheado se não veio extra
    final cachedPreview = ref
        .read(userConversationsProvider)
        .value
        ?.firstWhere(
          (p) => p.id == widget.conversationId,
          orElse: () => ConversationPreview(
            id: widget.conversationId,
            otherUserId: '',
            otherUserName: 'Usuário',
            unreadCount: 0,
            updatedAt: Timestamp.now(),
          ),
        );

    _otherUserName =
        extra?['otherUserName'] ?? cachedPreview?.otherUserName ?? 'Usuário';
    _otherUserPhoto = extra?['otherUserPhoto'] ?? cachedPreview?.otherUserPhoto;
    _otherUserId = extra?['otherUserId'] ?? cachedPreview?.otherUserId ?? '';
  }

  Future<void> _ensureConversationExists() async {
    final user = ref.read(currentUserProfileProvider).value;
    if (user == null || _otherUserId.isEmpty) return;

    final repository = ref.read(chatRepositoryProvider);

    try {
      // Garante que a conversa existe no backend (cria se não existir)
      // Isso é necessário para que as regras de segurança (participantsMap) funcionem
      // e para que o envio de mensagens (que faz update na conversa) não falhe.
      await repository.getOrCreateConversation(
        myUid: user.uid,
        otherUid: _otherUserId,
        otherUserName: _otherUserName,
        otherUserPhoto: _otherUserPhoto,
        myName: user.nome ?? 'Usuário',
        myPhoto: user.foto,
      );

      if (mounted) {
        await repository.markAsRead(
          conversationId: widget.conversationId,
          myUid: user.uid,
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao garantir conversa', e);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || text.length > 1000) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    // Busca documento atualizado para garantir os participantes corretos
    final docSnapshot = await ref
        .read(chatRepositoryProvider)
        .getConversationDoc(widget.conversationId);
    if (docSnapshot == null || !docSnapshot.exists) return;

    final data = docSnapshot.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUid = participants.firstWhere((uid) => uid != user.uid);

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(chatRepositoryProvider);
      await repository.sendMessage(
        conversationId: widget.conversationId,
        text: text,
        myUid: user.uid,
        otherUid: otherUid,
      );

      _textController.clear();

      // Scroll para baixo após enviar
      if (_scrollController.hasClients) {
        // Ignorar o futuro da animação
        _scrollController
            .animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            )
            .ignore();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar mensagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      conversationMessagesProvider(widget.conversationId),
    );
    final user = ref.watch(currentUserProfileProvider).value;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MubeAppBar(title: _buildAppBarTitle(), showBackButton: true),
      body: Column(
        children: [
          // Lista de mensagens
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma mensagem ainda\nEnvie a primeira!',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // Mais recentes embaixo
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == user.uid;

                    final conversationAsync = ref.watch(
                      conversationStreamProvider(widget.conversationId),
                    );
                    final conversationData =
                        conversationAsync.value?.data()
                            as Map<String, dynamic>?;

                    // Verifica se msg foi lida (✓✓)
                    bool isRead = false;
                    if (isMe && conversationData != null) {
                      final readUntilMap =
                          conversationData['readUntil']
                              as Map<String, dynamic>?;

                      // Encontra o ID do outro usuário (que não sou eu)
                      final participants = List<String>.from(
                        conversationData['participants'] ?? [],
                      );
                      final otherUid = participants.firstWhere(
                        (uid) => uid != user.uid,
                        orElse: () => '',
                      );

                      if (otherUid.isNotEmpty) {
                        final readUntil = readUntilMap?[otherUid] as Timestamp?;
                        if (readUntil != null) {
                          isRead = readUntil.compareTo(message.createdAt) >= 0;
                        }
                      }
                    }

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      isRead: isRead,
                    );
                  },
                );
              },
              loading: () => const _ChatShimmer(),
              error: (error, stack) {
                AppLogger.error(
                  'Error loading messages for conversation ${widget.conversationId}',
                  error,
                );
                return const Center(child: Text('Erro ao carregar mensagens'));
              },
            ),
          ),

          // Campo de input
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    // Usa dados locais (extra/cache) imediatamente
    return GestureDetector(
      onTap: () {
        if (_otherUserId.isNotEmpty) {
          context.push('/user/$_otherUserId');
        }
      },
      child: Row(
        children: [
          UserAvatar(size: 36, photoUrl: _otherUserPhoto, name: _otherUserName),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _otherUserName,
              style: AppTypography.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input field
          Expanded(
            child: TextField(
              controller: _textController,
              maxLength: 1000,
              maxLines: 5,
              minLines: 1,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Mensagem...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surface,
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send Button - WhatsApp style (arrow right)
          GestureDetector(
            onTap: _isLoading || !hasText ? null : _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: hasText
                    ? AppColors.brandPrimary
                    : AppColors.surfaceHighlight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded, // WhatsApp-style send icon
                        color: hasText ? Colors.white : AppColors.textTertiary,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isRead;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? AppColors.brandPrimary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe
                    ? const Radius.circular(20)
                    : const Radius.circular(4),
                bottomRight: isMe
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
              ),
              border: !isMe
                  ? Border.all(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end, // Aligns content to the right
              children: [
                Text(
                  message.text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt.toDate().toLocal()),
                      style: AppTypography.bodySmall.copyWith(
                        color: isMe
                            ? AppColors.textPrimary.withValues(alpha: 0.7)
                            : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead
                            ? AppColors.textPrimary
                            : AppColors.textPrimary.withValues(alpha: 0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _ChatShimmer extends StatelessWidget {
  const _ChatShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      reverse: true,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  AppShimmer.box(
                    width: index % 3 == 0 ? 150 : 200,
                    height: 48,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 4),
                  AppShimmer.text(width: 40, height: 10),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
