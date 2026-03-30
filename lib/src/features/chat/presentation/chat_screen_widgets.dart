part of 'chat_screen.dart';

extension _ChatScreenWidgets on _ChatScreenState {
  Widget _buildInitialLoadingScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: _buildAppBarTitle(), showBackButton: true),
      body: _hasKnownConversationContext
          ? _buildLoadingShimmer()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildChatBody({
    required bool conversationExists,
    required AsyncValue<QuerySnapshot<Map<String, dynamic>>>?
    messagesSnapshotAsync,
    required String currentUserId,
    required String otherUid,
    required Map<String, dynamic> readUntilMap,
    required bool isPendingRecipient,
  }) {
    return Column(
      children: [
        Expanded(
          child: _accessState == _ConversationAccessState.checking
              ? _buildLoadingShimmer()
              : _accessState != _ConversationAccessState.ready
              ? _buildConversationUnavailableState()
              : !conversationExists
              ? _buildDraftConversationState(currentUserId: currentUserId)
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
                            replyToMessageId: pending.replyToMessageId,
                            replyToSenderId: pending.replyToSenderId,
                            replyToText: pending.replyToText,
                            replyToType: pending.replyToType,
                          ),
                        )
                        .toList(growable: false);
                    final mergedMessages = <Message>[
                      ...pendingMessages,
                      ...serverMessages,
                    ];
                    _finishFirstMessagesFrameSpan(
                      snapshot: messagesSnapshot,
                      renderedCount: mergedMessages.length,
                      status: mergedMessages.isEmpty ? 'empty' : 'data',
                    );
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
                        final canReply =
                            _canReadConversation &&
                            !isPendingRecipient &&
                            !isPending &&
                            message.type == 'text' &&
                            message.text.trim().isNotEmpty;
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
                              replyAuthorLabel: message.replyToText == null
                                  ? null
                                  : message.replyToSenderId == currentUserId
                                  ? 'Voce'
                                  : _otherUserName,
                              onReply: canReply ? _setReplyTarget : null,
                            ),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const _ChatShimmer(),
                  error: (error, stack) {
                    _finishFirstMessagesFrameSpan(
                      renderedCount: 0,
                      status: 'messages_error',
                    );
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
        if (isPendingRecipient)
          _PendingRequestCard(
            isAccepting: _isAcceptingConversationRequest,
            onAccept: _isAcceptingConversationRequest
                ? null
                : () => _acceptConversationRequest(
                    myUid: currentUserId,
                    otherUid: otherUid,
                  ),
          ),
        _buildInputField(),
      ],
    );
  }

  Widget _buildDraftConversationState({required String currentUserId}) {
    final pendingMessages = _pendingMessages
        .map(
          (pending) => Message(
            id: pending.localId,
            senderId: currentUserId,
            text: pending.text,
            createdAt: Timestamp.fromDate(pending.createdAt),
            clientMessageId: pending.localId,
            replyToMessageId: pending.replyToMessageId,
            replyToSenderId: pending.replyToSenderId,
            replyToText: pending.replyToText,
            replyToType: pending.replyToType,
          ),
        )
        .toList(growable: false);

    _finishFirstMessagesFrameSpan(
      renderedCount: pendingMessages.length,
      status: pendingMessages.isEmpty ? 'draft_empty' : 'draft_pending',
    );

    if (pendingMessages.isEmpty) {
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
      itemCount: pendingMessages.length,
      itemBuilder: (context, index) {
        final message = pendingMessages[index];
        return _MessageBubble(
          message: message,
          isMe: true,
          isPending: true,
          isRead: false,
          replyAuthorLabel: message.replyToText == null
              ? null
              : message.replyToSenderId == currentUserId
              ? 'Voce'
              : _otherUserName,
        );
      },
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
    final currentUserId =
        ref.watch(currentUserProfileProvider).value?.uid ??
        ref.watch(authStateChangesProvider).value?.uid ??
        ref.read(authRepositoryProvider).currentUser?.uid ??
        '';
    final canInteract =
        _canReadConversation && !_isPendingRecipient(currentUserId);
    final replyTarget = _replyingToMessage;
    final replyAuthorLabel = replyTarget == null
        ? null
        : replyTarget.senderId == currentUserId
        ? 'Voce'
        : _otherUserName;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTarget != null) ...[
            _ReplyComposerPreview(
              authorLabel: replyAuthorLabel ?? 'Mensagem',
              text: replyTarget.text,
              onClose: _clearReplyTarget,
            ),
            const SizedBox(height: AppSpacing.s8),
          ],
          Row(
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
                  hint: !_canReadConversation
                      ? 'Conversa indisponivel'
                      : canInteract
                      ? 'Mensagem...'
                      : 'Aceite para responder',
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textController,
                builder: (context, value, _) {
                  final hasText = value.text.trim().isNotEmpty;

                  return Tooltip(
                    message: 'Enviar mensagem',
                    child: Semantics(
                      button: true,
                      enabled: canInteract && hasText,
                      label: 'Enviar mensagem',
                      child: GestureDetector(
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
                      ),
                    ),
                  );
                },
              ),
            ],
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

class _PendingRequestCard extends StatelessWidget {
  final bool isAccepting;
  final VoidCallback? onAccept;

