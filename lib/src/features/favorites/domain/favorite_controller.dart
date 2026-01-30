// ignore_for_file: avoid_print
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/data/auth_repository.dart';
import '../data/favorite_repository.dart';
import 'favorite_state.dart';

part 'favorite_controller.g.dart';

@Riverpod(keepAlive: true)
class FavoriteController extends _$FavoriteController {
  Timer? _debounceTimer;
  final _pendingChanges = <String, bool>{}; // targetId -> isLiked

  @override
  FavoriteState build() {
    // Reage a mudanças de auth (login/logout)
    final authState = ref.watch(authStateChangesProvider);

    // Carrega dados se houver usuário
    if (authState.value != null) {
      Future.microtask(() => loadFavorites());
    }

    return const FavoriteState();
  }

  Future<void> loadFavorites() async {
    // Só carrega se tiver usuário logado
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    state = state.copyWith(isSyncing: true);
    try {
      final serverFavorites = await ref
          .read(favoriteRepositoryProvider)
          .loadFavorites();

      // Merge: Começa com o que veio do servidor
      final mergedLocal = Set<String>.from(serverFavorites);

      // Reaplica as mudanças pendentes que ainda não foram syncadas
      _pendingChanges.forEach((id, isLiked) {
        if (isLiked) {
          mergedLocal.add(id);
        } else {
          mergedLocal.remove(id);
        }
      });

      state = state.copyWith(
        localFavorites: mergedLocal,
        serverFavorites: serverFavorites,
        isSyncing: false,
      );
    } catch (e) {
      state = state.copyWith(isSyncing: false);
      // Tratamento de erro silencioso por enquanto
    }
  }

  /// Verifica se um item é favoritado (usa estado LOCAL para UI instantânea)
  bool isLiked(String targetId) {
    return state.localFavorites.contains(targetId);
  }

  /// Retorna contagem local (atualizada otimisticamente) ou global
  int getCount(String targetId, int initialCount) {
    // A lógica real de contagem é complexa de manter 100% sync sem realtime listener.
    // Aqui fazemos uma aproximação: usamos o initialCount vindo do feed
    // E aplicamos o delta local (se eu dei like mas não tava, +1).

    // Precisaríamos saber se o initialCount JÁ incluía meu like ou não.
    // Assumindo que initialCount veio do servidor e reflete o estado no momento do fetch.
    // Se initialCount diz que tem 10 likes, e eu NÃO tinha dado like no server,
    // mas agora dei like local -> 11.

    // Simplificação para MVP:
    // O FeedItem deve trazer `isLikedByMe` e `likeCount`.
    // Se o estado local divergir do `isLikedByMe` original, ajustamos o count.
    // Mas como não temos o `isLikedByMe` original aqui fácil, vamos confiar no estado
    // e apenas atualizar o contador visualmente se detectarmos mudança de estado.

    // TODO: Implementar lógica mais precisa de contagem otimista.
    // Por enquanto retornamos o initialCount + delta simples se possível,
    // mas o componente de UI pode gerenciar sua própria animação de contador.
    return initialCount;
  }

  /// Alterna o estado de favorito de um item
  void toggle(String targetId) {
    // 1. Estado Atual
    final isCurrentlyLiked = state.localFavorites.contains(targetId);
    final newStatus = !isCurrentlyLiked;

    // 2. Atualiza UI Imediatamente (Optimistic)
    final newLocal = Set<String>.from(state.localFavorites);
    if (newStatus) {
      newLocal.add(targetId);
    } else {
      newLocal.remove(targetId);
    }

    state = state.copyWith(localFavorites: newLocal);

    // 3. Registra mudança pendente para Debounce
    _pendingChanges[targetId] = newStatus;

    // 4. Reinicia Timer de Debounce
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _syncWithServer);
  }

  /// Sincroniza mudanças pendentes com o servidor
  Future<void> _syncWithServer() async {
    if (_pendingChanges.isEmpty) return;

    // Copia e limpa pendências para processar
    final changesToProcess = Map<String, bool>.from(_pendingChanges);
    _pendingChanges.clear();

    final repo = ref.read(favoriteRepositoryProvider);

    for (final entry in changesToProcess.entries) {
      final targetId = entry.key;
      final shouldBeLiked = entry.value;

      // Verifica estado atual do servidor para ver se precisa agir
      final isServerLiked = state.serverFavorites.contains(targetId);

      if (shouldBeLiked == isServerLiked) continue; // Já está sincronizado

      try {
        if (shouldBeLiked) {
          await repo.addFavorite(targetId);
        } else {
          await repo.removeFavorite(targetId);
        }

        // Sucesso: Atualiza estado do Server para refletir realidade
        final newServer = Set<String>.from(state.serverFavorites);
        if (shouldBeLiked) {
          newServer.add(targetId);
        } else {
          newServer.remove(targetId);
        }
        state = state.copyWith(serverFavorites: newServer);
      } catch (e) {
        // Falha: Rollback do Local para bater com Server (que não mudou)
        // Reverte UI para mostrar que falhou
        final newLocal = Set<String>.from(state.localFavorites);
        if (isServerLiked) {
          newLocal.add(targetId); // Volta a ser like (já que remove falhou)
        } else {
          newLocal.remove(targetId); // Volta a ser unlike (já que add falhou)
        }
        state = state.copyWith(localFavorites: newLocal);

        // Opcional: Mostrar erro via Toast/SnackBar se possível
        print('Erro ao sincronizar like para $targetId: $e');
      }
    }
  }
}
