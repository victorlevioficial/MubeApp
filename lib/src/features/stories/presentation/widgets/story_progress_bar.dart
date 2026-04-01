import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_motion.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';

class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.progress,
  });

  final int itemCount;
  final int currentIndex;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (itemCount <= 0) return const SizedBox.shrink();

    return Row(
      children: List.generate(itemCount, (index) {
        final fill = switch (index) {
          _ when index < currentIndex => 1.0,
          _ when index > currentIndex => 0.0,
          _ => progress.clamp(0.0, 1.0),
        };

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == itemCount - 1 ? 0 : AppSpacing.s4,
            ),
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: SizedBox(
                height: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.textPrimary.withValues(alpha: 0.18),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: fill),
                      duration: AppMotion.short,
                      curve: AppMotion.standardCurve,
                      builder: (context, value, _) {
                        return FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value,
                          child: Container(color: AppColors.textPrimary),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
