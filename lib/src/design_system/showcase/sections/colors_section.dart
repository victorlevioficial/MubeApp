import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
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
          title: 'Brand Identity',
          colors: [
            _ColorItem('Brand Primary', AppColors.brandPrimary),
            _ColorItem('Brand Glow', AppColors.brandGlow),
          ],
          gradients: [_GradientItem('Brand Gradient', AppColors.brandGradient)],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ColorGroup(
          title: 'Backgrounds',
          colors: [
            _ColorItem('Background', AppColors.background),
            _ColorItem('Surface', AppColors.surface),
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
            _ColorItem('Text Action', AppColors.textAction),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _ColorGroup(
          title: 'Feedback & Action',
          colors: [
            _ColorItem('Semantic Action', AppColors.semanticAction),
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
        borderRadius: BorderRadius.circular(8),
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
                top: Radius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _colorToHex(item.color),
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 10,
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
        borderRadius: BorderRadius.circular(8),
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
                top: Radius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              item.name,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
