import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/foundations/tokens/app_assets.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_logger.dart';
import '../data/auth_repository.dart';

part 'email_verification_screen.g.dart';
part 'email_verification_screen_ui.dart';

/// State class for email verification with cooldown and polling info
class EmailVerificationState {
  final bool isChecking;
  final bool isResending;
  final String? error;
  final int resendCooldownSeconds;
  final int nextPollSeconds;
  final bool isVerified;
  final int verificationTimeSeconds;

  const EmailVerificationState({
    this.isChecking = false,
    this.isResending = false,
    this.error,
    this.resendCooldownSeconds = 0,
    this.nextPollSeconds = 0,
    this.isVerified = false,
    this.verificationTimeSeconds = 0,
  });

  EmailVerificationState copyWith({
    bool? isChecking,
    bool? isResending,
    String? error,
    int? resendCooldownSeconds,
    int? nextPollSeconds,
    bool? isVerified,
    int? verificationTimeSeconds,
  }) {
    return EmailVerificationState(
      isChecking: isChecking ?? this.isChecking,
      isResending: isResending ?? this.isResending,
      error: error,
      resendCooldownSeconds:
          resendCooldownSeconds ?? this.resendCooldownSeconds,
      nextPollSeconds: nextPollSeconds ?? this.nextPollSeconds,
      isVerified: isVerified ?? this.isVerified,
      verificationTimeSeconds:
          verificationTimeSeconds ?? this.verificationTimeSeconds,
    );
  }
}

@riverpod
class EmailVerificationController extends _$EmailVerificationController {
  Timer? _checkTimer;
  Timer? _cooldownTimer;
  Timer? _countdownTimer;
  final Stopwatch _verificationStopwatch = Stopwatch();

  // Backoff configuration: 3s → 5s → 10s → 30s (max)
  static const List<int> _pollIntervals = [3, 5, 10, 30];
  int _currentIntervalIndex = 0;

  @override
  EmailVerificationState build() {
    _verificationStopwatch.start();
    _startSmartPolling();

    ref.onDispose(() {
      _checkTimer?.cancel();
      _cooldownTimer?.cancel();
      _countdownTimer?.cancel();
      _verificationStopwatch.stop();
    });

    return const EmailVerificationState(nextPollSeconds: 3);
  }

  void _startSmartPolling() {
    _scheduleNextPoll();
    _startCountdownTimer();
  }

