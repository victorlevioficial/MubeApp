import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';

/// Widget de confetti animado para celebração de match
/// Usa LayoutBuilder para dimensões dinâmicas
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _initParticles(double width, double height) {
    if (_initialized) return;
    _initialized = true;

    for (int i = 0; i < 100; i++) {
      _particles.add(_ConfettiParticle(_random, width, height));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        _initParticles(width, height);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            for (var p in _particles) {
              p.update(width, height);
            }
            return CustomPaint(
              size: Size(width, height),
              painter: _ConfettiPainter(_particles),
            );
          },
        );
      },
    );
  }
}

class _ConfettiParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late Color color;
  late double size;
  late double rotation;
  late double rotationSpeed;
  late bool isCircle;
  final Random random;

  _ConfettiParticle(this.random, double screenWidth, double screenHeight) {
    reset(screenWidth);
    y = random.nextDouble() * -screenHeight; // Começa acima da tela
  }

  void reset(double screenWidth) {
    x = random.nextDouble() * screenWidth;
    y = -20;
    vx = random.nextDouble() * 4 - 2;
    vy = random.nextDouble() * 5 + 2;
    size = random.nextDouble() * 8 + 4;
    rotation = random.nextDouble() * 2 * pi;
    rotationSpeed = random.nextDouble() * 0.2;
    isCircle = random.nextBool();

    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.info,
      AppColors.warning,
      AppColors.badgeBand,
      AppColors.medalGold,
      AppColors.celebrationPink,
    ];
    color = colors[random.nextInt(colors.length)];
  }

  void update(double screenWidth, double screenHeight) {
    x += vx;
    y += vy;
    rotation += rotationSpeed;
    if (y > screenHeight) {
      reset(screenWidth);
    }
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      canvas.save();
      canvas.translate(p.x % size.width, p.y);
      canvas.rotate(p.rotation);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(Rect.fromLTWH(0, 0, p.size, p.size * 0.6), paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
