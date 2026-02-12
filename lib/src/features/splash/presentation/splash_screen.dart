import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/foundations/tokens/app_assets.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: initState');
    // Remove the native splash (Icon) immediately as this screen loads (Logo)
    // This creates the seamless transition.
    FlutterNativeSplash.remove();
    _startSplashTimer();
  }

  void _startSplashTimer() async {
    debugPrint('SplashScreen: Starting timer...');
    // Show splash for 1.2 seconds, then navigate.
    // The Router's redirect logic will handle the actual destination
    // (Login if not auth, Feed if auth, etc.) when we try to go to /login.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      debugPrint('SplashScreen: Configuring navigation to /login');
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Aumentado para combinar melhor com a splash nativa
    final logoWidth = min(screenWidth * 0.60, 240.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: GestureDetector(
          key: const Key('splash_logo'),
          onTap: () {
            if (kDebugMode) {
              debugPrint('Splash skipped by tap');
              context.go('/login');
            }
          },
          child: SizedBox(
            width: logoWidth,
            // height: logoWidth, // Removed to allow natural aspect ratio (matches scaleAspectFit)
            child: Image.asset(
              AppAssets.logoVerticalPng,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