  const _PendingRequestCard({
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        0,
      ),
      padding: AppSpacing.all16,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitacao de mensagem',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.buttonPrimary.fontWeight,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Leia a conversa normalmente. Para responder, aceite esta solicitacao.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAccept,
              icon: isAccepting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(isAccepting ? 'Aceitando...' : 'Aceitar solicitacao'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyComposerPreview extends StatelessWidget {
  final String authorLabel;
  final String text;
  final VoidCallback onClose;

  const _ReplyComposerPreview({
    required this.authorLabel,
    required this.text,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.surfaceHighlight.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Respondendo a $authorLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          GestureDetector(
            onTap: onClose,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool isPending;
  final bool isRead;
  final String? replyAuthorLabel;
  final ValueChanged<Message>? onReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    this.isPending = false,
    required this.isRead,
    this.replyAuthorLabel,
    this.onReply,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  static const double _replyTriggerDistance = 56;
  static const double _replyIconFadeDistance = 32;
  static const double _directDragDistance = 72;
  static const double _maxVisualDragOffset = 120;
  static const double _overshootResistance = 0.35;
  double _dragOffset = 0;
  double _dragTravel = 0;
  bool _isReplyArmed = false;

  @override
  Widget build(BuildContext context) {
    final canReply = widget.onReply != null;
    final showReplyPreview =
        widget.message.replyToText != null &&
        widget.message.replyToText!.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s4),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        dragStartBehavior: DragStartBehavior.down,
        onHorizontalDragStart: canReply ? _handleHorizontalDragStart : null,
        onHorizontalDragUpdate: canReply ? _handleHorizontalDragUpdate : null,
        onHorizontalDragEnd: canReply ? _handleHorizontalDragEnd : null,
        onHorizontalDragCancel: canReply ? _resetDrag : null,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (canReply)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.s12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Opacity(
                    opacity: (_dragOffset / _replyIconFadeDistance).clamp(
                      0.0,
                      1.0,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            Transform.translate(
              offset: Offset(_dragOffset, 0),
              child: Row(
                mainAxisAlignment: widget.isMe
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
                      color: widget.isMe
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.r24),
                        topRight: const Radius.circular(AppRadius.r24),
                        bottomLeft: widget.isMe
                            ? const Radius.circular(AppRadius.r24)
                            : const Radius.circular(AppRadius.r4),
                        bottomRight: widget.isMe
                            ? const Radius.circular(AppRadius.r4)
                            : const Radius.circular(AppRadius.r24),
                      ),
                      border: !widget.isMe
                          ? Border.all(
                              color: AppColors.surfaceHighlight.withValues(
                                alpha: 0.5,
                              ),
                            )
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (showReplyPreview)
                          _BubbleReplyPreview(
                            authorLabel: widget.replyAuthorLabel ?? 'Mensagem',
                            text: widget.message.replyToText!,
                            isMe: widget.isMe,
                          ),
                        Text(
                          widget.message.text,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(
                                widget.message.createdAt.toDate().toLocal(),
                              ),
                              style: AppTypography.chipLabel.copyWith(
                                color: widget.isMe
                                    ? AppColors.textPrimary.withValues(
                                        alpha: 0.7,
                                      )
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (widget.isMe) ...[
                              const SizedBox(width: AppSpacing.s4),
                              if (widget.isPending)
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: AppColors.textPrimary.withValues(
                                    alpha: 0.7,
                                  ),
                                )
                              else
                                Icon(
                                  widget.isRead ? Icons.done_all : Icons.done,
                                  size: 14,
                                  color: widget.isRead
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimary.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragTravel = 0;
    _isReplyArmed = false;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta ?? 0;
    if (delta == 0) return;

    final nextTravel = (_dragTravel + delta)
        .clamp(0.0, double.infinity)
        .toDouble();

    if (!mounted) return;
    setState(() {
      _dragTravel = nextTravel;
      _dragOffset = _visualDragOffsetFor(nextTravel);
      _isReplyArmed = nextTravel >= _replyTriggerDistance;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (_isReplyArmed) {
      HapticFeedback.selectionClick().ignore();
      widget.onReply?.call(widget.message);
    }
    _resetDrag();
  }

  void _resetDrag() {
    if (!mounted) return;
    setState(() {
      _dragOffset = 0;
      _dragTravel = 0;
      _isReplyArmed = false;
    });
  }

  double _visualDragOffsetFor(double dragTravel) {
    if (dragTravel <= 0) {
      return 0;
    }

    if (dragTravel <= _directDragDistance) {
      return dragTravel;
    }

    final overshootDistance = dragTravel - _directDragDistance;
    final resistedOffset =
        _directDragDistance + (overshootDistance * _overshootResistance);
    return resistedOffset.clamp(0.0, _maxVisualDragOffset).toDouble();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _BubbleReplyPreview extends StatelessWidget {
  final String authorLabel;
  final String text;
  final bool isMe;

  const _BubbleReplyPreview({
    required this.authorLabel,
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final previewColor = isMe
        ? AppColors.textPrimary.withValues(alpha: 0.08)
        : AppColors.background.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.s4 + AppSpacing.s2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4 + AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: previewColor,
        borderRadius: AppRadius.all12,
        border: Border(
          left: BorderSide(
            color: isMe
                ? AppColors.textPrimary.withValues(alpha: 0.45)
                : AppColors.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            authorLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: isMe ? AppColors.textPrimary : AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
