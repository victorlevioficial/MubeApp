import 'package:flutter/material.dart';
import '../../../../design_system/foundations/app_colors.dart';

/// Um botão de coração animado para o sistema de likes V8.
/// Puramente visual: recebe estado e callback, sem lógica de negócio.
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorited;
  final VoidCallback onTap;
  final double size;
  final Color favoriteColor;
  final Color defaultColor;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorited,
    required this.onTap,
    this.size = 28,
    this.favoriteColor = AppColors.primary,
    this.defaultColor = Colors.white54,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se mudou de false -> true, anima
    if (widget.isFavorited && !oldWidget.isFavorited) {
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Icon(
          widget.isFavorited ? Icons.favorite : Icons.favorite_border,
          color: widget.isFavorited
              ? widget.favoriteColor
              : widget.defaultColor,
          size: widget.size,
        ),
      ),
    );
  }
}
