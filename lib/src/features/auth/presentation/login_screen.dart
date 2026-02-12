import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/typedefs.dart';
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
import '../../../utils/auth_exception_handler.dart';
import '../data/auth_repository.dart';

part 'login_screen.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() {
    // initial state is void (null)
  }

  Future<void> login({required String email, required String password}) async {
    await _runAuthAction(
      action: () => ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email, password),
    );
  }

  Future<void> signInWithGoogle() async {
    await _runAuthAction(
      action: () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> signInWithApple() async {
    await _runAuthAction(
      action: () => ref.read(authRepositoryProvider).signInWithApple(),
    );
  }

  Future<void> _runAuthAction({
    required FutureResult<Unit> Function() action,
  }) async {
    state = const AsyncLoading();
    final result = await action();

    result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
      },
      (success) {
        state = const AsyncData(null);
      },
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(loginControllerProvider.notifier)
          .login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
    }
  }

  void _signInWithGoogle() {
    if (ref.read(loginControllerProvider).isLoading) return;
    unawaited(ref.read(loginControllerProvider.notifier).signInWithGoogle());
  }

  void _signInWithApple() {
    if (ref.read(loginControllerProvider).isLoading) return;
    unawaited(ref.read(loginControllerProvider.notifier).signInWithApple());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      if (next.hasError && !(previous?.hasError ?? false)) {
        final message = AuthExceptionHandler.handleException(next.error!);
        if (context.mounted) {
          AppSnackBar.show(context, message, isError: true);
        }
      }
    });

    final state = ref.watch(loginControllerProvider);

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
                      const _LoginHeader(),
                      const SizedBox(height: AppSpacing.s48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            fieldKey: const Key('email_input'),
                            controller: _emailController,
                            label: 'E-mail',
                            hint: 'seu@email.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              size: 20,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Digite seu e-mail';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.s24),
                          AppTextField(
                            fieldKey: const Key('password_input'),
                            controller: _passwordController,
                            label: 'Senha',
                            hint: '••••••••',
                            obscureText: !_isPasswordVisible,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              size: 20,
                            ),
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => context.push('/forgot-password'),
                              child: Text(
                                'Esqueceu a senha?',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s32),
                          SizedBox(
                            height: 56,
                            child: Semantics(
                              button: true,
                              label: 'Entrar na conta',
                              child: AppButton.primary(
                                key: const Key('login_button'),
                                text: 'Entrar',
                                size: AppButtonSize.large,
                                isLoading: state.isLoading,
                                onPressed: _submit,
                                isFullWidth: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s32),
                      const OrDivider(text: 'Ou entre com'),
                      const SizedBox(height: AppSpacing.s32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SocialLoginButton(
                            key: const Key('google_login_button'),
                            type: SocialType.google,
                            onPressed: _signInWithGoogle,
                          ),
                          const SizedBox(height: AppSpacing.s16),
                          SocialLoginButton(
                            key: const Key('apple_login_button'),
                            type: SocialType.apple,
                            onPressed: _signInWithApple,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s48),
                      const _RegisterLink(),
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

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

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
          'Bem-vindo de volta',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge.copyWith(
            fontSize: 32,
            letterSpacing: -1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'Entre para gerenciar sua carreira musical',
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

class _RegisterLink extends StatelessWidget {
  const _RegisterLink();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            'Não tem uma conta? ',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/register'),
            child: Text(
              'Crie agora',
              key: const Key('register_link'),
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
