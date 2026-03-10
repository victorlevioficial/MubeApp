import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/components/loading/app_loading_indicator.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../domain/matchpoint_availability.dart';
import 'matchpoint_intro_screen.dart';
import 'matchpoint_tabs_screen.dart';
import 'matchpoint_unavailable_screen.dart';

class MatchpointWrapperScreen extends ConsumerWidget {
  const MatchpointWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final user = userAsync.value;

    if (user != null) {
      return _buildResolvedState(user);
    }

    if (userAsync.isLoading) {
      return const Center(child: AppLoadingIndicator.medium());
    }

    if (userAsync.hasError) {
      return Center(child: Text('Erro: ${userAsync.error}'));
    }

    return const Center(child: Text('Erro: usuario nao encontrado'));
  }

  Widget _buildResolvedState(AppUser user) {
    if (!isMatchpointAvailableForType(user.tipoPerfil)) {
      return const MatchpointUnavailableScreen();
    }

    final profile = user.matchpointProfile;
    final isActive = profile != null && profile['is_active'] == true;

    if (isActive) {
      return const MatchpointTabsScreen();
    }
    return const MatchpointIntroScreen();
  }
}
