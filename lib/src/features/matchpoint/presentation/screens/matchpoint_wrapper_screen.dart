import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';
import 'matchpoint_intro_screen.dart';
import 'matchpoint_tabs_screen.dart';

class MatchpointWrapperScreen extends ConsumerWidget {
  const MatchpointWrapperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Erro: Usuário não encontrado'));
        }

        final profile = user.matchpointProfile;
        final isActive = profile != null && profile['is_active'] == true;

        if (isActive) {
          return const MatchpointTabsScreen();
        } else {
          return const MatchpointIntroScreen();
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
    );
  }
}
