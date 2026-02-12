import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/components/navigation/responsive_center.dart';
import '../../../design_system/foundations/tokens/app_assets.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../utils/auth_exception_handler.dart';
import '../data/auth_repository.dart';

part 'forgot_password_screen.g.dart';

@riverpod
class ForgotPasswordController extends _$ForgotPasswordController {
  @override
  FutureOr<void> build() {
    // initial state is void (null)
  }

  Future<void> sendResetEmail({required String email}) async {
    state = const AsyncLoading();
    final result = await ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email);

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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(forgotPasswordControllerProvider.notifier)
          .sendResetEmail(email: _emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    ref.listen<AsyncValue<void>>(forgotPasswordControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError && !(previous?.hasError ?? false)) {
        final message = AuthExceptionHandler.handleException(next.error!);
        if (context.mounted) {
          AppSnackBar.show(context, message, isError: true);
        }
      }

      if (next.hasValue && previous?.isLoading == true) {
        setState(() {
          _emailSent = true;
        });
      }
    });

    final state = ref.watch(forgotPasswordControllerProvider);

    return Scaffold(
      appBar: const AppAppBar(
        title: SizedBox.shrink(),
        backgroundColor: AppColors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: ResponsiveCenter(
          maxContentWidth: 600,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s32,
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
                        AppAssets.logoHorizontalSvg,
                        height: AppSpacing.s48,
                        fit: BoxFit.scaleDown,
                        placeholderBuilder: (context) =>
                            const SizedBox(height: AppSpacing.s48),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    Text(
                      'Recuperar senha',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineCompact.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      _emailSent
                          ? 'Verifique seu e-mail para redefinir sua senha'
                          : 'Digite seu e-mail para receber um link de recuperação',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.s32),

                if (!_emailSent) ...[
                  // EMAIL INPUT
                  AppTextField(
                    fieldKey: const Key('forgot_password_email_input'),
                    controller: _emailController,
                    label: 'E-mail',
                    hint: 'seu@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'E-mail inválido'
                        : null,
                  ),

                  const SizedBox(height: AppSpacing.s32),

                  // BUTTON "ENVIAR"
                  SizedBox(
                    height: 56,
                    child: Semantics(
                      button: true,
                      label: 'Enviar link de recuperação',
                      child: AppButton.primary(
                        key: const Key('forgot_password_button'),
                        text: 'Enviar link',
                        isLoading: state.isLoading,
                        onPressed: _submit,
                      ),
                    ),
                  ),
                ] else ...[
                  // SUCCESS STATE
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s24),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.all12,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: AppColors.success,
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        Text(
                          'E-mail enviado!',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.success,
                            fontWeight: AppTypography.buttonPrimary.fontWeight,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.s32),

                  // BUTTON "VOLTAR PARA LOGIN"
                  SizedBox(
                    height: 56,
                    child: AppButton.secondary(
                      key: const Key('back_to_login_button'),
                      text: 'Voltar para o login',
                      onPressed: () => context.go('/login'),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
