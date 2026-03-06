part of 'email_verification_screen.dart';

extension _EmailVerificationScreenUi on _EmailVerificationScreenState {
  Widget _buildVerificationBody({
    required EmailVerificationState state,
    required String email,
  }) {
    return SafeArea(
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
              _buildVerificationHeader(email),
              const SizedBox(height: AppSpacing.s40),
              _buildInfoBox(),
              const SizedBox(height: AppSpacing.s32),
              if (_shouldShowResendSuccess(state)) ...[
                _buildResendSuccessBanner(),
                const SizedBox(height: AppSpacing.s16),
              ],
              _buildResendButton(state),
              const SizedBox(height: AppSpacing.s16),
              _buildCheckButton(state),
              const SizedBox(height: AppSpacing.s24),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationHeader(String email) {
    return Column(
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
        const SizedBox(height: AppSpacing.s32),
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
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
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
    );
  }

  bool _shouldShowResendSuccess(EmailVerificationState state) {
    return state.resendCooldownSeconds > 0 && state.resendCooldownSeconds >= 55;
  }

  Widget _buildResendSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: AppRadius.all12,
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success),
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
    );
  }

  Widget _buildResendButton(EmailVerificationState state) {
    return SizedBox(
      height: 56,
      child: AppButton.primary(
        text: state.resendCooldownSeconds > 0
            ? 'Reenviar em ${state.resendCooldownSeconds}s'
            : 'Reenviar email',
        isLoading: state.isResending,
        onPressed:
            state.isResending ||
                state.isChecking ||
                state.resendCooldownSeconds > 0
            ? null
            : _onResendPressed,
      ),
    );
  }

  Widget _buildCheckButton(EmailVerificationState state) {
    return SizedBox(
      height: 56,
      child: AppButton.secondary(
        text: 'Já verifiquei meu email',
        isLoading: state.isChecking,
        onPressed: state.isChecking || state.isResending
            ? null
            : _onCheckPressed,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: TextButton(
        onPressed: _signOut,
        child: Text('Sair e usar outra conta', style: AppTypography.link),
      ),
    );
  }
}
