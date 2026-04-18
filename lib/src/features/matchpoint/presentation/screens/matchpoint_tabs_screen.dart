import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../../utils/app_logger.dart';
import '../../data/matchpoint_swipe_outbox_coordinator.dart';
import '../controllers/matchpoint_controller.dart';
import '../matchpoint_navigation.dart';
import '../screens/matchpoint_matches_screen.dart';
import 'hashtag_ranking_screen.dart';
import 'matchpoint_explore_screen.dart';

class MatchpointTabsScreen extends ConsumerStatefulWidget {
  const MatchpointTabsScreen({super.key});

  @override
  ConsumerState<MatchpointTabsScreen> createState() =>
      _MatchpointTabsScreenState();
}

class _MatchpointTabsScreenState extends ConsumerState<MatchpointTabsScreen> {
  static const _tabCount = 3;
  static const _outboxFlushDelay = Duration(milliseconds: 350);

  /// Tracks which tabs have been visited so we keep their state alive once
  /// built, but avoid building all three on first frame (the root cause of
  /// the iOS Swift-concurrency crash – too many Firebase operations at once).
  final Set<int> _initializedTabs = {0};
  late final MatchpointSwipeOutboxCoordinator _outboxCoordinator;

  @override
  void initState() {
    super.initState();
    _outboxCoordinator = ref.read(matchpointSwipeOutboxCoordinatorProvider);
    AppLogger.breadcrumb('mp:tabs:init');
    AppLogger.setCustomKey('mp_step', 'tabs:init');

    // Free the global image cache before the swipe deck mounts. The user
    // typically arrives here from the feed, which keeps dozens of images
    // resident — Crashlytics events for issue a37e597a consistently show
    // 86-200 MB free on a 6 GB iPhone 14 Pro Max, putting the iOS Swift
    // Concurrency cooperative pool under enough memory pressure to abort
    // tasks mid-flight (swift_task_dealloc → SIGABRT). Releasing the cache
    // here gives the matchpoint flow ~50-200 MB of headroom before it
    // starts loading 12 fresh card images and issuing Pigeon calls.
    AppLogger.breadcrumb('mp:tabs:image_cache_clear');
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    matchpointSelectedTabNotifier.value = 0;
    // The standalone fetchRemainingLikes() call has been removed entirely.
    // The submitMatchpointAction Cloud Function returns the updated quota
    // in its response, so the local likesQuotaProvider converges to the
    // server value after the first like — no separate Pigeon call needed.
  }

  @override
  void dispose() {
    _scheduleOutboxFlush(reason: 'tabs_dispose');
    super.dispose();
  }

  void _scheduleOutboxFlush({
    required String reason,
    Duration delay = _outboxFlushDelay,
  }) {
    _outboxCoordinator.scheduleFlush(delay: delay, reason: reason);
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return const MatchpointExploreScreen();
      case 1:
        return const MatchpointMatchesScreen();
      case 2:
        return const HashtagRankingScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        _scheduleOutboxFlush(reason: 'tabs_pop');
      },
      child: ValueListenableBuilder<int>(
        valueListenable: matchpointSelectedTabNotifier,
        builder: (context, rawIndex, child) {
          final selectedIndex = rawIndex.clamp(0, _tabCount - 1);

          // Mark tab as visited so it stays alive on future switches.
          _initializedTabs.add(selectedIndex);

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppAppBar(
              title: 'MatchPoint',
              showBackButton: true,
              onBackPressed: () => handleMatchpointBack(context),
              actions: [
                IconButton(
                  tooltip: 'Filtros avançados',
                  onPressed: () => context.push(RoutePaths.matchpointWizard),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  tooltip: 'Histórico de swipes',
                  onPressed: () => context.push(RoutePaths.matchpointHistory),
                  icon: const Icon(
                    Icons.history_rounded,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                // Custom Google Nav Bar (top menu)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.s16,
                    AppSpacing.s8,
                    AppSpacing.s16,
                    AppSpacing.s8,
                  ),
                  padding: AppSpacing.all4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                    ),
                  ),
                  child: GNav(
                    gap: AppSpacing.s8,
                    backgroundColor: AppColors.transparent,
                    color: AppColors.textSecondary,
                    activeColor: AppColors.textPrimary,
                    tabBackgroundColor: AppColors.primary,
                    padding: AppSpacing.h16v12,
                    duration: const Duration(milliseconds: 300),
                    selectedIndex: selectedIndex,
                    onTabChange: (index) {
                      AppLogger.breadcrumb('mp:tabs:change_to_$index');
                      AppLogger.setCustomKey('mp_step', 'tabs:change_$index');
                      matchpointSelectedTabNotifier.value = index;
                    },
                    tabs: [
                      GButton(
                        icon: Icons.explore_rounded,
                        text: 'Explorar',
                        textStyle: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.buttonPrimary.fontWeight,
                        ),
                      ),
                      GButton(
                        icon: Icons.bolt_rounded,
                        text: 'Matches',
                        textStyle: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.buttonPrimary.fontWeight,
                        ),
                      ),
                      GButton(
                        icon: Icons.trending_up_rounded,
                        text: 'Trending',
                        textStyle: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: AppTypography.buttonPrimary.fontWeight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),

                Expanded(
                  child: IndexedStack(
                    index: selectedIndex,
                    children: List.generate(_tabCount, (i) {
                      if (_initializedTabs.contains(i)) return _buildTab(i);
                      // Placeholder for tabs that haven't been visited yet.
                      return const SizedBox.shrink();
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
