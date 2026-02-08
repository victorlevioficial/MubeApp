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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MatchpointExploreScreen(),
    const MatchpointMatchesScreen(),
    const HashtagRankingScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Carregar quota de swipes ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(matchpointControllerProvider.notifier).fetchRemainingLikes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final quotaState = ref.watch(likesQuotaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'MatchPoint',
        showBackButton: false,
        actions: [
          // Contador de swipes restantes
          if (_selectedIndex == 0) ...[
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.s8),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s4,
              ),
              decoration: BoxDecoration(
                color: quotaState.hasReachedLimit
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: AppRadius.all8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 16,
                    color: quotaState.hasReachedLimit
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Text(
                    '${quotaState.remaining}/${quotaState.limit}',
                    style: AppTypography.labelMedium.copyWith(
                      color: quotaState.hasReachedLimit
                          ? AppColors.error
                          : AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            icon: const Icon(
              Icons.history_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () => context.push(RoutePaths.matchpointHistory),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            onPressed: () => context.push(RoutePaths.matchpointWizard),
          ),
          IconButton(
            icon: const Icon(
              Icons.help_outline,
              color: AppColors.textSecondary,
            ),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Google Nav Bar (Top Menu)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s16,
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
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
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

          // Content without Sweep Gesture (Resolves Conflict)
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _screens),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Sobre o MatchPoint', style: AppTypography.titleLarge),
        content: Text(
          'O MatchPoint é o lugar para formar sua próxima banda ou projeto musical.\n\n'
          '1. Explorar: Descubra músicos que combinam com seus gêneros e objetivos.\n\n'
          '2. Matches: Veja seus matches e inicie conversas.\n\n'
          '3. Trending: Descubra as hashtags mais populares entre músicos.\n\n'
          'Você tem 50 swipes por dia. Use com sabedoria!',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
