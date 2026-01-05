import 'package:flutter/material.dart';
import '../../../../common_widgets/user_avatar.dart';
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
            UserAvatar(
              size: 100,
              photoUrl: photoUrl,
              // Como não temos o nome aqui, usamos uma string vazia para o fallback de ícone
              name: '',
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.textPrimary,
                    ),
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
                  color: AppColors.textPrimary,
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
