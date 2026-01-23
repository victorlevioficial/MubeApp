import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/feed_favorite_service.dart';
import '../domain/feed_item.dart';

/// Estado do controller de favoritos.
class FeedFavoriteState {
  // Overrides otimistas para "isFavorited"
  final Map<String, bool> optimisticIsFavorited;

  // Deltas otimistas para "count" (+1 ou -1)
  final Map<String, int> optimisticCountDelta;

  // Set de IDs que estão com transação em andamento (Lock de debounce)
  final Set<String> inFlight;

  // Erro recente para exibir na UI
  final String? error;

  const FeedFavoriteState({
    this.optimisticIsFavorited = const {},
    this.optimisticCountDelta = const {},
    this.inFlight = const {},
    this.error,
  });

  FeedFavoriteState copyWith({
    Map<String, bool>? optimisticIsFavorited,
    Map<String, int>? optimisticCountDelta,
    Set<String>? inFlight,
    String? error,
  }) {
    return FeedFavoriteState(
      optimisticIsFavorited:
          optimisticIsFavorited ?? this.optimisticIsFavorited,
      optimisticCountDelta: optimisticCountDelta ?? this.optimisticCountDelta,
      inFlight: inFlight ?? this.inFlight,
      error: error,
    );
  }
}

/// Controller responsável pela UI Otimista dos Favoritos.
class FeedFavoriteController extends Notifier<FeedFavoriteState> {
  late final FeedFavoriteService _service;

  @override
  FeedFavoriteState build() {
    _service = ref.watch(feedFavoriteServiceProvider);
    return const FeedFavoriteState();
  }

  /// Tenta alternar o favorito com UI Otimista.
  Future<void> toggleFavorite({
    required FeedItem target,
    required bool? currentIsFavorited,
  }) async {
    final targetId = target.uid;

    if (state.inFlight.contains(targetId)) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) {
      state = state.copyWith(error: 'Você precisa estar logado.');
      return;
    }

    final isLikelyFavorited = currentIsFavorited ?? false;
    final willFavorite = !isLikelyFavorited;

    // Apply Optimistic Update
    final newInFlight = Set<String>.from(state.inFlight)..add(targetId);
    final newOptimisticIsFavorited = Map<String, bool>.from(
      state.optimisticIsFavorited,
    )..[targetId] = willFavorite;

    final newOptimisticCountDelta = Map<String, int>.from(
      state.optimisticCountDelta,
    )..[targetId] = willFavorite ? 1 : -1;

    state = state.copyWith(
      inFlight: newInFlight,
      optimisticIsFavorited: newOptimisticIsFavorited,
      optimisticCountDelta: newOptimisticCountDelta,
      error: null,
    );

    try {
      // Execute atomically
      await _service.toggleFavorite(meuId: user.uid, target: target);

      // BUFFER: Wait for Firestore to sync back to avoid flicker (Optimistic OFF -> Stream OLD -> Stream NEW)
      // We keep the optimistic state active for a buffer period.
      // The UI will handle the "Double Count" prevention by checking if Server State == Optimistic State.
      await Future.delayed(const Duration(milliseconds: 300));

      final successOptimisticIsFavorited = Map<String, bool>.from(
        state.optimisticIsFavorited,
      )..remove(targetId);

      final successOptimisticCountDelta = Map<String, int>.from(
        state.optimisticCountDelta,
      )..remove(targetId);

      final successInFlight = Set<String>.from(state.inFlight)
        ..remove(targetId);

      state = state.copyWith(
        optimisticIsFavorited: successOptimisticIsFavorited,
        optimisticCountDelta: successOptimisticCountDelta,
        inFlight: successInFlight,
      );
    } catch (e) {
      // Error: Rollback
      final rollbackOptimisticIsFavorited = Map<String, bool>.from(
        state.optimisticIsFavorited,
      )..remove(targetId);

      final rollbackOptimisticCountDelta = Map<String, int>.from(
        state.optimisticCountDelta,
      )..remove(targetId);

      final rollbackInFlight = Set<String>.from(state.inFlight)
        ..remove(targetId);

      state = state.copyWith(
        optimisticIsFavorited: rollbackOptimisticIsFavorited,
        optimisticCountDelta: rollbackOptimisticCountDelta,
        inFlight: rollbackInFlight,
        error: 'Falha ao atualizar favorito. Verifique sua conexão.',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider global do controller.
final feedFavoriteControllerProvider =
    NotifierProvider<FeedFavoriteController, FeedFavoriteState>(
      FeedFavoriteController.new,
    );
