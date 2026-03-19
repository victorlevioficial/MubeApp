part of 'public_profile_screen.dart';

class _OtherBottomBar extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onChat;

  const _OtherBottomBar({required this.onShare, required this.onChat});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBottomActionButton(
          icon: Icons.share_outlined,
          onPressed: onShare,
          tooltip: 'Compartilhar perfil',
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _PrimaryBottomActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Iniciar Conversa',
            onPressed: onChat,
          ),
        ),
      ],
    );
  }
}

class _IconBottomActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _IconBottomActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 56,
        height: 56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface2,
            side: const BorderSide(color: AppColors.surfaceHighlight),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.all20),
            padding: EdgeInsets.zero,
          ),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

class _PrimaryBottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryBottomActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryPressed],
          ),
          borderRadius: AppRadius.all20,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: AppRadius.all20,
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Text(label, style: AppTypography.buttonPrimary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeBottomBar extends StatelessWidget {
  final AppUser user;

  const _MeBottomBar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (user.tipoPerfil == AppUserType.band) ...[
          _SecondaryBottomActionButton(
            icon: Icons.people_rounded,
            label: 'Gerenciar Integrantes',
            onPressed: () => context.push(RoutePaths.manageMembers),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        _PrimaryBottomActionButton(
          icon: Icons.edit_rounded,
          label: 'Editar Perfil',
          onPressed: () => context.push(RoutePaths.profileEdit),
        ),
      ],
    );
  }
}

class _SecondaryBottomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SecondaryBottomActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface2,
          side: const BorderSide(color: AppColors.surfaceHighlight),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.all20),
          textStyle: AppTypography.buttonSecondary,
        ),
      ),
    );
  }
}
