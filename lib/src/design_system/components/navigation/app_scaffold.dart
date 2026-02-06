import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/chat/data/chat_unread_provider.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_typography.dart';

/// Scaffold principal com navegação inferior do Design System Mube.
///
/// Usado como container principal do aplicativo com bottom navigation.
///
/// Uso:
/// ```dart
/// AppScaffold(navigationShell: navigationShell)
/// ```
class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          _buildDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          _buildDestination(
            icon: Icons.search_outlined,
            selectedIcon: Icons.search,
            label: 'Busca',
          ),
          _buildDestination(
            icon: Icons.bolt_outlined,
            selectedIcon: Icons.bolt_rounded,
            label: 'MatchPoint',
          ),
          _buildChatDestination(),
          _buildDestination(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Config',
          ),
        ],
      ),
    );
  }

  NavigationDestination _buildDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textPrimary.withValues(alpha: 0.6)),
      selectedIcon: Icon(selectedIcon, color: AppColors.primary),
      label: label,
    );
  }

  NavigationDestination _buildChatDestination() {
    return NavigationDestination(
      icon: Consumer(
        builder: (context, ref, _) {
          final unreadCountAsync = ref.watch(unreadMessagesCountProvider);
          final unreadCount = unreadCountAsync.asData?.value ?? 0;

          return Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.buttonPrimary.fontWeight,
              ),
            ),
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.chat_bubble_outline,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
          );
        },
      ),
      selectedIcon: Consumer(
        builder: (context, ref, _) {
          final unreadCountAsync = ref.watch(unreadMessagesCountProvider);
          final unreadCount = unreadCountAsync.asData?.value ?? 0;

          return Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: AppTypography.chipLabel.copyWith(
                color: AppColors.textPrimary,
                fontWeight: AppTypography.buttonPrimary.fontWeight,
              ),
            ),
            backgroundColor: AppColors.primary,
            child: const Icon(
              Icons.chat_bubble,
              color: AppColors.primary,
            ),
          );
        },
      ),
      label: 'Chat',
    );
  }
}
