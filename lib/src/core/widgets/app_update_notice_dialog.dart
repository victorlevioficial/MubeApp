import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design_system/foundations/tokens/app_colors.dart';
import '../../design_system/foundations/tokens/app_radius.dart';
import '../../design_system/foundations/tokens/app_spacing.dart';
import '../../design_system/foundations/tokens/app_typography.dart';
import '../domain/app_update_notice.dart';

class AppUpdateNoticeDialog extends StatefulWidget {
  const AppUpdateNoticeDialog({
    super.key,
    required this.notice,
    required this.onOpenStore,
  });

  final AppUpdateNotice notice;
  final Future<bool> Function(Uri uri)? onOpenStore;

  @override
  State<AppUpdateNoticeDialog> createState() => _AppUpdateNoticeDialogState();
}

class _AppUpdateNoticeDialogState extends State<AppUpdateNoticeDialog> {
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.all24),
        title: Text(
          'Atualizacao necessaria',
          style: AppTypography.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _buildMessage(),
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.s12),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _handlePrimaryAction,
            child: _isProcessing
                ? const SizedBox(
                    width: AppSpacing.s20,
                    height: AppSpacing.s20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.notice.storeUri != null
                        ? 'Atualizar agora'
                        : 'Fechar app',
                    style: AppTypography.buttonSecondary.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _buildMessage() {
    final storeUri = widget.notice.storeUri;
    final baseMessage =
        'Voce esta usando a versao ${widget.notice.installedVersion}. '
        'Para continuar usando o Mube com seguranca e compatibilidade, '
        'atualize o app para uma versao mais recente.';

    if (storeUri != null) {
      return baseMessage;
    }

    return '$baseMessage '
        'No momento nao foi encontrado um link de atualizacao para este '
        'dispositivo. Feche o app e instale a versao mais recente.';
  }

  Future<void> _handlePrimaryAction() async {
    final storeUri = widget.notice.storeUri;
    if (storeUri == null) {
      await SystemNavigator.pop();
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final opened = await widget.onOpenStore?.call(storeUri) ?? false;
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _errorMessage = opened
          ? null
          : 'Nao foi possivel abrir a atualizacao. Tente novamente.';
    });
  }
}
