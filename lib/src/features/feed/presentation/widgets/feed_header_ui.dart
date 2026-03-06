part of 'feed_header.dart';

extension _FeedHeaderUi on _FeedHeaderState {
  Widget _buildAddressShortcut(
    BuildContext context,
    SavedAddress? primaryAddress,
  ) {
    return Material(
      key: const Key('feed_header_address_row'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all16,
        onTap: () => context.push(RoutePaths.addresses),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.68),
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: AppRadius.all12,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
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
                      'Endereço atual',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      _formatAddressShortcut(primaryAddress),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    String profileCategory,
    int notificationCount,
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
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                profileCategory,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    final profileType = _getProfileTypeLabel();
    final profileRole = _getProfileRole();
    final missingItems = completion.missingRequirements.take(3).toList();
    final remainingItems =
        completion.missingRequirements.length - missingItems.length;

    return GestureDetector(
      key: const Key('feed_header_profile_card'),
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push(RoutePaths.profileEdit);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.95),
              AppColors.primaryPressed,
            ],
          ),
          borderRadius: AppRadius.all20,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seu Perfil',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.86),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        '$profileType - $profileRole',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s10,
                        vertical: AppSpacing.s4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.14),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        '${completion.percent}%',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s10),
                    Container(
                      padding: AppSpacing.all8,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary.withValues(alpha: 0.12),
                        borderRadius: AppRadius.all12,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.textPrimary,
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'Falta completar',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary.withValues(alpha: 0.84),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s10),
            ...missingItems.map(_buildMissingItem),
            if (remainingItems > 0) ...[
              const SizedBox(height: AppSpacing.s4),
              Text(
                '+$remainingItems itens para revisar',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s14),
            ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                value: completion.percent / 100,
                backgroundColor: AppColors.textPrimary.withValues(alpha: 0.16),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.textPrimary,
                ),
                minHeight: 7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              size: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.3,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
