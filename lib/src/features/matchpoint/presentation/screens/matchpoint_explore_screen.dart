import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';

import '../../../../constants/firestore_constants.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/loading/app_skeleton.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../../utils/app_logger.dart';
import '../../domain/matchpoint_dynamic_fields.dart';
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
  bool _allCandidatesViewed = false;
  String _lastCandidatesSignature = '';
  int _lastHandledSwipeFeedbackId = -1;
  ProviderSubscription<MatchpointSwipeFeedbackEvent?>? _feedbackSubscription;

  bool _hasFetchedLikesQuota = false;

  /// True until fresh candidates arrive, so the UI shows the loading skeleton
  /// instead of stale cached data from a previous session.
  bool _awaitingFreshCandidates = true;

  /// Pending timers from the staggered initialization sequence. Cancelled
  /// in dispose() so navigating away during the 500ms / 2s delays does not
  /// leak timers (also keeps widget tests deterministic).
  Timer? _initStaggerTimer;
  Timer? _likesQuotaTimer;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();

    // Stagger the initial Firebase operations to avoid overwhelming the iOS
    // Swift Concurrency cooperative thread pool. In release builds (AOT),
    // Dart dispatches platform-channel calls faster than the cooperative
    // executor can drain, causing swift_task_dealloc / SIGABRT crashes.
    // A 500ms delay lets the profile stream listener and any pending
    // App Check / Auth token operations settle before we fire the
    // candidates Firestore query.
    //
    // We invalidate ONCE inside the postFrameCallback (not twice as before)
    // because firing two invalidations causes the provider's build() to
    // execute twice in quick succession, doubling the platform-channel
    // pressure on iOS during screen entry — the exact condition that
    // triggers the SIGABRT crash from the highlight card navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _initStaggerTimer = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;

        ref.invalidate(matchpointCandidatesProvider);

        // The cached state has been destroyed by invalidate(); safe to let
        // build() render normally — it will see AsyncLoading (no stale data).
        setState(() {
          _awaitingFreshCandidates = false;
        });

        _feedbackSubscription = ref.listenManual<MatchpointSwipeFeedbackEvent?>(
          matchpointSwipeFeedbackProvider,
          (previous, next) {
            if (next == null || next.id == _lastHandledSwipeFeedbackId) return;
            _lastHandledSwipeFeedbackId = next.id;
            ref.read(matchpointSwipeFeedbackProvider.notifier).clear();
            unawaited(
              _handleSwipeFeedback(next).catchError((
                Object error,
                StackTrace stack,
              ) {
                AppLogger.warning(
                  'Swipe feedback handler failed',
                  error,
                  stack,
                );
              }),
            );
          },
        );
      });
    });
  }

  Future<void> _checkTutorialStatus() async {
    final prefs = await ref.read(sharedPreferencesLoaderProvider)();
    final seen = prefs.getBool('matchpoint_tutorial_seen') ?? false;
    if (mounted && !seen) {
      setState(() {
        _showTutorial = true;
      });
    }
  }

  Future<void> _dismissTutorial() async {
    final prefs = await ref.read(sharedPreferencesLoaderProvider)();
    await prefs.setBool('matchpoint_tutorial_seen', true);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  @override
  void dispose() {
    _initStaggerTimer?.cancel();
    _likesQuotaTimer?.cancel();
    _feedbackSubscription?.close();
    _swiperController.dispose();
    // Note: do NOT call ref.invalidate() here — using ref after the widget
    // is unmounted causes a fatal "Bad state" crash (Crashlytics #de9982a4).
    // The stale-data guard is handled by initState() on re-entry instead.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Do NOT call ref.watch(matchpointCandidatesProvider) before
    // the staggered invalidation has fired. The first watch implicitly
    // triggers the provider's build() if its keep-alive cache is empty
    // (cold entry into the screen). When the _initStaggerTimer subsequently
    // fires ref.invalidate(matchpointCandidatesProvider), it triggers a
    // SECOND build() within ~500ms — two consecutive fetchCandidates()
    // calls overlap their unawaited analytics.logEvent Pigeon calls on the
    // iOS Swift Concurrency cooperative pool, causing swift_task_dealloc /
    // SIGABRT (Crashlytics issue a37e597a, confirmed in 1.6.15+162 with
    // duplicate `matchpoint_ranking_audit` breadcrumbs ~440ms apart).
    if (_awaitingFreshCandidates) {
      return Stack(
        children: [
          _buildLoadingState(),
          if (_showTutorial)
            Positioned.fill(
              child: MatchpointTutorialOverlay(onDismiss: _dismissTutorial),
            ),
        ],
      );
    }

    final candidatesAsync = ref.watch(matchpointCandidatesProvider);

    return Stack(
      children: [
        candidatesAsync.when(
          data: (candidates) {
            // Fetch likes quota only once, after candidates have loaded.
            // Delay by 2s to avoid concurrent Firebase platform-channel calls
            // that crash the iOS Swift Concurrency runtime (SIGABRT).
            // The ranking audit analytics + Firestore listeners are still
            // settling at this point; the extra gap prevents task contention
            // on the cooperative executor.
            if (!_hasFetchedLikesQuota) {
              _hasFetchedLikesQuota = true;
              _likesQuotaTimer = Timer(const Duration(seconds: 2), () {
                if (!mounted) return;
                ref
                    .read(matchpointControllerProvider.notifier)
                    .fetchRemainingLikes();
              });
            }

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
          loading: _buildLoadingState,
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
        if (_showTutorial)
          Positioned.fill(
            child: MatchpointTutorialOverlay(onDismiss: _dismissTutorial),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.s16),
      child: SkeletonShimmer(
        child: Column(
          children: [
            // Main card uses available height to avoid overflow.
            Expanded(
              child: SkeletonBox(width: double.infinity, borderRadius: 24),
            ),
            SizedBox(height: AppSpacing.s16),
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
    );
  }

  Widget _buildSwipeDeck(List<AppUser> candidates) {
    final canUndo = !ref.watch(
      matchpointSwipeQueueStateProvider.select(
        (state) => state.hasPendingActions,
      ),
    );

    return MatchSwipeDeck(
      candidates: candidates,
      controller: _swiperController,
      onSwipeRight: (user) async {
        final queued = await ref
            .read(matchpointControllerProvider.notifier)
            .queueSwipeRight(user);

        if (!queued) {
          AppLogger.warning('Swipe blocked before entering MatchPoint queue.');
          final message =
              ref
                  .read(matchpointControllerProvider)
                  .whenOrNull(error: (err, _) => err.toString()) ??
              'Não foi possível registrar seu like agora. Tente novamente.';
          if (!mounted) return false;
          AppSnackBar.error(context, message);
          return false;
        }

        AppLogger.debug('Queued like for ${user.nome}');
        return true;
      },
      onSwipeLeft: (user) async {
        final queued = await ref
            .read(matchpointControllerProvider.notifier)
            .queueSwipeLeft(user);

        if (!queued) {
          final message =
              ref
                  .read(matchpointControllerProvider)
                  .whenOrNull(error: (err, _) => err.toString()) ??
              'Não foi possível registrar seu dislike agora. Tente novamente.';
          if (!mounted) return false;
          AppSnackBar.error(context, message);
          return false;
        }

        AppLogger.debug('Queued dislike for ${user.nome}');
        return true;
      },
      onEnd: () {
        if (mounted) {
          setState(() {
            _allCandidatesViewed = true;
          });
        }
      },
      onUndoSwipe: () {
        ref.read(swipeHistoryProvider.notifier).undoLast();
      },
      currentUserGenres: _getCurrentUserGenres(),
      canUndo: canUndo,
    );
  }

  Future<void> _handleSwipeFeedback(MatchpointSwipeFeedbackEvent event) async {
    if (!mounted) return;

    if (event.isFailure) {
      final message =
          event.message ?? 'Não foi possível registrar sua ação agora.';
      AppSnackBar.error(context, message);
      return;
    }

    if (!event.isMatch) return;

    final currentUserProfile = ref.read(authRepositoryProvider).currentUser;
    if (currentUserProfile == null) return;

    final minimalUser = AppUser(
      uid: currentUserProfile.uid,
      email: currentUserProfile.email ?? '',
      foto: currentUserProfile.photoURL,
    );

    final fullProfile = ref.read(currentUserProfileProvider).value;
    final bestUser = fullProfile ?? minimalUser;
    if (!mounted) return;

    final result = await Navigator.of(context).push<MatchSuccessNavIntent>(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            MatchSuccessScreen(
              currentUser: bestUser,
              matchUser: event.targetUser,
              conversationId: event.conversationId,
            ),
      ),
    );

    // Handle navigation intent from the match overlay. The overlay cannot
    // use GoRouter directly because it was pushed via Navigator.push.
    if (result != null && mounted) {
      unawaited(
        context.push(
          RoutePaths.conversationById(result.conversationId),
          extra: {
            'otherUserId': result.otherUserId,
            'otherUserName': result.otherUserName,
            'otherUserPhoto': result.otherUserPhoto,
            'conversationType': 'matchpoint',
          },
        ),
      );
    }
  }

  List<String>? _getCurrentUserGenres() {
    final userProfile = ref.read(currentUserProfileProvider).value;
    if (userProfile == null) return null;

    final mpGenres = matchpointStringList(
      userProfile.matchpointProfile?[FirestoreFields.musicalGenres],
    );
    if (mpGenres.isNotEmpty) {
      return mpGenres;
    }

    final legacyMpGenres = matchpointStringList(
      userProfile.matchpointProfile?['musicalGenres'],
    );
    if (legacyMpGenres.isNotEmpty) {
      return legacyMpGenres;
    }

    final oldSnakeCase = matchpointStringList(
      userProfile.matchpointProfile?['musical_genres'],
    );
    if (oldSnakeCase.isNotEmpty) {
      return oldSnakeCase;
    }

    final profGenres = matchpointStringList(
      userProfile.dadosProfissional?['generosMusicais'],
    );
    if (profGenres.isNotEmpty) {
      return profGenres;
    }

    final bandGenres = matchpointStringList(
      userProfile.dadosBanda?['generosMusicais'],
    );
    if (bandGenres.isNotEmpty) {
      return bandGenres;
    }

    return null;
  }

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
                ref.invalidate(matchpointCandidatesProvider);
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
