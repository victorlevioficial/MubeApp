import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../auth/domain/app_user.dart';
import '../../../../profile/presentation/profile_controller.dart';
import '../../services/media_picker_service.dart';

class EditProfileHeader extends ConsumerStatefulWidget {
  final AppUser user;
  final TextEditingController nomeController;

  const EditProfileHeader({
    super.key,
    required this.user,
    required this.nomeController,
  });

  @override
  ConsumerState<EditProfileHeader> createState() => _EditProfileHeaderState();
}

class _EditProfileHeaderState extends ConsumerState<EditProfileHeader> {
  final _mediaPickerService = MediaPickerService();

  @override
  void dispose() {
    _mediaPickerService.dispose();
    super.dispose();
  }

  Future<void> _handlePhotoUpdate() async {
    final controller = ref.read(profileControllerProvider.notifier);

    try {
      final file = await _mediaPickerService.pickAndCropPhoto(
        context,
        lockAspectRatio: true,
      );

      if (file == null || !mounted) return;

      await controller.updateProfileImage(currentUser: widget.user, file: file);

      if (mounted) {
        AppSnackBar.success(context, 'Foto de perfil atualizada!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao atualizar foto: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _handlePhotoUpdate,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textPrimary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        backgroundImage: widget.user.foto != null
                            ? CachedNetworkImageProvider(widget.user.foto!)
                            : null,
                        child: widget.user.foto == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.textSecondary,
                              )
                            : null,
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background.withValues(alpha: 0.3),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: AppColors.textPrimary,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Alterar foto',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        AppTextField(
          controller: widget.nomeController,
          label: 'Nome de Exibição',
        ),
      ],
    );
  }
}
