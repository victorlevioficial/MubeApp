import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../foundations/tokens/app_motion.dart';

/// Um wrapper que adiciona feedback visual de toque (scale down) a qualquer widget.
///
/// Use para envolver cards, botões customizados ou imagens que são tocáveis,
/// para dar uma sensação "tátil" e responsiva (Mube Premium Feel).
///
/// Exemplo:
/// ```dart
/// AppAnimatedPress(
///   onPressed: () => print('Tapped'),
///   child: Container(color: Colors.red, width: 100, height: 100),
/// )
/// ```
class AppAnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleFactor;
  final Duration duration;

  const AppAnimatedPress({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleFactor = 0.95,
    this.duration = AppMotion.short,
  });

  @override
  State<AppAnimatedPress> createState() => _AppAnimatedPressState();
}

class _AppAnimatedPressState extends State<AppAnimatedPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppMotion.standardCurve,
            reverseCurve: AppMotion.leavingCurve,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(PointerDownEvent event) {
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      _controller.forward();
    }
  }

  void _handleTapUp(PointerUpEvent event) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel(PointerCancelEvent event) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se onPressed for nulo, apenas retorna o child sem animação/listener
    if (widget.onPressed == null) return widget.child;

    return Listener(
      onPointerDown: _handleTapDown,
      onPointerUp: _handleTapUp,
      onPointerCancel: _handleTapCancel,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
