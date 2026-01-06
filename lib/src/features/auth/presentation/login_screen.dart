import 'package:flutter/foundation.dart';
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
import '../../../utils/seed_database.dart';
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
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmailAndPassword(email, password),
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
      if (next.hasError) {
        final message = AuthExceptionHandler.handleException(next.error!);
        AppSnackBar.show(context, message, isError: true);
      }
    });

    final state = ref.watch(loginControllerProvider);

    return Scaffold(
      // backgroundColor: Theme default,
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxContentWidth: 600,
          padding: const EdgeInsets.only(
            top: 80,
            bottom: 32,
            left: 16,
            right: 16,
          ),
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
                  child: PrimaryButton(
                    text: 'Entrar',
                    isLoading: state.isLoading,
                    onPressed: _submit,
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
                      type: SocialType.google,
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    SocialLoginButton(type: SocialType.apple, onPressed: () {}),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/gallery'),
                        child: Text(
                          'Ver Galeria (Debug)',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (kDebugMode)
                        TextButton(
                          onPressed: () async {
                            try {
                              AppSnackBar.show(
                                context,
                                'Testando conexão...',
                                isError: false,
                              );
                              await DatabaseSeeder.testConnection();
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  'Conexão OK!',
                                  isError: false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  'Erro de Conexão: $e',
                                  isError: true,
                                );
                              }
                            }
                          },
                          child: const Text('TESTAR CONEXÃO'),
                        ),
                      if (kDebugMode)
                        TextButton(
                          onPressed: () async {
                            try {
                              AppSnackBar.show(
                                context,
                                'Gerando usuários...',
                                isError: false,
                              );
                              await DatabaseSeeder.seedUsers(count: 50);
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  '50 usuários gerados!',
                                  isError: false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  'Erro no Seed: $e',
                                  isError: true,
                                );
                              }
                            }
                          },
                          child: const Text(
                            'SEED DATABASE (50)',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      if (kDebugMode)
                        TextButton(
                          onPressed: () async {
                            try {
                              AppSnackBar.show(
                                context,
                                'Limpando usuários mock...',
                                isError: false,
                              );
                              await DatabaseSeeder.clearMockUsers();
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  'Limpeza concluída!',
                                  isError: false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                AppSnackBar.show(
                                  context,
                                  'Erro na Limpeza: $e',
                                  isError: true,
                                );
                              }
                            }
                          },
                          child: const Text(
                            'LIMPAR MOCKS',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ),
                    ],
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
