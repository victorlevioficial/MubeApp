import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import '../../foundations/tokens/app_typography.dart';

enum SocialType { google, apple }

class SocialLoginButton extends StatelessWidget {
  final SocialType type;
  final VoidCallback onPressed;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isGoogle = type == SocialType.google;
    final text = isGoogle ? 'Continuar com Google' : 'Continuar com Apple';
    final assetPath = isGoogle
        ? 'assets/images/icons/google.svg'
        : 'assets/images/icons/apple.svg';

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.s48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.transparent,
          // foregroundColor and side are inherited from specific OutlinedButtonTheme or default
          elevation: 0,
          padding: AppSpacing.h16,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: AppSpacing.s24,
              height: AppSpacing.s24,
              child: Center(
                child: SvgPicture.asset(
                  assetPath,
                  width: isGoogle ? 18 : 20,
                  height: isGoogle ? 18 : 20,
                  colorFilter: isGoogle
                      ? null // Original Google Colors
                      : ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        ), // Adaptable to light/dark themes
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Text(
              text,
              style: AppTypography.buttonSecondary.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
