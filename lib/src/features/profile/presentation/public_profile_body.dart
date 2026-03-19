part of 'public_profile_screen.dart';

class _ProfileBody extends StatelessWidget {
  static const double _topInset =
      AppSpacing.s48 + AppSpacing.s24 + AppSpacing.s20;

  final AppUser user;
  final List<MediaItem> galleryItems;
  final List<AppUser> bandMembers;
  final double? averageRating;
  final int reviewCount;
  final bool isMetricsLoading;
  final List<GigReview> reviews;
  final Map<String, AppUser> reviewAuthors;
  final bool isReviewsLoading;
  final List<Gig> openGigs;
  final bool isOpenGigsLoading;
  final String avatarHeroTag;
  final VoidCallback onAvatarTap;
  final void Function(int index, List<MediaItem> items) onMediaTap;

  const _ProfileBody({
    required this.user,
    required this.galleryItems,
    required this.bandMembers,
    required this.averageRating,
    required this.reviewCount,
    required this.isMetricsLoading,
    required this.reviews,
    required this.reviewAuthors,
    required this.isReviewsLoading,
    required this.openGigs,
    required this.isOpenGigsLoading,
    required this.avatarHeroTag,
    required this.onAvatarTap,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return isWide ? _wideLayout(context) : _narrowLayout(context);
  }

  Widget _narrowLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: _topInset),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
            child: ProfileHeroHeader(
              user: user,
              avatarHeroTag: avatarHeroTag,
              onAvatarTap: onAvatarTap,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _buildBody(context, padding: AppSpacing.s20),
          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s32,
        _topInset,
        AppSpacing.s32,
        AppSpacing.s48,
      ),
      child: ResponsiveCenter(
        padding: EdgeInsets.zero,
        maxContentWidth: 1200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: header + bio
            SizedBox(
              width: 340,
              child: ProfileHeroHeader(
                user: user,
                avatarHeroTag: avatarHeroTag,
                onAvatarTap: onAvatarTap,
              ),
            ),
            const SizedBox(width: AppSpacing.s32),
            // Right column: gallery + details + social proof
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildBody(context, padding: 0)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, {required double padding}) {
    final bio = user.profileBio;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user.tipoPerfil != AppUserType.contractor) ...[
            _buildGallery(),
            const SizedBox(height: AppSpacing.s16),
          ],
          if (bio != null) ...[
            _BioCard(bio: bio),
            const SizedBox(height: AppSpacing.s16),
          ],
          _buildProfileSections(),
        ],
      ),
    );
  }

  Widget _buildProfileSections() {
    final accentColor = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);
    final showOpenGigsSection = isOpenGigsLoading || openGigs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TypeDetails(user: user, bandMembers: bandMembers),
        if (showOpenGigsSection) ...[
          const SizedBox(height: AppSpacing.s16),
          _OpenGigsSection(
            accentColor: accentColor,
            gigs: openGigs,
            isLoading: isOpenGigsLoading,
          ),
        ],
        const SizedBox(height: AppSpacing.s16),
        _ReputationSection(
          accentColor: accentColor,
          averageRating: averageRating,
          reviewCount: reviewCount,
          isLoading: isMetricsLoading || isReviewsLoading,
          reviews: reviews,
          reviewAuthors: reviewAuthors,
        ),
      ],
    );
  }

  Widget _buildGallery() {
    return ProfileGalleryTabs(
      items: galleryItems,
      accentColor: ProfileHeroHeader.profileTypeColor(user.tipoPerfil),
      onItemTap: onMediaTap,
    );
  }
}

class _ReputationSection extends StatelessWidget {
  const _ReputationSection({
    required this.accentColor,
    required this.averageRating,
    required this.reviewCount,
    required this.isLoading,
    required this.reviews,
    required this.reviewAuthors,
  });

  final Color accentColor;
  final double? averageRating;
  final int reviewCount;
  final bool isLoading;
  final List<GigReview> reviews;
  final Map<String, AppUser> reviewAuthors;

