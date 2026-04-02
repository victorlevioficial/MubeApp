import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/story_constants.dart';
import '../../domain/story_item.dart';
import '../controllers/story_compose_controller.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(storyComposeControllerProvider);
    final controller = ref.read(storyComposeControllerProvider.notifier);
    final selectedMediaType = state.selectedMedia?.mediaType;

    _syncCaptionController(state.caption);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(
        title: 'Novo story',
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s16,
            AppSpacing.s24,
          ),
          children: [
            _StorySection(
              child: _StoryPickerActions(
                selectedMediaType: selectedMediaType,
                onPickImage: () => controller.pickImage(context),
                onPickVideo: () => controller.pickVideo(context),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            _StorySection(
              child: _SelectedStoryPreview(
                mediaType: selectedMediaType,
                file: state.selectedMedia?.file,
                isImageMirrored: state.isPhotoMirrored,
              ),
            ),
            if (state.isPublishing) ...[
              const SizedBox(height: AppSpacing.s16),
              _StoryPublishProgress(
                progress: state.publishProgress,
                label: state.publishStatus ?? 'Enviando story',
              ),
            ],
            if (state.selectedMedia != null) ...[
              const SizedBox(height: AppSpacing.s16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedMediaType == StoryMediaType.image) ...[
                    AppButton.secondary(
                      text: state.isPhotoMirrored
                          ? 'Desfazer espelho'
                          : 'Espelhar foto',
                      size: AppButtonSize.small,
                      icon: const Icon(Icons.flip_outlined, size: 16),
                      onPressed: controller.togglePhotoMirror,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  if (selectedMediaType == StoryMediaType.video) ...[
                    Text(
                      'Toque no preview para pausar.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                  AppTextField(
                    controller: _captionController,
                    hint: 'Legenda opcional',
                    minLines: 2,
                    maxLines: 2,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: controller.updateCaption,
                  ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s8),
                      child: Text(
                        state.errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.s16),
                  _StoryActionPanel(
                    isPublishing: state.isPublishing,
                    onClear: state.isPublishing
                        ? null
                        : controller.clearSelection,
                    onPublish: state.isPublishing
                        ? null
                        : () async {
                            final didPublish = await controller.publish(
                              context,
                            );
                            if (didPublish && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _syncCaptionController(String caption) {
    if (_captionController.text == caption) {
      return;
    }

    _captionController.value = TextEditingValue(
      text: caption,
      selection: TextSelection.collapsed(offset: caption.length),
    );
  }
}

class _StorySection extends StatelessWidget {
  const _StorySection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}

class _StoryPickerActions extends StatelessWidget {
  const _StoryPickerActions({
    required this.selectedMediaType,
    required this.onPickImage,
    required this.onPickVideo,
  });

  final StoryMediaType? selectedMediaType;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha uma foto ou video.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            Expanded(
              child: _PickerOptionCard(
                icon: Icons.photo_camera_outlined,
                title: 'Foto',
                subtitle: 'Selfie ou bastidor',
                isSelected: selectedMediaType == StoryMediaType.image,
                onTap: onPickImage,
              ),
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: _PickerOptionCard(
                icon: Icons.videocam_outlined,
                title: 'Video',
                subtitle: 'Clipe curto',
                isSelected: selectedMediaType == StoryMediaType.video,
                onTap: onPickVideo,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PickerOptionCard extends StatelessWidget {
  const _PickerOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.all12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.10)
                : AppColors.surfaceHighlight,
            borderRadius: AppRadius.all12,
            border: Border.all(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.28)
                  : AppColors.border.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedStoryPreview extends StatelessWidget {
  const _SelectedStoryPreview({
    required this.mediaType,
    required this.file,
    required this.isImageMirrored,
  });

  final StoryMediaType? mediaType;
  final File? file;
  final bool isImageMirrored;

  @override
  Widget build(BuildContext context) {
    final hasMedia = file != null && mediaType != null;
    final previewLabel = switch (mediaType) {
      StoryMediaType.image =>
        isImageMirrored ? 'Foto espelhada' : 'Foto pronta',
      StoryMediaType.video => 'Video pronto',
      null => 'Sem midia selecionada',
    };
    final previewDescription = switch (mediaType) {
      StoryMediaType.image =>
        'Confira enquadramento e como a foto ocupa o frame vertical.',
      StoryMediaType.video =>
        'Veja o corte final e toque para pausar ou continuar.',
      null => 'Assim que voce escolher foto ou video, o preview aparece aqui.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(previewLabel, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s4),
        Text(
          previewDescription,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        if (!hasMedia)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s20,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all16,
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.45),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: AppRadius.all12,
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(height: AppSpacing.s10),
                Text(
                  'Seu story vai aparecer aqui',
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Selecione uma foto ou video para revisar antes de publicar.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: AspectRatio(
                aspectRatio: StoryConstants.targetAspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: AppRadius.all16,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.all16,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (mediaType == StoryMediaType.image)
                          Transform(
                            alignment: Alignment.center,
                            transform: isImageMirrored
                                ? Matrix4.diagonal3Values(-1.0, 1.0, 1.0)
                                : Matrix4.identity(),
                            child: Image.file(
                              file!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        else
                          _StoryVideoPreview(file: file!),
                        Positioned(
                          top: AppSpacing.s12,
                          left: AppSpacing.s12,
                          child: _PreviewBadge(
                            label: mediaType == StoryMediaType.image
                                ? (isImageMirrored ? 'Foto espelhada' : 'Foto')
                                : 'Video',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StoryActionPanel extends StatelessWidget {
  const _StoryActionPanel({
    required this.isPublishing,
    required this.onClear,
    required this.onPublish,
  });

  final bool isPublishing;
  final VoidCallback? onClear;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton.outline(text: 'Limpar', onPressed: onClear),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: AppButton.primary(
            text: 'Publicar',
            isLoading: isPublishing,
            onPressed: onPublish,
          ),
        ),
      ],
    );
  }
}

class _StoryPublishProgress extends StatelessWidget {
  const _StoryPublishProgress({required this.progress, required this.label});

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();
    final percentage = (normalizedProgress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          ClipRRect(
            borderRadius: AppRadius.all4,
            child: LinearProgressIndicator(
              value: normalizedProgress,
              minHeight: 6,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryVideoPreview extends StatefulWidget {
  const _StoryVideoPreview({required this.file});

  final File file;

  @override
  State<_StoryVideoPreview> createState() => _StoryVideoPreviewState();
}

class _StoryVideoPreviewState extends State<_StoryVideoPreview> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant _StoryVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      unawaited(_disposeController());
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.file(widget.file);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e, stack) {
      AppLogger.error('VideoPlayer init error', e, stack);
      if (mounted) {
        setState(() => _controller = null);
      }
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return Center(
      child: GestureDetector(
        onTap: _togglePlayback,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            ),
            if (!controller.value.isPlaying)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.45),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill_rounded,
                    color: AppColors.textPrimary,
                    size: 64,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
