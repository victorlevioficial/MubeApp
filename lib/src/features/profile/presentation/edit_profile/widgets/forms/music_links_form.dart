import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../domain/music_link_validator.dart';
import '../../../music_platform_catalog.dart';

class MusicLinksForm extends StatelessWidget {
  final Map<String, TextEditingController> controllers;
  final VoidCallback onChanged;

  const MusicLinksForm({
    super.key,
    required this.controllers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Links Musicais', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Adicione links oficiais para suas plataformas de streaming.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s20),
          ...musicPlatformCatalog.map((platform) {
            final controller = controllers[platform.key]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s16),
              child: _MusicLinkCard(
                platform: platform,
                controller: controller,
                onChanged: onChanged,
              ),
            );
          }),
          const SizedBox(height: AppSpacing.s48 + AppSpacing.s32),
        ],
      ),
    );
  }
}

class _MusicLinkCard extends StatelessWidget {
  final MusicPlatformDefinition platform;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _MusicLinkCard({
    required this.platform,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSpacing.s40 + AppSpacing.s4,
                height: AppSpacing.s40 + AppSpacing.s4,
                padding: const EdgeInsets.all(AppSpacing.s10),
                decoration: BoxDecoration(
                  color: platform.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  platform.assetPath,
                  colorFilter: ColorFilter.mode(
                    platform.color,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(platform.label, style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'Link opcional',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              return AppTextField(
                controller: controller,
                label: 'URL',
                hint: platform.placeholder,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                suffixIcon: value.text.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar',
                        onPressed: () {
                          controller.clear();
                          onChanged();
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      ),
                validator: (rawValue) =>
                    MusicLinkValidator.validate(platform.key, rawValue),
                onChanged: (_) => onChanged(),
              );
            },
          ),
        ],
      ),
    );
  }
}
