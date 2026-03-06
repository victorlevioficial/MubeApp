import 'package:flutter/material.dart';

/// Dismisses the active keyboard focus when tapping on non-interactive space.
///
/// Using a tap gesture instead of a raw pointer listener avoids stealing focus
/// from controls associated with the current field, like chat send buttons.
class DismissKeyboardOnTap extends StatelessWidget {
  final Widget child;

  const DismissKeyboardOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
