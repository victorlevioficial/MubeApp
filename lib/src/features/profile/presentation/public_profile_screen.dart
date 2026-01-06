import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

import '../../../common_widgets/user_avatar.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../../feed/data/favorites_provider.dart';
import '../domain/media_item.dart';
import 'widgets/public_gallery_grid.dart';

/// Screen to view another user's public profile.
class PublicProfileScreen extends ConsumerStatefulWidget {
  final String uid;

  const PublicProfileScreen({super.key, required this.uid});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  AppUser? _user;
  List<MediaItem> _galleryItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'Perfil não encontrado';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      data['uid'] = doc.id;

      final user = AppUser.fromJson(data);

      // Load gallery items based on user type
      List<dynamic> galleryData = [];
      switch (user.tipoPerfil) {
        case AppUserType.professional:
          galleryData =
              user.dadosProfissional?['gallery'] as List<dynamic>? ?? [];
          break;
        case AppUserType.band:
          galleryData = user.dadosBanda?['gallery'] as List<dynamic>? ?? [];
          break;
        case AppUserType.studio:
          galleryData = user.dadosEstudio?['gallery'] as List<dynamic>? ?? [];
          break;
        case AppUserType.contractor:
          galleryData =
              user.dadosContratante?['gallery'] as List<dynamic>? ?? [];
          break;
        default:
          galleryData = [];
      }

      final gallery =
          galleryData
              .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _user = user;
        _galleryItems = gallery;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar perfil: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final notifier = ref.read(favoritesProvider.notifier);
    final isFavorited = await notifier.toggleFavorite(widget.uid);

    if (mounted) {
      final message = isFavorited
          ? 'Adicionado aos favoritos ❤️'
          : 'Removido dos favoritos';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openChat() {
    // TODO: Implement chat navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat em breve!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textPrimary),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: _isLoading
          ? const _ProfileSkeleton()
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : _buildProfileContent(),
      // Fixed bottom action bar
      bottomNavigationBar: _isLoading || _error != null
          ? null
          : _buildBottomActionBar(),
    );
  }

  /// Fixed bottom bar with Chat and Like buttons
  Widget _buildBottomActionBar() {
    final isFavorited = ref.watch(isFavoritedProvider(widget.uid));

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.s16,
        right: AppSpacing.s16,
        top: AppSpacing.s12,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chat Button (Primary action)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _openChat,
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Iniciar Conversa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          // Like Button (Secondary action)
          Container(
            decoration: BoxDecoration(
              color: isFavorited
                  ? AppColors.primary
                  : AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _toggleLike,
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.white : AppColors.textPrimary,
              ),
              padding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    final user = _user!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          _buildHeader(user),

          const SizedBox(height: AppSpacing.s24),

          // Bio Section
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            _buildBioSection(user.bio!),
            const SizedBox(height: AppSpacing.s24),
          ],

          // Type-specific details
          _buildTypeSpecificDetails(user),

          // Gallery Section (always show)
          const SizedBox(height: AppSpacing.s24),
          _buildGallerySection(),

          // Extra padding at bottom to not overlap with fixed bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHeader(AppUser user) {
    final displayName = _getDisplayName(user);
    final location = user.location;

    return Center(
      child: Column(
        children: [
          // Avatar
          UserAvatar(size: 120, photoUrl: user.foto, name: displayName),
          const SizedBox(height: AppSpacing.s16),

          // Display Name
          Text(
            displayName,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          // Real name (if different from display name)
          if (displayName != user.nome &&
              user.nome != null &&
              user.nome!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(
              user.nome!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.s8),

          // Profile Type Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.tipoPerfil?.label.toUpperCase() ?? 'PROFISSIONAL',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Location
          if (location != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${location['cidade'] ?? '-'}, ${location['estado'] ?? '-'}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBioSection(String bio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sobre', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s8),
        Text(
          bio,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSpecificDetails(AppUser user) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return _buildProfessionalDetails(user);
      case AppUserType.band:
        return _buildBandDetails(user);
      case AppUserType.studio:
        return _buildStudioDetails(user);
      case AppUserType.contractor:
        return _buildContractorDetails(user);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfessionalDetails(AppUser user) {
    final prof = user.dadosProfissional;
    if (prof == null) return const SizedBox.shrink();

    final instrumentos = (prof['instrumentos'] as List?)?.cast<String>() ?? [];
    final funcoes = (prof['funcoes'] as List?)?.cast<String>() ?? [];
    final generos = (prof['generosMusicais'] as List?)?.cast<String>() ?? [];

    final skills = [...instrumentos, ...funcoes];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (skills.isNotEmpty)
          _buildChipsSection('Habilidades', skills, isSkill: true),
        if (generos.isNotEmpty)
          _buildChipsSection('Gêneros Musicais', generos, isSkill: false),
      ],
    );
  }

  Widget _buildBandDetails(AppUser user) {
    final banda = user.dadosBanda;
    if (banda == null) return const SizedBox.shrink();

    final generos = (banda['generosMusicais'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (generos.isNotEmpty)
          _buildChipsSection('Gêneros Musicais', generos, isSkill: false),
      ],
    );
  }

  Widget _buildStudioDetails(AppUser user) {
    final estudio = user.dadosEstudio;
    if (estudio == null) return const SizedBox.shrink();

    final services = (estudio['services'] as List?)?.cast<String>() ?? [];
    final studioType = estudio['studioType'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (studioType != null)
          _buildChipsSection('Tipo', [
            studioType == 'commercial' ? 'Comercial' : 'Home Studio',
          ], isSkill: true),
        if (services.isNotEmpty)
          _buildChipsSection('Serviços', services, isSkill: true),
      ],
    );
  }

  Widget _buildContractorDetails(AppUser user) {
    final contratante = user.dadosContratante;
    if (contratante == null) return const SizedBox.shrink();

    final genero = contratante['genero'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (genero != null && genero.isNotEmpty)
          _buildChipsSection('Gênero', [genero], isSkill: true),
      ],
    );
  }

  Widget _buildChipsSection(
    String title,
    List<String> items, {
    required bool isSkill,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              if (isSkill) {
                return _buildSkillChip(item);
              } else {
                return _buildGenreChip(item);
              }
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildGenreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Galeria', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.s12),
        if (_galleryItems.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceHighlight),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Galeria Vazia',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Este usuário ainda não adicionou fotos ou vídeos.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          PublicGalleryGrid(
            items: _galleryItems,
            onItemTap: (index) {
              _showMediaViewer(index);
            },
          ),
      ],
    );
  }

  void _showMediaViewer(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) =>
          _MediaViewerDialog(items: _galleryItems, initialIndex: initialIndex),
    );
  }

  String _getDisplayName(AppUser user) {
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return user.dadosProfissional?['nomeArtistico'] ?? user.nome ?? '';
      case AppUserType.band:
        return user.dadosBanda?['nomeBanda'] ?? user.nome ?? '';
      case AppUserType.studio:
        return user.dadosEstudio?['nomeArtistico'] ?? user.nome ?? '';
      default:
        return user.nome ?? '';
    }
  }
}

