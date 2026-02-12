import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/image_cache_config.dart';
import '../../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../auth/domain/app_user.dart';
import '../../../../auth/domain/user_type.dart';
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
  bool _isUploadingAvatar = false;

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

      setState(() => _isUploadingAvatar = true);
      await controller.updateProfileImage(currentUser: widget.user, file: file);

      if (mounted) {
        AppSnackBar.success(context, 'Foto de perfil atualizada!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao atualizar foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameLabel = _getRegistrationNameLabel();
    final nameHint = _getRegistrationNameHint();

    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: _isUploadingAvatar ? null : _handlePhotoUpdate,
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
                      child: ClipOval(
                        child: widget.user.foto != null
                            ? CachedNetworkImage(
                                imageUrl: widget.user.foto!,
                                fit: BoxFit.cover,
                                width: 100,
                                height: 100,
                                cacheManager:
                                    ImageCacheConfig.profileCacheManager,
                                memCacheWidth: 240,
                                memCacheHeight: 240,
                                fadeInDuration: Duration.zero,
                                fadeOutDuration: Duration.zero,
                                placeholder: (context, _) =>
                                    Container(color: AppColors.surface),
                                errorWidget: (context, _, _) => const Center(
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    if (_isUploadingAvatar)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background.withValues(alpha: 0.5),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: AppColors.textPrimary,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  _isUploadingAvatar ? 'Enviando foto...' : 'Alterar foto',
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
          label: nameLabel,
          hint: nameHint,
        ),
      ],
    );
  }

  String _getRegistrationNameLabel() {
    switch (widget.user.tipoPerfil) {
      case AppUserType.band:
      case AppUserType.studio:
        return 'Nome Completo (Responsavel)';
      default:
        return 'Nome Completo';
    }
  }

  String _getRegistrationNameHint() {
    switch (widget.user.tipoPerfil) {
      case AppUserType.band:
      case AppUserType.studio:
        return 'Usado para cadastro interno do responsavel';
      default:
        return 'Usado para cadastro interno';
    }
  }
}
