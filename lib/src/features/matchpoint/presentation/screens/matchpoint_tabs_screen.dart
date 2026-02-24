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
import '../controllers/matchpoint_controller.dart';
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
  final List<Widget> _screens = [
    const MatchpointExploreScreen(),
    const MatchpointMatchesScreen(),
    const HashtagRankingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    matchpointSelectedTabNotifier.value = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchpointControllerProvider.notifier).fetchRemainingLikes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: matchpointSelectedTabNotifier,
      builder: (context, selectedIndex, child) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppAppBar(
          title: 'Matchpoint',
          showBackButton: false,
          leading: IconButton(
            tooltip: 'Historico de swipes',
            onPressed: () => context.push(RoutePaths.matchpointHistory),
            icon: const Icon(
              Icons.history_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Filtros avancados',
              onPressed: () => context.push(RoutePaths.matchpointWizard),
              icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
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
              child: IndexedStack(index: selectedIndex, children: _screens),
            ),
          ],
        ),
      ),
    );
  }
}