/// Skeleton loading for profile
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceHighlight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          children: [
            // Avatar skeleton
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            // Name skeleton
            Container(
              width: 180,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            // Badge skeleton
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 32),
            // Section skeleton
            Container(
              width: double.infinity,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            // Gallery skeleton
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: List.generate(
                6,
                (_) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen media viewer dialog
class _MediaViewerDialog extends StatefulWidget {
  final List<MediaItem> items;
  final int initialIndex;

  const _MediaViewerDialog({required this.items, required this.initialIndex});

  @override
  State<_MediaViewerDialog> createState() => _MediaViewerDialogState();
}

class _MediaViewerDialogState extends State<_MediaViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];

              if (item.type == MediaType.video) {
                return _VideoPlayerItem(videoUrl: item.url);
              }

              return InteractiveViewer(
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: item.url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.error, color: Colors.white, size: 48),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Page indicator
          if (widget.items.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.items.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget to play video in the gallery viewer
class _VideoPlayerItem extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerItem({required this.videoUrl});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _showControls = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
          _startHideControlsTimer();
        }
      });

    _controller.addListener(_videoListener);
  }

  void _videoListener() {
    if (mounted) {
      final isPlaying = _controller.value.isPlaying;
      if (isPlaying != _isPlaying) {
        setState(() => _isPlaying = isPlaying);
      }
      // Update UI for progress
      setState(() {});
    }
  }

  void _startHideControlsTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (_controller.value.isPlaying) {
      _controller.pause();
      setState(() => _showControls = true);
    } else {
      _controller.play();
      _startHideControlsTimer();
    }
  }

  void _onTap() {
    if (_showControls) {
      _togglePlay();
    } else {
      setState(() => _showControls = true);
      _startHideControlsTimer();
    }
  }

  void _seekTo(double value) {
    final duration = _controller.value.duration;
    final position = Duration(
      milliseconds: (value * duration.inMilliseconds).toInt(),
    );
    _controller.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Loading state with solid black background
    if (!_initialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),

            // Controls Overlay (auto-hide)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black38,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Play/Pause Button
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        iconSize: 64,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        onPressed: _togglePlay,
                      ),
                    ),
                    const Spacer(),

                    // Progress Bar and Timer
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: Column(
                        children: [
                          // Slider
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: AppColors.primary,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12,
                              ),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: progress.clamp(0.0, 1.0),
                              onChanged: _seekTo,
                            ),
                          ),
                          // Timer
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
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
          ],
        ),
      ),
    );
  }
}
