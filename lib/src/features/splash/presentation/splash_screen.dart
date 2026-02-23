import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/foundations/tokens/app_assets.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../providers/splash_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
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
    // Show splash for 1.2 seconds, then allow navigation.
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      debugPrint('SplashScreen: Timer finished, updating provider');
      ref.read(splashFinishedProvider.notifier).finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Tamanho bem mais contido e moderno (30% da tela, com um máximo de 100px)
    final logoWidth = min(screenWidth * 0.25, 100.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: GestureDetector(
          key: const Key('splash_logo'),
          onTap: () {
            if (kDebugMode) {
              debugPrint('Splash skipped by tap');
              ref.read(splashFinishedProvider.notifier).finish();
            }
          },
          child: SizedBox(
            width: logoWidth,
            child: Image.asset(AppAssets.logoVerticalPng, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
