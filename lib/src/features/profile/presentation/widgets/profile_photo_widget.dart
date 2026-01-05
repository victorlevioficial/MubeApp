import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../design_system/foundations/app_colors.dart';

class ProfilePhotoWidget extends StatelessWidget {
  final String? photoUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const ProfilePhotoWidget({
    super.key,
    required this.photoUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            _buildAvatar(),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: AppColors.surface,
        child: Icon(Icons.person, size: 50, color: AppColors.textSecondary),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: 100,
        height: 100,
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          fit: BoxFit.cover,
          memCacheHeight: 200,
          memCacheWidth: 200,
          fadeInDuration: const Duration(milliseconds: 150),
          fadeOutDuration: const Duration(milliseconds: 150),
          placeholder: (_, __) => Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.surface.withOpacity(0.5),
            child: Container(color: AppColors.surface),
          ),
          errorWidget: (_, __, ___) => Container(
            color: AppColors.surface,
            child: const Icon(
              Icons.person,
              size: 50,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
