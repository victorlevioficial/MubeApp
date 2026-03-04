import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';

/// Professional video player widget with auto-hide controls
class GalleryVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const GalleryVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<GalleryVideoPlayer> createState() => _GalleryVideoPlayerState();
}

class _GalleryVideoPlayerState extends State<GalleryVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  double? _thumbnailAspectRatio;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _resolveThumbnailAspectRatio();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant GalleryVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.thumbnailUrl != widget.thumbnailUrl) {
      _thumbnailAspectRatio = null;
      _resolveThumbnailAspectRatio();
    }

    if (oldWidget.videoUrl != widget.videoUrl) {
      _hideControlsTimer?.cancel();
      _disposeController();
      _isInitialized = false;
      _hasError = false;
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    final initialized = await _tryInitializeController();
    if (initialized || !mounted) return;

    AppLogger.warning(
      'Falha ao iniciar vídeo sem formatHint; tentando fallback com formatHint=other.',
    );

    _disposeController();
    final fallbackInitialized = await _tryInitializeController(
      formatHint: VideoFormat.other,
    );

    if (!fallbackInitialized && mounted) {
      setState(() => _hasError = true);
    }
  }

  Future<void> _resolveThumbnailAspectRatio() async {
    final thumbnailUrl = widget.thumbnailUrl;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) return;

    final completer = Completer<Size>();
    final provider = NetworkImage(thumbnailUrl);
    final stream = provider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, _) {
        if (!completer.isCompleted) {
          completer.complete(
            Size(
              imageInfo.image.width.toDouble(),
              imageInfo.image.height.toDouble(),
            ),
          );
        }
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    stream.addListener(listener);
    try {
      final size = await completer.future.timeout(const Duration(seconds: 3));
      if (!mounted || size.height <= 0) return;

      final aspectRatio = size.width / size.height;
      if (!aspectRatio.isFinite || aspectRatio <= 0) return;

      setState(() {
        _thumbnailAspectRatio = aspectRatio;
      });
    } catch (_) {
      // Best effort only; player fallback usa aspect ratio do video.
    } finally {
      stream.removeListener(listener);
    }
  }

  double _resolveDisplayAspectRatio(double rawVideoAspectRatio) {
    final videoAspectRatio =
        rawVideoAspectRatio.isFinite && rawVideoAspectRatio > 0
        ? rawVideoAspectRatio
        : 16 / 9;

    final thumbnailAspectRatio = _thumbnailAspectRatio;
    if (thumbnailAspectRatio == null ||
        !thumbnailAspectRatio.isFinite ||
        thumbnailAspectRatio <= 0) {
      return videoAspectRatio;
    }

    final videoLandscape = videoAspectRatio >= 1;
    final thumbnailLandscape = thumbnailAspectRatio >= 1;
    final largest = videoAspectRatio > thumbnailAspectRatio
        ? videoAspectRatio
        : thumbnailAspectRatio;
    final delta = (videoAspectRatio - thumbnailAspectRatio).abs() / largest;

    if (videoLandscape != thumbnailLandscape || delta >= 0.55) {
      return thumbnailAspectRatio;
    }

    return videoAspectRatio;
  }

  Future<bool> _tryInitializeController({VideoFormat? formatHint}) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        formatHint: formatHint,
      );

      await controller.initialize();
      await controller.setLooping(true);
      controller.addListener(_onControllerChanged);

      if (!mounted) {
        await controller.dispose();
        return false;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
        _hasError = false;
      });

      await controller.play();
      _showControlsWithTimer();
      return true;
    } catch (e, s) {
      final controllerError = controller?.value.errorDescription;
      AppLogger.error(
        'Erro ao inicializar vídeo | hint=$formatHint | os=${Platform.operatingSystem} ${Platform.operatingSystemVersion} | controllerError=$controllerError | url=${widget.videoUrl}',
        e,
        s,
      );
      await controller?.dispose();
      return false;
    }
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _disposeController() {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onControllerChanged);
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _disposeController();
    super.dispose();
  }

  void _showControlsWithTimer() {
    if (mounted) {
      setState(() => _showControls = true);
    }

    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      final controller = _controller;
      if (mounted && controller != null && controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
    });
    _showControlsWithTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: AppColors.error, size: 64),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Erro ao carregar vídeo',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      );
    }

    final durationMs = controller.value.duration.inMilliseconds.toDouble();
    final maxSlider = durationMs > 0 ? durationMs : 1.0;
    final sliderValue = controller.value.position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxSlider)
        .toDouble();
    final displayAspectRatio = _resolveDisplayAspectRatio(
      controller.value.aspectRatio,
    );

    return GestureDetector(
      onTap: _showControlsWithTimer,
      child: Container(
        color: AppColors.background,
        child: Center(
          child: AspectRatio(
            aspectRatio: displayAspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(controller),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background.withValues(alpha: 0.7),
                          AppColors.transparent,
                          AppColors.transparent,
                          AppColors.background.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        padding: AppSpacing.all16,
                        child: Icon(
                          controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: AppColors.textPrimary,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  bottom: _showControls ? 0 : -100,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: !_showControls,
                    child: Container(
                      padding: AppSpacing.h16v12,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.transparent,
                            AppColors.background.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 32,
                            child: Material(
                              color: AppColors.transparent,
                              child: SliderTheme(
                                data: SliderThemeData(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.textPrimary
                                      .withValues(alpha: 0.24),
                                  thumbColor: AppColors.primary,
                                  overlayColor: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Slider(
                                  value: sliderValue,
                                  min: 0,
                                  max: maxSlider,
                                  onChanged: durationMs <= 0
                                      ? null
                                      : (value) {
                                          controller.seekTo(
                                            Duration(
                                              milliseconds: value.toInt(),
                                            ),
                                          );
                                        },
                                  onChangeStart: (value) {
                                    _hideControlsTimer?.cancel();
                                  },
                                  onChangeEnd: (value) {
                                    _showControlsWithTimer();
                                  },
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(controller.value.position),
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    decoration: TextDecoration.none,
                                    shadows: const [
                                      Shadow(
                                        color: AppColors.background,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDuration(controller.value.duration),
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    decoration: TextDecoration.none,
                                    shadows: const [
                                      Shadow(
                                        color: AppColors.background,
                                        offset: Offset(1, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
