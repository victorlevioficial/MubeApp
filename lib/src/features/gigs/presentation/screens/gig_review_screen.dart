import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/gig_draft.dart';
import '../controllers/gig_review_controller.dart';
import '../gig_error_message.dart';
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
        loading: () => const _GigReviewLoadingState(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: EmptyStateWidget(
              icon: Icons.rate_review_outlined,
              title: 'Nao foi possivel carregar a avaliacao',
              subtitle: resolveGigErrorMessage(error),
            ),
          ),
        ),
        data: (users) {
          final user = users[widget.userId];
          final displayName =
              widget.userName ?? user?.appDisplayName ?? 'Usuário';
          final photo = widget.userPhoto ?? user?.foto;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s24,
            ),
            children: [
              _UserHeroSection(
                displayName: displayName,
                photo: photo,
                gigTitle: widget.gigTitle,
              ),
              const SizedBox(height: AppSpacing.s24),
              _RatingSection(
                rating: _rating,
                onRatingChanged: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: AppSpacing.s24),
              // Comment card
              Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.all16,
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: AppRadius.all8,
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: AppColors.info,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s10),
                        Text(
                          'Comentário (opcional)',
                          style: AppTypography.titleSmall.copyWith(
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    AppTextField(
                      controller: _commentController,
                      hint: 'Conte como foi trabalhar com essa pessoa.',
                      maxLines: 5,
                      minLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s32),
              AppButton.primary(
                text: 'Enviar avaliação',
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
      AppSnackBar.success(context, 'Avaliação enviada com sucesso.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, resolveGigErrorMessage(error));
    }
  }
}

class _GigReviewLoadingState extends StatelessWidget {
  const _GigReviewLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          child: const SkeletonShimmer(
            child: Column(
              children: [
                SkeletonCircle(size: 78),
                SizedBox(height: AppSpacing.s16),
                SkeletonText(width: 180, height: 18),
                SizedBox(height: AppSpacing.s8),
                SkeletonText(width: 220, height: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
          ),
          child: const SkeletonShimmer(
            child: Column(
              children: [
                SkeletonText(width: 220, height: 16),
                SizedBox(height: AppSpacing.s20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonCircle(size: 36),
                    SizedBox(width: AppSpacing.s8),
                    SkeletonCircle(size: 36),
                    SizedBox(width: AppSpacing.s8),
                    SkeletonCircle(size: 36),
                    SizedBox(width: AppSpacing.s8),
                    SkeletonCircle(size: 36),
                    SizedBox(width: AppSpacing.s8),
                    SkeletonCircle(size: 36),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        const SkeletonShimmer(
          child: SkeletonBox(height: 132, borderRadius: AppRadius.r16),
        ),
        const SizedBox(height: AppSpacing.s32),
        const SkeletonShimmer(
          child: SkeletonBox(height: 48, borderRadius: AppRadius.r24),
        ),
      ],
    );
  }
}

class _UserHeroSection extends StatelessWidget {
  const _UserHeroSection({
    required this.displayName,
    required this.photo,
    this.gigTitle,
  });

  final String displayName;
  final String? photo;
  final String? gigTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Avatar with primary ring
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
                width: 2,
              ),
            ),
            child: UserAvatar(
              size: 72,
              photoUrl: photo,
              name: displayName,
              showBorder: false,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: AppTypography.titleLarge,
          ),
          if ((gigTitle ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              gigTitle!,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.rating, required this.onRatingChanged});

  final int rating;
  final ValueChanged<int> onRatingChanged;

  static const _labels = ['', 'Péssimo', 'Ruim', 'Regular', 'Bom', 'Excelente'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: rating > 0
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Qual nota você dá para esta experiência?',
            textAlign: TextAlign.center,
            style: AppTypography.titleSmall.copyWith(letterSpacing: -0.1),
          ),
          const SizedBox(height: AppSpacing.s20),
          StarRatingWidget(
            rating: rating,
            onRatingChanged: onRatingChanged,
            size: 40,
          ),
          if (rating > 0) ...[
            const SizedBox(height: AppSpacing.s12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _labels[rating],
                key: ValueKey(rating),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
