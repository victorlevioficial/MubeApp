import 'package:flutter/material.dart';

import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_typography.dart';

/// Avatar widget that shows user photo or initials with random color.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;
  final double? borderRadius;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.size = 80,
    this.borderRadius,
  });

  /// List of pleasant background colors for initials avatar.
  static const List<Color> _avatarColors = [
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF26A69A), // Teal
    Color(0xFF42A5F5), // Blue
    Color(0xFF66BB6A), // Green
    Color(0xFFAB47BC), // Purple
    Color(0xFFEC407A), // Pink
    Color(0xFFFF7043), // Deep Orange
    Color(0xFF8D6E63), // Brown
    Color(0xFF78909C), // Blue Grey
    Color(0xFFFFCA28), // Amber
  ];

  /// Get deterministic color based on name hash.
  Color _getColorForName(String name) {
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
    final radius = borderRadius ?? size / 6;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: size, height: size, child: _buildContent()),
    );
  }

  Widget _buildContent() {
    // If photo URL exists and is not empty, show image
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialsAvatar(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.surface,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
                color: AppColors.textSecondary,
              ),
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
    final bgColor = displayName.isNotEmpty
        ? _getColorForName(displayName)
        : AppColors.surface;
    final initials = displayName.isNotEmpty ? _getInitials(displayName) : '?';

    // Calculate font size based on avatar size
    final fontSize = size * 0.4;

    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          initials,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