  void _scheduleNextPoll() {
    _checkTimer?.cancel();
    final interval = _pollIntervals[_currentIntervalIndex];

    _checkTimer = Timer(Duration(seconds: interval), () async {
      await _silentCheckVerificationStatus();

      // Increase interval for next poll (backoff)
      if (_currentIntervalIndex < _pollIntervals.length - 1) {
        _currentIntervalIndex++;
      }

      // Schedule next poll if not verified
      if (!state.isVerified) {
        _scheduleNextPoll();
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final currentCooldown = state.resendCooldownSeconds;
      if (currentCooldown > 0) {
        state = state.copyWith(resendCooldownSeconds: currentCooldown - 1);
      }
    });
  }

  /// Silent check that doesn't show loading state (for background polling)
  Future<void> _silentCheckVerificationStatus() async {
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final isEmailVerified = await authRepository.isEmailVerified();
      if (isEmailVerified) {
        // Mantém validação por claim como melhor esforço sem bloquear navegação.
        final isTokenSynced = await authRepository
            .hasVerifiedEmailTokenClaim(forceRefresh: true)
            .catchError((_) => false);
        if (!isTokenSynced) {
          AppLogger.debug(
            'Email verificado no Auth; claim ainda sincronizando. Continuando fluxo.',
          );
        }

        _checkTimer?.cancel();
        _verificationStopwatch.stop();

        // Force provider to emit updated value so guard sees emailVerified == true
        ref.invalidate(authStateChangesProvider);

        state = state.copyWith(
          isVerified: true,
          verificationTimeSeconds: _verificationStopwatch.elapsed.inSeconds,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.warning(
        'Silent email verification check failed',
        e,
        stackTrace,
      );
    }
  }

  Future<void> checkVerificationStatus() async {
    state = state.copyWith(isChecking: true, error: null);
    try {
      // Reset polling to be more aggressive when user clicks
      _currentIntervalIndex = 0;

      final authRepository = ref.read(authRepositoryProvider);
      final isEmailVerified = await authRepository.isEmailVerified();
      if (isEmailVerified) {
        final isTokenSynced = await authRepository
            .hasVerifiedEmailTokenClaim(forceRefresh: true)
            .catchError((_) => false);
        if (!isTokenSynced) {
          AppLogger.debug(
            'Claim email_verified ainda não sincronizou, mas o e-mail já está verificado.',
          );
        }

        _checkTimer?.cancel();
        _verificationStopwatch.stop();

        // Force provider to emit updated value so guard sees emailVerified == true
        ref.invalidate(authStateChangesProvider);

        state = state.copyWith(
          isChecking: false,
          isVerified: true,
          verificationTimeSeconds: _verificationStopwatch.elapsed.inSeconds,
        );
      } else {
        state = state.copyWith(
          isChecking: false,
          error:
              'Email ainda não verificado. Verifique sua caixa de entrada e spam.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        state = state.copyWith(
          isChecking: false,
          error: 'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
        );
      } else {
        state = state.copyWith(
          isChecking: false,
          error: e.message ?? 'Erro ao verificar email. Tente novamente.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: 'Erro ao verificar email: $e',
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    // Don't allow resend if in cooldown
    if (state.resendCooldownSeconds > 0 || state.isResending) return;

    state = state.copyWith(isResending: true, error: null);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .sendEmailVerification();

      result.fold(
        (failure) {
          state = state.copyWith(isResending: false, error: failure.message);
        },
        (success) {
          // Start 60 second cooldown
          state = state.copyWith(isResending: false, resendCooldownSeconds: 60);

          // Reset polling to be more aggressive after resend
          _currentIntervalIndex = 0;
          _scheduleNextPoll();
        },
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        state = state.copyWith(
          isResending: false,
          error: 'Muitas tentativas de envio. Aguarde alguns minutos.',
          resendCooldownSeconds: 120, // Longer cooldown on rate limit
        );
      } else {
        state = state.copyWith(
          isResending: false,
          error: e.message ?? 'Erro ao enviar email. Tente novamente.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isResending: false,
        error: 'Erro ao enviar email: $e',
      );
    }
  }
}

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  ProviderSubscription<EmailVerificationState>? _errorSubscription;
  ProviderSubscription<EmailVerificationState>? _verificationSubscription;
  bool _handledVerifiedNavigation = false;

  @override
  void initState() {
    super.initState();
    // Setup pulsing animation for email icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _errorSubscription = ref.listenManual<EmailVerificationState>(
      emailVerificationControllerProvider,
      (previous, next) {
        if (next.error != null && previous?.error != next.error && mounted) {
          AppSnackBar.show(context, next.error!, isError: true);
        }
      },
    );

    _verificationSubscription = ref.listenManual<EmailVerificationState>(
      emailVerificationControllerProvider,
      (previous, next) {
        final becameVerified =
            next.isVerified && !(previous?.isVerified ?? false);
        if (becameVerified) {
          _handleVerifiedNavigation();
        }
      },
    );
  }

  @override
  void dispose() {
    _errorSubscription?.close();
    _verificationSubscription?.close();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleVerifiedNavigation() {
    if (!mounted || _handledVerifiedNavigation) return;
    _handledVerifiedNavigation = true;

    if (_canPopVerificationRoute()) {
      context.pop();
      return;
    }

    final router = GoRouter.of(context);
    final currentPath = router.routerDelegate.currentConfiguration.uri.path;
    if (currentPath != RoutePaths.splash) {
      router.go(RoutePaths.splash);
    }
  }

  void _onResendPressed() {
    ref
        .read(emailVerificationControllerProvider.notifier)
        .resendVerificationEmail();
  }

  void _onCheckPressed() {
    ref
        .read(emailVerificationControllerProvider.notifier)
        .checkVerificationStatus();
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    if (!mounted) return;
    context.go(RoutePaths.login);
  }

  bool _canPopVerificationRoute() {
    return GoRouter.maybeOf(context)?.canPop() ??
        Navigator.maybeOf(context)?.canPop() ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (AppLocalizations.of(context) == null) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(emailVerificationControllerProvider);
    final user = ref.watch(authRepositoryProvider).currentUser;
    final email = user?.email ?? 'seu email';

    return PopScope(
      canPop: _canPopVerificationRoute(),
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        body: _buildVerificationBody(state: state, email: email),
      ),
    );
  }
}
