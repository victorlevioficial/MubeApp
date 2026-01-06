import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated favorite button with professional animations and haptic feedback
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorited;
  final VoidCallback? onTap;
  final double size;
  final Color? favoriteColor;
  final Color? defaultColor;
  final bool isLoading;

  const AnimatedFavoriteButton({
    super.key,
    required this.isFavorited,
    this.onTap,
    this.size = 24,
    this.favoriteColor,
    this.defaultColor,
    this.isLoading = false,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.4,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(AnimatedFavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorited && !oldWidget.isFavorited) {
      _playAnimation();
    }
  }

  void _playAnimation() {
    _controller.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isFavorited
        ? (widget.favoriteColor ?? const Color(0xFFE91E63))
        : (widget.defaultColor ?? Colors.white54);

    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: widget.isLoading
                  ? SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    )
                  : Icon(
                      widget.isFavorited
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: color,
                      size: widget.size,
                    ),
            ),
          );
        },
      ),
    );
  }
}
