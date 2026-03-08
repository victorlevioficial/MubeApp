import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/feedback/empty_state_widget.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../routing/route_paths.dart';
import '../providers/gig_streams.dart';
import '../widgets/gig_card.dart';

class MyGigsScreen extends ConsumerWidget {
  const MyGigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gigsAsync = ref.watch(myGigsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Meus gigs'),
      body: gigsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro: $error')),
        data: (gigs) {
          if (gigs.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.library_music_outlined,
              title: 'Voce ainda nao publicou gigs',
              subtitle: 'Quando publicar, elas aparecerao aqui.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s16),
            itemBuilder: (context, index) => GigCard(
              gig: gigs[index],
              onTap: () =>
                  context.push(RoutePaths.gigDetailById(gigs[index].id)),
            ),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
            itemCount: gigs.length,
          );
        },
      ),
    );
  }
}
