import 'package:flutter/material.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';

class MatchpointTutorialOverlay extends StatelessWidget {
  final VoidCallback onDismiss;

  const MatchpointTutorialOverlay({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Dimension Background
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.85)),
        ),

        // Content
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Swipe Instructions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const _TutorialItem(
                    icon: Icons.swipe_left,
                    text: 'Não Curti',
                    color: AppColors.error,
                  ),
                  Container(width: 1, height: 50, color: Colors.white24),
                  const _TutorialItem(
                    icon: Icons.swipe_right,
                    text: 'Curti!',
                    color: AppColors.primary,
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // Undo Instruction
              const Icon(
                Icons.replay,
                color: AppColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Errou? Desfaça a ação',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Got it Button
              Padding(
                padding: const EdgeInsets.only(bottom: 150),
                child: FilledButton(
                  onPressed: onDismiss,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: Text(
                    'Entendi',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TutorialItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _TutorialItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: AppSpacing.s12),
        Text(text, style: AppTypography.headlineMedium.copyWith(color: color)),
      ],
    );
  }
}
