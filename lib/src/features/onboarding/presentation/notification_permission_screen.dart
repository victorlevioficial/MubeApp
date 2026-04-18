import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/push_notification_provider.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_logger.dart';
import '../providers/notification_permission_prompt_provider.dart';

class NotificationPermissionScreen extends ConsumerStatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  ConsumerState<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends ConsumerState<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _markPermissionPromptAsShown() async {
    await ref.read(notificationPermissionPromptProvider.notifier).markAsShown();
  }

  Future<void> _handleAccept() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _markPermissionPromptAsShown();
      await ref.read(pushNotificationServiceProvider).init();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to handle notification permission accept flow',
        error,
        stackTrace,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (mounted) {
      context.go(RoutePaths.feed);
    }
  }

  Future<void> _handleSkip() async {
    if (_isLoading) return;

    try {
      await _markPermissionPromptAsShown();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to skip notification permission prompt',
        error,
        stackTrace,
      );
    } finally {
      if (mounted) {
        context.go(RoutePaths.feed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || _isLoading) return;
        unawaited(_handleSkip());
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ResponsiveCenter(
              maxContentWidth: 420,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s24,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _NotificationHeader(),
                      const SizedBox(height: AppSpacing.s24),
                      const _BenefitsList(),
                      const SizedBox(height: AppSpacing.s24),
                      SizedBox(
                        height: 52,
                        child: Semantics(
                          button: true,
                          label: 'Ativar notificações',
                          child: AppButton.primary(
                            text: 'Ativar notificações',
                            size: AppButtonSize.medium,
                            isLoading: _isLoading,
                            onPressed: _handleAccept,
                            isFullWidth: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleSkip,
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.s8),
                            child: Text(
                              'Agora não',
                              style: AppTypography.bodySmall.copyWith(
                                color: _isLoading
                                    ? AppColors.textTertiary
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            size: 36,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(
          'Fique por dentro de tudo',
          textAlign: TextAlign.center,
          style: AppTypography.titleLarge.copyWith(
            fontSize: 22,
            letterSpacing: -0.5,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Ative para receber mensagens, convites e matches.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  static const _benefits = [
    _BenefitData(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Mensagens no chat',
    ),
    _BenefitData(
      icon: Icons.group_add_outlined,
      title: 'Convites para bandas',
    ),
    _BenefitData(
      icon: Icons.music_note_rounded,
      title: 'Novos matches musicais',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < _benefits.length; index++) ...[
          _BenefitItem(data: _benefits[index]),
          if (index < _benefits.length - 1)
            const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.data});

  final _BenefitData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(data.icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            data.title,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitData {
  final IconData icon;
  final String title;

  const _BenefitData({required this.icon, required this.title});
}
