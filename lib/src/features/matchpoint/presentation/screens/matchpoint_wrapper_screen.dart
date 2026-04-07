import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/app_logger.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/matchpoint_availability.dart';
import '../matchpoint_navigation.dart';
import 'matchpoint_intro_screen.dart';
import 'matchpoint_tabs_screen.dart';
import 'matchpoint_unavailable_screen.dart';

class MatchpointWrapperScreen extends ConsumerWidget {
  const MatchpointWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.breadcrumb('mp:wrapper:build');
    final userAsync = ref.watch(currentUserProfileProvider);

    return userAsync.when(
      data: (user) {
        AppLogger.breadcrumb(
          'mp:wrapper:profile_data uid=${user?.uid ?? "null"}',
        );
        if (user == null) {
          return _buildFallbackScaffold(
            context,
            'Erro: usuario nao encontrado',
          );
        }
        return _buildResolvedState(user);
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppAppBar(
          title: 'Matchpoint',
          showBackButton: true,
          onBackPressed: () => handleMatchpointBack(context),
        ),
        body: const Center(child: AppLoadingIndicator.medium()),
      ),
      error: (error, stack) {
        AppLogger.warning(
          'MatchpointWrapper: profile stream error',
          error,
          stack,
        );
        // If previous data exists, use it to avoid blocking the user.
        final previousUser = userAsync.value;
        if (previousUser != null) {
          return _buildResolvedState(previousUser);
        }
        return _buildFallbackScaffold(context, 'Erro: $error');
      },
    );
  }

  Widget _buildResolvedState(AppUser user) {
    if (!isMatchpointAvailableForUser(user)) {
      AppLogger.breadcrumb('mp:wrapper:unavailable');
      return const MatchpointUnavailableScreen(showBackButton: true);
    }

    final profile = user.matchpointProfile;
    final isActive = profile != null && profile['is_active'] == true;
    AppLogger.breadcrumb('mp:wrapper:resolve isActive=$isActive');

    if (isActive) {
      AppLogger.setCustomKey('mp_step', 'wrapper:returning_tabs');
      return const MatchpointTabsScreen();
    }
    return const MatchpointIntroScreen();
  }

  Widget _buildFallbackScaffold(BuildContext context, String message) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Matchpoint',
        showBackButton: true,
        onBackPressed: () => handleMatchpointBack(context),
      ),
      body: Center(
        child: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
