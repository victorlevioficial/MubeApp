part of 'public_profile_screen.dart';

class _OtherBottomBar extends StatelessWidget {
  final VoidCallback onChat;

  const _OtherBottomBar({required this.onChat});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onChat,
        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
        label: const Text('Iniciar Conversa'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.all16),
          textStyle: AppTypography.buttonPrimary,
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.push(RoutePaths.manageMembers),
              icon: const Icon(Icons.people_rounded, size: 18),
              label: const Text('Gerenciar Integrantes'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.all16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(RoutePaths.profileEdit),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Editar Perfil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.all16,
                    ),
                    textStyle: AppTypography.buttonPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
