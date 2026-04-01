import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Novo story'),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            _StoryPickerActions(
              onPickImage: () => controller.pickImage(context),
              onPickVideo: () => controller.pickVideo(context),
            ),
            const SizedBox(height: AppSpacing.s20),
            _SelectedStoryPreview(
              mediaType: state.selectedMedia?.mediaType,
              file: state.selectedMedia?.file,
            ),
            if (state.selectedMedia != null) ...[
              const SizedBox(height: AppSpacing.s16),
              TextField(
                controller: _captionController,
                maxLength: 120,
                onChanged: controller.updateCaption,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Legenda opcional',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: const OutlineInputBorder(
                    borderRadius: AppRadius.all16,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.all16,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: AppRadius.all16,
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
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
              Row(
                children: [
                  Expanded(
                    child: AppButton.outline(
                      text: 'Limpar',
                      onPressed: controller.clearSelection,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: AppButton.primary(
                      text: 'Publicar',
                      isLoading: state.isPublishing,
                      onPressed: () async {
                        final didPublish = await controller.publish(context);
                        if (didPublish && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoryPickerActions extends StatelessWidget {
  const _StoryPickerActions({
    required this.onPickImage,
    required this.onPickVideo,
  });

  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: AppSpacing.all16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escolha a midia do story',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Voce pode publicar foto ou video vertical de ate 15 segundos.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    text: 'Foto',
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    onPressed: onPickImage,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: AppButton.secondary(
                    text: 'Video',
                    icon: const Icon(Icons.videocam_outlined, size: 18),
                    onPressed: onPickVideo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedStoryPreview extends StatelessWidget {
  const _SelectedStoryPreview({required this.mediaType, required this.file});

  final StoryMediaType? mediaType;
  final File? file;

  @override
  Widget build(BuildContext context) {
    if (file == null || mediaType == null) {
      return Container(
        height: 420,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.all20,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Padding(
            padding: AppSpacing.all24,
            child: Text(
              'Selecione uma foto ou video para visualizar o story.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.all20,
      child: Container(
        height: 420,
        color: AppColors.surface,
        child: mediaType == StoryMediaType.image
            ? Image.file(file!, fit: BoxFit.cover, width: double.infinity)
            : _StoryVideoPreview(file: file!),
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
    final controller = VideoPlayerController.file(widget.file);
    await controller.initialize();
    await controller.setLooping(true);
    await controller.play();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() => _controller = controller);
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
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
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}
