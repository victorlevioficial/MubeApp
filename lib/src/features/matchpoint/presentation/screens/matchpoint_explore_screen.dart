import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/firestore_constants.dart';
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
  bool _allCandidatesViewed = false; // Rastreia quando todos foram vistos
  String _lastCandidatesSignature = '';

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();

    // Força refresh dos candidatos ao entrar na tela
    // Necessário porque o provider tem keepAlive e pode ter cache antigo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(matchpointCandidatesProvider);
    });
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
          data: (candidates) {
            final signature = candidates.map((c) => c.uid).join('|');
            if (signature != _lastCandidatesSignature) {
              _lastCandidatesSignature = signature;
              if (_allCandidatesViewed && candidates.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  setState(() {
                    _allCandidatesViewed = false;
                  });
                });
              }
            }

            if (_allCandidatesViewed) return _buildAllViewedState();
            if (candidates.isNotEmpty) return _buildSwipeDeck(candidates);
            return _buildEmptyState();
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s16),
            child: SkeletonShimmer(
              child: Column(
                children: [
                  // Card principal
                  SkeletonBox(
                    width: double.infinity,
                    height: 480,
                    borderRadius: 24,
                  ),
                  SizedBox(height: AppSpacing.s16),
                  // Botões de ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SkeletonBox(width: 60, height: 60, borderRadius: 30),
                      SkeletonBox(width: 80, height: 80, borderRadius: 40),
                      SkeletonBox(width: 60, height: 60, borderRadius: 30),
                    ],
                  ),
                ],
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
          return false;
        }

        debugPrint('Liked ${user.nome}');
        final match = swipeResult.matchedUser;

        if (match != null && context.mounted) {
          final currentUserProfile = ref
              .read(authRepositoryProvider)
              .currentUser;

          if (currentUserProfile == null) return true;

          // Construct a partial AppUser or get from provider
          final minimalUser = AppUser(
            uid: currentUserProfile.uid,
            email: currentUserProfile.email ?? '',
            foto: currentUserProfile.photoURL,
          );

          final fullProfile = ref.read(currentUserProfileProvider).value;
          final bestUser = fullProfile ?? minimalUser;

          if (!context.mounted) return true;
          // ignore: use_build_context_synchronously
          final navigator = Navigator.of(context);

          await navigator.push(
            PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  MatchSuccessScreen(
                    currentUser: bestUser,
                    matchUser: match,
                    conversationId: swipeResult.conversationId,
                  ),
            ),
          );
        }

        return true;
      },
      onSwipeLeft: (user) async {
        // NÃO removemos da lista porque o CardSwiper gerencia os índices internamente

        final success = await ref
            .read(matchpointControllerProvider.notifier)
            .swipeLeft(user);

        if (success) {
          debugPrint('Disliked ${user.nome}');
        }

        return success;
      },
      onEnd: () {
        if (mounted) {
          setState(() {
            _allCandidatesViewed = true;
          });
        }
      },
      currentUserGenres: _getCurrentUserGenres(),
    );
  }

  /// Busca os gêneros musicais do usuário atual para calcular compatibilidade
  List<String>? _getCurrentUserGenres() {
    final userProfile = ref.read(currentUserProfileProvider).value;
    if (userProfile == null) return null;

    // Tenta buscar do matchpointProfile primeiro
    final mpGenres =
        userProfile.matchpointProfile?[FirestoreFields.musicalGenres] as List?;
    if (mpGenres != null && mpGenres.isNotEmpty) {
      return mpGenres.cast<String>();
    }

    final legacyMpGenres =
        userProfile.matchpointProfile?['musicalGenres'] as List?;
    if (legacyMpGenres != null && legacyMpGenres.isNotEmpty) {
      return legacyMpGenres.cast<String>();
    }

    final oldSnakeCase =
        userProfile.matchpointProfile?['musical_genres'] as List?;
    if (oldSnakeCase != null && oldSnakeCase.isNotEmpty) {
      return oldSnakeCase.cast<String>();
    }

    // Fallback para dadosProfissional ou dadosBanda
    final profGenres =
        userProfile.dadosProfissional?['generosMusicais'] as List?;
    if (profGenres != null && profGenres.isNotEmpty) {
      return profGenres.cast<String>();
    }

    final bandGenres = userProfile.dadosBanda?['generosMusicais'] as List?;
    if (bandGenres != null && bandGenres.isNotEmpty) {
      return bandGenres.cast<String>();
    }

    return null;
  }

  /// Tela quando todos os candidatos foram vistos
  Widget _buildAllViewedState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.s24),
          Text(
            'Você viu todos!',
            style: AppTypography.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Não há mais perfis para avaliar no momento.\nVolte mais tarde para ver novos músicos!',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s32),
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              onPressed: () {
                // Invalida o provider primeiro - vai mostrar loading state
                // O _allCandidatesViewed será resetado pelo listener quando houver dados
                ref.invalidate(matchpointCandidatesProvider);
                // Reseta após invalidar para evitar flash (loading aparece primeiro)
                if (mounted) {
                  setState(() {
                    _allCandidatesViewed = false;
                  });
                }
              },
              icon: const Icon(Icons.refresh),
              text: 'Buscar Novamente',
              isFullWidth: true,
            ),
          ),
        ],
      ),
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
