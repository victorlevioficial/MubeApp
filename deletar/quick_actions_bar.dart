import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Quick actions bar with icon buttons for common tasks.
///
/// Features:
/// - MatchPoint, Saved, Messages, Nearby quick access
/// - Icon-first design with labels
/// - Tap animations
/// - Modern card design
class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: FontAwesomeIcons.fire,
              label: 'MatchPoint',
              color: AppColors.primary,
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/matchpoint');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: _QuickActionButton(
              icon: FontAwesomeIcons.solidHeart,
              label: 'Salvos',
              color: AppColors.info,
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/favorites');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: _QuickActionButton(
              icon: FontAwesomeIcons.solidComment,
              label: 'Mensagens',
              color: AppColors.success,
              onTap: () {
                HapticFeedback.mediumImpact();
                context.push('/chat');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: _QuickActionButton(
              icon: FontAwesomeIcons.locationDot,
              label: 'Próximos',
              color: AppColors.warning,
              onTap: () {
                HapticFeedback.mediumImpact();
                // Navigate to nearby filter in feed
                context.push('/feed');
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual quick action button
class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s8,
            vertical: AppSpacing.s16,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: _isPressed
                  ? widget.color.withValues(alpha: 0.5)
                  : AppColors.surfaceHighlight,
              width: 1,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: AppSpacing.all12,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  widget.icon,
                  size: 20,
                  color: widget.color,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                widget.label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
