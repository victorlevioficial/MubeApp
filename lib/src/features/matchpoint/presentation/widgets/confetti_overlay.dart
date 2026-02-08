import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';

/// Widget de confetti animado para celebração de match
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();

    _particles = List.generate(50, (_) => _ConfettiParticle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiParticle {
  final double startX;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double wobble;
  final bool isCircle;

  _ConfettiParticle()
    : startX = Random().nextDouble(),
      speed = 0.3 + Random().nextDouble() * 0.7,
      size = 6 + Random().nextDouble() * 8,
      color = _randomColor(),
      rotation = Random().nextDouble() * 6.28,
      wobble = Random().nextDouble() * 50,
      isCircle = Random().nextBool();

  static Color _randomColor() {
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.badgeBand, // Fuchsia/Purple
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF69B4), // Hot Pink
    ];
    return colors[Random().nextInt(colors.length)];
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Fade out near the end
      final opacity = progress < 0.8 ? 1.0 : (1.0 - progress) * 5;
      if (opacity <= 0) continue;

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Calculate position
      final x =
          particle.startX * size.width +
          sin(progress * 6.28 * 2 + particle.wobble) * 30;
      final y = -50 + progress * (size.height + 100) * particle.speed;

      if (y < 0 || y > size.height) continue;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * 6.28 * 2);

      if (particle.isCircle) {
        canvas.drawCircle(Offset.zero, particle.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          paint,
        );
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
