import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../../../../routing/route_paths.dart';
import '../../presentation/controllers/matchpoint_controller.dart';
import '../widgets/match_swipe_deck.dart';
import '../widgets/matchpoint_tutorial_overlay.dart';
import 'match_success_screen.dart';

class MatchpointExploreScreen extends ConsumerStatefulWidget {
  const MatchpointExploreScreen({super.key});

  @override
  ConsumerState<MatchpointExploreScreen> createState() =>
      _MatchpointExploreScreenState();
}

class _MatchpointExploreScreenState
    extends ConsumerState<MatchpointExploreScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('matchpoint_tutorial_seen') ?? false;
    if (mounted && !seen) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('matchpoint_tutorial_seen', true);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final candidatesAsync = ref.watch(matchpointCandidatesProvider);

    return Stack(
      children: [
        // Main Content
        candidatesAsync.when(
          data: (candidates) => candidates.isNotEmpty
              ? _buildSwipeDeck(candidates)
              : _buildEmptyState(),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: SkeletonShimmer(
                child: SkeletonBox(
                  width: double.infinity,
                  height: 600,
                  borderRadius: 24,
                ),
              ),
            ),
          ),
          error: (err, stack) => Center(
            child: Padding(
              padding: AppSpacing.all24,
              child: SelectableText(
                'Erro: $err',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),

        // Tutorial Overlay (if active)
        if (_showTutorial)
          Positioned.fill(
            child: MatchpointTutorialOverlay(onDismiss: _dismissTutorial),
          ),
      ],
    );
  }

  Widget _buildSwipeDeck(List<AppUser> candidates) {
    return MatchSwipeDeck(
      candidates: candidates,
      controller: _swiperController,
      onSwipeRight: (user) async {
        final swipeResult = await ref
            .read(matchpointControllerProvider.notifier)
            .swipeRight(user);

        if (!swipeResult.success) {
          debugPrint('Swipe bloqueado: backend retornou falha.');
          return;
        }

        debugPrint('Liked ${user.nome}');
        final match = swipeResult.matchedUser;

        if (match != null && context.mounted) {
          final currentUserProfile = ref
              .read(authRepositoryProvider)
              .currentUser;

          if (currentUserProfile == null) return;

          // Construct a partial AppUser or get from provider
          final minimalUser = AppUser(
            uid: currentUserProfile.uid,
            email: currentUserProfile.email ?? '',
            foto: currentUserProfile.photoURL,
          );

          final fullProfile = ref.read(currentUserProfileProvider).value;
          final bestUser = fullProfile ?? minimalUser;

          if (!context.mounted) return;
          // ignore: use_build_context_synchronously
          final navigator = Navigator.of(context);

          await navigator.push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MatchSuccessScreen(currentUser: bestUser, matchUser: match),
            ),
          );
        }
      },
      onSwipeLeft: (user) async {
        final success = await ref
            .read(matchpointControllerProvider.notifier)
            .swipeLeft(user);

        if (success) {
          debugPrint('Disliked ${user.nome}');
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied_rounded,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Nenhum perfil encontrado',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Não encontramos ninguém com seus filtros no momento.\nTente ajustar suas preferências ou volte mais tarde.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s32),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              onPressed: () {
                context.push(RoutePaths.matchpointWizard).then((_) {
                  // Refresh the provider
                  ref.invalidate(matchpointCandidatesProvider);
                });
              },
              icon: const Icon(Icons.tune),
              text: 'Ajustar Filtros',
              isFullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
