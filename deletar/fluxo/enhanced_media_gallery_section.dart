import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/components/buttons/app_button.dart';
import '../../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../auth/domain/app_user.dart';
import '../services/media_picker_service.dart';
import 'gallery_grid.dart';

/// Enhanced Media Gallery Section with modern design matching the profile forms.
class EnhancedMediaGallerySection extends ConsumerStatefulWidget {
  final AppUser user;

  const EnhancedMediaGallerySection({super.key, required this.user});

  @override
  ConsumerState<EnhancedMediaGallerySection> createState() =>
      _EnhancedMediaGallerySectionState();
}

class _EnhancedMediaGallerySectionState
    extends ConsumerState<EnhancedMediaGallerySection> {
  final _mediaPickerService = MediaPickerService();

  @override
  void dispose() {
    _mediaPickerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mídia & Portfólio',
            style: AppTypography.headlineLarge.copyWith(fontSize: 28),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Adicione fotos, vídeos e trabalhos da sua carreira',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.s32),

          // Upload Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.s24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  'Adicionar Mídia',
                  style: AppTypography.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Arraste arquivos aqui ou toque para selecionar',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s24),
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outline(
                        text: 'Foto',
                        onPressed: () => _handlePhotoUpload(context),
                        icon: const Icon(Icons.photo_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: AppButton.outline(
                        text: 'Vídeo',
                        onPressed: () => _handleVideoUpload(context),
                        icon: const Icon(
                          Icons.video_library_outlined,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.s48),

          // Gallery Section
          if (widget.user.midia != null && widget.user.midia!.isNotEmpty) ...[
            Text('Galeria', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.s16),
            GalleryGrid(
              items: widget.user.midia ?? [],
              onRemove: (index) => _handleMediaRemove(index),
              onAddPhoto: () => _handlePhotoUpload(context),
              onAddVideo: () => _handleVideoUpload(context),
              onReorder: _handleReorder,
            ),
            const SizedBox(height: AppSpacing.s48),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s48,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.all16,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    'Nenhuma mídia adicionada',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    'Comece adicionando suas fotos e vídeos',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handlePhotoUpload(BuildContext context) async {
    // TODO: Implement photo upload
  }

  Future<void> _handleVideoUpload(BuildContext context) async {
    // TODO: Implement video upload
  }

  Future<void> _handleMediaRemove(int index) async {
    // TODO: Implement media removal
  }

  void _handleReorder(int oldIndex, int newIndex) {
    // TODO: Implement reorder logic
  }
}
