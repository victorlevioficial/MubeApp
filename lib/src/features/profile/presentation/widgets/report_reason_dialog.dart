import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/app_text_field.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';

class ReportReasonDialog extends StatefulWidget {
  const ReportReasonDialog({super.key});

  @override
  State<ReportReasonDialog> createState() => _ReportReasonDialogState();
}

class _ReportReasonDialogState extends State<ReportReasonDialog> {
  final _descriptionController = TextEditingController();
  String? _selectedReason;

  final _reasons = [
    'Spam',
    'Perfil Falso',
    'Conteúdo Ofensivo',
    'Golpe / Fraude',
    'Outro',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If 'Outro' is selected, validation requires description
    final bool isOther = _selectedReason == 'Outro';
    final bool isValid =
        _selectedReason != null &&
        (!isOther || _descriptionController.text.trim().isNotEmpty);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.s16),
          border: Border.all(color: AppColors.surfaceHighlight),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Denunciar Usuário',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              Text(
                'Selecione o motivo:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              ..._reasons.map(
                (reason) => RadioListTile<String>(
                  title: Text(
                    reason,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  value: reason,
                  groupValue: _selectedReason,
                  activeColor: AppColors.error,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                    });
                  },
                ),
              ),
              if (isOther) ...[
                const SizedBox(height: AppSpacing.s16),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Detalhes (obrigatório)',
                  hint: 'Descreva o problema...',
                  maxLines: 3,
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: AppSpacing.s32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Cancelar',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  TextButton(
                    onPressed: isValid
                        ? () {
                            final reason = _selectedReason!;
                            final description = _descriptionController.text
                                .trim();

                            // Return Map with data
                            context.pop({
                              'reason': reason,
                              'description': description.isNotEmpty
                                  ? description
                                  : null,
                            });
                          }
                        : null, // Disabled until valid
                    child: Text(
                      'Denunciar',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isValid
                            ? AppColors.error
                            : AppColors.textTertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
