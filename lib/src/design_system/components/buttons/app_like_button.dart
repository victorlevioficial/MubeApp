import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:like_button/like_button.dart';

import '../../../features/favorites/domain/favorite_controller.dart';
import '../../foundations/app_colors.dart';
import '../../foundations/app_typography.dart';

class AppLikeButton extends ConsumerWidget {
  final String targetId;
  final int initialCount;
  final bool initialIsLiked;
  final double size;
  final bool showCount;

  const AppLikeButton({
    super.key,
    required this.targetId,
    required this.initialCount,
    this.initialIsLiked = false,
    this.size = 24.0,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta o estado global de favoritos
    final favoritesState = ref.watch(favoriteControllerProvider);

    // Determina se está curtido baseado no estado local (Optimistic)
    // Se o targetId estiver na lista de favoritos locais, é true.
    final isLiked = favoritesState.localFavorites.contains(targetId);

    // Calcula a contagem otimista
    // Base: initialCount
    // Ajuste:
    //   Se (Liked Agora) e (Não era Liked Inicialmente) -> +1
    //   Se (Não é Liked Agora) e (Era Liked Inicialmente) -> -1
    //   Caso contrário -> 0 (manteve estado inicial ou mudou e voltou)
    int currentCount = initialCount;
    if (isLiked && !initialIsLiked) {
      currentCount = initialCount + 1;
    } else if (!isLiked && initialIsLiked) {
      currentCount = initialCount - 1;
    }

    if (currentCount < 0) currentCount = 0;

    return LikeButton(
      size: size,
      isLiked: isLiked,
      likeCount: currentCount,
      padding: EdgeInsets.zero,

      // Animação de bolhas com cores da marca
      bubblesColor: const BubblesColor(
        dotPrimaryColor: AppColors.brandPrimary,
        dotSecondaryColor: AppColors.semanticAction,
      ),

      // Animação do círculo
      circleColor: const CircleColor(
        start: AppColors.semanticAction,
        end: AppColors.brandPrimary,
      ),

      // Builder do Ícone
      likeBuilder: (bool isLiked) {
        return Icon(
          isLiked ? Icons.favorite : Icons.favorite_outline,
          color: isLiked ? AppColors.brandPrimary : AppColors.textSecondary,
          size: size,
        );
      },

      // Formatação do Contador (1.2k, 1M)
      countBuilder: (int? count, bool isLiked, String text) {
        if (!showCount || count == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 2.0), // Pequeno ajuste vertical
          child: Text(
            text,
            style: AppTypography.labelMedium.copyWith(
              color: isLiked ? AppColors.brandPrimary : AppColors.textSecondary,
              fontWeight: isLiked ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        );
      },

      // Lógica de Tap
      onTap: (bool isLiked) async {
        // Haptic Feedback suave
        unawaited(HapticFeedback.lightImpact());

        // Chama controller para toggle (lógica otimista e server sync)
        ref.read(favoriteControllerProvider.notifier).toggle(targetId);

        // Retorna o inverso para a animação do botão ocorrer
        // O estado do Riverpod atualizará e reconstruirá o widget,
        // mas o LikeButton precisa desse return para animar visualmente o ícone localmente
        return !isLiked;
      },
    );
  }
}
