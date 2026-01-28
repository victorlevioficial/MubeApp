import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
import '../data/auth_repository.dart';

part 'login_screen.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<void> build() {
    // initial state is void (null)
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .signInWithEmailAndPassword(email, password);

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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false; // Add state for visibility toggle

  @override
  void initState() {
    super.initState();
    // [TEST FIX] Ensure clean state. If user navigates here despite being logged in, force logout.
    // This handles test runner state leakage where session persists between tests.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        debugPrint(
          'LoginScreen: User already logged in. Forcing logout for clean state.',
        );
        ref.read(authRepositoryProvider).signOut();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(loginControllerProvider, (previous, next) {
      // Only show error if this is a NEW error (not a stale one from before)
      // This prevents duplicate snackbars when widget rebuilds
      if (next.hasError && !(previous?.hasError ?? false)) {
        final message = AuthExceptionHandler.handleException(next.error!);
        debugPrint('LOGIN ERROR CAUGHT: $message (Original: ${next.error})');
        // Double check we're still on screen before showing snackbar
        if (context.mounted) {
          AppSnackBar.show(context, message, isError: true);
        }
      }
    });

    final state = ref.watch(loginControllerProvider);

    return Scaffold(
      // backgroundColor: Theme default,
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Column(
                  children: [
                    Center(
                      child: SvgPicture.asset(
                        'assets/images/logos_svg/logo horizontal.svg',
                        height: 50, // Reduced size
                        fit: BoxFit.scaleDown,
                        placeholderBuilder: (context) =>
                            const SizedBox(height: 50),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.s24),
                    Text(
                      'Bem-vindo de volta',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize:
                                24, // Override to match verified preference
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(
                      height: AppSpacing.s8,
                    ), // Title -> 8px -> Subtitle
                    Text(
                      'Entre para gerenciar sua carreira musical',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: AppSpacing
                      .s32, // Adjusted from s40 to s32 as per spacing scale
                ), // Subtitle -> 32px -> Form
                // INPUTS
                AppTextField(
                  fieldKey: const Key('email_input'),
                  controller: _emailController,
                  label: 'E-mail',
                  hint: 'seu@email.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'E-mail inválido'
                      : null,
                ),

                const SizedBox(height: AppSpacing.s24),

                AppTextField(
                  fieldKey: const Key('password_input'),
                  controller: _passwordController,
                  label: 'Senha',
                  hint: '••••••••',
                  obscureText: !_isPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: (value) => value == null || value.length < 6
                      ? 'Mínimo 6 caracteres'
                      : null,
                ),

                const SizedBox(height: AppSpacing.s16),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Esqueceu a senha?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.s32),

                // BUTTON "ENTRAR"
                SizedBox(
                  height: 56, // Fixed Height
                  child: Semantics(
                    button: true,
                    label: 'Entrar na conta',
                    child: PrimaryButton(
                      key: const Key('login_button'),
                      text: 'Entrar',
                      isLoading: state.isLoading,
                      onPressed: _submit,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.s32),

                // DIVIDER
                const OrDivider(text: 'Ou entre com'),

                const SizedBox(height: AppSpacing.s32),

                // SOCIAL BUTTONS (Using new Component)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SocialLoginButton(
                      key: const Key('google_login_button'),
                      type: SocialType.google,
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    SocialLoginButton(
                      key: const Key('apple_login_button'),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
