import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mube/src/constants/firestore_constants.dart';
import 'package:mube/src/core/domain/app_config.dart';
import 'package:mube/src/core/providers/app_config_provider.dart';
import 'package:mube/src/core/providers/firebase_providers.dart';
import 'package:mube/src/core/services/analytics/analytics_provider.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_feed_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_command_repository.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_outbox_coordinator.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_swipe_outbox_store.dart';
import 'package:mube/src/features/matchpoint/domain/hashtag_ranking.dart';
import 'package:mube/src/features/matchpoint/domain/match_info.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command.dart';
import 'package:mube/src/features/matchpoint/domain/matchpoint_swipe_command_result.dart';
import 'package:mube/src/features/matchpoint/domain/swipe_history_entry.dart';
import 'package:mube/src/features/moderation/data/blocked_users_provider.dart';
import 'package:mube/src/utils/app_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'matchpoint_controller.g.dart';

final matchpointSelectedTabNotifier = ValueNotifier<int>(0);

class LikesQuotaState {
  final int remaining;
  final int limit;
  final DateTime? resetTime;
  final bool isLoading;

  const LikesQuotaState({
    this.remaining = 50,
    this.limit = 50,
    this.resetTime,
    this.isLoading = false,
  });

  bool get hasReachedLimit => remaining <= 0;

