import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/matchpoint_availability.dart';

enum MatchpointHighlightState { active, pendingSetup, locked }

MatchpointHighlightState resolveMatchpointHighlightState(AppUser? user) {
  if (!isMatchpointAvailableForUser(user)) {
    return MatchpointHighlightState.locked;
  }

  final isActive = user?.matchpointProfile?['is_active'] == true;
  if (isActive) {
    return MatchpointHighlightState.active;
  }

  return MatchpointHighlightState.pendingSetup;
}

class MatchpointHighlightCard extends StatelessWidget {
  final AppUser? user;
  final VoidCallback onTap;

  const MatchpointHighlightCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = resolveMatchpointHighlightState(user);
    final content = _MatchpointHighlightContent.fromState(state);
    final isCompactWidth = MediaQuery.sizeOf(context).width < 380;

    return Container(
      key: const ValueKey('matchpoint_highlight_card'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.surface2,
            AppColors.surface,
          ],
        ),
        borderRadius: AppRadius.all20,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.all20,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        'MatchPoint',
                        style: AppTypography.headlineCompact.copyWith(
                          fontSize: isCompactWidth ? 22 : 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    _LightningAccent(size: isCompactWidth ? 42 : 48),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  content.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.s14),
                _buildCtaButton(content),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCtaButton(_MatchpointHighlightContent content) {
    return AppButton.secondary(
      text: content.buttonLabel,
      size: AppButtonSize.small,
      onPressed: onTap,
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
    );
  }
}

class _LightningAccent extends StatelessWidget {
  const _LightningAccent({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: AppRadius.all16,
        color: AppColors.surfaceHighlight.withValues(alpha: 0.42),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Icon(
        Icons.bolt_rounded,
        size: size * 0.58,
        color: AppColors.primary,
      ),
    );
  }
}

class _MatchpointHighlightContent {
  final String description;
  final String buttonLabel;

  const _MatchpointHighlightContent({
    required this.description,
    required this.buttonLabel,
  });

  factory _MatchpointHighlightContent.fromState(
    MatchpointHighlightState state,
  ) {
    switch (state) {
      case MatchpointHighlightState.active:
        return const _MatchpointHighlightContent(
          description:
              'Continue explorando perfis, matches e o histórico da sua rede.',
          buttonLabel: 'Abrir MatchPoint',
        );
      case MatchpointHighlightState.pendingSetup:
        return const _MatchpointHighlightContent(
          description:
              'Ative seu perfil para entrar no fluxo de descoberta por compatibilidade.',
          buttonLabel: 'Ativar MatchPoint',
        );
      case MatchpointHighlightState.locked:
        return const _MatchpointHighlightContent(
          description:
              'Disponivel para perfis Profissional e Banda. Abra a area para ver como a feature funciona.',
          buttonLabel: 'Ver detalhes',
        );
    }
  }
}
