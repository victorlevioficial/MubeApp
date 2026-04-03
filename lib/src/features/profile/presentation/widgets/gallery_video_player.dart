import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/image_cache_config.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/video_transcode_state.dart';

/// Professional video player widget with auto-hide controls
class GalleryVideoPlayer extends ConsumerStatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  final bool isActive;

  const GalleryVideoPlayer({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
    this.isActive = true,
  });

  @override
  ConsumerState<GalleryVideoPlayer> createState() => _GalleryVideoPlayerState();
}

class _GalleryVideoPlayerState extends ConsumerState<GalleryVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  double? _thumbnailAspectRatio;
  Timer? _hideControlsTimer;
  int _initializationToken = 0;
  bool _resumeAfterInterruption = true;
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumeAfterInterruption = widget.isActive;
    _resolveThumbnailAspectRatio();
    if (widget.isActive) {
      _initializePlayer();
    }
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
      unawaited(_disposeController());
      _isInitialized = false;
      _hasError = false;
      _resumeAfterInterruption = widget.isActive;
      if (widget.isActive) {
        _initializePlayer();
      }
    }

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive &&
          !_isInitialized &&
          _controller == null &&
          !_hasError) {
        _initializePlayer();
      }
      _handleActiveStateChange();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = switch (state) {
      AppLifecycleState.resumed => true,
      AppLifecycleState.inactive ||
      AppLifecycleState.hidden ||
      AppLifecycleState.paused ||
      AppLifecycleState.detached => false,
    };

    if (_isAppInForeground == isForeground) return;
    _isAppInForeground = isForeground;

    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (!isForeground) {
      _resumeAfterInterruption = controller.value.isPlaying;
      unawaited(_pauseController(controller, reason: 'app_backgrounded'));
      _hideControlsTimer?.cancel();
      if (mounted && !_showControls) {
        setState(() => _showControls = true);
      }
      return;
    }

    if (widget.isActive &&
        _resumeAfterInterruption &&
        !controller.value.isPlaying) {
      unawaited(_resumeControllerIfNeeded(controller, reason: 'app_resumed'));
    }
  }

  Future<void> _initializePlayer() async {
    final initializationToken = ++_initializationToken;
    final sourceUrl = widget.videoUrl;

    // Validação preventiva: URLs vazias ou sem scheme causam crash nativo
    // no iOS (SIGABRT) que não é capturável pelo try/catch do Dart.
    if (sourceUrl.isEmpty) {
      AppLogger.warning(
        'GalleryVideoPlayer: URL de vídeo vazia, abortando inicialização.',
      );
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }

    final uri = Uri.tryParse(sourceUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      AppLogger.warning(
        'GalleryVideoPlayer: URL de vídeo inválida ($sourceUrl), '
        'abortando inicialização.',
      );
      if (mounted) {
        setState(() => _hasError = true);
      }
      return;
    }

    final initialized = await _tryInitializeController(
      videoUrl: sourceUrl,
      initializationToken: initializationToken,
    );
    if (!_isInitializationValid(initializationToken)) return;
    if (initialized || !mounted) return;

    AppLogger.warning(
      'Falha ao iniciar vídeo sem formatHint; tentando fallback com formatHint=other.',
    );

    await _disposeController();
    final fallbackInitialized = await _tryInitializeController(
      videoUrl: sourceUrl,
      formatHint: VideoFormat.other,
      initializationToken: initializationToken,
    );
    if (!_isInitializationValid(initializationToken)) return;
    if (fallbackInitialized || !mounted) return;

    final transcodedUrl = await _resolveTranscodedVideoUrl(sourceUrl);
    if (!_isInitializationValid(initializationToken)) return;

    if (transcodedUrl != null && transcodedUrl != sourceUrl) {
      AppLogger.warning(
        'Fallback para URL transcodificada após falha no player original. '
        'source=$sourceUrl transcoded=$transcodedUrl',
      );

      await _disposeController();
      final transcodedInitialized = await _tryInitializeController(
        videoUrl: transcodedUrl,
        initializationToken: initializationToken,
      );
      if (!_isInitializationValid(initializationToken)) return;
      if (transcodedInitialized || !mounted) return;

      await _disposeController();
      final transcodedFallbackInitialized = await _tryInitializeController(
        videoUrl: transcodedUrl,
        formatHint: VideoFormat.other,
        initializationToken: initializationToken,
      );
      if (!_isInitializationValid(initializationToken)) return;
      if (transcodedFallbackInitialized || !mounted) return;
    }

    if (!fallbackInitialized && mounted) {
      await _recordPlaybackDiagnostics(
        sourceUrl: sourceUrl,
        transcodedUrl: transcodedUrl,
      );
      AppLogger.error(
        'GalleryVideoPlaybackFailed | os=${Platform.operatingSystem} '
        '${Platform.operatingSystemVersion} | source=$sourceUrl '
        '| transcodedFallback=${transcodedUrl ?? "unavailable"}',
        StateError('gallery_video_playback_failed'),
        StackTrace.current,
        true,
      );
      setState(() => _hasError = true);
    }
  }

  void _handleActiveStateChange() {
    final controller = _controller;
    if (controller == null || !_isInitialized) return;

    if (!widget.isActive) {
      _resumeAfterInterruption = controller.value.isPlaying;
      unawaited(_pauseController(controller, reason: 'widget_inactive'));
      _hideControlsTimer?.cancel();
      if (mounted && !_showControls) {
        setState(() => _showControls = true);
      }
      return;
    }

    if (_isAppInForeground &&
        _resumeAfterInterruption &&
        !controller.value.isPlaying) {
      unawaited(_resumeControllerIfNeeded(controller, reason: 'widget_active'));
    }
  }

  Future<void> _resolveThumbnailAspectRatio() async {
    final thumbnailUrl = widget.thumbnailUrl;
    if (thumbnailUrl == null || thumbnailUrl.isEmpty) return;

    final completer = Completer<Size>();
    final provider = CachedNetworkImageProvider(
      thumbnailUrl,
      cacheManager: ImageCacheConfig.thumbnailCacheManager,
      maxWidth: 640,
      maxHeight: 640,
    );
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

  Future<bool> _tryInitializeController({
    required String videoUrl,
    required int initializationToken,
    VideoFormat? formatHint,
  }) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        formatHint: formatHint,
      );

      await controller.initialize();
      await controller.setLooping(true);

      if (!_isInitializationValid(initializationToken)) {
        await controller.dispose();
        return false;
      }

      setState(() {
        _controller = controller;
        _isInitialized = true;
        _hasError = false;
      });

      if (widget.isActive && _isAppInForeground && _resumeAfterInterruption) {
        final didStartPlayback = await _playController(
          controller,
          reason: 'initial_playback',
        );
        if (didStartPlayback) {
          _showControlsWithTimer();
        }
      } else if (mounted && !_showControls) {
        setState(() => _showControls = true);
      }
      return true;
    } catch (e, s) {
      final controllerError = controller?.value.errorDescription;
      AppLogger.error(
        'Erro ao inicializar vídeo | hint=$formatHint | os=${Platform.operatingSystem} ${Platform.operatingSystemVersion} | controllerError=$controllerError | url=$videoUrl',
        e,
        s,
        false,
      );
      await controller?.dispose();
      return false;
    }
  }

  bool _isInitializationValid(int token) {
    return mounted && token == _initializationToken;
  }

  Future<String?> _resolveTranscodedVideoUrl(String originalUrl) async {
    if (isTranscodedVideoUrl(originalUrl)) return null;

    final sourceIds = _extractSourceIdsFromStorageUrl(originalUrl);
    if (sourceIds == null) return null;

    final fromTranscodeJob = await _loadTranscodedUrlFromJob(sourceIds);
    if (fromTranscodeJob != null && fromTranscodeJob.isNotEmpty) {
      return fromTranscodeJob;
    }

    return _loadTranscodedUrlFromStorage(sourceIds);
  }

  Future<String?> _loadTranscodedUrlFromJob(_StorageVideoSourceIds ids) async {
    try {
      final jobDoc = await ref
          .read(firebaseFirestoreProvider)
          .collection('mediaTranscodeJobs')
          .doc('${ids.userId}_${ids.mediaId}')
          .get();
      final data = jobDoc.data();
      if (data == null) return null;

      final status = (data['status'] as String? ?? '').toLowerCase();
      final transcodedUrl = data['transcodedUrl'] as String?;
      final hasTranscodedUrl =
          transcodedUrl != null && transcodedUrl.isNotEmpty;
      if (!hasTranscodedUrl) return null;

      if (status.isEmpty ||
          kSuccessfulVideoTranscodeStatuses.contains(status)) {
        return transcodedUrl;
      }

      AppLogger.info(
        'Transcode job retornou URL com status não final, mantendo fallback disponível. '
        'status=$status user=${ids.userId} media=${ids.mediaId}',
      );
      return transcodedUrl;
    } catch (e, s) {
      AppLogger.warning(
        'Falha ao buscar URL transcodificada em mediaTranscodeJobs '
        'user=${ids.userId} media=${ids.mediaId}',
        e,
        s,
      );
      return null;
    }
  }

  Future<String?> _loadTranscodedUrlFromStorage(
    _StorageVideoSourceIds ids,
  ) async {
    final path =
        'gallery_videos_transcoded/${ids.userId}/${ids.mediaId}/master.mp4';
    try {
      return await ref
          .read(firebaseStorageProvider)
          .ref()
          .child(path)
          .getDownloadURL();
    } on FirebaseException catch (e, s) {
      if (e.code != 'object-not-found') {
        AppLogger.warning(
          'Falha ao buscar fallback transcodificado no Storage '
          'path=$path code=${e.code}',
          e,
          s,
        );
      }
      return null;
    } catch (e, s) {
      AppLogger.warning(
        'Falha inesperada ao buscar fallback transcodificado no Storage '
        'path=$path',
        e,
        s,
      );
      return null;
    }
  }

  _StorageVideoSourceIds? _extractSourceIdsFromStorageUrl(String url) {
    final match = RegExp(
      r'gallery_videos(?!_transcoded)(?:%2f|/)([^/%?]+)(?:%2f|/)([^/%?]+)\.mp4',
      caseSensitive: false,
    ).firstMatch(url);
    if (match == null) return null;

    final userId = Uri.decodeComponent(match.group(1) ?? '').trim();
    final mediaId = Uri.decodeComponent(match.group(2) ?? '').trim();
    if (userId.isEmpty || mediaId.isEmpty) return null;

    return _StorageVideoSourceIds(userId: userId, mediaId: mediaId);
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (error, stackTrace) {
        AppLogger.warning(
          'Falha ao liberar controller de vídeo da galeria',
          error,
          stackTrace,
          false,
        );
      }
    }
  }

  Future<bool> _playController(
    VideoPlayerController controller, {
    required String reason,
  }) async {
    try {
      await controller.play();
      return true;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao reproduzir vídeo da galeria | reason=$reason',
        error,
        stackTrace,
        false,
      );
      return false;
    }
  }

  Future<bool> _pauseController(
    VideoPlayerController controller, {
    required String reason,
  }) async {
    try {
      await controller.pause();
      return true;
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao pausar vídeo da galeria | reason=$reason',
        error,
        stackTrace,
        false,
      );
      return false;
    }
  }

  Future<void> _resumeControllerIfNeeded(
    VideoPlayerController controller, {
    required String reason,
  }) async {
    final didStartPlayback = await _playController(controller, reason: reason);
    if (didStartPlayback) {
      _showControlsWithTimer();
    }
  }

  Future<void> _recordPlaybackDiagnostics({
    required String sourceUrl,
    required String? transcodedUrl,
  }) async {
    final sourceProbe = await _probeVideoUrl(sourceUrl);
    final transcodedProbe = transcodedUrl == null
        ? 'not_available'
        : await _probeVideoUrl(transcodedUrl);
    final sourceUri = Uri.tryParse(sourceUrl);

    AppLogger.setCustomKey('gallery_video_platform', Platform.operatingSystem);
    AppLogger.setCustomKey(
      'gallery_video_platform_version',
      Platform.operatingSystemVersion,
    );
    AppLogger.setCustomKey(
      'gallery_video_source_host',
      sourceUri?.host ?? 'unknown',
    );
    AppLogger.setCustomKey('gallery_video_source_probe', sourceProbe);
    AppLogger.setCustomKey(
      'gallery_video_transcoded_available',
      transcodedUrl != null,
    );
    AppLogger.setCustomKey('gallery_video_transcoded_probe', transcodedProbe);
  }

  Future<String> _probeVideoUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'unsupported_uri';
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      var response = await _sendProbeRequest(client, uri, useHead: true);
      if (response.statusCode == HttpStatus.methodNotAllowed) {
        await response.drain<void>();
        response = await _sendProbeRequest(client, uri, useHead: false);
      }

      final statusCode = response.statusCode;
      await response.drain<void>();
      return 'http_$statusCode';
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Falha ao inspecionar URL do vídeo da galeria',
        error,
        stackTrace,
        false,
      );
      return 'probe_failed_${error.runtimeType}';
    } finally {
      client.close(force: true);
    }
  }

  Future<HttpClientResponse> _sendProbeRequest(
    HttpClient client,
    Uri uri, {
    required bool useHead,
  }) async {
    final request = useHead
        ? await client.headUrl(uri)
        : await client.getUrl(uri);
    return request.close().timeout(const Duration(seconds: 4));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _initializationToken++;
    _hideControlsTimer?.cancel();
    unawaited(_disposeController());
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

  Future<void> _togglePlayPause() async {
    final controller = _controller;
    if (controller == null) return;

    final shouldPlay = !controller.value.isPlaying;
    if (mounted) {
      setState(() {
        _resumeAfterInterruption = shouldPlay;
        _showControls = true;
      });
    } else {
      _resumeAfterInterruption = shouldPlay;
    }

    if (shouldPlay) {
      await _resumeControllerIfNeeded(controller, reason: 'toggle_play_pause');
      return;
    }

    await _pauseController(controller, reason: 'toggle_play_pause');
    _showControlsWithTimer();
  }

  void _retryInitialization() {
    _hideControlsTimer?.cancel();
    unawaited(_disposeController());
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _showControls = true;
      _resumeAfterInterruption = widget.isActive;
    });
    _initializePlayer();
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
            const SizedBox(height: AppSpacing.s12),
            TextButton(
              onPressed: _retryInitialization,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return _buildLoadingPreview();
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      child: VideoPlayer(controller),
      builder: (context, value, videoChild) {
        final durationMs = value.duration.inMilliseconds.toDouble();
        final maxSlider = durationMs > 0 ? durationMs : 1.0;
        final sliderValue = value.position.inMilliseconds
            .toDouble()
            .clamp(0.0, maxSlider)
            .toDouble();
        final displayAspectRatio = _resolveDisplayAspectRatio(
          value.aspectRatio,
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
                    ?videoChild,
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
                              color: AppColors.background.withValues(
                                alpha: 0.6,
                              ),
                              shape: BoxShape.circle,
                            ),
                            padding: AppSpacing.all16,
                            child: Icon(
                              value.isPlaying ? Icons.pause : Icons.play_arrow,
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
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 14,
                                          ),
                                      activeTrackColor: AppColors.primary,
                                      inactiveTrackColor: AppColors.textPrimary
                                          .withValues(alpha: 0.24),
                                      thumbColor: AppColors.primary,
                                      overlayColor: AppColors.primary
                                          .withValues(alpha: 0.3),
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
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.s4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(value.position),
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
                                      _formatDuration(value.duration),
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
      },
    );
  }

  Widget _buildLoadingPreview() {
    final thumbnailUrl = widget.thumbnailUrl;
    final aspectRatio = _thumbnailAspectRatio ?? (16 / 9);
    final isWaitingForActivePlayback = !widget.isActive;

    Widget background = Container(
      color: AppColors.surface,
      child: const Center(
        child: Icon(
          Icons.videocam_outlined,
          color: AppColors.textSecondary,
          size: 48,
        ),
      ),
    );

    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      background = CachedNetworkImage(
        imageUrl: thumbnailUrl,
        fit: BoxFit.contain,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        useOldImageOnUrlChange: true,
        cacheManager: ImageCacheConfig.thumbnailCacheManager,
        memCacheWidth: 900,
        maxWidthDiskCache: 1400,
        placeholder: (context, url) => Container(color: AppColors.surface),
        errorWidget: (context, url, error) => Container(
          color: AppColors.surface,
          child: const Center(
            child: Icon(
              Icons.videocam_off,
              color: AppColors.textSecondary,
              size: 48,
            ),
          ),
        ),
        errorListener: (error) => AppLogger.logHandledImageError(
          source: 'GalleryVideoPlayer.loadingPreview',
          url: thumbnailUrl,
          error: error,
        ),
      );
    }

    return Container(
      color: AppColors.background,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              background,
              Container(color: AppColors.background.withValues(alpha: 0.18)),
              Center(
                child: isWaitingForActivePlayback
                    ? Container(
                        padding: AppSpacing.all12,
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: AppColors.textPrimary,
                          size: 40,
                        ),
                      )
                    : const CircularProgressIndicator(
                        color: AppColors.textPrimary,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageVideoSourceIds {
  final String userId;
  final String mediaId;

  const _StorageVideoSourceIds({required this.userId, required this.mediaId});
}