  @override
  Widget build(BuildContext context) {
    final commentedReviews = reviews
        .where((review) => (review.comment ?? '').trim().isNotEmpty)
        .take(3)
        .toList(growable: false);

    return _InfoCard(
      icon: Icons.star_rounded,
      title: 'Avaliações',
      accentColor: accentColor,
      count: reviewCount > 0 ? reviewCount : null,
      trailing: reviews.isNotEmpty
          ? TextButton(
              onPressed: () => _showAllReviews(context),
              child: const Text('Ver todas'),
            )
          : null,
      child: isLoading
          ? Text(
              'Carregando avaliações...',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : reviewCount <= 0 || averageRating == null
          ? Text(
              'Ainda sem avaliações públicas.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      averageRating!.toStringAsFixed(1),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarRatingWidget(
                            rating: averageRating!.round().clamp(0, 5),
                            size: 18,
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            reviewCount == 1
                                ? '1 avaliação recebida'
                                : '$reviewCount avaliações recebidas',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                if (commentedReviews.isEmpty)
                  Text(
                    'As avaliações ainda não têm comentários escritos.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  Column(
                    children: [
                      for (var i = 0; i < commentedReviews.length; i++) ...[
                        _ReviewCommentTile(
                          review: commentedReviews[i],
                          reviewer:
                              reviewAuthors[commentedReviews[i].reviewerId],
                        ),
                        if (i != commentedReviews.length - 1)
                          const SizedBox(height: AppSpacing.s12),
                      ],
                    ],
                  ),
              ],
            ),
    );
  }

  Future<void> _showAllReviews(BuildContext context) {
    return AppOverlay.bottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.top24),
      builder: (context) =>
          _AllReviewsSheet(reviews: reviews, reviewAuthors: reviewAuthors),
    );
  }
}

class _ReviewCommentTile extends StatelessWidget {
  const _ReviewCommentTile({
    required this.review,
    required this.reviewer,
    this.showEmptyComment = false,
  });

  final GigReview review;
  final AppUser? reviewer;
  final bool showEmptyComment;

  @override
  Widget build(BuildContext context) {
    final reviewerName = reviewer?.appDisplayName ?? 'Usuário Mube';
    final createdAt = review.createdAt;
    final comment = (review.comment ?? '').trim();
    final displayComment = comment.isEmpty && showEmptyComment
        ? 'Sem comentário escrito.'
        : comment;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewerName,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        _formatShortDate(createdAt),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              StarRatingWidget(rating: review.rating.clamp(0, 5), size: 14),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          Text(
            displayComment,
            style: AppTypography.bodySmall.copyWith(
              color: comment.isEmpty
                  ? AppColors.textTertiary
                  : AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenGigsSection extends StatelessWidget {
  const _OpenGigsSection({
    required this.accentColor,
    required this.gigs,
    required this.isLoading,
  });

  final Color accentColor;
  final List<Gig> gigs;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      icon: Icons.work_outline_rounded,
      title: 'Gigs em andamento',
      accentColor: accentColor,
      count: gigs.isNotEmpty ? gigs.length : null,
      child: isLoading
          ? Text(
              'Carregando gigs ativas...',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < gigs.length; i++) ...[
                  _OpenGigTile(gig: gigs[i], accentColor: accentColor),
                  if (i != gigs.length - 1)
                    const SizedBox(height: AppSpacing.s10),
                ],
              ],
            ),
    );
  }
}

class _OpenGigTile extends StatelessWidget {
  const _OpenGigTile({required this.gig, required this.accentColor});

  final Gig gig;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      _formatGigDate(gig),
      gig.displayCompensation,
      gig.availableSlots == 1
          ? '1 vaga restante'
          : '${gig.availableSlots} vagas restantes',
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all12,
        onTap: () => context.go(RoutePaths.gigDetailById(gig.id)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppRadius.all12,
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.s4),
                width: AppSpacing.s10,
                height: AppSpacing.s10,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gig.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      details.join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllReviewsSheet extends StatelessWidget {
  const _AllReviewsSheet({required this.reviews, required this.reviewAuthors});

  final List<GigReview> reviews;
  final Map<String, AppUser> reviewAuthors;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s20,
          right: AppSpacing.s20,
          top: AppSpacing.s12,
          bottom: MediaQuery.of(context).viewPadding.bottom + AppSpacing.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: AppRadius.pill,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text('Todas as avaliações', style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.s16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: reviews.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.s12),
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _ReviewCommentTile(
                    review: review,
                    reviewer: reviewAuthors[review.reviewerId],
                    showEmptyComment: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatShortDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatGigDate(Gig gig) {
  final date = gig.gigDate;
  if (date == null) {
    return 'Data a combinar';
  }
  return _formatShortDate(date);
}

class _PublicProfileSkeleton extends StatelessWidget {
  const _PublicProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: _ProfileBody._topInset),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SkeletonBox(
                    width: double.infinity,
                    height: 180,
                    borderRadius: 24,
                  ),
                  SizedBox(height: AppSpacing.s16),
                  SkeletonBox(
                    width: double.infinity,
                    height: 220,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s16),
                  SkeletonBox(
                    width: double.infinity,
                    height: 132,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s16),
                  SkeletonBox(
                    width: double.infinity,
                    height: 180,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;

  const _ErrorBody({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.all24,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
