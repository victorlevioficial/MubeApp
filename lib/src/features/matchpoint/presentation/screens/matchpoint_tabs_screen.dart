import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../../../common_widgets/mube_app_bar.dart';
import '../../../../design_system/foundations/app_colors.dart';
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
      appBar: MubeAppBar(
        title: 'MatchPoint',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.semanticAction,
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
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: GNav(
              gap: 8,
              backgroundColor: Colors.transparent,
              color: AppColors.textSecondary,
              activeColor: Colors.white,
              tabBackgroundColor: AppColors.brandPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 300),
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              tabs: const [
                GButton(
                  icon: Icons.explore_rounded,
                  text: 'Explorar',
                  textStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                GButton(
                  icon: Icons.bolt_rounded,
                  text: 'Matches',
                  textStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
        title: const Text(
          'Sobre o MatchPoint',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'O MatchPoint é o lugar para formar sua próxima banda ou projeto musical.\n\n'
          '1. Explore: Descubra músicos que combinam com seus gêneros e objetivos.\n\n'
          '2. Filtre: Use o botão de filtros para refinar sua busca por instrumentos, estilos e localização.\n\n'
          '3. Conecte: Envie convites e comece a criar música juntos!',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendi',
              style: TextStyle(color: AppColors.brandPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
