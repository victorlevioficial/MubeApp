part of 'public_profile_screen.dart';

class _ProfileBody extends StatelessWidget {
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
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeroHeader(
            user: user,
            avatarHeroTag: avatarHeroTag,
            onAvatarTap: onAvatarTap,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s4,
              AppSpacing.s20,
              AppSpacing.s24,
            ),
            child: _buildContentSections(context),
          ),
          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileHeroHeader(
            user: user,
            avatarHeroTag: avatarHeroTag,
            onAvatarTap: onAvatarTap,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s32,
              AppSpacing.s24,
              AppSpacing.s32,
              AppSpacing.s32,
            ),
            child: ResponsiveCenter(
              padding: EdgeInsets.zero,
              maxContentWidth: 1100,
              child: _buildContentSections(context),
            ),
          ),
          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }

  Widget _buildContentSections(BuildContext context) {
    final bio = user.profileBio;
    final hasGallery = galleryItems.isNotEmpty;
    final showOpenGigsSection = isOpenGigsLoading || openGigs.isNotEmpty;
    final accentColor = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (bio != null) ...[
          const SizedBox(height: AppSpacing.s8),
          _ExpandableBio(text: bio),
          const SizedBox(height: AppSpacing.s20),
        ] else
          const SizedBox(height: AppSpacing.s8),
        _TypeDetails(user: user, bandMembers: bandMembers),
        if (showOpenGigsSection) ...[
          const SizedBox(height: AppSpacing.s24),
          _OpenGigsSection(
            accentColor: accentColor,
            gigs: openGigs,
            isLoading: isOpenGigsLoading,
          ),
        ],
        if (hasGallery) ...[
          const SizedBox(height: AppSpacing.s24),
          _GallerySectionHeader(count: galleryItems.length, user: user),
          const SizedBox(height: AppSpacing.s12),
          PublicGalleryGrid(
            items: galleryItems,
            onItemTap: (index) => onMediaTap(index, galleryItems),
          ),
        ],
        const SizedBox(height: AppSpacing.s24),
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
}

class _ExpandableBio extends StatefulWidget {
  final String text;

  const _ExpandableBio({required this.text});

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  static const int _collapsedMaxLines = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.bodyMedium.copyWith(
      color: AppColors.textSecondary,
      height: 1.55,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final span = TextSpan(text: widget.text, style: textStyle);
          final tp = TextPainter(
            text: span,
            textDirection: TextDirection.ltr,
            maxLines: _collapsedMaxLines,
          )..layout(maxWidth: constraints.maxWidth);

          final didOverflow = tp.didExceedMaxLines;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BlockHeader(
                icon: Icons.auto_stories_rounded,
                title: 'SOBRE',
              ),
              const SizedBox(height: AppSpacing.s10),
              AnimatedSize(
                duration: AppMotion.medium,
                curve: AppMotion.standardCurve,
                alignment: Alignment.topLeft,
                child: Text(
                  widget.text,
                  style: textStyle,
                  maxLines: _expanded ? null : _collapsedMaxLines,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
              ),
              if (didOverflow) ...[
                const SizedBox(height: AppSpacing.s8),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s4,
                    ),
                    child: Text(
                      _expanded ? 'Mostrar menos' : 'Mostrar mais',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final int? count;
  final Widget? trailing;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.accentColor,
    this.count,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (count != null && count! > 0)
          Container(
            margin: const EdgeInsets.only(left: AppSpacing.s8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.pill,
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$count',
              style: AppTypography.labelSmall.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.s8),
          trailing!,
        ],
      ],
    );
  }
}

class _GallerySectionHeader extends StatelessWidget {
  final int count;
  final AppUser user;

  const _GallerySectionHeader({required this.count, required this.user});

  @override
  Widget build(BuildContext context) {
    final accentColor = ProfileHeroHeader.profileTypeColor(user.tipoPerfil);
    return _SectionHeader(
      icon: Icons.collections_outlined,
      title: 'Mídia',
      accentColor: accentColor,
      count: count,
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
    if (isLoading) {
      return Row(
        children: [
          const Icon(
            Icons.star_outline_rounded,
            size: 16,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            'Carregando avaliações…',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      );
    }

    if (reviewCount <= 0 || averageRating == null) {
      return _EmptyReputation(accentColor: accentColor);
    }

    final commentedReviews = reviews
        .where((review) => (review.comment ?? '').trim().isNotEmpty)
        .take(3)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.star_rounded,
          title: 'Avaliações',
          accentColor: accentColor,
          count: reviewCount,
          trailing: reviews.length > commentedReviews.length
              ? TextButton(
                  onPressed: () => _showAllReviews(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Ver todas'),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              averageRating!.toStringAsFixed(1),
              style: AppTypography.headlineLarge.copyWith(
                color: AppColors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.0,
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
                  const SizedBox(height: AppSpacing.s2),
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
        if (commentedReviews.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          for (var i = 0; i < commentedReviews.length; i++) ...[
            _ReviewCommentTile(
              review: commentedReviews[i],
              reviewer: reviewAuthors[commentedReviews[i].reviewerId],
            ),
            if (i != commentedReviews.length - 1)
              const SizedBox(height: AppSpacing.s10),
          ],
        ],
      ],
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

class _EmptyReputation extends StatelessWidget {
  final Color accentColor;

  const _EmptyReputation({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.star_outline_rounded,
          size: 16,
          color: AppColors.textTertiary,
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            'Conte com o tempo. Avaliações aparecem após gigs concluídos.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
              height: 1.4,
            ),
          ),
        ),
      ],
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
        color: AppColors.surface,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          icon: Icons.work_outline_rounded,
          title: 'Gigs em andamento',
          accentColor: accentColor,
          count: gigs.length,
        ),
        const SizedBox(height: AppSpacing.s12),
        if (isLoading)
          Text(
            'Carregando gigs ativas…',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          )
        else
          for (var i = 0; i < gigs.length; i++) ...[
            _OpenGigTile(gig: gigs[i], accentColor: accentColor),
            if (i != gigs.length - 1) const SizedBox(height: AppSpacing.s8),
          ],
      ],
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
            color: AppColors.surface,
            borderRadius: AppRadius.all12,
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: AppSpacing.s8,
                height: AppSpacing.s8,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
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
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      details.join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
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
    final height = ProfileHeroHeader.heightFor(context);
    return SkeletonShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(
              width: double.infinity,
              height: height,
              borderRadius: AppRadius.r4,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s24,
                AppSpacing.s20,
                AppSpacing.s24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SkeletonBox(height: 14, borderRadius: AppRadius.r4),
                  SizedBox(height: AppSpacing.s8),
                  SkeletonBox(height: 14, borderRadius: AppRadius.r4),
                  SizedBox(height: AppSpacing.s8),
                  SkeletonBox(
                    width: 160,
                    height: 14,
                    borderRadius: AppRadius.r4,
                  ),
                  SizedBox(height: AppSpacing.s24),
                  SkeletonBox(height: 120, borderRadius: AppRadius.r16),
                  SizedBox(height: AppSpacing.s24),
                  _GallerySkeletonGrid(),
                  SizedBox(height: AppSpacing.s24),
                  SkeletonBox(height: 60, borderRadius: AppRadius.r12),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s48),
          ],
        ),
      ),
    );
  }
}

class _GallerySkeletonGrid extends StatelessWidget {
  const _GallerySkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.s4,
        crossAxisSpacing: AppSpacing.s4,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => const SkeletonBox(borderRadius: AppRadius.r8),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
