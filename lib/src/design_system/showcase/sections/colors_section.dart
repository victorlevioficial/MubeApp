import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class ColorsSection extends StatelessWidget {
  const ColorsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ColorGroup(
          title: 'Primary',
          colors: [
            _ColorItem('Primary', AppColors.primary),
            _ColorItem('Primary Pressed', AppColors.primaryPressed),
            _ColorItem('Primary Muted', AppColors.primaryMuted),
            _ColorItem('Primary Disabled', AppColors.primaryDisabled),
          ],
          gradients: [_GradientItem('Primary Gradient', AppColors.primaryGradient)],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ColorGroup(
          title: 'Backgrounds',
          colors: [
            _ColorItem('Background', AppColors.background),
            _ColorItem('Surface', AppColors.surface),
            _ColorItem('Surface 2', AppColors.surface2),
            _ColorItem('Surface Highlight', AppColors.surfaceHighlight),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ColorGroup(
          title: 'Text',
          colors: [
            _ColorItem('Text Primary', AppColors.textPrimary),
            _ColorItem('Text Secondary', AppColors.textSecondary),
            _ColorItem(
              'Text Tertiary',
              AppColors.textTertiary,
            ), // Includes placeholder
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ColorGroup(
          title: 'Feedback',
          colors: [
            _ColorItem('Success', AppColors.success),
            _ColorItem('Error', AppColors.error),
            _ColorItem('Warning', AppColors.warning),
            _ColorItem('Info', AppColors.info),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ColorGroup(
          title: 'Avatar Palette',
          colors: AppColors.avatarColors.asMap().entries.map((e) {
            return _ColorItem('Avatar ${e.key + 1}', e.value);
          }).toList(),
        ),
      ],
    );
  }
}

class _ColorGroup extends StatelessWidget {
  final String title;
  final List<_ColorItem> colors;
  final List<_GradientItem>? gradients;

  const _ColorGroup({
    required this.title,
    required this.colors,
    this.gradients,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s12,
          runSpacing: AppSpacing.s12,
          children: [
            ...colors.map((c) => _ColorSwatch(item: c)),
            if (gradients != null)
              ...gradients!.map((g) => _GradientSwatch(item: g)),
          ],
        ),
      ],
    );
  }
}

class _ColorItem {
  final String name;
  final Color color;
  _ColorItem(this.name, this.color);
}

class _GradientItem {
  final String name;
  final Gradient gradient;
  _GradientItem(this.name, this.gradient);
}

class _ColorSwatch extends StatelessWidget {
  final _ColorItem item;

  const _ColorSwatch({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all8,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.r8),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.all8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.buttonPrimary.fontWeight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  _colorToHex(item.color),
                  style: AppTypography.labelSmall.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).toUpperCase().substring(2)}';
  }
}

class _GradientSwatch extends StatelessWidget {
  final _GradientItem item;

  const _GradientSwatch({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all8,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: item.gradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.r8),
              ),
            ),
          ),
          Padding(
            padding: AppSpacing.all8,
            child: Text(
              item.name,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.buttonPrimary.fontWeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
