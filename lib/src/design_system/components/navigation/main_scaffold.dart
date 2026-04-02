import 'dart:async';

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
class MainScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  Timer? _enableUnreadTimer;
  bool _enableUnreadCount = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enableUnreadTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _enableUnreadCount = true);
      });
    });
  }

  @override
  void dispose() {
    _enableUnreadTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 600;
    const visibleBranchIndexes = <int>[0, 1, 2, 3, 4];
    final selectedVisibleIndex = widget.navigationShell.currentIndex;

    if (isWide) {
      return _buildWideLayout(
        context,
        selectedVisibleIndex: selectedVisibleIndex,
        visibleBranchIndexes: visibleBranchIndexes,
      );
    }

    return _buildNarrowLayout(
      context,
      selectedVisibleIndex: selectedVisibleIndex,
      visibleBranchIndexes: visibleBranchIndexes,
    );
  }

  Widget _buildWideLayout(
    BuildContext context, {
    required int selectedVisibleIndex,
    required List<int> visibleBranchIndexes,
  }) {
    return Scaffold(
      body: Row(
        children: [
          _AdaptiveRail(
            selectedIndex: selectedVisibleIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(index, visibleBranchIndexes),
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
              child: widget.navigationShell,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
    BuildContext context, {
    required int selectedVisibleIndex,
    required List<int> visibleBranchIndexes,
  }) {
    final unreadCount = _enableUnreadCount
        ? ref.watch(unreadMessagesCountProvider)
        : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveCenter(
        padding: EdgeInsets.zero,
        child: widget.navigationShell,
      ),
      bottomNavigationBar: _ModernNavBar(
        selectedIndex: selectedVisibleIndex,
        onDestinationSelected: (index) =>
            _onDestinationSelected(index, visibleBranchIndexes),
        unreadCount: unreadCount,
      ),
    );
  }

  void _onDestinationSelected(
    int visibleIndex,
    List<int> visibleBranchIndexes,
  ) {
    if (visibleIndex < 0 || visibleIndex >= visibleBranchIndexes.length) {
      return;
    }

    final branchIndex = visibleBranchIndexes[visibleIndex];

    // Settings should always open at its root screen when switching tabs.
    final shouldResetToRoot =
        branchIndex == widget.navigationShell.currentIndex || branchIndex == 4;
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: shouldResetToRoot,
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
    return SafeArea(
      top: false,
      left: false,
      right: false,
      minimum: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Container(
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
              label: 'Feed',
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
              icon: Icons.work_outline_rounded,
              selectedIcon: Icons.work_rounded,
              label: 'Gigs',
              isSelected: selectedIndex == 2,
              onTap: () => onDestinationSelected(2),
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
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              label: 'Conta',
              isSelected: selectedIndex == 4,
              onTap: () => onDestinationSelected(4),
            ),
          ],
        ),
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

  const _NavBarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
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
    const activeColor = AppColors.primary;
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
                        borderRadius: AppRadius.all16,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s4,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: AppRadius.all12,
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
    final unreadCount = ref.watch(unreadMessagesCountProvider);

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
          label: Text('Feed'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          label: Text('Busca'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.work_outline_rounded),
          selectedIcon: Icon(Icons.work_rounded, color: AppColors.primary),
          label: Text('Gigs'),
        ),
        NavigationRailDestination(
          icon: _ChatRailIcon(count: unreadCount, isSelected: false),
          selectedIcon: _ChatRailIcon(count: unreadCount, isSelected: true),
          label: const Text('Chat'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          label: Text('Conta'),
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
