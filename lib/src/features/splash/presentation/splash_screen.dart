import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../../../design_system/foundations/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Remove the native splash (Icon) immediately as this screen loads (Logo)
    // This creates the seamless transition.
    FlutterNativeSplash.remove();
    _startSplashTimer();
  }

  void _startSplashTimer() async {
    // Show splash for 1.2 seconds, then navigate.
    // The Router's redirect logic will handle the actual destination
    // (Login if not auth, Feed if auth, etc.) when we try to go to /login.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Rule: width = min(0.70 * screenWidth, 420)
    final logoWidth = min(screenWidth * 0.70, 420.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: logoWidth,
          child: Image.asset(
            'assets/images/logos_png/logo vertical.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
