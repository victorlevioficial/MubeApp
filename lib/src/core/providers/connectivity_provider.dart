import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/foundations/tokens/app_colors.dart';
import '../../design_system/foundations/tokens/app_spacing.dart';
import '../../design_system/foundations/tokens/app_typography.dart';
import '../../utils/app_logger.dart';

/// Provider que monitora o estado de conectividade da rede
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  final controller = StreamController<ConnectivityStatus>.broadcast();

  // Estado inicial
  controller.add(ConnectivityStatus.checking);

  // Monitora mudanças de conectividade
  final subscription = Connectivity().onConnectivityChanged.listen((result) {
    final status = _mapResultToStatus(result);
    controller.add(status);

    if (status == ConnectivityStatus.offline) {
      AppLogger.warning('📴 App ficou offline');
    } else if (status == ConnectivityStatus.online) {
      AppLogger.info('📶 App voltou online');
    }
  });

  // Verifica estado inicial
  Connectivity().checkConnectivity().then((result) {
    controller.add(_mapResultToStatus(result));
  });

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Provider que retorna apenas se está online ou não
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (status) => status == ConnectivityStatus.online,
    loading: () => true, // Assume online enquanto carrega
    error: (_, _) => true, // Assume online em caso de erro
  );
});

/// Enum que representa o estado de conectividade
enum ConnectivityStatus { online, offline, checking }

/// Mapeia o resultado do ConnectivityPlus para nosso enum
ConnectivityStatus _mapResultToStatus(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.none)) {
    return ConnectivityStatus.offline;
  }
  return ConnectivityStatus.online;
}

/// Widget que mostra um indicador de offline quando não há conexão
class OfflineIndicator extends ConsumerWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Column(
      children: [
        // Banner de offline
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: isOnline ? 0 : 32,
          color: AppColors.warning,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isOnline ? 0 : 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  'Sem conexão com a internet',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Conteúdo principal
        Expanded(child: child),
      ],
    );
  }
}
