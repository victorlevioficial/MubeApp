import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import 'match_card.dart';

class MatchSwipeDeck extends StatelessWidget {
  final List<AppUser> candidates;
  final Function(AppUser user) onSwipeRight;
  final Function(AppUser user) onSwipeLeft;
  final CardSwiperController controller;

  const MatchSwipeDeck({
    super.key,
    required this.candidates,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return const Center(
        child: Text(
          'Não há mais perfis por perto.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // 1. The Swipe Deck
        Positioned.fill(
          bottom: 100, // Leave space for buttons
          child: CardSwiper(
            controller: controller,
            cardsCount: candidates.length,
            numberOfCardsDisplayed: min(
              candidates.length,
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
                      MatchCard(user: candidates[index]),
                      // Swipe Overlay
                      if (opacity > 0.05)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color:
                                  (isLike
                                          ? AppColors.primary
                                          : AppColors.error)
                                      .withValues(alpha: opacity * 0.4),
                            ),
                            child: Center(
                              child: Transform.scale(
                                scale: 1.0 + opacity,
                                child: Icon(
                                  isLike ? Icons.favorite : Icons.close,
                                  color: Colors.white.withValues(
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
              final user = candidates[previousIndex];
              if (direction == CardSwiperDirection.right) {
                onSwipeRight(user);
              } else if (direction == CardSwiperDirection.left) {
                onSwipeLeft(user);
              }
              return true;
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
                onPressed: () => controller.swipe(CardSwiperDirection.left),
              ),

              const SizedBox(width: AppSpacing.s24),

              // UNDO
              _ActionButton(
                icon: Icons.replay,
                color: AppColors.textSecondary,
                backgroundColor: AppColors.surface,
                size: 48,
                onPressed: () => controller.undo(),
              ),

              const SizedBox(width: AppSpacing.s24),

              // LIKE
              _ActionButton(
                icon: Icons.favorite,
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                size: 64,
                onPressed: () => controller.swipe(CardSwiperDirection.right),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Icon(icon, color: color, size: size * 0.5),
        ),
      ),
    );
  }
}
