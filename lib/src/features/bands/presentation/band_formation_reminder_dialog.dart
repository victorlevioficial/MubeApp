import 'package:flutter/material.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../domain/band_activation_rules.dart';

class BandFormationReminderDialog extends StatelessWidget {
  final String bandName;
  final int acceptedMembers;

  const BandFormationReminderDialog({
    super.key,
    required this.bandName,
    required this.acceptedMembers,
  });

  static Future<bool> show({
    required BuildContext context,
    required String bandName,
    required int acceptedMembers,
  }) async {
    final result = await AppOverlay.dialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => BandFormationReminderDialog(
        bandName: bandName,
        acceptedMembers: acceptedMembers,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final missingMembers = missingBandMembersForActivation(acceptedMembers);
    final progressLabel =
        '$acceptedMembers de $minimumBandMembersForActivation integrantes confirmados';
    final message = missingMembers == 1
        ? 'Falta só mais 1 integrante aceitar o convite para liberar a visibilidade da banda no app.'
        : 'Faltam $missingMembers integrantes aceitarem o convite para liberar a visibilidade da banda no app.';

    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s20,
        vertical: AppSpacing.s16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.all24,
        side: BorderSide(color: AppColors.badgeBand.withValues(alpha: 0.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s24,
            AppSpacing.s20,
            AppSpacing.s24,
            AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.badgeBand.withValues(alpha: 0.14),
                      borderRadius: AppRadius.all16,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.badgeBand,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sua banda ainda está em formação',
                          style: AppTypography.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          bandName,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
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
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s20),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: AppRadius.all20,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.badgeBand.withValues(alpha: 0.12),
                        borderRadius: AppRadius.all16,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.verified_user_outlined,
                        color: AppColors.badgeBand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            progressLabel,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.badgeBand,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            message,
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
                        Icons.visibility_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: Text(
                        'Você pode fechar e continuar navegando agora. Quando quiser, entre em Gerenciar integrantes para enviar convites.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              AppButton.primary(
                text: 'Gerenciar integrantes',
                size: AppButtonSize.large,
                isFullWidth: true,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: AppSpacing.s8),
              AppButton.ghost(
                text: 'Agora não',
                size: AppButtonSize.large,
                isFullWidth: true,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
