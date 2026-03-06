part of 'chat_screen.dart';

extension _ChatScreenWidgets on _ChatScreenState {
  Widget _buildChatBody({
    required AsyncValue<QuerySnapshot<Map<String, dynamic>>>?
    messagesSnapshotAsync,
    required String currentUserId,
    required String otherUid,
    required Map<String, dynamic> readUntilMap,
  }) {
    return Column(
      children: [
        Expanded(
          child: _accessState == _ConversationAccessState.checking
              ? _buildLoadingShimmer()
              : _accessState != _ConversationAccessState.ready
              ? _buildConversationUnavailableState()
              : messagesSnapshotAsync!.when(
                  data: (messagesSnapshot) {
                    final latestMessages = _messagesFromSnapshot(
                      messagesSnapshot,
                    );
                    final serverMessages = _mergeServerMessages(latestMessages);
                    final serverClientMessageIds = serverMessages
                        .map((message) => message.clientMessageId)
                        .whereType<String>()
                        .toSet();

                    final pendingMessages = _pendingMessages
                        .where(
                          (pending) =>
                              !serverClientMessageIds.contains(pending.localId),
                        )
                        .map(
                          (pending) => Message(
                            id: pending.localId,
                            senderId: currentUserId,
                            text: pending.text,
                            createdAt: Timestamp.fromDate(pending.createdAt),
                            clientMessageId: pending.localId,
                          ),
                        )
                        .toList(growable: false);
                    final mergedMessages = <Message>[
                      ...pendingMessages,
                      ...serverMessages,
                    ];
                    final showPaginationLoader =
                        _isLoadingOlderMessages || _hasMoreOlderMessages;

                    if (mergedMessages.isEmpty) {
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
                      reverse: true,
                      padding: AppSpacing.all16,
                      itemCount:
                          mergedMessages.length +
                          (showPaginationLoader ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (showPaginationLoader &&
                            index == mergedMessages.length) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.s8,
                              bottom: AppSpacing.s4,
                            ),
                            child: Center(
                              child: _isLoadingOlderMessages
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Suba para carregar mais',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                            ),
                          );
                        }

                        final message = mergedMessages[index];
                        final isMe = message.senderId == currentUserId;
                        final isPending = message.id.startsWith('local_');
                        final showDateSeparator = _shouldShowDateSeparator(
                          mergedMessages,
                          index,
                        );
                        final dateLabel = showDateSeparator
                            ? _formatDateSeparatorLabel(
                                message.createdAt.toDate().toLocal(),
                              )
                            : null;

                        bool isRead = false;
                        if (isMe && otherUid.isNotEmpty) {
                          final readUntil = readUntilMap[otherUid];
                          if (readUntil is Timestamp) {
                            isRead =
                                readUntil.compareTo(message.createdAt) >= 0;
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (dateLabel != null)
                              _DaySeparator(label: dateLabel),
                            _MessageBubble(
                              message: message,
                              isMe: isMe,
                              isPending: isPending,
                              isRead: isRead,
                            ),
                          ],
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
                    return const Center(
                      child: Text('Erro ao carregar mensagens'),
                    );
                  },
                ),
        ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildAppBarTitle() {
    return GestureDetector(
      onTap: () {
        if (_otherUserId.isNotEmpty) {
          context.push(RoutePaths.publicProfileById(_otherUserId));
        }
      },
      child: Row(
        children: [
          UserAvatar(size: 36, photoUrl: _otherUserPhoto, name: _otherUserName),
          const SizedBox(width: AppSpacing.s8),
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
    final canInteract = _canReadConversation;

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s12,
        right: AppSpacing.s12,
        top: AppSpacing.s8,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s8,
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
          Expanded(
            child: AppTextField(
              controller: _textController,
              readOnly: !canInteract,
              canRequestFocus: _canReadConversation,
              keyboardType: TextInputType.multiline,
              maxLength: 1000,
              showCounter: false,
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              textCapitalization: TextCapitalization.sentences,
              enableSuggestions: false,
              autocorrect: false,
              hint: _canReadConversation
                  ? 'Mensagem...'
                  : 'Conversa indisponivel',
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textController,
            builder: (context, value, _) {
              final hasText = value.text.trim().isNotEmpty;

              return GestureDetector(
                onTap: canInteract && hasText ? _sendMessage : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: hasText && _canReadConversation
                        ? AppColors.primary
                        : AppColors.surfaceHighlight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.send_rounded,
                      color: hasText && _canReadConversation
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return const _ChatShimmer();
  }

  Widget _buildConversationUnavailableState() {
    return Center(
      child: Padding(
        padding: AppSpacing.h24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.s12),
            Text(
              _conversationAccessMessage ??
                  'Não foi possível acessar esta conversa.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isPending;
  final bool isRead;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.isPending = false,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12,
              vertical: AppSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadius.r24),
                topRight: const Radius.circular(AppRadius.r24),
                bottomLeft: isMe
                    ? const Radius.circular(AppRadius.r24)
                    : const Radius.circular(AppRadius.r4),
                bottomRight: isMe
                    ? const Radius.circular(AppRadius.r4)
                    : const Radius.circular(AppRadius.r24),
              ),
              border: !isMe
                  ? Border.all(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message.text,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt.toDate().toLocal()),
                      style: AppTypography.chipLabel.copyWith(
                        color: isMe
                            ? AppColors.textPrimary.withValues(alpha: 0.7)
                            : AppColors.textSecondary,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: AppSpacing.s4),
                      if (isPending)
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.textPrimary.withValues(alpha: 0.7),
                        )
                      else
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

class _DaySeparator extends StatelessWidget {
  final String label;

  const _DaySeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8, top: AppSpacing.s8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s4,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all12,
            border: Border.all(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: AppTypography.titleSmall.fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatShimmer extends StatelessWidget {
  const _ChatShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppSpacing.all16,
      itemCount: 8,
      reverse: true,
      itemBuilder: (context, index) {
        final isMe = index % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s16),
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
                  const SizedBox(height: AppSpacing.s4),
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
