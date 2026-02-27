import 'package:flutter/material.dart';

enum FadeInSlideDirection {
  ttb, // top to bottom
  btt, // bottom to top
  ltr, // left to right
  rtl, // right to left
}

class FadeInSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final FadeInSlideDirection direction;

  const FadeInSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.offset = 20.0,
    this.direction = FadeInSlideDirection.rtl,
  });

  @override
  State<FadeInSlide> createState() => _FadeInSlideState();
}

class _FadeInSlideState extends State<FadeInSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _translate = Tween<double>(
      begin: widget.offset,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: AnimatedBuilder(
        animation: _translate,
        child: widget.child,
        builder: (context, child) {
          final value = _translate.value;
          Offset offset;

          switch (widget.direction) {
            case FadeInSlideDirection.ttb:
              offset = Offset(0, -value);
            case FadeInSlideDirection.btt:
              offset = Offset(0, value);
            case FadeInSlideDirection.ltr:
              offset = Offset(-value, 0);
            case FadeInSlideDirection.rtl:
              offset = Offset(value, 0);
          }

          return Transform.translate(offset: offset, child: child);
        },
      ),
    );
  }
}
