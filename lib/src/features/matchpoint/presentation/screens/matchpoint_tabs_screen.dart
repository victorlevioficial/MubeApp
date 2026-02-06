import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../screens/matchpoint_matches_screen.dart';
import 'matchpoint_explore_screen.dart';

class MatchpointTabsScreen extends StatefulWidget {
  const MatchpointTabsScreen({super.key});

  @override
  State<MatchpointTabsScreen> createState() => _MatchpointTabsScreenState();
}

class _MatchpointTabsScreenState extends State<MatchpointTabsScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MatchpointExploreScreen(),
    const MatchpointMatchesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'MatchPoint',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
            ),
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
        title: Text(
          'Sobre o MatchPoint',
          style: AppTypography.titleLarge,
        ),
        content: Text(
          'O MatchPoint é o lugar para formar sua próxima banda ou projeto musical.\n\n'
          '1. Explore: Descubra músicos que combinam com seus gêneros e objetivos.\n\n'
          '2. Filtre: Use o botão de filtros para refinar sua busca por instrumentos, estilos e localização.\n\n'
          '3. Conecte: Envie convites e comece a criar música juntos!',
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
