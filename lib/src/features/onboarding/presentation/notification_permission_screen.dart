import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/foundations/tokens/app_assets.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';

class NotificationPermissionScreen extends StatefulWidget {
  const NotificationPermissionScreen({super.key});

  @override
  State<NotificationPermissionScreen> createState() =>
      _NotificationPermissionScreenState();
}

class _NotificationPermissionScreenState
    extends State<NotificationPermissionScreen>
    with SingleTickerProviderStateMixin {
  static const String _permissionShownKey = 'notification_permission_shown';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionShownKey, true);
  }

  Future<void> _handleAccept() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _markPermissionPromptAsShown();
      await PushNotificationService().init();
    } catch (error) {
      debugPrint('Error handling notification permission: $error');
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
    } catch (error) {
      debugPrint('Error skipping notification permission: $error');
    } finally {
      if (mounted) {
        context.go(RoutePaths.feed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ResponsiveCenter(
            maxContentWidth: 480,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s24,
              vertical: AppSpacing.s48,
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
                    const SizedBox(height: AppSpacing.s40),
                    const _BenefitsCard(),
                    const SizedBox(height: AppSpacing.s32),
                    SizedBox(
                      height: 56,
                      child: Semantics(
                        button: true,
                        label: 'Ativar notificações',
                        child: AppButton.primary(
                          text: 'Ativar notificações',
                          size: AppButtonSize.large,
                          isLoading: _isLoading,
                          onPressed: _handleAccept,
                          isFullWidth: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    Center(
                      child: GestureDetector(
                        onTap: _isLoading ? null : _handleSkip,
                        child: Text(
                          'Agora não',
                          style: AppTypography.bodyMedium.copyWith(
                            color: _isLoading
                                ? AppColors.textTertiary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: SvgPicture.asset(
            AppAssets.logoHorizontalSvg,
            height: 40,
            fit: BoxFit.contain,
            placeholderBuilder: (context) =>
                const SizedBox(height: 40, width: 120),
          ),
        ),
        const SizedBox(height: AppSpacing.s32),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: AppColors.primaryMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            size: 52,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        Text(
          'Fique por dentro de tudo',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 32,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Ative as notificações para acompanhar mensagens, convites e novos matches.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard();

  static const _benefits = [
    _BenefitData(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Mensagens no chat',
      subtitle: 'Responda produtores e músicos rapidamente.',
    ),
    _BenefitData(
      icon: Icons.group_add_outlined,
      title: 'Convites para bandas',
      subtitle: 'Receba convites assim que forem enviados.',
    ),
    _BenefitData(
      icon: Icons.music_note_rounded,
      title: 'Novos matches musicais',
      subtitle: 'Descubra oportunidades no momento certo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < _benefits.length; index++) ...[
            _BenefitItem(data: _benefits[index]),
            if (index < _benefits.length - 1) ...[
              const SizedBox(height: AppSpacing.s16),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.s16),
            ],
          ],
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.data});

  final _BenefitData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: AppRadius.all12,
          ),
          child: Icon(data.icon, size: 22, color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.title,
                style: AppTypography.titleMedium.copyWith(height: 1.3),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                data.subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BenefitData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BenefitData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}
