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

/// Featured carousel that rotates spotlight profiles on the home feed.
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

class _FeaturedSpotlightCarouselState extends State<FeaturedSpotlightCarousel>
    with WidgetsBindingObserver {
  /// Maximum number of profiles shown in the carousel window.
  static const int _maxVisible = 5;

  /// Interval between automatic page advances.
  static const Duration _autoScrollInterval = Duration(seconds: 5);

  /// Duration of the slide animation between pages.
  static const Duration _slideDuration = Duration(milliseconds: 450);

  late final PageController _pageController;

  /// Logical index of the active card, in `[0, _visibleCount)`. Drives the dots.
  int _activeIndex = 0;

  /// Current raw page of the (infinitely looping) [PageView]. `raw % count`
  /// gives the logical index. Tracking the raw page lets auto-advance always
  /// move forward and wrap seamlessly instead of rewinding back to the start.
  int _currentRawPage = 0;

  int _visibleCount = 0;
  int _itemsFingerprint = 0;
  List<FeedItem> _spotlightItems = const <FeedItem>[];

  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  bool _autoScrollAllowed = true;

  /// The carousel can only loop/auto-advance with more than one card.
  bool get _canLoop => _visibleCount > 1;

  /// A raw page far enough from 0 that the user can also swipe backwards
  /// through the loop. Always a multiple of [_visibleCount] so it maps to
  /// logical index 0.
  int get _loopAnchorPage => _canLoop ? _visibleCount * 1000 : 0;

  @override
  void initState() {
    super.initState();
    _syncVisibleItems();
    _currentRawPage = _loopAnchorPage;
    _activeIndex = 0;
    _pageController = PageController(
      viewportFraction: 0.9,
      initialPage: _currentRawPage,
    );
    WidgetsBinding.instance.addObserver(this);
    _startAutoScroll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor the OS "reduce motion" accessibility setting.
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final allowed = !disableAnimations;
    if (allowed == _autoScrollAllowed) return;

    _autoScrollAllowed = allowed;
    if (allowed) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  @override
  void didUpdateWidget(covariant FeaturedSpotlightCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    final previousCount = _visibleCount;
    final previousFingerprint = _itemsFingerprint;
    _syncVisibleItems();

    if (_visibleCount == 0) {
      _autoScrollTimer?.cancel();
      return;
    }

    final countChanged = previousCount != _visibleCount;
    final contentChanged = previousFingerprint != _itemsFingerprint;

    if (countChanged) {
      // The loop math depends on _visibleCount, so realign to a clean anchor
      // and reset to the first card whenever the window size changes.
      _activeIndex = 0;
      _currentRawPage = _loopAnchorPage;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(_currentRawPage);
      });
    } else if (_activeIndex >= _visibleCount) {
      _activeIndex = _visibleCount - 1;
    }

    if (!_canLoop) {
      _autoScrollTimer?.cancel();
      return;
    }

    // Only re-arm the timer when the data actually changed; plain rebuilds
    // (the parent rebuilds a fresh list every frame) must not reset it.
    if ((countChanged || contentChanged) && !_isUserInteracting) {
      _startAutoScroll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!_canLoop || !_autoScrollAllowed || _isUserInteracting) return;

    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_canLoop || _isUserInteracting || !_pageController.hasClients) {
        return;
      }
      // Always advance forward; the infinite loop makes the wrap seamless.
      _pageController.nextPage(
        duration: _slideDuration,
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _syncVisibleItems() {
    _visibleCount = math.min(widget.items.length, _maxVisible);
    _spotlightItems = widget.items.take(_visibleCount).toList(growable: false);
    _itemsFingerprint = Object.hashAll(_spotlightItems.map((item) => item.uid));
  }

  void _handlePageChanged(int rawPage) {
    _currentRawPage = rawPage;
    final logical = _canLoop ? rawPage % _visibleCount : 0;
    if (_activeIndex != logical) {
      setState(() => _activeIndex = logical);
    }
  }

  void _onUserInteractionStart() {
    _isUserInteracting = true;
    _autoScrollTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    if (!_isUserInteracting) return;
    _isUserInteracting = false;
    _startAutoScroll();
  }

  void _goToIndex(int targetIndex) {
    if (!_canLoop || !_pageController.hasClients) return;

    var delta = targetIndex - _activeIndex;
    // Take the shortest path around the loop instead of sweeping across pages.
    final half = _visibleCount / 2;
    if (delta > half) {
      delta -= _visibleCount;
    } else if (delta < -half) {
      delta += _visibleCount;
    }
    if (delta == 0) return;

    _pageController.animateToPage(
      _currentRawPage + delta,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
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
                padding: const EdgeInsets.all(AppSpacing.s8),
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
          child: Listener(
            onPointerDown: (_) => _onUserInteractionStart(),
            onPointerUp: (_) => _onUserInteractionEnd(),
            onPointerCancel: (_) => _onUserInteractionEnd(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _handlePageChanged,
              itemCount: _canLoop ? null : _visibleCount,
              itemBuilder: (context, index) {
                final item = _spotlightItems[index % _visibleCount];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                  ),
                  child: _SpotlightCard(
                    item: item,
                    onTap: () => widget.onItemTap(item),
                  ),
                );
              },
            ),
          ),
        ),
        if (_visibleCount > 1) ...[
          const SizedBox(height: AppSpacing.s16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                _visibleCount,
                (index) => _PageIndicator(
                  isActive: index == _activeIndex,
                  onTap: () => _goToIndex(index),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;

  static final BoxDecoration _cardDecoration = BoxDecoration(
    borderRadius: AppRadius.all20,
    boxShadow: [
      BoxShadow(
        color: AppColors.background.withValues(alpha: 0.5),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static final BoxDecoration _overlayDecoration = BoxDecoration(
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
  );

  static final BoxDecoration _ctaDecoration = BoxDecoration(
    color: AppColors.background.withValues(alpha: 0.85),
    borderRadius: AppRadius.pill,
    border: Border.all(color: AppColors.surfaceHighlight, width: 1),
  );

  const _SpotlightCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Perfil em destaque: ${item.displayName}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: _cardDecoration,
          child: ClipRRect(
            borderRadius: AppRadius.all20,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.foto != null)
                  OptimizedImage(
                    imageUrl: item.foto!,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0.0, -0.5),
                    fadeInDuration: const Duration(milliseconds: 250),
                  )
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
                Container(decoration: _overlayDecoration),
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
                    decoration: _ctaDecoration,
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
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
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
