import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_motion.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/story_constants.dart';
import '../../domain/story_item.dart';
import '../../domain/story_tray_bundle.dart';
import '../../domain/story_viewer_route_args.dart';
import '../controllers/story_viewer_controller.dart';
import '../widgets/story_progress_bar.dart';
import '../widgets/story_ring_avatar.dart';
import '../widgets/story_viewer_fallback_state.dart';

class StoryViewerScreen extends ConsumerStatefulWidget {
  const StoryViewerScreen({super.key, required this.args, this.cacheManager});

  final StoryViewerRouteArgs args;
  final BaseCacheManager? cacheManager;

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late List<StoryTrayBundle> _bundles;
  late int _bundleIndex;
  late int _storyIndex;
  late final AnimationController _imageProgressController;
  final Set<String> _markedStoryIds = <String>{};
  double _videoProgress = 0;
  bool _isPaused = false;
  bool _isCurrentImageReady = false;

  StoryTrayBundle get _currentBundle => _bundles[_bundleIndex];
  StoryItem get _currentStory => _currentBundle.stories[_storyIndex];

  @override
  void initState() {
    super.initState();
    _bundles = widget.args.bundles
        .where((bundle) => bundle.stories.isNotEmpty)
        .toList(growable: false);
    _bundleIndex = 0;
    _storyIndex = 0;

    if (_bundles.isNotEmpty) {
      final initialBundleIndex = _bundles.indexWhere(
        (bundle) => bundle.ownerUid == widget.args.initialOwnerUid,
      );
      _bundleIndex = initialBundleIndex >= 0 ? initialBundleIndex : 0;
      _storyIndex = _resolveInitialStoryIndex(_bundleIndex);
    }

    _imageProgressController =
        AnimationController(
          vsync: this,
          duration: StoryConstants.imageDisplayDuration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _advanceStory();
          }
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _bundles.isEmpty) return;
      _activateCurrentStory();
    });
  }

  int _resolveInitialStoryIndex(int bundleIndex) {
    final initialStoryId = widget.args.initialStoryId;
    if (initialStoryId == null) return 0;
    final bundle = _bundles[bundleIndex];
    final index = bundle.stories.indexWhere(
      (story) => story.id == initialStoryId,
    );
    return index >= 0 ? index : 0;
  }

  @override
  void dispose() {
    _imageProgressController.dispose();
    super.dispose();
  }

  void _activateCurrentStory() {
    if (_bundles.isEmpty) return;
    final story = _currentStory;
    _isCurrentImageReady = false;
    _markViewed(story);
    _precacheNextStory();

    if (story.isVideo) {
      _imageProgressController
        ..stop()
        ..value = 0;
      setState(() => _videoProgress = 0);
      return;
    }

    // The image timer is intentionally NOT started here. `_StoryMediaStage`
    // calls back via `onImageReady` once the bitmap is decoded so the user
    // always gets the full display duration, even on slow networks.
    _imageProgressController
      ..stop()
      ..duration = StoryConstants.imageDisplayDuration
      ..value = 0;
  }

  void _handleImageReady(StoryItem story) {
    if (!mounted || _bundles.isEmpty) return;
    if (_currentStory.id != story.id) return;
    if (story.isVideo) return;
    _isCurrentImageReady = true;
    if (_isPaused) return;

    _imageProgressController
      ..duration = StoryConstants.imageDisplayDuration
      ..forward();
  }

  void _precacheNextStory() {
    StoryItem? nextStory;
    if (_storyIndex < _currentBundle.stories.length - 1) {
      nextStory = _currentBundle.stories[_storyIndex + 1];
    } else if (_bundleIndex < _bundles.length - 1) {
      final nextBundle = _bundles[_bundleIndex + 1];
      if (nextBundle.stories.isNotEmpty) {
        nextStory = nextBundle.stories.first;
      }
    }
    if (nextStory != null && !nextStory.isVideo) {
      precacheImage(
        CachedNetworkImageProvider(
          nextStory.mediaUrl,
          cacheManager: widget.cacheManager,
        ),
        context,
        onError: (_, _) {},
      ).ignore();
    }
  }

  Future<void> _markViewed(StoryItem story) async {
    if (!_markedStoryIds.add(story.id)) return;
    unawaited(ref.read(storyViewerControllerProvider).markViewed(story));
  }

  void _pauseStory() {
    if (_isPaused || _bundles.isEmpty) return;
    setState(() => _isPaused = true);
    if (_currentStory.isVideo) return;
    _imageProgressController.stop();
  }

  void _resumeStory() {
    if (!_isPaused || _bundles.isEmpty) return;
    setState(() => _isPaused = false);
    if (_currentStory.isVideo) return;
    // If the image became ready while the story was paused, the controller is
    // still at zero. Start it on resume instead of waiting for another decode
    // callback that will not fire for the same image.
    if (_isCurrentImageReady && _imageProgressController.value < 1) {
      _imageProgressController.forward();
    }
  }

  void _goToStory({required int bundleIndex, required int storyIndex}) {
    setState(() {
      _bundleIndex = bundleIndex;
      _storyIndex = storyIndex;
      _isPaused = false;
      _isCurrentImageReady = false;
      _videoProgress = 0;
    });
    _activateCurrentStory();
  }

  void _advanceStory() {
    if (_bundles.isEmpty) return;

    if (_storyIndex < _currentBundle.stories.length - 1) {
      _goToStory(bundleIndex: _bundleIndex, storyIndex: _storyIndex + 1);
      return;
    }

    if (_bundleIndex < _bundles.length - 1) {
      _goToStory(bundleIndex: _bundleIndex + 1, storyIndex: 0);
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _goBackStory() {
    if (_bundles.isEmpty) return;

    if (_storyIndex > 0) {
      _goToStory(bundleIndex: _bundleIndex, storyIndex: _storyIndex - 1);
      return;
    }

    if (_bundleIndex > 0) {
      final previousBundleIndex = _bundleIndex - 1;
      final previousStoryIndex =
          _bundles[previousBundleIndex].stories.length - 1;
      _goToStory(
        bundleIndex: previousBundleIndex,
        storyIndex: previousStoryIndex,
      );
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteCurrentStory() async {
    final story = _currentStory;
    final shouldDelete = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Excluir story?',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Esse story sera removido imediatamente.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    await ref.read(storyViewerControllerProvider).deleteStory(story);

    final updatedBundles = <StoryTrayBundle>[];
    for (final bundle in _bundles) {
      if (bundle.ownerUid != story.ownerUid) {
        updatedBundles.add(bundle);
        continue;
      }

      final remainingStories = bundle.stories
          .where((item) => item.id != story.id)
          .toList(growable: false);
      if (remainingStories.isEmpty) {
        continue;
      }

      updatedBundles.add(bundle.copyWith(stories: remainingStories));
    }

    if (updatedBundles.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final nextBundleIndex = _bundleIndex.clamp(0, updatedBundles.length - 1);
    final nextStoryIndex = _storyIndex.clamp(
      0,
      updatedBundles[nextBundleIndex].stories.length - 1,
    );

    setState(() {
      _bundles = updatedBundles;
      _bundleIndex = nextBundleIndex;
      _storyIndex = nextStoryIndex;
      _isPaused = false;
      _isCurrentImageReady = false;
      _videoProgress = 0;
    });
    _activateCurrentStory();
  }

  void _handleTap(TapUpDetails details, BoxConstraints constraints) {
    final dx = details.localPosition.dx;
    final width = constraints.maxWidth;
    if (dx < width * 0.32) {
      _goBackStory();
      return;
    }
    _advanceStory();
  }

  @override
  Widget build(BuildContext context) {
    if (_bundles.isEmpty) {
      return const StoryViewerFallbackState(
        title: 'Story não encontrado.',
        subtitle: 'Esse story não está mais disponível.',
      );
    }

    final currentBundle = _currentBundle;
    final currentStory = _currentStory;
    final progress = currentStory.isVideo
        ? _videoProgress
        : _imageProgressController.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => _handleTap(details, constraints),
              onLongPressStart: (_) => _pauseStory(),
              onLongPressEnd: (_) => _resumeStory(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _StoryMediaStage(
                    key: ValueKey(currentStory.id),
                    story: currentStory,
                    cacheManager: widget.cacheManager,
                    isPaused: _isPaused,
                    onCompleted: _advanceStory,
                    onProgressChanged: (value) {
                      if (mounted) {
                        setState(() => _videoProgress = value);
                      }
                    },
                    onImageReady: () => _handleImageReady(currentStory),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background.withValues(alpha: 0.72),
                          Colors.transparent,
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.56),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s16,
                      AppSpacing.s12,
                      AppSpacing.s16,
                      AppSpacing.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StoryProgressBar(
                          itemCount: currentBundle.stories.length,
                          currentIndex: _storyIndex,
                          progress: progress,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Row(
                          children: [
                            StoryRingAvatar(
                              name: currentBundle.ownerName,
                              photoUrl: currentBundle.ownerPhoto,
                              photoPreviewUrl: currentBundle.ownerPhotoPreview,
                              size: 44,
                              hasUnseen: currentBundle.hasUnseen,
                            ),
                            const SizedBox(width: AppSpacing.s10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentBundle.ownerName,
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.s2),
                                  Text(
                                    _formatRelativeTime(currentStory.createdAt),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (currentBundle.isCurrentUser)
                              IconButton(
                                onPressed: () => context.push(
                                  RoutePaths.storyViewersById(currentStory.id),
                                ),
                                icon: Text(
                                  '${currentStory.viewersCount}',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            if (currentBundle.isCurrentUser)
                              IconButton(
                                onPressed: _confirmDeleteCurrentStory,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if ((currentStory.caption ?? '').trim().isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: AppSpacing.all16,
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(
                                alpha: 0.5,
                              ),
                              borderRadius: AppRadius.all16,
                            ),
                            child: Text(
                              currentStory.caption!.trim(),
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Agora';
    if (difference.inHours < 1) return '${difference.inMinutes} min';
    return '${difference.inHours} h';
  }
}

class _StoryMediaStage extends StatefulWidget {
  const _StoryMediaStage({
    super.key,
    required this.story,
    required this.cacheManager,
    required this.isPaused,
    required this.onCompleted,
    required this.onProgressChanged,
    required this.onImageReady,
  });

  final StoryItem story;
  final BaseCacheManager? cacheManager;
  final bool isPaused;
  final VoidCallback onCompleted;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onImageReady;

  @override
  State<_StoryMediaStage> createState() => _StoryMediaStageState();
}

class _StoryMediaStageState extends State<_StoryMediaStage> {
  VideoPlayerController? _controller;
  bool _hasCompleted = false;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.story.isVideo) {
      _initializeVideo();
    } else {
      _imageLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onProgressChanged(0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _StoryMediaStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.story.id != widget.story.id) {
      _hasCompleted = false;
      _imageLoaded = false;
      unawaited(_disposeController());
      if (widget.story.isVideo) {
        _initializeVideo();
      } else {
        widget.onProgressChanged(0);
      }
    } else if (oldWidget.isPaused != widget.isPaused) {
      unawaited(_syncPauseState());
    }
  }

  Future<void> _initializeVideo() async {
    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.story.mediaUrl),
    );
    await controller.initialize();
    controller.addListener(_handleVideoTick);

    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() => _controller = controller);
    await _syncPauseState();
    widget.onProgressChanged(0);
  }

  Future<void> _syncPauseState() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (widget.isPaused) {
      await controller.pause();
      return;
    }

    await controller.play();
  }

  void _handleVideoTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final durationMs = controller.value.duration.inMilliseconds;
    final positionMs = controller.value.position.inMilliseconds;
    final progress = durationMs <= 0 ? 0.0 : positionMs / durationMs;
    widget.onProgressChanged(progress.clamp(0.0, 1.0));

    // Advance only when the playhead actually reaches the end. The previous
    // `!isPlaying` check fired `onCompleted` whenever the user paused near
    // the end of the clip, accidentally skipping to the next story.
    if (!_hasCompleted &&
        durationMs > 0 &&
        positionMs >= durationMs &&
        !controller.value.isPlaying) {
      _hasCompleted = true;
      widget.onCompleted();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    controller?.removeListener(_handleVideoTick);
    await controller?.dispose();
  }

  @override
  void dispose() {
    unawaited(_disposeController());
    super.dispose();
  }

  void _markImageReady() {
    if (_imageLoaded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _imageLoaded) return;
      setState(() => _imageLoaded = true);
      widget.onImageReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.story.isVideo) {
      final thumbnailUrl = widget.story.thumbnailUrl;
      return SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl != null &&
                thumbnailUrl.isNotEmpty &&
                !_imageLoaded)
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                cacheManager: widget.cacheManager,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            AnimatedOpacity(
              opacity: _imageLoaded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: CachedNetworkImage(
                imageUrl: widget.story.mediaUrl,
                cacheManager: widget.cacheManager,
                fit: BoxFit.cover,
                imageBuilder: (context, imageProvider) {
                  _markImageReady();
                  return Image(image: imageProvider, fit: BoxFit.cover);
                },
                errorWidget: (context, url, error) {
                  // Even on a load error we let the timer run so the viewer
                  // doesn't get stuck on a broken story forever.
                  _markImageReady();
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textPrimary,
                      size: 52,
                    ),
                  );
                },
                placeholder: (context, url) => const SizedBox.shrink(),
              ),
            ),
            if (!_imageLoaded && (thumbnailUrl == null || thumbnailUrl.isEmpty))
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      final thumbnailUrl = widget.story.thumbnailUrl;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: thumbnailUrl,
              cacheManager: widget.cacheManager,
              fit: BoxFit.cover,
            ),
          const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ],
      );
    }

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      child: ColoredBox(
        key: ValueKey(widget.story.id),
        color: AppColors.background,
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}
