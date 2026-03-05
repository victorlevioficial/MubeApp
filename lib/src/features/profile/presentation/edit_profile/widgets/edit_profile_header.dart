import 'dart:io';

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
  bool _isProcessingAvatar = false;
  bool _isUploadingAvatar = false;

  /// Local file for optimistic avatar preview.
  File? _optimisticAvatarFile;

  bool get _isAvatarBusy => _isProcessingAvatar || _isUploadingAvatar;

  String get _avatarActionLabel {
    if (_isUploadingAvatar) return 'Enviando foto...';
    if (_isProcessingAvatar) return 'Preparando foto...';
    return 'Alterar foto';
  }

  @override
  void dispose() {
    _mediaPickerService.dispose();
    super.dispose();
  }

  Future<void> _handlePhotoUpdate() async {
    if (_isAvatarBusy) return;

    final controller = ref.read(profileControllerProvider.notifier);

    try {
      setState(() {
        _isProcessingAvatar = true;
      });

      // Show source picker bottom sheet
      final source = await MediaPickerService.showMediaSourcePicker(
        context,
        title: 'Foto de Perfil',
        cameraIcon: Icons.camera_alt_outlined,
        cameraLabel: 'Tirar Foto',
        galleryIcon: Icons.photo_library_outlined,
        galleryLabel: 'Escolher da Galeria',
      );

      if (source == null || !mounted) return;

      final file = await _mediaPickerService.pickAndCropPhoto(
        context,
        lockAspectRatio: true,
        source: source,
      );

      if (file == null || !mounted) return;

      // Optimistic: show local file immediately
      setState(() {
        _isProcessingAvatar = false;
        _isUploadingAvatar = true;
        _optimisticAvatarFile = file;
      });

      await controller.updateProfileImage(currentUser: widget.user, file: file);

      if (mounted) {
        // Keep local preview until parent rebuilds with updated remote URL.
        AppSnackBar.success(context, 'Foto de perfil atualizada!');
      }
    } catch (e) {
      if (mounted) {
        // Revert optimistic: remove local preview
        setState(() {
          _optimisticAvatarFile = null;
        });
        AppSnackBar.error(context, 'Erro ao atualizar foto: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAvatar = false;
          _isUploadingAvatar = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant EditProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Once profile URL changes, remote image is up to date and local preview
    // can be discarded safely.
    if (_optimisticAvatarFile != null &&
        oldWidget.user.foto != widget.user.foto) {
      _optimisticAvatarFile = null;
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
            onTap: _isAvatarBusy ? null : _handlePhotoUpdate,
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
                      child: ClipOval(child: _buildAvatarContent()),
                    ),
                    if (_isAvatarBusy)
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
                  _avatarActionLabel,
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

  /// Build avatar content: optimistic local file > remote URL > fallback icon.
  Widget _buildAvatarContent() {
    // Priority 1: optimistic local file preview
    if (_optimisticAvatarFile != null) {
      return Image.file(
        _optimisticAvatarFile!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );
    }

    // Priority 2: remote photo URL
    if (widget.user.foto != null) {
      return CachedNetworkImage(
        imageUrl: widget.user.foto!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        cacheManager: ImageCacheConfig.profileCacheManager,
        memCacheWidth: 240,
        memCacheHeight: 240,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, _) => Container(color: AppColors.surface),
        errorWidget: (context, _, _) => const Center(
          child: Icon(Icons.person, size: 50, color: AppColors.textSecondary),
        ),
      );
    }

    // Priority 3: fallback icon
    return const Center(
      child: Icon(Icons.person, size: 50, color: AppColors.textSecondary),
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
