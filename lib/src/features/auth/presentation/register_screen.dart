import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../common_widgets/or_divider.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/responsive_center.dart';
import '../../../common_widgets/social_login_button.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../../utils/auth_exception_handler.dart';
import 'register_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  // bool _isLoading = false; // Removed in favor of controller state
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Dismiss keyboard
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

  @override
  Widget build(BuildContext context) {
    // Listen for errors
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
      // backgroundColor: Theme default,
      // AppBar removed as requested
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxContentWidth: 600,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s32,
          ).copyWith(top: 80),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SvgPicture.asset(
                    'assets/images/logos_svg/logo horizontal.svg',
                    height: 50,
                    fit: BoxFit.scaleDown,
                    placeholderBuilder: (context) => const SizedBox(height: 50),
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                Text(
                  'Criar Conta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Entre para a comunidade da música',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: AppSpacing.s32),

                AppTextField(
                  fieldKey: const Key('register_email_input'),
                  controller: _emailController,
                  label: 'E-mail',
                  hint: 'seu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v != null && v.isNotEmpty ? null : 'E-mail obrigatório',
                ),
                const SizedBox(height: 16),

                AppTextField(
                  fieldKey: const Key('register_password_input'),
                  controller: _passwordController,
                  label: 'Senha',
                  hint: '••••••••',
                  obscureText: !_isPasswordVisible,
                  onToggleVisibility: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                  validator: (v) =>
                      v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
                ),
                const SizedBox(height: AppSpacing.s16),

                AppTextField(
                  fieldKey: const Key('register_confirm_password_input'),
                  controller: _confirmPasswordController,
                  label: 'Confirmar Senha',
                  hint: '••••••••',
                  obscureText: !_isConfirmPasswordVisible,
                  onToggleVisibility: () => setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                  validator: (v) => v == _passwordController.text
                      ? null
                      : 'As senhas não conferem',
                ),

                const SizedBox(height: AppSpacing.s32),

                SizedBox(
                  height: 56,
                  child: PrimaryButton(
                    key: const Key('register_button'),
                    text: 'Cadastrar',
                    isLoading: state.isLoading,
                    onPressed: _submit,
                  ),
                ),

                const SizedBox(height: AppSpacing.s32),

                // DIVIDER
                const OrDivider(text: 'Ou cadastre-se com'),

                const SizedBox(height: AppSpacing.s32),

                // SOCIAL BUTTONS
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SocialLoginButton(
                      key: const Key('google_register_button'),
                      type: SocialType.google,
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    SocialLoginButton(
                      key: const Key('apple_register_button'),
                      type: SocialType.apple,
                      onPressed: () {},
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
