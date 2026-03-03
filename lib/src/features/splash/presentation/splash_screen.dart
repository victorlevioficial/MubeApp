import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/foundations/tokens/app_colors.dart';
import '../providers/app_bootstrap_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapApp());
    });
  }

  Future<void> _bootstrapApp() async {
    await ref.read(appBootstrapProvider.notifier).start();
    if (!mounted) return;
    // Keep splash route only as a bootstrap gate; no extra visual delay.
    ref.read(splashFinishedProvider.notifier).finish();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.background);
  }
}
