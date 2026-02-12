import 'package:flutter/material.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

/// Professional settings tile with refined visual design
///
/// Features:
/// - Refined icon container with subtle accent colors
/// - Better typography hierarchy
/// - Smooth hover and press states
/// - Professional spacing and alignment
/// - Optional subtitle for additional context
class NeonSettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? customAccentColor;
  final bool isDestructive;

  const NeonSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.customAccentColor,
    this.isDestructive = false,
  });

  @override
  State<NeonSettingsTile> createState() => _NeonSettingsTileState();
}

class _NeonSettingsTileState extends State<NeonSettingsTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Define active color based on destructiveness or custom accent
    final activeColor = widget.isDestructive
        ? AppColors.error
        : (widget.customAccentColor ?? AppColors.primary);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: AppRadius.all16,
          splashColor: activeColor.withValues(alpha: 0.08),
          highlightColor: activeColor.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: AppEffects.fast,
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.s14,
              horizontal: AppSpacing.s14,
            ),
            decoration: BoxDecoration(
              color: _isPressed
                  ? AppColors.surface.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: AppRadius.all16,
              border: Border.all(
                color: _isPressed
                    ? activeColor.withValues(alpha: 0.1)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Refined Icon Container
                _IconContainer(
                  icon: widget.icon,
                  color: activeColor,
                  isPressed: _isPressed,
                ),

                const SizedBox(width: AppSpacing.s16),

                // Text Content with enhanced typography
                Expanded(
                  child: _TextContent(
                    title: widget.title,
                    subtitle: widget.subtitle,
                    isDestructive: widget.isDestructive,
                  ),
                ),

                const SizedBox(width: AppSpacing.s8),

                // Trailing Chevron (subtle)
                if (!widget.isDestructive)
                  _TrailingChevron(isPressed: _isPressed),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon container with refined styling
class _IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isPressed;

  const _IconContainer({
    required this.icon,
    required this.color,
    required this.isPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppEffects.fast,
      curve: Curves.easeOut,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        // Refined background with gradient
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: isPressed ? 0.15 : 0.12),
            color.withValues(alpha: isPressed ? 0.12 : 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isPressed ? 0.25 : 0.15),
          width: 1,
        ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

/// Text content with title and optional subtitle
class _TextContent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isDestructive;

  const _TextContent({
    required this.title,
    required this.isDestructive,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.bodyLarge.copyWith(
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.s4),
          Text(
            subtitle!,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.75),
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Subtle trailing chevron
class _TrailingChevron extends StatelessWidget {
  final bool isPressed;

  const _TrailingChevron({required this.isPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppEffects.fast,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(isPressed ? 2 : 0, 0, 0),
      child: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary.withValues(alpha: 0.4),
        size: 20,
      ),
    );
  }
}
