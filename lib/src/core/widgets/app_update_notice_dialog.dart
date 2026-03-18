import 'package:flutter/material.dart';

import '../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../design_system/components/feedback/app_overlay.dart';
import '../domain/app_update_notice.dart';

class AppUpdateNoticeDialog extends StatelessWidget {
  const AppUpdateNoticeDialog({super.key, required this.notice});

  final AppUpdateNotice notice;

  static Future<bool?> show(
    BuildContext context, {
    required AppUpdateNotice notice,
  }) {
    return AppOverlay.dialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AppUpdateNoticeDialog(notice: notice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppConfirmationDialog(
      title: 'Atualizacao disponivel',
      message:
          'Voce esta usando a versao ${notice.installedVersion}. '
          'Existe uma versao mais recente do Mube com correcoes e melhorias.',
      confirmText: notice.storeUri != null ? 'Atualizar' : 'Entendi',
      cancelText: 'Depois',
      isDestructive: false,
    );
  }
}
