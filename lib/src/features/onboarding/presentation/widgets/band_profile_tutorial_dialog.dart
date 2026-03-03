import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

class BandProfileTutorialDialog extends StatelessWidget {
  final int minimumMembers;

  const BandProfileTutorialDialog({super.key, required this.minimumMembers});

  static Future<bool> show({
    required BuildContext context,
    required int minimumMembers,
  }) async {
    final result = await AppOverlay.dialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return BandProfileTutorialDialog(minimumMembers: minimumMembers);
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s16,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.all24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: viewportHeight * 0.82,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
              ),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s24,
                    AppSpacing.s20,
                    AppSpacing.s24,
                    AppSpacing.s20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surface2,
                                      borderRadius: AppRadius.all16,
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.groups_rounded,
                                      color: AppColors.badgeBand,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.s12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Como funciona o perfil de banda',
                                          style: AppTypography.headlineSmall,
                                        ),
                                        const SizedBox(height: AppSpacing.s4),
                                        Text(
                                          'Voce cria agora. Convites e visibilidade vem depois.',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.textSecondary,
                                                height: 1.4,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Fechar',
                                    constraints: const BoxConstraints.tightFor(
                                      width: 36,
                                      height: 36,
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.s16),
                              const _TutorialItem(
                                icon: Icons.edit_note_rounded,
                                title: 'Crie o perfil',
                                description:
                                    'Salve o nome e os dados iniciais da banda.',
                              ),
                              const SizedBox(height: AppSpacing.s10),
                              const _TutorialItem(
                                icon: Icons.group_add_rounded,
                                title: 'Convide integrantes',
                                description:
                                    'Faca isso depois na area de gerenciamento.',
                              ),
                              const SizedBox(height: AppSpacing.s10),
                              _TutorialItem(
                                icon: Icons.visibility_rounded,
                                title: 'Libera no app',
                                description:
                                    'A banda aparece quando $minimumMembers integrantes aceitarem.',
                              ),
                              const SizedBox(height: AppSpacing.s12),
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.s14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface2,
                                  borderRadius: AppRadius.all16,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Icon(
                                        Icons.visibility_off_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s8),
                                    Expanded(
                                      child: Text(
                                        'Ate la, a banda fica em rascunho e nao aparece para outros usuarios.',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: AppColors.textSecondary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      AppButton.primary(
                        text: 'Continuar como banda',
                        size: AppButtonSize.large,
                        isFullWidth: true,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      AppButton.ghost(
                        text: 'Escolher outro tipo',
                        size: AppButtonSize.large,
                        isFullWidth: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TutorialItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
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
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all12,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.badgeBand, size: 18),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
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
