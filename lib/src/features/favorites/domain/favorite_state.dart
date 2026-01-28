import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_state.freezed.dart';

@freezed
sealed class FavoriteState with _$FavoriteState {
  const factory FavoriteState({
    /// Favoritos locais refletidos na UI instantaneamente (Optimistic UI)
    @Default({}) Set<String> localFavorites,

    /// Favoritos confirmados pelo servidor (Source of Truth)
    @Default({}) Set<String> serverFavorites,

    /// Indica se há sincronização pendente com o servidor
    @Default(false) bool isSyncing,

    /// Mapa de contador de likes para cada item (targetId -> count)
    @Default({}) Map<String, int> likeCounts,
  }) = _FavoriteState;
}
