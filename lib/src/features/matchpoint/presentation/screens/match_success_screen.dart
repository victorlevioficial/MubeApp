import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

import '../../../../core/services/image_cache_config.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../chat/data/chat_repository.dart';
import '../widgets/confetti_overlay.dart';

/// Result returned when the user taps "Mandar Mensagem" on the match overlay.
class MatchSuccessNavIntent {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;

  const MatchSuccessNavIntent({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
  });
}

class MatchSuccessScreen extends ConsumerStatefulWidget {
  final AppUser currentUser;
  final AppUser matchUser;
  final String? conversationId;

  const MatchSuccessScreen({
    super.key,
    required this.currentUser,
    required this.matchUser,
    this.conversationId,
  });

  @override
  ConsumerState<MatchSuccessScreen> createState() => _MatchSuccessScreenState();
}

class _MatchSuccessScreenState extends ConsumerState<MatchSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchUserName = widget.matchUser.appDisplayName;

    return Scaffold(
      backgroundColor: AppColors.background.withValues(alpha: 0.95),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Confetti Animation
          const Positioned.fill(child: ConfettiOverlay()),
          // Main Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      Text("IT'S A", style: AppTypography.matchSuccessKicker),
                      Text('MATCH!', style: AppTypography.matchSuccessTitle),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s48),

                // Avatars
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Current User (Left)
                      Positioned(
                        left: 20,
                        child: _buildAvatar(widget.currentUser.foto, -15),
                      ),
                      // Match User (Right)
                      Positioned(
                        right: 20,
                        child: _buildAvatar(widget.matchUser.foto, 15),
                      ),
                      // Icon in center
                      Container(
                        padding: AppSpacing.all8,
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s16),
                Text(
                  'Você e $matchUserName se curtiram!',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.s48),

                // Buttons
                AppButton.primary(
                  text: 'Mandar Mensagem',
                  isFullWidth: true,
                  onPressed: () {
                    final repo = ref.read(chatRepositoryProvider);
                    final conversationId =
                        widget.conversationId ??
                        repo.getConversationId(
                          widget.currentUser.uid,
                          widget.matchUser.uid,
                        );
                    // Pop with a navigation intent so the parent (which has
                    // a valid GoRouter context) handles the push.
                    Navigator.of(context).pop(
                      MatchSuccessNavIntent(
                        conversationId: conversationId,
                        otherUserId: widget.matchUser.uid,
                        otherUserName: matchUserName,
                        otherUserPhoto: widget.matchUser.foto,
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.secondary(
                    text: 'Continuar Deslizando',
                    onPressed: () => Navigator.of(context).pop(),
                    isFullWidth: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? url, double angle) {
    final avatarImage = url != null
        ? DecorationImage(
            image: CachedNetworkImageProvider(
              url,
              cacheManager: ImageCacheConfig.profileCacheManager,
              maxWidth: 512,
              maxHeight: 512,
            ),
            fit: BoxFit.cover,
          )
        : null;
    return Transform.rotate(
      angle: angle * 3.14159 / 180,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textPrimary, width: 4),
          boxShadow: AppEffects.subtleShadow,
          image: avatarImage,
          color: AppColors.surfaceHighlight,
        ),
        child: url == null
            ? const Icon(Icons.person, size: 60, color: AppColors.textPrimary)
            : null,
      ),
    );
  }
}