  LikesQuotaState copyWith({
    int? remaining,
    int? limit,
    DateTime? resetTime,
    bool? isLoading,
  }) {
    return LikesQuotaState(
      remaining: remaining ?? this.remaining,
      limit: limit ?? this.limit,
      resetTime: resetTime ?? this.resetTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SwipeActionResult {
  final bool success;
  final AppUser? matchedUser;
  final String? conversationId;

  const SwipeActionResult({
    required this.success,
    this.matchedUser,
    this.conversationId,
  });
}

enum MatchpointSwipeFeedbackKind { failure, match }

class MatchpointSwipeFeedbackEvent {
  final int id;
  final MatchpointSwipeFeedbackKind kind;
  final AppUser targetUser;
  final String action;
  final String? message;
  final String? conversationId;

  const MatchpointSwipeFeedbackEvent._({
    required this.id,
    required this.kind,
    required this.targetUser,
    required this.action,
    this.message,
    this.conversationId,
  });

  const MatchpointSwipeFeedbackEvent.failure({
    required int id,
    required AppUser targetUser,
    required String action,
    required String message,
  }) : this._(
         id: id,
         kind: MatchpointSwipeFeedbackKind.failure,
         targetUser: targetUser,
         action: action,
         message: message,
       );

  const MatchpointSwipeFeedbackEvent.match({
    required int id,
    required AppUser targetUser,
    required String action,
    String? conversationId,
  }) : this._(
         id: id,
         kind: MatchpointSwipeFeedbackKind.match,
         targetUser: targetUser,
         action: action,
         conversationId: conversationId,
       );

  bool get isFailure => kind == MatchpointSwipeFeedbackKind.failure;
  bool get isMatch => kind == MatchpointSwipeFeedbackKind.match;
}

class MatchpointSwipeQueueState {
  final int pendingActions;

  const MatchpointSwipeQueueState({this.pendingActions = 0});

  bool get hasPendingActions => pendingActions > 0;

  MatchpointSwipeQueueState copyWith({int? pendingActions}) {
    return MatchpointSwipeQueueState(
      pendingActions: pendingActions ?? this.pendingActions,
    );
  }
}

class MatchpointSwipeQueueStateController
    extends Notifier<MatchpointSwipeQueueState> {
  @override
  MatchpointSwipeQueueState build() {
    return const MatchpointSwipeQueueState();
  }

  void setPendingActions(int nextValue) {
    final normalizedValue = nextValue < 0 ? 0 : nextValue;
    if (state.pendingActions == normalizedValue) return;
    state = state.copyWith(pendingActions: normalizedValue);
  }
}

final matchpointSwipeQueueStateProvider =
    NotifierProvider<
      MatchpointSwipeQueueStateController,
      MatchpointSwipeQueueState
    >(MatchpointSwipeQueueStateController.new);

class MatchpointSwipeFeedbackController
    extends Notifier<MatchpointSwipeFeedbackEvent?> {
  @override
  MatchpointSwipeFeedbackEvent? build() {
    return null;
  }

  void emit(MatchpointSwipeFeedbackEvent event) {
    state = event;
  }

  void clear() {
    if (state == null) return;
    state = null;
  }
}

final matchpointSwipeFeedbackProvider =
    NotifierProvider<
      MatchpointSwipeFeedbackController,
      MatchpointSwipeFeedbackEvent?
    >(MatchpointSwipeFeedbackController.new);

class _QueuedSwipeAction {
  final AppUser targetUser;
  final String type;
  final bool reservedLikeQuota;

  const _QueuedSwipeAction({
    required this.targetUser,
    required this.type,
    this.reservedLikeQuota = false,
  });
}

@Riverpod(keepAlive: true)
class MatchpointController extends _$MatchpointController {
  static const Duration _deferredQueuedSwipeDrainDelay = Duration(
    milliseconds: 750,
  );
  static const Duration _queuedOutboxFlushDelay = Duration(seconds: 2);

  @visibleForTesting
  static bool? debugForceDeferredQueuedSwipeDrain;

  @visibleForTesting
  static Duration debugDeferredQueuedSwipeDrainDelay =
      _deferredQueuedSwipeDrainDelay;

  final Queue<_QueuedSwipeAction> _queuedSwipes = Queue<_QueuedSwipeAction>();
  Timer? _queuedSwipeDrainTimer;
  bool _isProcessingQueuedSwipes = false;
  bool _shouldRefreshCandidatesAfterFailure = false;
  int _nextSwipeFeedbackId = 0;

  @override
  FutureOr<void> build() {
    ref.onDispose(() {
      _queuedSwipeDrainTimer?.cancel();
      _queuedSwipeDrainTimer = null;
    });
  }

  @visibleForTesting
  static bool shouldDeferQueuedSwipeDrain({
    bool isReleaseMode = kReleaseMode,
    bool isWeb = kIsWeb,
    TargetPlatform? platform,
  }) {
    final resolvedPlatform = platform ?? defaultTargetPlatform;
    return isReleaseMode && !isWeb && resolvedPlatform == TargetPlatform.iOS;
  }

  bool get _shouldDeferQueuedSwipeDrain {
    final debugOverride = debugForceDeferredQueuedSwipeDrain;
    if (debugOverride != null) return debugOverride;
    return shouldDeferQueuedSwipeDrain() &&
        !FirestoreMatchpointSwipeCommandRepository.shouldBypassImmediateSubmission();
  }

  Duration get _queuedSwipeDrainDelay {
    if (debugForceDeferredQueuedSwipeDrain != null) {
      return debugDeferredQueuedSwipeDrainDelay;
    }
    return _deferredQueuedSwipeDrainDelay;
  }

  Future<void> saveMatchpointProfile({
    required String intent,
    required List<String> genres,
    required List<String> hashtags,
    required bool isVisibleInHome,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final appUser = ref.read(currentUserProfileProvider).value;
      if (appUser == null) {
        throw Exception('Perfil não carregado');
      }

      final authRepo = ref.read(authRepositoryProvider);
      final normalizedHashtags = _normalizeHashtagList(hashtags);

      final updatedMatchpointProfile = <String, dynamic>{
        ...appUser.matchpointProfile ?? {},
        FirestoreFields.intent: intent,
        FirestoreFields.musicalGenres: genres,
        FirestoreFields.hashtags: normalizedHashtags,
        FirestoreFields.isActive: true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final updatedPrivacy = <String, dynamic>{
        ...appUser.privacySettings,
        'visible_in_home': isVisibleInHome,
      };

      final updatedUser = appUser.copyWith(
        matchpointProfile: updatedMatchpointProfile,
        privacySettings: updatedPrivacy,
      );

      final result = await authRepo.updateUser(updatedUser);

      return result.fold((failure) => throw failure.message, (_) {
        unawaited(
          ref
              .read(analyticsServiceProvider)
              .logMatchPointFilter(
                instruments: [],
                genres: genres,
                distance: 0,
              ),
        );
        return null;
      });
    });
  }

  List<String> _normalizeHashtagList(Iterable<String> source) {
    final normalizedTags = <String>[];
    final seen = <String>{};

    for (final raw in source) {
      final token = _normalizeHashtagToken(raw);
      if (token.isEmpty) continue;

      final hashtag = '#$token';
      if (seen.add(hashtag)) {
        normalizedTags.add(hashtag);
      }
    }

    return normalizedTags;
  }

  String _normalizeHashtagToken(String rawValue) {
    final withoutHash = rawValue.replaceAll('#', '');
    final withoutDiacritics = removeDiacritics(withoutHash);
    final noSpaces = withoutDiacritics.replaceAll(RegExp(r'\s+'), '');
    final normalized = noSpaces.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return normalized.toLowerCase();
  }

  Future<SwipeActionResult> swipeRight(AppUser targetUser) async {
    return _handleSwipe(targetUser, 'like');
  }

  Future<bool> queueSwipeRight(AppUser targetUser) async {
    return _enqueueSwipe(targetUser, 'like');
  }

  Future<bool> swipeLeft(AppUser targetUser) async {
    final result = await _handleSwipe(targetUser, 'dislike');
    return result.success;
  }

  Future<bool> queueSwipeLeft(AppUser targetUser) async {
    return _enqueueSwipe(targetUser, 'dislike');
  }

  Future<bool> _enqueueSwipe(AppUser targetUser, String type) async {
    final authRepo = ref.read(authRepositoryProvider);
    if (authRepo.currentUser == null) {
      state = const AsyncError(
        'Sua sessão expirou. Faça login novamente.',
        StackTrace.empty,
      );
      return false;
    }

    // Note: fetchRemainingLikes() is intentionally NOT called here. The
    // submitMatchpointAction Cloud Function returns the updated quota in
    // its response and _buildSwipeSuccessResult applies it via
    // likesQuotaProvider.updateRemaining(). The local optimistic decrement
    // below keeps the UI snappy in the meantime, and the local quota
    // converges to the server value after the first successful submit.
    // Calling fetchRemainingLikes() on entry was the smoking-gun trigger
    // for the iOS SIGABRT (Crashlytics issue a37e597a Crash 2): a Cloud
    // Function Pigeon call landing while the Firestore queries were still
    // draining on the Swift cooperative pool.

    var reservedLikeQuota = false;
    if (type == 'like' && ref.read(likesQuotaProvider).hasReachedLimit) {
      state = const AsyncError(
        'Limite diário de 50 swipes atingido. Tente novamente amanhã.',
        StackTrace.empty,
      );
      return false;
    }

    if (type == 'like') {
      ref.read(likesQuotaProvider.notifier).decrementOptimistically();
      reservedLikeQuota = true;
    }

    _queuedSwipes.add(
      _QueuedSwipeAction(
        targetUser: targetUser,
        type: type,
        reservedLikeQuota: reservedLikeQuota,
      ),
    );
    _syncQueuedSwipeState();
    AppLogger.info(
      'MatchPoint swipe queued: action=$type target=${targetUser.uid} '
      'pending=${_queuedSwipes.length}',
    );

    _scheduleQueuedSwipeDrain();

    return true;
  }

  void _scheduleQueuedSwipeDrain() {
    if (_isProcessingQueuedSwipes || _queuedSwipes.isEmpty || !ref.mounted) {
      return;
    }

    _queuedSwipeDrainTimer?.cancel();
    if (_shouldDeferQueuedSwipeDrain) {
      // Avoid stacking Firebase Auth/App Check/Functions calls on the same
      // gesture frame in iOS release builds, where the swipe animation and the
      // native Firebase work were racing inside Swift Concurrency.
      _queuedSwipeDrainTimer = Timer(
        _queuedSwipeDrainDelay,
        _startQueuedSwipeDrain,
      );
      return;
    }

    _startQueuedSwipeDrain();
  }

  void _startQueuedSwipeDrain() {
    if (_isProcessingQueuedSwipes || _queuedSwipes.isEmpty || !ref.mounted) {
      return;
    }

    _queuedSwipeDrainTimer?.cancel();
    _queuedSwipeDrainTimer = null;
    unawaited(_drainQueuedSwipes());
  }

  Future<SwipeActionResult> _handleSwipe(
    AppUser targetUser,
    String type, {
    bool reservedLikeQuota = false,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      state = const AsyncError(
        'Sua sessão expirou. Faça login novamente.',
        StackTrace.empty,
      );
      return const SwipeActionResult(success: false);
    }

    final commandRepository = ref.read(
      matchpointSwipeCommandRepositoryProvider,
    );
    final result = await commandRepository.submit(
      MatchpointSwipeCommand(
        sourceUserId: currentUser.uid,
        targetUserId: targetUser.uid,
        action: _swipeActionFromType(type),
        createdAt: DateTime.now(),
      ),
    );

    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (_) => throw StateError('Expected swipe failure'),
      );

      AppLogger.error('Failed to process swipe: $failure');
      state = AsyncError(failure.message, StackTrace.current);
      return const SwipeActionResult(success: false);
    }

    final actionResult = result.fold(
      (_) => throw StateError('Expected swipe success'),
      (success) => success,
    );
    if (actionResult.isQueued && actionResult.commandId != null) {
      ref
          .read(matchpointSwipeOutboxCoordinatorProvider)
          .scheduleFlush(
            delay: _queuedOutboxFlushDelay,
            reason: 'queued_swipe:$type',
          );
      unawaited(
        _awaitSwipeCommandCompletion(
          commandId: actionResult.commandId!,
          targetUser: targetUser,
          type: type,
          reservedLikeQuota: reservedLikeQuota,
        ),
      );
    }
    return _buildSwipeSuccessResult(
      targetUser: targetUser,
      type: type,
      actionResult: actionResult,
    );
  }

  Future<void> drainPendingSwipesNow() async {
    if (!ref.mounted) return;
    _queuedSwipeDrainTimer?.cancel();
    _queuedSwipeDrainTimer = null;
    if (_isProcessingQueuedSwipes || _queuedSwipes.isEmpty) {
      return;
    }
    await _drainQueuedSwipes();
  }

  Future<void> _awaitSwipeCommandCompletion({
    required String commandId,
    required AppUser targetUser,
    required String type,
    required bool reservedLikeQuota,
  }) async {
    final commandRepository = ref.read(
      matchpointSwipeCommandRepositoryProvider,
    );
    final command = MatchpointSwipeCommand(
      sourceUserId: ref.read(authRepositoryProvider).currentUser?.uid ?? '',
      targetUserId: targetUser.uid,
      action: _swipeActionFromType(type),
      createdAt: DateTime.now(),
      idempotencyKey: commandId,
    );

    final result = await commandRepository.awaitResult(
      command,
      commandId: commandId,
    );
    if (!ref.mounted) return;

    if (result.isLeft()) {
      final failure = result.fold(
        (failure) => failure,
        (_) => throw StateError('Expected deferred swipe failure'),
      );
      if (reservedLikeQuota) {
        ref.read(likesQuotaProvider.notifier).incrementOptimistically();
      }
      AppLogger.error('Deferred MatchPoint swipe command failed: $failure');
      state = AsyncError(failure.message, StackTrace.current);
      _emitSwipeFeedback(
        MatchpointSwipeFeedbackEvent.failure(
          id: _nextSwipeFeedbackId++,
          targetUser: targetUser,
          action: type,
          message: failure.message,
        ),
      );
      await _refreshCandidatesAfterQueueFailure();
      return;
    }

    final completion = result.fold(
      (_) => throw StateError('Expected deferred swipe success'),
      (completion) => completion,
    );
    if (!completion.isProcessed) return;
    final swipeResult = _buildSwipeSuccessResult(
      targetUser: targetUser,
      type: type,
      actionResult: completion,
      recordHistory: false,
      logSubmission: false,
    );
    if (swipeResult.matchedUser != null) {
      _emitSwipeFeedback(
        MatchpointSwipeFeedbackEvent.match(
          id: _nextSwipeFeedbackId++,
          targetUser: swipeResult.matchedUser!,
          action: type,
          conversationId: swipeResult.conversationId,
        ),
      );
    }
  }

  Future<void> _drainQueuedSwipes() async {
    if (_isProcessingQueuedSwipes) return;

    _queuedSwipeDrainTimer?.cancel();
    _queuedSwipeDrainTimer = null;
    _isProcessingQueuedSwipes = true;
    _syncQueuedSwipeState();

    try {
      while (_queuedSwipes.isNotEmpty) {
        final nextAction = _queuedSwipes.removeFirst();
        _syncQueuedSwipeState();

        final result = await _handleSwipe(
          nextAction.targetUser,
          nextAction.type,
          reservedLikeQuota: nextAction.reservedLikeQuota,
        );
        if (!result.success) {
          if (nextAction.reservedLikeQuota) {
            ref.read(likesQuotaProvider.notifier).incrementOptimistically();
          }
          final message =
              state.whenOrNull(error: (error, _) => error.toString()) ??
              _fallbackSwipeFailureMessage(nextAction.type);
          _shouldRefreshCandidatesAfterFailure = true;
          _emitSwipeFeedback(
            MatchpointSwipeFeedbackEvent.failure(
              id: _nextSwipeFeedbackId++,
              targetUser: nextAction.targetUser,
              action: nextAction.type,
              message: message,
            ),
          );
          continue;
        }

        if (result.matchedUser != null) {
          _emitSwipeFeedback(
            MatchpointSwipeFeedbackEvent.match(
              id: _nextSwipeFeedbackId++,
              targetUser: result.matchedUser!,
              action: nextAction.type,
              conversationId: result.conversationId,
            ),
          );
        }
      }
    } finally {
      _isProcessingQueuedSwipes = false;
      _syncQueuedSwipeState();
    }

    if (_shouldRefreshCandidatesAfterFailure && ref.mounted) {
      _shouldRefreshCandidatesAfterFailure = false;
      await _refreshCandidatesAfterQueueFailure();
    }
  }

  void _emitSwipeFeedback(MatchpointSwipeFeedbackEvent event) {
    if (!ref.mounted) return;
    ref.read(matchpointSwipeFeedbackProvider.notifier).emit(event);
  }

  void _syncQueuedSwipeState() {
    if (!ref.mounted) return;
    final outstandingActions =
        _queuedSwipes.length + (_isProcessingQueuedSwipes ? 1 : 0);
    ref
        .read(matchpointSwipeQueueStateProvider.notifier)
        .setPendingActions(outstandingActions);
  }

  Future<void> _refreshCandidatesAfterQueueFailure() async {
    if (!ref.mounted) return;
    try {
      await ref.read(matchpointCandidatesProvider.notifier).refresh();
    } catch (error, stackTrace) {
      final isDisposedDuringRefresh =
          !ref.mounted ||
          (error is StateError &&
              error.message.toString().contains(
                'matchpointCandidatesProvider was disposed during loading state',
              ));
      if (isDisposedDuringRefresh) return;
      AppLogger.warning(
        'Failed to refresh MatchPoint candidates after queued swipe failure.',
        error,
        stackTrace,
        false,
      );
    }
  }

  String _fallbackSwipeFailureMessage(String type) {
    if (type == 'like') {
      return 'Não foi possível registrar seu like agora. Tente novamente.';
    }
    return 'Não foi possível registrar seu dislike agora. Tente novamente.';
  }

  SwipeActionResult _buildSwipeSuccessResult({
    required AppUser targetUser,
    required String type,
    required MatchpointSwipeCommandResult actionResult,
    bool recordHistory = true,
    bool logSubmission = true,
  }) {
    if (actionResult.remainingLikes != null) {
      ref
          .read(likesQuotaProvider.notifier)
          .updateRemaining(actionResult.remainingLikes!);
    }

    if (recordHistory) {
      ref.read(swipeHistoryProvider.notifier).addSwipe(targetUser, type);
    }
    if (logSubmission) {
      AppLogger.info(
        'MatchPoint swipe submitted: action=$type target=${targetUser.uid} '
        'status=${actionResult.status.name} '
        'match=${actionResult.isMatch} '
        'remainingLikes=${actionResult.remainingLikes ?? 'unknown'}',
      );
    }

    if (!actionResult.isProcessed) {
      return const SwipeActionResult(success: true);
    }

    if (actionResult.isMatch) {
      AppLogger.info("IT'S A MATCH!");
      ref.invalidate(matchesProvider);
      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        try {
          final chatRepository = ref.read(chatRepositoryProvider);
          unawaited(
            chatRepository
                .reevaluateConversationAccessByUsers(
                  userAId: currentUserId,
                  userBId: targetUser.uid,
                  trigger: 'matchpoint_match',
                )
                .then(
                  (result) => result.fold(
                    (failure) => AppLogger.warning(
                      'Falha ao promover conversa apos match',
                      failure.message,
                    ),
                    (_) {},
                  ),
                ),
          );
        } catch (e, stackTrace) {
          AppLogger.warning(
            'Promocao de conversa apos match indisponivel neste contexto',
            '$e\n$stackTrace',
          );
        }
      }

      return SwipeActionResult(
        success: true,
        matchedUser: targetUser,
        conversationId: actionResult.conversationId,
      );
    }

    return const SwipeActionResult(success: true);
  }

