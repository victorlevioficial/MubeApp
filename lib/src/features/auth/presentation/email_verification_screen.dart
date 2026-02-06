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
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../data/auth_repository.dart';

part 'email_verification_screen.g.dart';

/// State class for email verification with cooldown and polling info
class EmailVerificationState {
  final bool isLoading;
  final String? error;
  final int resendCooldownSeconds;
  final int nextPollSeconds;
  final bool isVerified;
  final int verificationTimeSeconds;

  const EmailVerificationState({
    this.isLoading = false,
    this.error,
    this.resendCooldownSeconds = 0,
    this.nextPollSeconds = 0,
    this.isVerified = false,
    this.verificationTimeSeconds = 0,
  });

  EmailVerificationState copyWith({
    bool? isLoading,
    String? error,
    int? resendCooldownSeconds,
    int? nextPollSeconds,
    bool? isVerified,
    int? verificationTimeSeconds,
  }) {
    return EmailVerificationState(
      isLoading: isLoading ?? this.isLoading,
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
      final isVerified = await ref
          .read(authRepositoryProvider)
          .isEmailVerified();
      if (isVerified) {
        _checkTimer?.cancel();
        _verificationStopwatch.stop();
        state = state.copyWith(
          isVerified: true,
          verificationTimeSeconds: _verificationStopwatch.elapsed.inSeconds,
        );
      }
    } catch (e) {
      debugPrint('Silent email verification check failed: $e');
    }
  }

  Future<void> checkVerificationStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Reset polling to be more aggressive when user clicks
      _currentIntervalIndex = 0;

      final isVerified = await ref
          .read(authRepositoryProvider)
          .isEmailVerified();
      if (isVerified) {
        _checkTimer?.cancel();
        _verificationStopwatch.stop();
        state = state.copyWith(
          isLoading: false,
          isVerified: true,
          verificationTimeSeconds: _verificationStopwatch.elapsed.inSeconds,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error:
              'Email ainda não verificado. Verifique sua caixa de entrada e spam.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        state = state.copyWith(
          isLoading: false,
          error: 'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e.message ?? 'Erro ao verificar email. Tente novamente.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao verificar email: $e',
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    // Don't allow resend if in cooldown
    if (state.resendCooldownSeconds > 0) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ref
          .read(authRepositoryProvider)
          .sendEmailVerification();

      result.fold(
        (failure) {
          state = state.copyWith(isLoading: false, error: failure.message);
        },
        (success) {
          // Start 60 second cooldown
          state = state.copyWith(isLoading: false, resendCooldownSeconds: 60);

          // Reset polling to be more aggressive after resend
          _currentIntervalIndex = 0;
          _scheduleNextPoll();
        },
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        state = state.copyWith(
          isLoading: false,
          error: 'Muitas tentativas de envio. Aguarde alguns minutos.',
          resendCooldownSeconds: 120, // Longer cooldown on rate limit
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: e.message ?? 'Erro ao enviar email. Tente novamente.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final state = ref.watch(emailVerificationControllerProvider);

    // Listen for errors and show snackbar
    ref.listen<EmailVerificationState>(emailVerificationControllerProvider, (
      previous,
      next,
    ) {
      if (next.error != null && previous?.error != next.error) {
        if (context.mounted) {
          AppSnackBar.show(context, next.error!, isError: true);
        }
      }
    });

    // Navigate when verified
    ref.listen<EmailVerificationState>(emailVerificationControllerProvider, (
      previous,
      next,
    ) {
      if (next.isVerified && !(previous?.isVerified ?? false)) {
        if (context.mounted) {
          context.go('/onboarding');
        }
      }
    });

    final user = ref.watch(authRepositoryProvider).currentUser;
    final email = user?.email ?? 'seu email';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxContentWidth: 600,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Column(
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logos_svg/logo horizontal.svg',
                        height: AppSpacing.s48,
                        fit: BoxFit.scaleDown,
                        placeholderBuilder: (context) =>
                            const SizedBox(
                              height: AppSpacing.s48,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s32),

                    // Animated Email Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.all24,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_outlined,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),

                    Text(
                      'Verifique seu email',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineCompact.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    Text(
                      'Enviamos um link de verificação para',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: AppTypography.titleSmall.fontWeight,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),

                    Text(
                      'Clique no link no email para verificar sua conta e continuar.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s40),

                // INFO BOX
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: AppRadius.all12,
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.s8),
                          Expanded(
                            child: Text(
                              'Não recebeu o email?',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        'Verifique sua pasta de spam ou lixo eletrônico. Se não encontrar, você pode solicitar um novo email.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.s32),

                // Success message when email was resent
                if (state.resendCooldownSeconds > 0 &&
                    state.resendCooldownSeconds >= 55) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.all12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.s8),
                        Expanded(
                          child: Text(
                            'Email reenviado com sucesso!',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                ],

                // RESEND BUTTON with cooldown
                SizedBox(
                  height: 56,
                  child: AppButton.primary(
                    text: state.resendCooldownSeconds > 0
                        ? 'Reenviar em ${state.resendCooldownSeconds}s'
                        : 'Reenviar email',
                    isLoading: state.isLoading,
                    onPressed:
                        state.isLoading || state.resendCooldownSeconds > 0
                        ? null
                        : () {
                            ref
                                .read(
                                  emailVerificationControllerProvider.notifier,
                                )
                                .resendVerificationEmail();
                          },
                  ),
                ),

                const SizedBox(height: AppSpacing.s16),

                // CHECK BUTTON
                SizedBox(
                  height: 56,
                  child: AppButton.secondary(
                    text: 'Já verifiquei meu email',
                    isLoading: state.isLoading,
                    onPressed: state.isLoading
                        ? null
                        : () {
                            ref
                                .read(
                                  emailVerificationControllerProvider.notifier,
                                )
                                .checkVerificationStatus();
                          },
                  ),
                ),

                const SizedBox(height: AppSpacing.s24),

                // LOGOUT OPTION
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: Text(
                      'Sair e usar outra conta',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
