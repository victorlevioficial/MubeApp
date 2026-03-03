import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

enum SelectionMode { single, multi }

enum SelectionCardDensity { regular, compact }

/// Full-width selection card with icon, title, and description.
///
/// Used for category/type selection in onboarding flow.
/// Similar to the design shown in the reference image.
///
/// Example:
/// ```dart
/// FullWidthSelectionCard(
///   icon: FontAwesomeIcons.microphone,
///   title: 'Profissional',
///   description: 'Músico, cantor, DJ, técnico',
///   isSelected: true,
///   onTap: () => setState(() => selected = 'profissional'),
/// )
/// ```
class FullWidthSelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? customIconColor;
  final SelectionMode selectionMode;
  final Widget? trailing;
  final bool isEnabled;
  final SelectionCardDensity density;

  const FullWidthSelectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.isSelected,
    this.onTap,
    this.customIconColor,
    this.selectionMode = SelectionMode.single,
    this.trailing,
    this.isEnabled = true,
    this.density = SelectionCardDensity.regular,
  });

  @override
  Widget build(BuildContext context) {
    final isInteractive = isEnabled && onTap != null;
    final cardPadding = density == SelectionCardDensity.compact
        ? AppSpacing.s16
        : AppSpacing.s20;
    final iconContainerSize = density == SelectionCardDensity.compact
        ? 52.0
        : 64.0;
    final iconSize = density == SelectionCardDensity.compact ? 22.0 : 28.0;
    final contentSpacing = density == SelectionCardDensity.compact
        ? AppSpacing.s12
        : AppSpacing.s16;
    final trailingSpacing = density == SelectionCardDensity.compact
        ? AppSpacing.s8
        : AppSpacing.s12;
    final titleStyle =
        (density == SelectionCardDensity.compact
                ? AppTypography.titleMedium
                : AppTypography.titleLarge)
            .copyWith(
              color: isInteractive || isSelected
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            );
    final descriptionStyle =
        (density == SelectionCardDensity.compact
                ? AppTypography.bodySmall
                : AppTypography.bodyMedium)
            .copyWith(
              color: isInteractive
                  ? AppColors.textSecondary
                  : AppColors.textTertiary,
              height: density == SelectionCardDensity.compact ? 1.35 : 1.4,
            );

    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface2 : AppColors.surface,
          borderRadius: AppRadius.all16,
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isInteractive
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.45),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : !isInteractive
                    ? AppColors.surfaceHighlight.withValues(alpha: 0.6)
                    : AppColors.surfaceHighlight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(
                  icon,
                  size: iconSize,
                  color: isSelected || isInteractive
                      ? (customIconColor ?? AppColors.primary)
                      : AppColors.textTertiary,
                ),
              ),
            ),

            SizedBox(width: contentSpacing),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  if (description != null &&
                      description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s4),
                    Text(description!, style: descriptionStyle),
                  ],
                ],
              ),
            ),

            SizedBox(width: trailingSpacing),
            trailing ??
                _SelectionIndicator(
                  isSelected: isSelected,
                  selectionMode: selectionMode,
                ),
          ],
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  final bool isSelected;
  final SelectionMode selectionMode;

  const _SelectionIndicator({
    required this.isSelected,
    required this.selectionMode,
  });

  @override
  Widget build(BuildContext context) {
    final shape = selectionMode == SelectionMode.multi
        ? const RoundedRectangleBorder(borderRadius: AppRadius.all8)
        : const CircleBorder();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: 24,
      height: 24,
      decoration: ShapeDecoration(
        color: isSelected ? AppColors.primary : AppColors.transparent,
        shape: shape.copyWith(
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1.5,
          ),
        ),
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 16, color: AppColors.textPrimary)
          : null,
    );
  }
}