  Future<void> unmatchUser(String targetUserId) async {
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) return;

    final commandRepository = ref.read(
      matchpointSwipeCommandRepositoryProvider,
    );
    final result = await commandRepository.submit(
      MatchpointSwipeCommand(
        sourceUserId: currentUser.uid,
        targetUserId: targetUserId,
        action: MatchpointSwipeAction.dislike,
        createdAt: DateTime.now(),
      ),
    );

    result.fold(
      (failure) {
        AppLogger.error('Failed to unmatch user: ${failure.message}');
      },
      (_) {
        AppLogger.info('MatchpointController: unmatched $targetUserId');
        ref.invalidate(matchesProvider);
      },
    );
  }

  Future<void> fetchRemainingLikes() async {
    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.getRemainingLikes();

    result.fold(
      (failure) {
        AppLogger.error('Failed to fetch likes quota: ${failure.message}');
      },
      (quota) {
        ref
            .read(likesQuotaProvider.notifier)
            .setQuota(
              remaining: quota.remaining,
              limit: quota.limit,
              resetTime: quota.resetTime,
            );
      },
    );
  }
}

MatchpointSwipeAction _swipeActionFromType(String type) {
  switch (type) {
    case 'like':
      return MatchpointSwipeAction.like;
    case 'dislike':
      return MatchpointSwipeAction.dislike;
    default:
      throw ArgumentError.value(type, 'type', 'Unsupported swipe action');
  }
}

