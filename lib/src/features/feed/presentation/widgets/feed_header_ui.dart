part of 'feed_header.dart';

extension _FeedHeaderUi on _FeedHeaderState {
  Widget _buildWelcomeSection(
    BuildContext context,
    String profileCategory,
    int notificationCount,
    SavedAddress? primaryAddress,
  ) {
    final displayName = _getDisplayName();
    final firstName = displayName.split(' ').first;
    final avatarSize = widget.isScrolled ? 56.0 : 68.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'profile-avatar',
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              final uid = widget.currentUser?.uid;
              if (uid != null) {
                context.push(
                  RoutePaths.publicProfileById(uid),
                  extra: {RoutePaths.avatarHeroTagExtraKey: 'profile-avatar'},
                );
              }
            },
            child: AnimatedContainer(
              key: const Key('feed_header_avatar'),
              duration: const Duration(milliseconds: 300),
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.background.withValues(alpha: 0.26),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: UserAvatar(
                photoUrl: widget.currentUser?.foto,
                name: displayName,
                size: avatarSize,
                showBorder: false,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $firstName!',
                style: widget.isScrolled
                    ? AppTypography.headlineSmall
                    : AppTypography.headlineMedium.copyWith(fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                profileCategory,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.currentUser != null) ...[
                const SizedBox(height: AppSpacing.s4),
                _buildInlineAddress(context, primaryAddress),
              ],
            ],
          ),
        ),
        _NotificationButton(
          count: notificationCount,
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onNotificationTap?.call();
          },
        ),
      ],
    );
  }

  Widget _buildInlineAddress(BuildContext context, SavedAddress? address) {
    final bairro = address?.bairro.trim() ?? '';
    final cidade = address?.cidade.trim() ?? '';
    final hasAddress = bairro.isNotEmpty || cidade.isNotEmpty;
    final label = hasAddress
        ? (bairro.isNotEmpty ? bairro : cidade)
        : 'Adicionar endereço';

    return InkWell(
      key: const Key('feed_header_address_inline'),
      borderRadius: AppRadius.all8,
      onTap: () => context.push(RoutePaths.addresses),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesShortcut(BuildContext context, int favoritesCount) {
    return Material(
      key: const Key('feed_header_favorites_shortcut'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all16,
        onTap: () {
          HapticFeedback.selectionClick();
          context.push(RoutePaths.receivedFavorites);
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all12,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Favoritos',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      'Ver quem curtiu você',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(
                '$favoritesCount',
                style: AppTypography.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.78),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaleDataNotice(DateTime? dataUpdatedAt) {
    final updatedAtLabel = _formatStaleDataTime(dataUpdatedAt);

    return Container(
      key: const Key('feed_header_stale_data_notice'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.16),
              borderRadius: AppRadius.all12,
            ),
            child: const Icon(
              Icons.cached_rounded,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mostrando dados salvos',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                Text(
                  updatedAtLabel == null
                      ? 'Atualizamos automaticamente quando a conexao permitir.'
                      : 'Ultima atualizacao: $updatedAtLabel. Atualizamos automaticamente quando a conexao permitir.',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _formatStaleDataTime(DateTime? dataUpdatedAt) {
    if (dataUpdatedAt == null) return null;

    final now = DateTime.now();
    final difference = now.difference(dataUpdatedAt);
    if (difference.inMinutes < 1) {
      return 'agora ha pouco';
    }
    if (difference.inMinutes < 60) {
      return 'ha ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'ha ${difference.inHours} h';
    }
    return 'ha ${difference.inDays} dias';
  }

  Widget _buildAlertsSurface(BuildContext context, List<_HeaderAlert> alerts) {
    switch (_alertDisplayMode) {
      case _AlertDisplayMode.expanded:
        return _buildExpandedAlertsCard(context, alerts);
      case _AlertDisplayMode.hidden:
        return _buildHiddenAlertsBar(alerts);
      case _AlertDisplayMode.compact:
        return _buildCompactAlertsBar(context, alerts);
    }
  }

  Widget _buildCompactAlertsBar(
    BuildContext context,
    List<_HeaderAlert> alerts,
  ) {
    final firstAlert = alerts.first;

    return Material(
      key: const Key('feed_header_alerts_compact'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all16,
        onTap: () {
          HapticFeedback.selectionClick();
          _showAlertsSheet(context, alerts);
        },
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: firstAlert.accentColor.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: firstAlert.accentColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all12,
                ),
                child: Icon(
                  firstAlert.icon,
                  color: firstAlert.accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  _compactAlertLabel(alerts),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (alerts.length > 1) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: firstAlert.accentColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
              ],
              _HeaderActionButton(
                key: const Key('feed_header_alerts_expand_button'),
                icon: Icons.unfold_more_rounded,
                tooltip: 'Expandir alertas',
                onTap: _expandAlerts,
              ),
              const SizedBox(width: AppSpacing.s4),
              _HeaderActionButton(
                key: const Key('feed_header_alerts_hide_button'),
                icon: Icons.visibility_off_outlined,
                tooltip: 'Ocultar alertas',
                onTap: _hideAlerts,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedAlertsCard(
    BuildContext context,
    List<_HeaderAlert> alerts,
  ) {
    final firstAlert = alerts.first;
    final extraAlerts = alerts.length - 1;

    return Material(
      key: const Key('feed_header_alerts_expanded'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all20,
        onTap: () {
          HapticFeedback.selectionClick();
          _showAlertsSheet(context, alerts);
        },
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.94),
            borderRadius: AppRadius.all20,
            border: Border.all(
              color: firstAlert.accentColor.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: firstAlert.accentColor.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: firstAlert.accentColor.withValues(alpha: 0.14),
                      borderRadius: AppRadius.all16,
                    ),
                    child: Icon(
                      firstAlert.icon,
                      color: firstAlert.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      extraAlerts > 0 ? 'Alertas ativos' : 'Alerta ativo',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _HeaderActionButton(
                    key: const Key('feed_header_alerts_compact_button'),
                    icon: Icons.vertical_align_center_rounded,
                    tooltip: 'Achatar alertas',
                    onTap: _compactAlerts,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  _HeaderActionButton(
                    key: const Key('feed_header_alerts_hide_button'),
                    icon: Icons.visibility_off_outlined,
                    tooltip: 'Ocultar alertas',
                    onTap: _hideAlerts,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s14),
              Text(
                firstAlert.title,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                firstAlert.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Text(
                    extraAlerts > 0
                        ? '+$extraAlerts alertas para revisar'
                        : 'Toque para abrir',
                    style: AppTypography.bodySmall.copyWith(
                      color: firstAlert.accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: firstAlert.accentColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHiddenAlertsBar(List<_HeaderAlert> alerts) {
    return Container(
      key: const Key('feed_header_alerts_hidden'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.75),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.visibility_off_outlined,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              alerts.length == 1
                  ? '1 alerta oculto'
                  : '${alerts.length} alertas ocultos',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: const Key('feed_header_alerts_restore_button'),
            onPressed: _restoreAlerts,
            child: const Text('Mostrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    ProfileCompletionResult completion,
  ) {
    final percent = completion.percent;
    final missingItems = completion.missingRequirements;
    final expanded = _profileCardExpanded;

    return AnimatedContainer(
      key: const Key('feed_header_profile_card'),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.72),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: AppColors.textPrimary.withValues(alpha: 0.07),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: AppRadius.all16,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _profileCardExpanded = !expanded);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s14,
                  vertical: AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    _CompletionRing(percent: percent),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _friendlyProfileTitle(percent),
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            _friendlyProfileSubtitle(missingItems.length),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: expanded
                  ? _buildProfileCardExpandedBody(context, missingItems)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCardExpandedBody(
    BuildContext context,
    List<String> missingItems,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s14,
        0,
        AppSpacing.s14,
        AppSpacing.s12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            color: AppColors.textPrimary.withValues(alpha: 0.07),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (missingItems.isEmpty)
            Text(
              'Tudo pronto por aqui!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in missingItems) _buildMissingItem(item),
              ],
            ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.push(RoutePaths.profileEdit);
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Completar agora'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.pill,
                ),
                textStyle: AppTypography.buttonSecondary.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyProfileTitle(int percent) {
    if (percent >= 80) return 'Quase lá!';
    if (percent >= 50) return 'Seu perfil está tomando forma';
    if (percent >= 20) return 'Bora dar mais brilho ao seu perfil';
    return 'Começando seu perfil';
  }

  String _friendlyProfileSubtitle(int missingCount) {
    if (missingCount == 0) return 'Tudo preenchido, ótimo trabalho!';
    if (missingCount == 1) return '1 detalhe faltando · toque para ver';
    return '$missingCount detalhes faltando · toque para ver';
  }

  Widget _buildMissingItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s4),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAlertsSheet(BuildContext context, List<_HeaderAlert> alerts) {
    AppOverlay.bottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            0,
            AppSpacing.s20,
            AppSpacing.s24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alertas da home',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Use estes atalhos para resolver o que está pendente no seu perfil.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                ...alerts.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s14),
                    child: _AlertSheetCard(
                      alert: alert,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        context.push(alert.route);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeaderAlert {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String message;
  final String actionLabel;
  final String route;

  const _HeaderAlert({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.route,
  });
}

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: onTap,
          radius: 20,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              borderRadius: AppRadius.all12,
            ),
            child: Icon(icon, size: 16, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _AlertSheetCard extends StatelessWidget {
  const _AlertSheetCard({required this.alert, required this.onTap});

  final _HeaderAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: AppRadius.all20,
        border: Border.all(color: alert.accentColor.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: alert.accentColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.all16,
                ),
                child: Icon(alert.icon, color: alert.accentColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      alert.message,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          AppButton.secondary(
            text: alert.actionLabel,
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _CompletionRing extends StatelessWidget {
  const _CompletionRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100) / 100.0;
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: clamped,
            strokeWidth: 3.2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          Text(
            '$percent%',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: AppSpacing.all12,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surfaceHighlight, width: 1),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryPressed],
                  ),
                  borderRadius: AppRadius.pill,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
