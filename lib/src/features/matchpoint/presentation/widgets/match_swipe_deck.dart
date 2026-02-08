import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import 'match_card.dart';

class MatchSwipeDeck extends StatefulWidget {
  final List<AppUser> candidates;
  final Future<void> Function(AppUser user) onSwipeRight;
  final Future<void> Function(AppUser user) onSwipeLeft;
  final CardSwiperController controller;
  final VoidCallback? onEnd;
  final List<String>? currentUserGenres;

  const MatchSwipeDeck({
    super.key,
    required this.candidates,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.controller,
    this.onEnd,
    this.currentUserGenres,
  });

  @override
  State<MatchSwipeDeck> createState() => _MatchSwipeDeckState();
}

class _MatchSwipeDeckState extends State<MatchSwipeDeck> {
  // Rastreia interações já enviadas para evitar duplicação no undo
  final Set<String> _processedInteractions = {};

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return Center(
        child: Text(
          'Não há mais perfis por perto.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      );
    }

    return Stack(
      children: [
        // 1. The Swipe Deck
        Positioned.fill(
          bottom: 100, // Leave space for buttons
          child: CardSwiper(
            controller: widget.controller,
            cardsCount: widget.candidates.length,
            isLoop:
                false, // IMPORTANTE: Não fazer loop - cada perfil aparece só uma vez
            numberOfCardsDisplayed: min(
              widget.candidates.length,
              2,
            ), // Optimize performance
            backCardOffset: const Offset(0, 40),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s16,
            ),
            cardBuilder:
                (context, index, percentThresholdX, percentThresholdY) {
                  final opacity = (percentThresholdX / 100).abs().clamp(
                    0.0,
                    1.0,
                  );
                  final isLike = percentThresholdX > 0;

                  return Stack(
                    children: [
                      MatchCard(
                        user: widget.candidates[index],
                        currentUserGenres: widget.currentUserGenres,
                      ),
                      // Swipe Overlay
                      if (opacity > 0.05)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.all16,
                              color:
                                  (isLike ? AppColors.primary : AppColors.error)
                                      .withValues(alpha: opacity * 0.4),
                            ),
                            child: Center(
                              child: Transform.scale(
                                scale: 1.0 + opacity,
                                child: Icon(
                                  isLike ? Icons.favorite : Icons.close,
                                  color: AppColors.textPrimary.withValues(
                                    alpha: opacity,
                                  ),
                                  size: 100,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
            onSwipe: (previousIndex, currentIndex, direction) {
              final user = widget.candidates[previousIndex];
              final interactionKey = '${user.uid}_${direction.name}';

              // Evita duplicação: só envia se ainda não foi processado
              if (!_processedInteractions.contains(interactionKey)) {
                _processedInteractions.add(interactionKey);

                if (direction == CardSwiperDirection.right) {
                  unawaited(widget.onSwipeRight(user));
                } else if (direction == CardSwiperDirection.left) {
                  unawaited(widget.onSwipeLeft(user));
                }
              } else {
                debugPrint(
                  '⚠️ Interação já processada: $interactionKey (ignorando duplicata)',
                );
              }
              return true;
            },
            onUndo: (previousIndex, currentIndex, direction) {
              // previousIndex pode ser null em alguns casos
              if (previousIndex == null) return false;

              // Ao desfazer, removemos a interação do set para permitir nova decisão
              final user = widget.candidates[previousIndex];
              final interactionKey = '${user.uid}_${direction.name}';
              _processedInteractions.remove(interactionKey);
              debugPrint('🔄 Undo: removido $interactionKey do histórico');
              return true;
            },
            onEnd: () {
              debugPrint('🎯 MatchPoint: Todos os candidatos foram vistos');
              widget.onEnd?.call();
            },
            allowedSwipeDirection: const AllowedSwipeDirection.only(
              right: true,
              left: true,
            ),
          ),
        ),

        // 2. Floating Action Buttons (Bottom)
        Positioned(
          bottom: AppSpacing.s32,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // DISLIKE
              _ActionButton(
                icon: Icons.close,
                color: AppColors.textSecondary, // Grey
                backgroundColor: AppColors.surfaceHighlight,
                size: 64,
                onPressed: () =>
                    widget.controller.swipe(CardSwiperDirection.left),
              ),

              const SizedBox(width: AppSpacing.s24),

              // UNDO
              _ActionButton(
                icon: Icons.replay,
                color: AppColors.textSecondary,
                backgroundColor: AppColors.surface,
                size: 48,
                onPressed: () => widget.controller.undo(),
              ),

              const SizedBox(width: AppSpacing.s24),

              // LIKE
              _ActionButton(
                icon: Icons.favorite,
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                size: 64,
                onPressed: () =>
                    widget.controller.swipe(CardSwiperDirection.right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.backgroundColor = AppColors.surface,
    required this.onPressed,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: AppEffects.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      ),
    );
  }
}
