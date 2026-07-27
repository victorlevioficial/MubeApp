import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/data/chat_repository.dart';
import '../../features/favorites/domain/favorite_effects.dart';
import '../../features/feed/presentation/feed_controller.dart';
import '../../utils/app_logger.dart';

/// Connects favorite domain events to projections owned by other features.
class FavoriteIntegrationEffects implements FavoriteEffects {
  final Ref _ref;

  const FavoriteIntegrationEffects(this._ref);

  @override
  void onLocalStatusChanged(String targetId, {required bool isFavorite}) {
    try {
      _ref
          .read(feedControllerProvider.notifier)
          .updateLikeCount(targetId, isLiked: isFavorite);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Favorite feed projection update unavailable',
        error,
        stackTrace,
        false,
      );
    }
  }

  @override
  Future<void> onFavoriteAdded({
    required String currentUserId,
    required String targetId,
  }) async {
    try {
      final result = await _ref
          .read(chatRepositoryProvider)
          .reevaluateConversationAccessByUsers(
            userAId: currentUserId,
            userBId: targetId,
            trigger: 'favorite_added',
          );
      result.fold(
        (failure) => AppLogger.warning(
          'Falha ao promover conversa apos favorito',
          failure.message,
        ),
        (_) {},
      );
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Promocao de conversa apos favorito indisponivel neste contexto',
        error,
        stackTrace,
        false,
      );
    }
  }
}
