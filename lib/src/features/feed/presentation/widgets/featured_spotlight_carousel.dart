import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/components/data_display/optimized_image.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../domain/feed_item.dart';
import 'profile_type_badge.dart';

/// Featured carousel that highlights top profiles from the loaded sections.
class FeaturedSpotlightCarousel extends StatefulWidget {
  final List<FeedItem> items;
  final void Function(FeedItem) onItemTap;

  const FeaturedSpotlightCarousel({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  State<FeaturedSpotlightCarousel> createState() =>
      _FeaturedSpotlightCarouselState();
}

class _FeaturedSpotlightCarouselState extends State<FeaturedSpotlightCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _visibleCount = 0;
  int _itemsFingerprint = 0;
  List<FeedItem> _spotlightItems = const <FeedItem>[];
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _syncVisibleItems();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant FeaturedSpotlightCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousCount = _visibleCount;
    final previousFingerprint = _itemsFingerprint;
    final didClampPage = _syncVisibleItems();

    if (_visibleCount == 0) {
      _autoScrollTimer?.cancel();
      return;
    }

    if (didClampPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_currentPage);
      });
    }

    if (_visibleCount <= 1) {
      _autoScrollTimer?.cancel();
      return;
    }

    final hasContentChanged = previousFingerprint != _itemsFingerprint;
    if (previousCount != _visibleCount || hasContentChanged) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_visibleCount <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_visibleCount <= 1 || !_pageController.hasClients) return;

      final nextPage = (_currentPage + 1) % _visibleCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  bool _syncVisibleItems() {
    final previousPage = _currentPage;
    _visibleCount = math.min(widget.items.length, 5);
    _spotlightItems = widget.items.take(_visibleCount).toList(growable: false);
    _itemsFingerprint = Object.hashAll(_spotlightItems.map((item) => item.uid));

    if (_visibleCount == 0) {
      _currentPage = 0;
    } else if (_currentPage >= _visibleCount) {
      _currentPage = _visibleCount - 1;
    }

    return previousPage != _currentPage;
  }

  @override
  Widget build(BuildContext context) {
    if (_visibleCount == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryPressed],
                  ),
                  borderRadius: AppRadius.all8,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Em Destaque',
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (_currentPage != index) {
                setState(() => _currentPage = index);
              }
              if (_visibleCount > 1) {
                _startAutoScroll();
              }
            },
            itemCount: _visibleCount,
            itemBuilder: (context, index) {
              final item = _spotlightItems[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s12),
                child: _SpotlightCard(
                  item: item,
                  onTap: () => widget.onItemTap(item),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _visibleCount,
              (index) => _PageIndicator(
                isActive: index == _currentPage,
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  const _SpotlightCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.all20,
          boxShadow: [
            BoxShadow(
              color: AppColors.background.withValues(alpha: 0.5),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.all20,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.foto != null)
                OptimizedImage(imageUrl: item.foto!, fit: BoxFit.cover)
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.surface, AppColors.surface2],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withValues(alpha: 0.6),
                      AppColors.background.withValues(alpha: 0.95),
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ProfileTypeBadge(
                      tipoPerfil: item.tipoPerfil,
                      subCategories: item.subCategories,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      item.displayName,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 20,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        if (item.distanceText.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.s4),
                          Text(
                            item.distanceText,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s8),
                        ],
                        if (item.formattedGenres.isNotEmpty)
                          Expanded(
                            child: Text(
                              item.formattedGenres.take(2).join(' - '),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: AppSpacing.s16,
                right: AppSpacing.s16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.85),
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: AppColors.surfaceHighlight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.s4),
                      Text(
                        'Ver perfil',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;

  const _PageIndicator({required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryPressed],
                )
              : null,
          color: isActive ? null : AppColors.surfaceHighlight,
          borderRadius: AppRadius.pill,
        ),
      ),
    );
  }
}
