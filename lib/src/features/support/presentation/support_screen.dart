import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../data/faq_data.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Ajuda e Suporte'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Actions Grid
            Row(
              children: [
                Expanded(
                  child: _SupportActionCard(
                    icon: Icons.add_circle_outline,
                    title: 'Novo Ticket',
                    color: AppColors.primary,
                    onTap: () => context.push(
                      '${RoutePaths.support}/${RoutePaths.supportCreate}',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: _SupportActionCard(
                    icon: Icons.history,
                    title: 'Meus Tickets',
                    color: AppColors.info,
                    onTap: () => context.push(
                      '${RoutePaths.support}/${RoutePaths.supportTickets}',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.s32),

            // 2. FAQ Header
            Text('Perguntas Frequentes', style: AppTypography.headlineSmall),
            const SizedBox(height: AppSpacing.s16),

            // 3. FAQ List
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.all16,
                border: Border.all(color: AppColors.surfaceHighlight),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: kAppFAQs.map((faq) {
                  final isLast = faq == kAppFAQs.last;
                  return Column(
                    children: [
                      ExpansionTile(
                        tilePadding: AppSpacing.h16v8,
                        title: Text(
                          faq.question,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: AppTypography.titleSmall.fontWeight,
                          ),
                        ),
                        backgroundColor: AppColors.surface,
                        collapsedBackgroundColor: AppColors.surface,
                        textColor: AppColors.textPrimary,
                        iconColor: AppColors.primary,
                        collapsedIconColor: AppColors.textSecondary,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.s16,
                              0,
                              AppSpacing.s16,
                              AppSpacing.s16,
                            ),
                            child: Text(
                              faq.answer,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: AppTypography.bodyLarge.height,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          color: AppColors.surfaceHighlight,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.s32),

            // 4. Contact Info
            Center(
              child: Text(
                'Ainda precisa de ajuda?\nEnvie um email para suporte@mube.app',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SupportActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
        boxShadow: AppEffects.subtleShadow,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all16,
          child: Padding(
            padding: AppSpacing.all16,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: AppSpacing.all8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: AppTypography.titleSmall.fontWeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
