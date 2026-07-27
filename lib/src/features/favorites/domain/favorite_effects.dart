import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Integration boundary for reactions that belong outside the favorites
/// feature, such as refreshing another feature's local projection.
abstract interface class FavoriteEffects {
  void onLocalStatusChanged(String targetId, {required bool isFavorite});

  Future<void> onFavoriteAdded({
    required String currentUserId,
    required String targetId,
  });
}

class _NoopFavoriteEffects implements FavoriteEffects {
  const _NoopFavoriteEffects();

  @override
  void onLocalStatusChanged(String targetId, {required bool isFavorite}) {}

  @override
  Future<void> onFavoriteAdded({
    required String currentUserId,
    required String targetId,
  }) async {}
}

/// Defaults to a no-op so the feature remains independently testable.
///
/// The production bootstrap replaces it with the app integration adapter.
final favoriteEffectsProvider = Provider<FavoriteEffects>(
  (ref) => const _NoopFavoriteEffects(),
  name: 'favoriteEffectsProvider',
);
