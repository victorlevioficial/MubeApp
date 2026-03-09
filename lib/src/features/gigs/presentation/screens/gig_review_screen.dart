import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../domain/gig_draft.dart';
import '../controllers/gig_review_controller.dart';
import '../providers/gig_streams.dart';
import '../widgets/star_rating_widget.dart';

class GigReviewScreen extends ConsumerStatefulWidget {
  const GigReviewScreen({
    super.key,
    required this.gigId,
    required this.userId,
    this.userName,
    this.userPhoto,
    this.gigTitle,
  });

  final String gigId;
  final String userId;
  final String? userName;
  final String? userPhoto;
  final String? gigTitle;

  @override
  ConsumerState<GigReviewScreen> createState() => _GigReviewScreenState();
}

class _GigReviewScreenState extends ConsumerState<GigReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(gigReviewControllerProvider);
    final userAsync = ref.watch(
      gigUsersByStableIdsProvider(encodeGigUserIdsKey([widget.userId])),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Avaliar participante'),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (users) {
          final user = users[widget.userId];
          final displayName =
              widget.userName ?? user?.appDisplayName ?? 'Usuario';
          final photo = widget.userPhoto ?? user?.foto;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              UserAvatar(size: 80, photoUrl: photo, name: displayName),
              const SizedBox(height: AppSpacing.s16),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
              ),
              if ((widget.gigTitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  widget.gigTitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s32),
              Text(
                'Qual nota voce da para esta experiencia?',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.s12),
              Center(
                child: StarRatingWidget(
                  rating: _rating,
                  onRatingChanged: (value) => setState(() => _rating = value),
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.s24),
              AppTextField(
                controller: _commentController,
                label: 'Comentario (opcional)',
                hint: 'Conte como foi trabalhar com essa pessoa.',
                maxLines: 5,
                minLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.s24),
              AppButton.primary(
                text: 'Enviar avaliacao',
                isFullWidth: true,
                isLoading: reviewState.isLoading,
                onPressed: _rating <= 0 ? null : _submit,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(gigReviewControllerProvider.notifier)
          .submitReview(
            GigReviewDraft(
              gigId: widget.gigId,
              reviewedUserId: widget.userId,
              rating: _rating,
              comment: _commentController.text.trim(),
            ),
          );
      if (!mounted) return;
      AppSnackBar.success(context, 'Avaliacao enviada com sucesso.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}
