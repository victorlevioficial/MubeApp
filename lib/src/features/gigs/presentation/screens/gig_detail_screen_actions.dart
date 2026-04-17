part of 'gig_detail_screen.dart';

extension _GigDetailScreenActions on _GigDetailScreenState {
  Future<void> _showApplyDialog(BuildContext context, String gigId) async {
    final message = await AppOverlay.dialog<String>(
      context: context,
      builder: (context) => const _GigApplyDialog(),
    );

    if (message == null || !context.mounted) return;

    await _runPendingAction(_GigDetailPendingAction.apply, () async {
      try {
        await ref
            .read(gigActionsControllerProvider.notifier)
            .applyToGig(gigId, message);
        if (!context.mounted) return;
        AppSnackBar.success(
          context,
          'Candidatura enviada. A gig agora aparece em Minhas candidaturas.',
        );
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _withdraw(BuildContext context, String gigId) async {
    await _runPendingAction(_GigDetailPendingAction.withdraw, () async {
      try {
        await ref
            .read(gigActionsControllerProvider.notifier)
            .withdrawApplication(gigId);
        if (!context.mounted) return;
        AppSnackBar.success(context, 'Candidatura retirada com sucesso.');
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _confirmCloseGig(BuildContext context, String gigId) async {
    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Encerrar gig?',
        message: 'A gig deixará de aceitar novas ações operacionais.',
        confirmText: 'Encerrar',
      ),
    );

    if (confirmed != true) return;
    await _runPendingAction(_GigDetailPendingAction.closeGig, () async {
      try {
        await ref.read(gigActionsControllerProvider.notifier).closeGig(gigId);
        if (!context.mounted) return;
        AppSnackBar.success(context, 'Gig encerrada.');
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _confirmCancelGig(BuildContext context, String gigId) async {
    final confirmed = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Cancelar gig?',
        message:
            'As candidaturas serão congeladas e os envolvidos notificados.',
        confirmText: 'Cancelar gig',
        isDestructive: true,
      ),
    );

    if (confirmed != true) return;
    await _runPendingAction(_GigDetailPendingAction.cancelGig, () async {
      try {
        await ref.read(gigActionsControllerProvider.notifier).cancelGig(gigId);
        if (!context.mounted) return;
        AppSnackBar.success(context, 'Gig cancelada.');
      } catch (error) {
        if (!context.mounted) return;
        AppSnackBar.error(context, resolveGigErrorMessage(error));
      }
    });
  }

  Future<void> _showEditDescriptionDialog(BuildContext context, Gig gig) async {
    final controller = TextEditingController(text: gig.description);
    final result = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Editar descrição'),
        content: AppTextField(
          controller: controller,
          maxLines: 5,
          minLines: 5,
          label: 'Descrição',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != true) return;
    await _runPendingAction(
      _GigDetailPendingAction.updateDescription,
      () async {
        try {
          await ref
              .read(gigActionsControllerProvider.notifier)
              .updateGig(
                gig.id,
                GigUpdate(description: controller.text.trim()),
              );
          if (!context.mounted) return;
          AppSnackBar.success(context, 'Descrição atualizada.');
        } catch (error) {
          if (!context.mounted) return;
          AppSnackBar.error(context, resolveGigErrorMessage(error));
        }
      },
    );
  }
}
