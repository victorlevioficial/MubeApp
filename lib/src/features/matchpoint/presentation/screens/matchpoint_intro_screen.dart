import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';

class MatchpointIntroScreen extends StatelessWidget {
  const MatchpointIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 80,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(
              'Bem-vindo ao MatchPoint',
              style: AppTypography.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'A nova forma de conectar músicos e bandas incríveis. Configure seu perfil para começar.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.s32),
            ElevatedButton(
              onPressed: () {
                context.push(RoutePaths.matchpointWizard);
              },
              child: const Text('Começar Configuração'),
            ),
          ],
        ),
      ),
    );
  }
}
