import 'feed_favorite_controller.dart';

extension FeedFavoriteLogic on FeedFavoriteState {
  /// Calcula se o item deve aparecer como favoritado na UI.
  /// Prioridade: Estado Otimista > Estado do Servidor.
  bool isFavorited(String itemId, bool serverState) {
    return optimisticIsFavorited[itemId] ?? serverState;
  }

  /// Calcula o número a ser exibido usando Lógica Inteligente.
  /// Reconcilia o estado do servidor com o otimista para evitar "flicker" ou contagem dupla.
  int displayCount(String itemId, int serverCount, bool serverState) {
    final optimisticState = optimisticIsFavorited[itemId];

    // Se não há estado otimista, confia 100% no servidor
    if (optimisticState == null) return serverCount;

    int finalCount = serverCount;

    if (optimisticState == true && !serverState) {
      // Otimista: Like | Server: Dislike (Ainda não chegou) -> Soma 1
      finalCount++;
    } else if (optimisticState == false && serverState) {
      // Otimista: Dislike | Server: Like (Ainda não chegou) -> Subtrai 1
      finalCount--;
    }
    // Se (optimistic == true && server == true), o servidor já alcançou. Não somamos nada.

    return finalCount.clamp(0, 999999);
  }
}
