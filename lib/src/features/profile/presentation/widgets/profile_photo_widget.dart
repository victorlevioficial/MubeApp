import 'package:flutter/material.dart';
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
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.surface,
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.textSecondary,
                    )
                  : null,
            ),
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
}
