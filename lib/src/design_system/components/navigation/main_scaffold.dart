import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/chat/data/chat_unread_provider.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_typography.dart';
import 'responsive_center.dart';

/// Scaffold principal com bottom navigation.
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveCenter(padding: EdgeInsets.zero, child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
            selectedIcon: const Icon(
              Icons.home,
              color: AppColors.primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.search_outlined,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
            selectedIcon: const Icon(
              Icons.search,
              color: AppColors.primary,
            ),
            label: 'Busca',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.bolt_outlined,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
            selectedIcon: const Icon(
              Icons.bolt_rounded,
              color: AppColors.primary,
            ),
            label: 'MatchPoint',
          ),
          NavigationDestination(
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
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
              color: AppColors.textPrimary.withValues(alpha: 0.6),
            ),
            selectedIcon: const Icon(
              Icons.settings,
              color: AppColors.primary,
            ),
            label: 'Config',
          ),
        ],
      ),
    );
  }
}
