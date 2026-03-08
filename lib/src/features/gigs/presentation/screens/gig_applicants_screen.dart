import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/application_status.dart';
import '../controllers/gig_actions_controller.dart';
import '../providers/gig_streams.dart';

class GigApplicantsScreen extends ConsumerWidget {
  const GigApplicantsScreen({super.key, required this.gigId});

  final String gigId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(gigApplicationsProvider(gigId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Candidaturas'),
      body: applicationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (applications) {
          if (applications.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma candidatura ainda.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          final applicantIds = applications
              .map((application) => application.applicantId)
              .toList(growable: false);
          final usersAsync = ref.watch(gigUsersByIdsProvider(applicantIds));

          return usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Erro: $error')),
            data: (users) {
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemBuilder: (context, index) {
                  final application = applications[index];
                  final user = users[application.applicantId];
                  return Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.all16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            UserAvatar(
                              size: 48,
                              photoUrl: user?.foto,
                              name: user?.appDisplayName ?? 'Usuario',
                            ),
                            const SizedBox(width: AppSpacing.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.appDisplayName ?? 'Usuario',
                                    style: AppTypography.titleSmall.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.s4),
                                  Text(
                                    application.status.label,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: _statusColor(application.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          application.message.isEmpty
                              ? 'Sem mensagem adicional.'
                              : application.message,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        if (application.status == ApplicationStatus.pending)
                          Row(
                            children: [
                              Expanded(
                                child: AppButton.primary(
                                  text: 'Aceitar',
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(
                                            gigActionsControllerProvider.notifier,
                                          )
                                          .acceptApplication(
                                            gigId: gigId,
                                            applicantId: application.applicantId,
                                          );
                                      if (!context.mounted) return;
                                      AppSnackBar.success(
                                        context,
                                        'Candidatura aceita.',
                                      );
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      AppSnackBar.error(
                                        context,
                                        error
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s12),
                              Expanded(
                                child: AppButton.outline(
                                  text: 'Recusar',
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(
                                            gigActionsControllerProvider.notifier,
                                          )
                                          .rejectApplication(
                                            gigId: gigId,
                                            applicantId: application.applicantId,
                                          );
                                      if (!context.mounted) return;
                                      AppSnackBar.success(
                                        context,
                                        'Candidatura recusada.',
                                      );
                                    } catch (error) {
                                      if (!context.mounted) return;
                                      AppSnackBar.error(
                                        context,
                                        error
                                            .toString()
                                            .replaceFirst('Exception: ', ''),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          )
                        else if (application.status ==
                            ApplicationStatus.accepted)
                          AppButton.secondary(
                            text: 'Enviar mensagem',
                            isFullWidth: true,
                            onPressed: () => ref
                                .read(gigActionsControllerProvider.notifier)
                                .openConversation(
                                  context,
                                  otherUserId: application.applicantId,
                                ),
                          ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
                itemCount: applications.length,
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppColors.warning;
      case ApplicationStatus.accepted:
        return AppColors.success;
      case ApplicationStatus.rejected:
        return AppColors.error;
      case ApplicationStatus.gigCancelled:
        return AppColors.textSecondary;
    }
  }
}
