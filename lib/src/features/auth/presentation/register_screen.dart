import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/buttons/app_social_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/components/patterns/or_divider.dart';
import '../../../design_system/foundations/tokens/app_assets.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/auth_exception_handler.dart';
import 'register_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      await ref
          .read(registerControllerProvider.notifier)
          .register(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _signInWithGoogle() {
    if (ref.read(registerControllerProvider).isLoading) return;
    unawaited(ref.read(registerControllerProvider.notifier).signInWithGoogle());
  }

  void _signInWithApple() {
    if (ref.read(registerControllerProvider).isLoading) return;
    unawaited(ref.read(registerControllerProvider.notifier).signInWithApple());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(registerControllerProvider, (prev, next) {
      if (next.hasError && !(prev?.hasError ?? false)) {
        final message = AuthExceptionHandler.handleException(next.error!);
        if (context.mounted) {
          AppSnackBar.show(context, message, isError: true);
        }
      }
    });

    final state = ref.watch(registerControllerProvider);

    return Scaffold(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _RegisterHeader(),
                      const SizedBox(height: AppSpacing.s48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            fieldKey: const Key('register_email_input'),
                            controller: _emailController,
                            label: 'E-mail',
                            hint: 'seu@email.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                            ),
                            validator: (v) => v != null && v.isNotEmpty
                                ? null
                                : 'E-mail obrigatório',
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          AppTextField(
                            fieldKey: const Key('register_password_input'),
                            controller: _passwordController,
                            label: 'Senha',
                            hint: '••••••••',
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            validator: (v) => v != null && v.length >= 6
                                ? null
                                : 'Mínimo 6 caracteres',
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          AppTextField(
                            fieldKey: const Key(
                              'register_confirm_password_input',
                            ),
                            controller: _confirmPasswordController,
                            label: 'Confirmar Senha',
                            hint: '••••••••',
                            obscureText: !_isConfirmPasswordVisible,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            onToggleVisibility: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                            validator: (v) => v == _passwordController.text
                                ? null
                                : 'As senhas não conferem',
                          ),
                          const SizedBox(height: AppSpacing.s32),
                          SizedBox(
                            height: 56,
                            child: Semantics(
                              button: true,
                              label: 'Cadastrar conta',
                              child: AppButton.primary(
                                key: const Key('register_button'),
                                text: 'Cadastrar',
                                size: AppButtonSize.large,
                                isLoading: state.isLoading,
                                onPressed: _submit,
                                isFullWidth: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Padding(
                            padding: AppSpacing.h16,
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Ao criar sua conta, você concorda com nossos\n',
                                  ),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GestureDetector(
                                      onTap: () => context.push(
                                        '${RoutePaths.legal}/termsOfUse',
                                      ),
                                      child: Text(
                                        'Termos de Uso',
                                        style: AppTypography.link.copyWith(
                                          fontSize: 12,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: ' e '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: GestureDetector(
                                      onTap: () => context.push(
                                        '${RoutePaths.legal}/privacyPolicy',
                                      ),
                                      child: Text(
                                        'Política de Privacidade',
                                        style: AppTypography.link.copyWith(
                                          fontSize: 12,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s32),
                      const OrDivider(text: 'Ou cadastre-se com'),
                      const SizedBox(height: AppSpacing.s32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SocialLoginButton(
                            key: const Key('google_register_button'),
                            type: SocialType.google,
                            onPressed: _signInWithGoogle,
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          SocialLoginButton(
                            key: const Key('apple_register_button'),
                            type: SocialType.apple,
                            onPressed: _signInWithApple,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s48),
                      const _LoginLink(),
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

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader();

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
        Text(
          'Criar Conta',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 32,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Entre para a comunidade da música',
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

class _LoginLink extends StatelessWidget {
  const _LoginLink();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            'Já tem uma conta? ',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              'Entrar',
              key: const Key('login_link'),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
