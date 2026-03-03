import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';
import '../buttons/app_button.dart';
import 'app_overlay.dart';

class AppInfoDialogHighlight {
  final IconData icon;
  final String title;
  final String description;

  const AppInfoDialogHighlight({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class AppInfoDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmText;
  final Color accentColor;
  final String? subtitle;
  final String? note;
  final List<AppInfoDialogHighlight> highlights;

  const AppInfoDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.confirmText = 'Entendi',
    this.accentColor = AppColors.info,
    this.subtitle,
    this.note,
    this.highlights = const [],
  });

  static Future<void> show({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
    String confirmText = 'Entendi',
    Color accentColor = AppColors.info,
    String? subtitle,
    String? note,
    List<AppInfoDialogHighlight> highlights = const [],
  }) {
    return AppOverlay.dialog<void>(
      context: context,
      builder: (context) => AppInfoDialog(
        icon: icon,
        title: title,
        message: message,
        confirmText: confirmText,
        accentColor: accentColor,
        subtitle: subtitle,
        note: note,
        highlights: highlights,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all24,
        side: BorderSide(color: accentColor.withValues(alpha: 0.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DialogHeader(
                icon: icon,
                title: title,
                subtitle: subtitle,
                accentColor: accentColor,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s24,
                  AppSpacing.s20,
                  AppSpacing.s24,
                  AppSpacing.s24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s20),
                      ...highlights.asMap().entries.map((entry) {
                        final index = entry.key;
                        final highlight = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == highlights.length - 1
                                ? 0
                                : AppSpacing.s12,
                          ),
                          child: _DialogHighlightCard(
                            index: index + 1,
                            accentColor: accentColor,
                            highlight: highlight,
                          ),
                        );
                      }),
                    ],
                    if (note != null && note!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s20),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: AppRadius.all16,
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.visibility_off_outlined,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(width: AppSpacing.s10),
                            Expanded(
                              child: Text(
                                note!,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(54),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.pill,
                          ),
                          textStyle: AppTypography.buttonPrimary.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(confirmText),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    AppButton.ghost(
                      text: 'Voltar e escolher outro tipo',
                      isFullWidth: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accentColor;

  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s24,
        AppSpacing.s24,
        AppSpacing.s24,
        AppSpacing.s20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.20),
            accentColor.withValues(alpha: 0.08),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: AppRadius.all20,
              border: Border.all(color: accentColor.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(height: AppSpacing.s20),
          Text(
            title,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              subtitle!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DialogHighlightCard extends StatelessWidget {
  final int index;
  final Color accentColor;
  final AppInfoDialogHighlight highlight;

  const _DialogHighlightCard({
    required this.index,
    required this.accentColor,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: AppRadius.all12,
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: AppTypography.titleSmall.copyWith(color: accentColor),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all12,
            ),
            child: Icon(highlight.icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  highlight.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
