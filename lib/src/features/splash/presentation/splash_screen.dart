import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../providers/app_bootstrap_provider.dart';
import '../providers/splash_provider.dart';
import 'splash_feed_render_tracking.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _timeoutDuration = Duration(seconds: 10);

  Timer? _timeoutTimer;
  bool _showFallback = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    startSplashToFeedRenderTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBootstrap();
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startBootstrap() {
    _cancelTimeout();
    _startTimeout();
    unawaited(_bootstrapApp());
  }

  void _startTimeout() {
    _timeoutTimer = Timer(_timeoutDuration, _onTimeout);
  }

  void _cancelTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  void _onTimeout() {
    if (!mounted) return;
    setState(() => _showFallback = true);
  }

  Future<void> _bootstrapApp() async {
    await ref.read(appBootstrapProvider.notifier).start();
    if (!mounted) return;
    _finishSplash();
  }

  void _finishSplash() {
    _cancelTimeout();
    if (!mounted) return;
    ref.read(splashFinishedProvider.notifier).finish();
  }

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
      _showFallback = false;
    });

    _cancelTimeout();
    _startTimeout();

    try {
      // Invalidate profile to force refetch.
      ref.invalidate(currentUserProfileProvider);
      await ref.read(appBootstrapProvider.notifier).start();
      if (!mounted) return;

      // Only finish if bootstrap actually completed.
      final bootstrapState = ref.read(appBootstrapProvider);
      if (bootstrapState == AppBootstrapState.ready) {
        _finishSplash();
      }
      // If bootstrap is still running (start() was a no-op because
      // _isStarting was true), do NOT finish — let the timeout handle it.
    } catch (_) {
      if (!mounted) return;
      setState(() => _showFallback = true);
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  Future<void> _signOutAndExit() async {
    _cancelTimeout();
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    // After sign-out, the auth guard will redirect to login.
    ref.read(splashFinishedProvider.notifier).finish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: _showFallback ? _buildFallbackUI() : _buildSplashLogo(),
      ),
    );
  }

  Widget _buildSplashLogo() {
    return const Image(
      image: AssetImage(
        'assets/images/logos_png/logo_vertical_splash_small.png',
      ),
      width: 164,
      fit: BoxFit.contain,
    );
  }

  Widget _buildFallbackUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Image(
            image: AssetImage(
              'assets/images/logos_png/logo_vertical_splash_small.png',
            ),
            width: 120,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'O app está demorando mais que o esperado.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          AppButton.primary(
            text: 'Tentar novamente',
            onPressed: _isRetrying ? null : _retry,
            isLoading: _isRetrying,
            isFullWidth: true,
          ),
          const SizedBox(height: AppSpacing.s12),
          AppButton.outline(
            text: 'Sair',
            onPressed: _signOutAndExit,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
