import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';

/// Professional video player widget with auto-hide controls
class GalleryVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const GalleryVideoPlayer({super.key, required this.videoUrl});

  @override
  State<GalleryVideoPlayer> createState() => _GalleryVideoPlayerState();
}

class _GalleryVideoPlayerState extends State<GalleryVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();
      await _controller.setLooping(true);

      // Listen to player state changes
      _controller.addListener(() {
        if (mounted) setState(() {});
      });

      if (mounted) {
        setState(() => _isInitialized = true);
        await _controller.play();

        // Show controls initially, then hide after 3 seconds
        _showControlsWithTimer();
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao inicializar vídeo', e);
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _showControlsWithTimer() {
    setState(() => _showControls = true);

    // Cancel existing timer
    _hideControlsTimer?.cancel();

    // Hide controls after 3 seconds
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
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

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.textPrimary),
      );
    }

    return GestureDetector(
      onTap: () {
        _showControlsWithTimer();
      },
      child: Container(
        color: AppColors.background,
        child: Center(
          child: AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Video
                VideoPlayer(_controller),

                // Controls overlay with animation
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

                // Play/Pause button (center) with animation
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
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: AppColors.textPrimary,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom controls with animation
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
                          // Progress bar - Professional implementation
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
                                  inactiveTrackColor:
                                      AppColors.textPrimary.withValues(
                                    alpha: 0.24,
                                  ),
                                  thumbColor: AppColors.primary,
                                  overlayColor: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Slider(
                                  value: _controller
                                      .value
                                      .position
                                      .inMilliseconds
                                      .toDouble(),
                                  min: 0,
                                  max: _controller.value.duration.inMilliseconds
                                      .toDouble(),
                                  onChanged: (value) {
                                    _controller.seekTo(
                                      Duration(milliseconds: value.toInt()),
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
                          // Time display
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.s4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_controller.value.position),
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
                                  _formatDuration(_controller.value.duration),
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