@Riverpod(keepAlive: true)
class LikesQuota extends _$LikesQuota {
  @override
  LikesQuotaState build() {
    return const LikesQuotaState();
  }

  void setQuota({
    required int remaining,
    required int limit,
    required DateTime resetTime,
  }) {
    state = LikesQuotaState(
      remaining: remaining,
      limit: limit,
      resetTime: resetTime,
      isLoading: false,
    );
  }

  void updateRemaining(int remaining) {
    state = state.copyWith(remaining: remaining);
  }

  void decrementOptimistically() {
    if (state.remaining > 0) {
      state = state.copyWith(remaining: state.remaining - 1);
    }
  }

  void incrementOptimistically() {
    if (state.remaining >= state.limit) return;
    state = state.copyWith(remaining: state.remaining + 1);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

@Riverpod(keepAlive: true)
class MatchpointCandidates extends _$MatchpointCandidates {
  @override
  Future<List<AppUser>> build() async {
    AppLogger.breadcrumb('mp:cand:build');
    AppLogger.setCustomKey('mp_step', 'cand:build');
    final authRepo = ref.read(authRepositoryProvider);
    final currentUser = authRepo.currentUser;
    if (currentUser == null) {
      AppLogger.breadcrumb('mp:cand:no_auth');
      return [];
    }

    // Use ref.read (not ref.watch) for the profile to avoid the candidates
    // provider rebuilding every time the Firestore profile stream emits.
    // Each rebuild fires a fresh fetchCandidates() — multiple in-flight
    // fetches stack platform-channel calls that crash the iOS Swift
    // Concurrency runtime (SIGABRT). Manual refresh via initState's
    // explicit invalidate() is the trigger for fresh data instead.
    final profileAsync = ref.read(currentUserProfileProvider);
    final userProfile = profileAsync.value;

    if (profileAsync.isLoading && userProfile == null) {
      AppLogger.info('MatchPoint: waiting for current profile...');
      AppLogger.breadcrumb('mp:cand:profile_loading');
      return [];
    }

    if (userProfile == null) {
      AppLogger.breadcrumb('mp:cand:no_profile');
      return [];
    }

    final rawGenres = _resolveGenres(userProfile);
    final hashtags = _resolveHashtags(userProfile);
    // Use ref.read (not ref.watch) for appConfig and blockedUsers to avoid
    // opening extra Firestore listeners on the same frame. These values are
    // stable during a matchpoint session and don't need reactive rebuilds.
    // This reduces concurrent platform-channel calls that crash the iOS
    // Swift Concurrency runtime (swift_Concurrency_fatalError / SIGABRT).
    final appConfig = ref
        .read(appConfigProvider)
        .maybeWhen(data: (config) => config, orElse: () => null);
    final genres = _buildQueryGenres(rawGenres, appConfig?.genres ?? const []);

    AppLogger.info(
      'MatchPoint filters: rawGenres=$rawGenres queryGenres=$genres hashtags=$hashtags',
    );

    final blockedState = ref.read(blockedUsersProvider);
    final blockedFromCollection = blockedState.when(
      data: (value) => value,
      loading: () => const <String>[],
      error: (_, _) => const <String>[],
    );

    final blockedUsers = {
      ...userProfile.blockedUsers,
      ...blockedFromCollection,
    }.toList();
    final pendingOutboxTargetIds = await _loadPendingOutboxTargetIds(
      currentUser.uid,
    );

    final repo = ref.read(matchpointFeedRepositoryProvider);
    AppLogger.breadcrumb('mp:cand:repo_call');
    final result = await repo.fetchExploreFeed(
      currentUser: userProfile,
      genres: genres,
      hashtags: hashtags,
      blockedUsers: blockedUsers,
    );
    AppLogger.breadcrumb('mp:cand:repo_returned');

    return result.fold(
      (failure) {
        AppLogger.error('MatchPoint query error: ${failure.message}');
        AppLogger.breadcrumb('mp:cand:fail ${failure.message}');
        throw failure.message;
      },
      (snapshot) {
        final locallyFilteredCandidates = snapshot.candidates
            .where(
              (candidate) => !pendingOutboxTargetIds.contains(candidate.uid),
            )
            .toList(growable: false);
        if (locallyFilteredCandidates.length != snapshot.candidates.length) {
          AppLogger.info(
            'MatchPoint local exclusion filtered '
            '${snapshot.candidates.length - locallyFilteredCandidates.length} '
            'pending outbox candidates',
          );
        }
        AppLogger.info(
          'MatchPoint query success: found ${locallyFilteredCandidates.length} candidates '
          'source=${snapshot.source.name}',
        );
        AppLogger.breadcrumb(
          'mp:cand:success count=${locallyFilteredCandidates.length}',
        );
        AppLogger.setCustomKey('mp_step', 'cand:success');
        return locallyFilteredCandidates;
      },
    );
  }

  Future<Set<String>> _loadPendingOutboxTargetIds(String userId) async {
    try {
      final pendingCommands = await ref
          .read(matchpointSwipeOutboxStoreProvider)
          .load(userId);
      return pendingCommands
          .map((entry) => entry.command.targetUserId)
          .where((targetUserId) => targetUserId.trim().isNotEmpty)
          .toSet();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to load MatchPoint pending outbox for local exclusion.',
        error,
        stackTrace,
        false,
      );
      return const <String>{};
    }
  }

  List<String> _resolveGenres(AppUser userProfile) {
    final matchpointGenres =
        userProfile.matchpointProfile?[FirestoreFields.musicalGenres] ??
        userProfile.matchpointProfile?['musicalGenres'] ??
        userProfile.matchpointProfile?['musical_genres'];
    if (matchpointGenres is List && matchpointGenres.isNotEmpty) {
      return matchpointGenres.whereType<String>().toList();
    }

    final professionalGenres =
        userProfile.dadosProfissional?['generosMusicais'];
    if (professionalGenres is List && professionalGenres.isNotEmpty) {
      return professionalGenres.whereType<String>().toList();
    }

    final bandGenres = userProfile.dadosBanda?['generosMusicais'];
    if (bandGenres is List && bandGenres.isNotEmpty) {
      return bandGenres.whereType<String>().toList();
    }

    return const <String>[];
  }

  List<String> _resolveHashtags(AppUser userProfile) {
    final rawHashtags =
        userProfile.matchpointProfile?[FirestoreFields.hashtags];
    if (rawHashtags is! List || rawHashtags.isEmpty) {
      return const <String>[];
    }

    final seen = <String>{};
    final result = <String>[];
    for (final hashtag in rawHashtags.whereType<String>()) {
      final normalized = hashtag.trim();
      if (normalized.isEmpty) continue;

      final dedupeKey = normalized.toLowerCase();
      if (seen.add(dedupeKey)) {
        result.add(normalized);
      }
    }

    return result;
  }

  List<String> _buildQueryGenres(
    List<String> rawGenres,
    List<ConfigItem> configGenres,
  ) {
    final canonicalIds = <String>[];
    final expanded = <String>[];

    for (final raw in rawGenres) {
      final token = raw.trim();
      if (token.isEmpty) continue;

      final configItem = _findConfigGenre(token, configGenres);
      if (configItem != null) {
        canonicalIds.add(configItem.id);
        expanded.add(configItem.label);
        expanded.addAll(configItem.aliases);
      }
      expanded.add(token);
    }

    final seen = <String>{};
    final queryGenres = <String>[];
    for (final token in [...canonicalIds, ...expanded]) {
      final normalized = token.trim();
      if (normalized.isEmpty) continue;

      final dedupeKey = normalized.toLowerCase();
      if (seen.add(dedupeKey)) {
        queryGenres.add(normalized);
      }
    }

    return queryGenres.take(10).toList();
  }

  ConfigItem? _findConfigGenre(String token, List<ConfigItem> configGenres) {
    final normalized = token.trim().toLowerCase();
    for (final item in configGenres) {
      if (item.id.toLowerCase() == normalized) return item;
      if (item.label.toLowerCase() == normalized) return item;
      if (item.aliases.any((alias) => alias.toLowerCase() == normalized)) {
        return item;
      }
    }
    return null;
  }

  void removeCandidate(String uid) {
    state = state.whenData((list) => list.where((u) => u.uid != uid).toList());
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<List<MatchInfo>> matches(Ref ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  final currentUser = authRepo.currentUser;
  if (currentUser == null) return [];

  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.fetchMatches(currentUser.uid);

  return result.fold((failure) {
    AppLogger.error('Failed to fetch matches: ${failure.message}');
    throw failure.message;
  }, (matches) => matches);
}

@riverpod
Future<List<HashtagRanking>> hashtagRanking(Ref ref, int limit) async {
  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.fetchHashtagRanking(limit: limit);

  return result.fold((failure) {
    AppLogger.error('Failed to fetch hashtag ranking: ${failure.message}');
    return [];
  }, (rankings) => rankings);
}

@riverpod
Future<List<HashtagRanking>> hashtagSearch(Ref ref, String query) async {
  if (query.length < 2) return [];

  final repo = ref.read(matchpointRepositoryProvider);
  final result = await repo.searchHashtags(query, limit: 20);

  return result.fold((failure) {
    AppLogger.error('Failed to search hashtags: ${failure.message}');
    return [];
  }, (rankings) => rankings);
}

@Riverpod(keepAlive: true)
class SwipeHistory extends _$SwipeHistory {
  static const _storageKeyPrefix = 'swipe_history_';
  static const _legacyStorageKey = 'swipe_history';
  static const _maxEntries = 200;

  @override
  List<SwipeHistoryEntry> build() {
    final authUser = ref.watch(authStateChangesProvider).value;
    if (authUser == null) {
      return [];
    }

    unawaited(_loadFromStorage(authUser.uid));
    return [];
  }

  String _storageKeyForUser(String userId) => '$_storageKeyPrefix$userId';

  Future<void> _loadFromStorage(String userId) async {
    try {
      final prefs = await ref.read(sharedPreferencesLoaderProvider)();
      if (!ref.mounted) return;
      final jsonStr =
          prefs.getString(_storageKeyForUser(userId)) ??
          prefs.getString(_legacyStorageKey);
      if (jsonStr == null) return;

      final list = (jsonDecode(jsonStr) as List)
          .map((e) => SwipeHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      final seenTargets = <String>{};
      final normalized = list
          .where((item) => seenTargets.add(item.targetUserId))
          .toList();

      if (!ref.mounted) return;
      final currentUserId = ref.read(authRepositoryProvider).currentUser?.uid;
      if (currentUserId != null && currentUserId != userId) return;

      state = normalized;
    } catch (e, st) {
      AppLogger.warning('Failed to load swipe history', e, st);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final userId = ref.read(authRepositoryProvider).currentUser?.uid;
      final prefs = await ref.read(sharedPreferencesLoaderProvider)();
      if (!ref.mounted) return;
      final jsonStr = jsonEncode(state.map((e) => e.toJson()).toList());

      if (userId != null) {
        await prefs.setString(_storageKeyForUser(userId), jsonStr);
      }

      await prefs.setString(_legacyStorageKey, jsonStr);
    } catch (e, st) {
      AppLogger.warning('Failed to save swipe history', e, st);
    }
  }

  void addSwipe(AppUser user, String type) {
    final entry = SwipeHistoryEntry(
      targetUserId: user.uid,
      targetUserName: user.appDisplayName.isNotEmpty
          ? user.appDisplayName
          : (user.nome ?? 'Usuario'),
      targetUserPhoto: user.foto,
      action: type,
      timestamp: DateTime.now(),
    );

    final withoutSameUser = state
        .where((item) => item.targetUserId != user.uid)
        .toList();
    state = [entry, ...withoutSameUser].take(_maxEntries).toList();
    _saveToStorage();
  }

  void undoLast() {
    if (state.isNotEmpty) {
      state = state.sublist(1);
      _saveToStorage();
    }
  }
}
