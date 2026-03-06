part of 'public_profile_screen.dart';

class _ProfileBody extends StatelessWidget {
  final AppUser user;
  final List<MediaItem> galleryItems;
  final List<AppUser> bandMembers;
  final String avatarHeroTag;
  final VoidCallback onAvatarTap;
  final void Function(int index, List<MediaItem> items) onMediaTap;

  const _ProfileBody({
    required this.user,
    required this.galleryItems,
    required this.bandMembers,
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
          ProfileHeroHeader(
            user: user,
            avatarHeroTag: avatarHeroTag,
            onAvatarTap: onAvatarTap,
          ),
          _buildBody(context, padding: AppSpacing.s20),
          const SizedBox(height: AppSpacing.s48),
        ],
      ),
    );
  }

  Widget _wideLayout(BuildContext context) {
    final bio = user.profileBio;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s32),
      child: ResponsiveCenter(
        padding: EdgeInsets.zero,
        maxContentWidth: 1200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: header + bio
            SizedBox(
              width: 340,
              child: Column(
                children: [
                  ProfileHeroHeader(
                    user: user,
                    avatarHeroTag: avatarHeroTag,
                    onAvatarTap: onAvatarTap,
                  ),
                  if (bio != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s20,
                      ),
                      child: _BioCard(bio: bio),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s32),
            // Right column: details + gallery
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.s24),
                  _buildDetails(),
                  if (user.tipoPerfil != AppUserType.contractor) ...[
                    const SizedBox(height: AppSpacing.s20),
                    _buildGallery(),
                  ],
                  const SizedBox(height: AppSpacing.s48),
                ],
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
          if (bio != null) ...[
            _BioCard(bio: bio),
            const SizedBox(height: AppSpacing.s16),
          ],
          _buildDetails(),
          if (user.tipoPerfil != AppUserType.contractor) ...[
            const SizedBox(height: AppSpacing.s20),
            _buildGallery(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return _TypeDetails(user: user, bandMembers: bandMembers);
  }

  Widget _buildGallery() {
    return ProfileGalleryTabs(
      items: galleryItems,
      accentColor: ProfileHeroHeader.profileTypeColor(user.tipoPerfil),
      onItemTap: onMediaTap,
    );
  }
}

class _PublicProfileSkeleton extends StatelessWidget {
  static const double _topSpacing =
      AppSpacing.s48 + AppSpacing.s24 + AppSpacing.s20;

  const _PublicProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: _topSpacing),
            Center(child: SkeletonCircle(size: 124)),
            SizedBox(height: AppSpacing.s20),
            Center(child: SkeletonText(width: 180, height: 24)),
            SizedBox(height: AppSpacing.s8),
            Center(child: SkeletonText(width: 120, height: 14)),
            SizedBox(height: AppSpacing.s24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.s20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SkeletonBox(
                    width: double.infinity,
                    height: 112,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s12),
                  SkeletonBox(
                    width: double.infinity,
                    height: 132,
                    borderRadius: 16,
                  ),
                  SizedBox(height: AppSpacing.s20),
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
