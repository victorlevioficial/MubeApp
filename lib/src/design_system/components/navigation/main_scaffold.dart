import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/chat/data/chat_unread_provider.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_typography.dart';
import 'responsive_center.dart';

/// Scaffold principal com navegação adaptativa.
/// Alterna entre NavigationBar (inferior) e NavigationRail (lateral) com base na largura da tela.
class MainScaffold extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 600;

    if (isWide) {
      return _buildWideLayout(context, ref);
    }

    return _buildNarrowLayout(context, ref);
  }

  Widget _buildWideLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          _AdaptiveRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: AppColors.surfaceHighlight,
          ),
          Expanded(
            child: ResponsiveCenter(
              padding: EdgeInsets.zero,
              maxContentWidth: double.infinity,
              child: navigationShell,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ResponsiveCenter(padding: EdgeInsets.zero, child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.transparent,
        elevation: 0,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _buildNavigationDestinations(ref),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  List<NavigationDestination> _buildNavigationDestinations(WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadMessagesCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return [
      const NavigationDestination(
        icon: Icon(Icons.home_outlined, color: AppColors.textSecondary),
        selectedIcon: Icon(Icons.home, color: AppColors.primary),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.search_outlined, color: AppColors.textSecondary),
        selectedIcon: Icon(Icons.search, color: AppColors.primary),
        label: 'Busca',
      ),
      const NavigationDestination(
        icon: Icon(Icons.bolt_outlined, color: AppColors.textSecondary),
        selectedIcon: Icon(Icons.bolt_rounded, color: AppColors.primary),
        label: 'MatchPoint',
      ),
      NavigationDestination(
        icon: _UnreadBadge(count: unreadCount, isSelected: false),
        selectedIcon: _UnreadBadge(count: unreadCount, isSelected: true),
        label: 'Chat',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
        selectedIcon: Icon(Icons.settings, color: AppColors.primary),
        label: 'Config',
      ),
    ];
  }
}

class _AdaptiveRail extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _AdaptiveRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadMessagesCountProvider);
    final unreadCount = unreadCountAsync.value ?? 0;

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: AppColors.background,
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
      labelType: NavigationRailLabelType.all,
      useIndicator: true,
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: Text('Busca'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.bolt_outlined),
          selectedIcon: Icon(Icons.bolt_rounded),
          label: Text('MatchPoint'),
        ),
        NavigationRailDestination(
          icon: _UnreadBadge(count: unreadCount, isSelected: false),
          selectedIcon: _UnreadBadge(count: unreadCount, isSelected: true),
          label: const Text('Chat'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Config'),
        ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  final bool isSelected;

  const _UnreadBadge({required this.count, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(
        count > 99 ? '99+' : '$count',
        style: AppTypography.chipLabel.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppColors.primary,
      child: Icon(
        isSelected ? Icons.chat_bubble : Icons.chat_bubble_outline,
        color: isSelected
            ? AppColors.primary
            : AppColors.textPrimary.withValues(alpha: 0.6),
      ),
    );
  }
}
