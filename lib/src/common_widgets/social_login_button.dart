import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../design_system/foundations/app_radius.dart';

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
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          // foregroundColor and side are inherited from specific OutlinedButtonTheme or default
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
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
            const SizedBox(width: 12),
            Text(
              text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
