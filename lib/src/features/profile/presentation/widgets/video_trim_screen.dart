import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_native_video_trimmer/flutter_native_video_trimmer.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_effects.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';

class VideoTrimScreen extends StatefulWidget {
  final String videoPath;
  final int maxDurationSeconds;

  const VideoTrimScreen({
    super.key,
    required this.videoPath,
    this.maxDurationSeconds = 60,
  });

  @override
  State<VideoTrimScreen> createState() => _VideoTrimScreenState();
}

class _VideoTrimScreenState extends State<VideoTrimScreen> {
  static const int _thumbnailCount = 6;
  static const int _trimSafetyMarginMs = 500;
  static const int _trimOutputWidth = 480;
  static const int _trimOutputHeight = 640;

  late final VideoPlayerController _controller;
  final VideoTrimmer _nativeTrimmer = VideoTrimmer();
  late final Future<void> _nativeTrimmerLoadFuture;
  RangeValues _trimRange = const RangeValues(0, 1);
  double _videoDurationSeconds = 1;
  bool _isInitialized = false;
  bool _isExporting = false;
  bool _isSeekingToLoopStart = false;
  bool _isLoadingThumbnails = true;
  List<Uint8List> _thumbnails = const [];

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath));
    _nativeTrimmerLoadFuture = _nativeTrimmer.loadVideo(widget.videoPath);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
      _controller.addListener(_onVideoTick);

      final durationSeconds = _controller.value.duration.inMilliseconds / 1000;
      final safeDuration = durationSeconds <= 0 ? 1.0 : durationSeconds;
      final initialEnd = safeDuration < widget.maxDurationSeconds
          ? safeDuration
          : widget.maxDurationSeconds.toDouble();

      if (!mounted) return;
      setState(() {
        _videoDurationSeconds = safeDuration;
        _trimRange = RangeValues(0, initialEnd);
        _isInitialized = true;
      });

      await _controller.seekTo(Duration.zero);
      await _loadThumbnails();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Nao foi possivel abrir o editor de video.');
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadThumbnails() async {
    final totalMs = (_videoDurationSeconds * 1000).round();
    if (totalMs <= 0) {
      if (mounted) {
        setState(() {
          _isLoadingThumbnails = false;
        });
      }
      return;
    }

    final thumbs = <Uint8List>[];
    for (var i = 0; i < _thumbnailCount; i++) {
      final positionMs = _thumbnailCount == 1
          ? 0
          : ((totalMs * i) / (_thumbnailCount - 1)).round();
      final bytes = await VideoCompress.getByteThumbnail(
        widget.videoPath,
        quality: 25,
        position: positionMs,
      );
      if (bytes != null) {
        thumbs.add(bytes);
      }
    }

    if (!mounted) return;
    setState(() {
      _thumbnails = thumbs;
      _isLoadingThumbnails = false;
    });
  }

  void _onVideoTick() {
    if (!_controller.value.isInitialized ||
        !_controller.value.isPlaying ||
        _isSeekingToLoopStart) {
      return;
    }

    final positionMs = _controller.value.position.inMilliseconds;
    final rangeEndMs = (_trimRange.end * 1000).round();
    if (positionMs >= rangeEndMs) {
      _isSeekingToLoopStart = true;
      _controller
          .seekTo(Duration(milliseconds: (_trimRange.start * 1000).round()))
          .whenComplete(() => _isSeekingToLoopStart = false);
    }
  }

  void _togglePlayback() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      return;
    }

    final positionSec = _controller.value.position.inMilliseconds / 1000;
    if (positionSec < _trimRange.start || positionSec >= _trimRange.end) {
      _controller.seekTo(
        Duration(milliseconds: (_trimRange.start * 1000).round()),
      );
    }
    _controller.play();
  }

  void _onTrimRangeChanged(RangeValues values) {
    final normalizedRange = _normalizeRange(values);
    setState(() {
      _trimRange = normalizedRange;
    });

    final positionSec = _controller.value.position.inMilliseconds / 1000;
    if (positionSec < normalizedRange.start ||
        positionSec > normalizedRange.end) {
      _controller.seekTo(
        Duration(milliseconds: (normalizedRange.start * 1000).round()),
      );
    }
  }

  RangeValues _normalizeRange(RangeValues values) {
    final maxBound = _videoDurationSeconds;
    var start = values.start.clamp(0, maxBound).toDouble();
    var end = values.end.clamp(0, maxBound).toDouble();

    if (end < start) {
      final temp = start;
      start = end;
      end = temp;
    }

    final maxWindow = widget.maxDurationSeconds.toDouble();
    if (end - start > maxWindow) {
      final startMovedMore =
          (start - _trimRange.start).abs() > (end - _trimRange.end).abs();
      if (startMovedMore) {
        start = (end - maxWindow).clamp(0, maxBound).toDouble();
      } else {
        end = (start + maxWindow).clamp(0, maxBound).toDouble();
      }
    }

    if (end - start > maxWindow) {
      if (end >= maxBound) {
        start = (maxBound - maxWindow).clamp(0, maxBound).toDouble();
        end = maxBound;
      } else {
        end = (start + maxWindow).clamp(0, maxBound).toDouble();
      }
    }

    if (end <= start) {
      end = (start + 0.1).clamp(0, maxBound).toDouble();
      if (end <= start) {
        start = (end - 0.1).clamp(0, maxBound).toDouble();
      }
    }

    return RangeValues(start, end);
  }

  Future<void> _confirmTrim() async {
    if (_isExporting || !_isInitialized) return;

    setState(() {
      _isExporting = true;
    });

    try {
      await _nativeTrimmerLoadFuture;
      await _controller.pause();

      final request = _buildTrimRequest();
      final trimmedFile = await _exportTrim(
        startTimeMs: request.$1,
        endTimeMs: request.$2,
      );

      if (!mounted) return;
      if (trimmedFile == null) {
        AppLogger.error(
          'Video trim export returned null path=${widget.videoPath} '
          'rangeStart=${_trimRange.start.toStringAsFixed(3)} '
          'rangeEnd=${_trimRange.end.toStringAsFixed(3)} '
          'requestStartMs=${request.$1} requestEndMs=${request.$2}',
        );
        AppSnackBar.error(context, 'Nao foi possivel cortar o video.');
        return;
      }

      final persistedFile = await _persistTrimmedVideo(trimmedFile);
      if (!mounted) return;
      AppLogger.info(
        'Video trim export succeeded output=${persistedFile.path}',
      );
      Navigator.of(context).pop(persistedFile);
    } catch (_) {
      if (mounted) {
        AppLogger.error(
          'Video trim export threw exception path=${widget.videoPath}',
        );
        AppSnackBar.error(context, 'Erro ao cortar o video. Tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  (int, int) _buildTrimRequest() {
    final totalDurationMs = math.max(
      1,
      (_videoDurationSeconds * 1000).round(),
    );
    // Leave a small safety margin to avoid device-specific metadata drift
    // that can report a 60s clip as slightly above the limit.
    final maxWindowMs = math.max(
      1,
      (widget.maxDurationSeconds * 1000) - _trimSafetyMarginMs,
    );

    final startTimeMs = (_trimRange.start * 1000)
        .round()
        .clamp(0, math.max(0, totalDurationMs - 1))
        .toInt();
    var endTimeMs = (_trimRange.end * 1000)
        .round()
        .clamp(startTimeMs + 1, totalDurationMs)
        .toInt();

    if (endTimeMs - startTimeMs > maxWindowMs) {
      endTimeMs = math.min(totalDurationMs, startTimeMs + maxWindowMs);
    }

    if (endTimeMs <= startTimeMs) {
      endTimeMs = math.min(totalDurationMs, startTimeMs + 1);
    }

    return (startTimeMs, endTimeMs);
  }

  Future<File?> _exportTrim({
    required int startTimeMs,
    required int endTimeMs,
  }) async {
    AppLogger.info(
      'Video trim export requested path=${widget.videoPath} '
      'startMs=$startTimeMs endMs=$endTimeMs '
      'rangeStart=${_trimRange.start.toStringAsFixed(3)} '
      'rangeEnd=${_trimRange.end.toStringAsFixed(3)}',
    );

    final trimmedPath = await _nativeTrimmer.trimVideo(
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
      includeAudio: true,
      outputWidth: _trimOutputWidth,
      outputHeight: _trimOutputHeight,
    );

    if (trimmedPath == null || trimmedPath.isEmpty) {
      return null;
    }

    return File(trimmedPath);
  }

  Future<File> _persistTrimmedVideo(File trimmedFile) async {
    final tempDir = await getTemporaryDirectory();
    final extension = path.extension(trimmedFile.path);
    final safeExtension = extension.isEmpty ? '.mp4' : extension;
    final targetPath = path.join(
      tempDir.path,
      'mube_trimmed_${DateTime.now().millisecondsSinceEpoch}$safeExtension',
    );

    return trimmedFile.copy(targetPath);
  }

  String _formatSeconds(double seconds) {
    final total = seconds.round().clamp(0, 360000);
    final mins = total ~/ 60;
    final secs = total % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildThumbnailTimeline() {
    if (_isLoadingThumbnails) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.all12,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_thumbnails.isEmpty) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.all12,
          border: Border.all(color: AppColors.border, width: 1),
        ),
      );
    }

    return ClipRRect(
      borderRadius: AppRadius.all12,
      child: SizedBox(
        height: 56,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _thumbnails
              .map(
                (bytes) => Expanded(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    _nativeTrimmer.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDuration = _trimRange.end - _trimRange.start;
    return PopScope(
      canPop: !_isExporting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppAppBar(
          title: 'Ajustar Video',
          showBackButton: true,
          onBackPressed: _isExporting
              ? () {}
              : () => Navigator.of(context).pop(),
        ),
        body: Stack(
          children: [
            if (!_isInitialized)
              const Center(child: CircularProgressIndicator())
            else
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.all16,
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: AppEffects.subtleShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selecione o trecho do video',
                              style: AppTypography.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              'Escolha o inicio e o fim. O trecho final pode ter no maximo ${widget.maxDurationSeconds} segundos.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.all16,
                            border: Border.all(
                              color: AppColors.border,
                              width: 1,
                            ),
                            boxShadow: AppEffects.subtleShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: AppRadius.all16,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                AspectRatio(
                                  aspectRatio:
                                      _controller.value.aspectRatio <= 0
                                      ? 16 / 9
                                      : _controller.value.aspectRatio,
                                  child: VideoPlayer(_controller),
                                ),
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: AppColors.background.withValues(
                                      alpha: 0.6,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    iconSize: 42,
                                    color: AppColors.textPrimary,
                                    onPressed: _isExporting
                                        ? null
                                        : _togglePlayback,
                                    icon: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.all16,
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _TrimInfoTile(
                                    label: 'Inicio',
                                    value: _formatSeconds(_trimRange.start),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(
                                  child: _TrimInfoTile(
                                    label: 'Duracao',
                                    value: _formatSeconds(selectedDuration),
                                    highlight: true,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(
                                  child: _TrimInfoTile(
                                    label: 'Fim',
                                    value: _formatSeconds(_trimRange.end),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            _buildThumbnailTimeline(),
                            const SizedBox(height: AppSpacing.s8),
                            RangeSlider(
                              values: _trimRange,
                              min: 0,
                              max: _videoDurationSeconds,
                              onChanged: _isExporting
                                  ? null
                                  : _onTrimRangeChanged,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.outline(
                              text: 'Cancelar',
                              onPressed: _isExporting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: AppButton.primary(
                              text: 'Usar trecho',
                              isLoading: _isExporting,
                              onPressed: _isExporting ? null : _confirmTrim,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (_isExporting)
              Container(
                color: AppColors.background.withValues(alpha: 0.6),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrimInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TrimInfoTile({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surfaceHighlight.withValues(alpha: 0.35),
        borderRadius: AppRadius.all12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(value, style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}
