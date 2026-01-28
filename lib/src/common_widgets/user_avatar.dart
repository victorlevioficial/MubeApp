import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_typography.dart';

/// Avatar widget that shows user photo or initials with a modern professional design.
/// Features a thick border and modern pastel colors for initials fallback.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;

  const UserAvatar({super.key, this.photoUrl, this.name, this.size = 80});

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
        border: Border.all(
          color: AppColors.surfaceHighlight,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: Container(
          color: AppColors.surface, // Background for the image area
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // If photo URL exists and is not empty, show image
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: BoxFit.cover,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        memCacheWidth: (size * 2).toInt(),
        // No placeholder - shows nothing until image loads to prevent flicker
        placeholder: (context, url) => const SizedBox.shrink(),
        // Always show initials on error
        errorWidget: (context, url, error) => _buildInitialsAvatar(),
        // Use imageBuilder to ensure smooth rendering
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          );
        },
      );
    }

    // Otherwise show initials
    return _buildInitialsAvatar();
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
            color: Colors.black.withValues(alpha: 0.65),
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
