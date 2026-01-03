import 'package:flutter/material.dart';
import 'responsive_center.dart';

/// A Shell Wrapper that enforces max-width constraints for its children.
/// Used in GoRouter to wrap main app screens (Feed, Profile, etc).
class ResponsiveShell extends StatelessWidget {
  final Widget navigationShell;

  const ResponsiveShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveCenter(
        padding: EdgeInsets
            .zero, // Shell handles raw constraint; children handle padding
        child: navigationShell,
      ),
      // Here you could also add a global BottomNavigationBar constrained consistently
    );
  }
}
