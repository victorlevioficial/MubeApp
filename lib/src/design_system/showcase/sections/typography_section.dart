import 'package:flutter/material.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TextStyleGroup(
          title: 'Headlines',
          items: [
            _TextStyleItem('Headline Large', AppTypography.headlineLarge),
            _TextStyleItem('Headline Medium', AppTypography.headlineMedium),
            _TextStyleItem('Headline Small', AppTypography.headlineSmall),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _TextStyleGroup(
          title: 'Titles',
          items: [
            _TextStyleItem('Title Large', AppTypography.titleLarge),
            _TextStyleItem('Title Medium', AppTypography.titleMedium),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _TextStyleGroup(
          title: 'Body',
          items: [
            _TextStyleItem('Body Large', AppTypography.bodyLarge),
            _TextStyleItem('Body Medium', AppTypography.bodyMedium),
            _TextStyleItem('Body Small', AppTypography.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.s24),

        _TextStyleGroup(
          title: 'Labels & Semantic',
          items: [
            _TextStyleItem('Label Medium', AppTypography.labelMedium),
            _TextStyleItem('Card Title', AppTypography.cardTitle),
            _TextStyleItem('Chip Label', AppTypography.chipLabel),
          ],
        ),
      ],
    );
  }
}

class _TextStyleGroup extends StatelessWidget {
  final String title;
  final List<_TextStyleItem> items;

  const _TextStyleGroup({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all12,
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const Divider(color: AppColors.surfaceHighlight, height: 1),
            itemBuilder: (context, index) => _TypographyRow(item: items[index]),
          ),
        ),
      ],
    );
  }
}

class _TextStyleItem {
  final String name;
  final TextStyle style;
  _TextStyleItem(this.name, this.style);
}

class _TypographyRow extends StatelessWidget {
  final _TextStyleItem item;

  const _TypographyRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.all16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.name,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${item.style.fontSize?.toInt()}sp / ${item.style.fontWeight}',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'The quick brown fox jumps over the lazy dog.',
            style: item.style.copyWith(color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
