import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../core/services/image_cache_config.dart';
import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_typography.dart';

/// Avatar widget that shows user photo or initials with a modern professional design.
/// Features a thick border and modern pastel colors for initials fallback.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;
  final bool showBorder;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.size = 80,
    this.showBorder = true,
  });

  /// List of modern pastel background colors.
  static const List<Color> _avatarColors = AppColors.avatarColors;

  /// Get deterministic color based on name hash.
  Color _getColorForName(String name) {
    if (name.isEmpty) return AppColors.surfaceHighlight;
    final hash = name.hashCode.abs();
    return _avatarColors[hash % _avatarColors.length];
  }

  /// Get initials from name (first letter, or first 2 if multiple words).
  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    const borderWidth = 2.5;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.surfaceHighlight, width: borderWidth)
            : null,
      ),
      child: ClipOval(
        child: Container(
          color: AppColors.surface, // Background for the image area
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final pixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    final cacheSize = (size * pixelRatio).round().clamp(64, 1024).toInt();

    // If photo URL exists and is not empty, show image
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      final imageProvider = CachedNetworkImageProvider(
        photoUrl!,
        cacheManager: ImageCacheConfig.profileCacheManager,
        maxWidth: cacheSize,
        maxHeight: cacheSize,
      );

      return Image(
        image: imageProvider,
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
      );
    }

    // Otherwise show initials
    return _buildInitialsAvatar();
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceHighlight,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final displayName = name ?? '';
    final bgColor = _getColorForName(displayName);
    final initials = displayName.isNotEmpty ? _getInitials(displayName) : '?';

    // Calculate font size based on avatar size
    final fontSize = size * 0.38;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, bgColor.withValues(alpha: 0.9)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.titleMedium.copyWith(
            // Use a dark tonal color for text to look more professional with pastels
            color: AppColors.background.withValues(alpha: 0.65),
            fontSize: fontSize,
            fontWeight: AppTypography.buttonPrimary.fontWeight,
            letterSpacing: AppTypography.headlineLarge.letterSpacing,
          ),
        ),
      ),
    );
  }
}
