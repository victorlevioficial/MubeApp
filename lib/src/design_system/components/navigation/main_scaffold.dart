import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/chat/data/chat_unread_provider.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_effects.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';
import 'responsive_center.dart';

/// Professional scaffold with modern adaptive navigation
///
/// Features:
/// - Floating navigation bar with glassmorphic effect
/// - Smooth animations and transitions
/// - Elegant active indicator
/// - Adaptive layout (rail for wide screens, bottom bar for narrow)
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
      backgroundColor: AppColors.background,
      body: ResponsiveCenter(padding: EdgeInsets.zero, child: navigationShell),
      extendBody: true, // Allow content to extend behind nav bar
      bottomNavigationBar: _ModernNavBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        unreadCount: ref.watch(unreadMessagesCountProvider).value ?? 0,
      ),
    );
  }

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Modern floating navigation bar with glassmorphic design
class _ModernNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final int unreadCount;

  const _ModernNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        bottom: AppSpacing.s16,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        // Solid background (nao mais transparente)
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface,
            AppColors.surface.withValues(alpha: 0.98),
          ],
        ),
        borderRadius: AppRadius.all24,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onDestinationSelected(0),
          ),
          _NavBarItem(
            icon: Icons.search_outlined,
            selectedIcon: Icons.search_rounded,
            label: 'Busca',
            isSelected: selectedIndex == 1,
            onTap: () => onDestinationSelected(1),
          ),
          _NavBarItem(
            icon: Icons.bolt_outlined,
            selectedIcon: Icons.bolt_rounded,
            label: 'Match',
            isSelected: selectedIndex == 2,
            onTap: () => onDestinationSelected(2),
            isPrimary: true, // Highlight for main feature
          ),
          _NavBarItem(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
            label: 'Chat',
            isSelected: selectedIndex == 3,
            onTap: () => onDestinationSelected(3),
            badgeCount: unreadCount,
          ),
          _NavBarItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Config',
            isSelected: selectedIndex == 4,
            onTap: () => onDestinationSelected(4),
          ),
        ],
      ),
    );
  }
}

/// Individual navigation bar item with animations
class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;
  final bool isPrimary;

  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
    this.isPrimary = false,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _labelOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: AppEffects.normal, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _labelOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isPrimary
        ? AppColors.primary
        : AppColors.primary;
    final inactiveColor = AppColors.textSecondary.withValues(alpha: 0.6);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.all16,
          splashColor: Colors.transparent, // Remove splash effect
          highlightColor: Colors.transparent, // Remove highlight effect
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with badge and active indicator
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Active indicator background
                    AnimatedContainer(
                      duration: AppEffects.normal,
                      curve: Curves.easeOut,
                      width: 56,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: widget.isSelected
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  activeColor.withValues(alpha: 0.15),
                                  activeColor.withValues(alpha: 0.08),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        border: widget.isSelected
                            ? Border.all(
                                color: activeColor.withValues(alpha: 0.2),
                                width: 1,
                              )
                            : null,
                      ),
                    ),

                    // Icon
                    SizedBox(
                      width: 56,
                      height: 32,
                      child: Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Icon(
                            widget.isSelected
                                ? widget.selectedIcon
                                : widget.icon,
                            size: 24,
                            color: widget.isSelected
                                ? activeColor
                                : inactiveColor,
                          ),
                        ),
                      ),
                    ),

                    // Badge for unread count
                    if (widget.badgeCount > 0)
                      Positioned(
                        top: -4,
                        right: 8,
                        child: _UnreadBadge(count: widget.badgeCount),
                      ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s4),

                // Label with fade animation
                FadeTransition(
                  opacity: widget.isSelected
                      ? _labelOpacityAnimation
                      : const AlwaysStoppedAnimation(0.6),
                  child: Text(
                    widget.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: widget.isSelected ? activeColor : inactiveColor,
                      fontWeight: widget.isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Modern unread badge with pulse animation
class _UnreadBadge extends StatefulWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  State<_UnreadBadge> createState() => _UnreadBadgeState();
}

class _UnreadBadgeState extends State<_UnreadBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.background, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          widget.count > 99 ? '99+' : '${widget.count}',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 9,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

/// Adaptive navigation rail for wide screens
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
      indicatorColor: AppColors.primary.withValues(alpha: 0.15),
      labelType: NavigationRailLabelType.all,
      useIndicator: true,
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
          label: Text('Home'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          label: Text('Busca'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.bolt_outlined),
          selectedIcon: Icon(Icons.bolt_rounded, color: AppColors.primary),
          label: Text('MatchPoint'),
        ),
        NavigationRailDestination(
          icon: _ChatRailIcon(count: unreadCount, isSelected: false),
          selectedIcon: _ChatRailIcon(count: unreadCount, isSelected: true),
          label: const Text('Chat'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded, color: AppColors.primary),
          label: Text('Config'),
        ),
      ],
    );
  }
}

/// Chat icon for navigation rail with badge
class _ChatRailIcon extends StatelessWidget {
  final int count;
  final bool isSelected;

  const _ChatRailIcon({required this.count, required this.isSelected});

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
        isSelected
            ? Icons.chat_bubble_rounded
            : Icons.chat_bubble_outline_rounded,
        color: isSelected ? AppColors.primary : null,
      ),
    );
  }
}
