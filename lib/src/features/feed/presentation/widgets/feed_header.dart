import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/app_constants.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/feedback/app_overlay.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../auth/domain/app_user.dart';
import '../../../auth/domain/profile_completion_evaluator.dart';
import '../../../auth/domain/user_type.dart';
import '../../../bands/data/invites_repository.dart';
import '../../../bands/domain/band_activation_rules.dart';
import '../../../notifications/data/notification_providers.dart';
import '../../../settings/domain/saved_address.dart';
import '../../../settings/domain/saved_address_book.dart';

enum _AlertDisplayMode { compact, expanded, hidden }

class FeedHeader extends ConsumerStatefulWidget {
  final AppUser? currentUser;
  final VoidCallback? onNotificationTap;
  final bool isScrolled;
  final int? notificationCount;

  const FeedHeader({
    super.key,
    this.currentUser,
    this.onNotificationTap,
    this.isScrolled = false,
    this.notificationCount,
  });

  @override
  ConsumerState<FeedHeader> createState() => _FeedHeaderState();
}

class _FeedHeaderState extends ConsumerState<FeedHeader> {
  _AlertDisplayMode _alertDisplayMode = _AlertDisplayMode.compact;

  @override
  void didUpdateWidget(covariant FeedHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUser?.uid != widget.currentUser?.uid) {
      _alertDisplayMode = _AlertDisplayMode.compact;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completion = ProfileCompletionEvaluator.evaluate(widget.currentUser);
    final int resolvedNotificationCount =
        widget.notificationCount ?? ref.watch(unreadNotificationCountProvider);
    final pendingInviteCount = _getPendingInviteCount();
    final alerts = _buildAlerts(pendingInviteCount);
    final primaryAddress = _getPrimaryAddress();

    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isScrolled
                ? [AppColors.background, AppColors.background]
                : [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.02),
                    AppColors.background,
                  ],
            stops: widget.isScrolled ? null : const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s20,
              AppSpacing.s24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.currentUser != null) ...[
                  _buildAddressShortcut(context, primaryAddress),
                  const SizedBox(height: AppSpacing.s14),
                ],
                _buildWelcomeSection(
                  context,
                  _getHeaderCategoryLabel(),
                  resolvedNotificationCount,
                ),
                if (alerts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s16),
                  _buildAlertsSurface(context, alerts),
                ],
                if (widget.currentUser != null && !completion.isComplete) ...[
                  const SizedBox(height: AppSpacing.s16),
                  _buildProfileCard(context, completion),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                      'Endereco atual',
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
              if (uid != null) context.push('/user/$uid');
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
                'Ola, $firstName!',
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
                  'Use estes atalhos para resolver o que esta pendente no seu perfil.',
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

  void _compactAlerts() {
    HapticFeedback.selectionClick();
    setState(() => _alertDisplayMode = _AlertDisplayMode.compact);
  }

  void _expandAlerts() {
    HapticFeedback.selectionClick();
    setState(() => _alertDisplayMode = _AlertDisplayMode.expanded);
  }

  void _hideAlerts() {
    HapticFeedback.selectionClick();
    setState(() => _alertDisplayMode = _AlertDisplayMode.hidden);
  }

  void _restoreAlerts() {
    HapticFeedback.selectionClick();
    setState(() => _alertDisplayMode = _AlertDisplayMode.compact);
  }

  int _getPendingInviteCount() {
    final user = widget.currentUser;
    if (user == null || user.tipoPerfil != AppUserType.professional) return 0;
    return ref.watch(pendingInviteCountProvider(user.uid)).value ?? 0;
  }

  SavedAddress? _getPrimaryAddress() {
    final user = widget.currentUser;
    if (user == null) return null;
    final addresses = SavedAddressBook.effectiveAddresses(user);
    if (addresses.isEmpty) return null;
    return addresses.first;
  }

  List<_HeaderAlert> _buildAlerts(int pendingInviteCount) {
    final user = widget.currentUser;
    if (user == null) return const [];

    final alerts = <_HeaderAlert>[];

    if (user.tipoPerfil == AppUserType.band &&
        !isBandEligibleForActivation(user.members.length)) {
      final acceptedMembers = user.members.length;
      final missingMembers = missingBandMembersForActivation(acceptedMembers);
      alerts.add(
        _HeaderAlert(
          icon: Icons.groups_rounded,
          accentColor: AppColors.badgeBand,
          title:
              '$acceptedMembers de $minimumBandMembersForActivation integrantes confirmados',
          message: missingMembers == 1
              ? 'Falta 1 integrante aceitar o convite para liberar a visibilidade da banda.'
              : 'Faltam $missingMembers integrantes aceitarem o convite para liberar a visibilidade da banda.',
          actionLabel: 'Gerenciar integrantes',
          route: RoutePaths.manageMembers,
        ),
      );
    }

    if (user.tipoPerfil == AppUserType.professional && pendingInviteCount > 0) {
      alerts.add(
        _HeaderAlert(
          icon: Icons.mail_outline_rounded,
          accentColor: AppColors.info,
          title: pendingInviteCount == 1
              ? '1 convite pendente para banda'
              : '$pendingInviteCount convites pendentes para banda',
          message: pendingInviteCount == 1
              ? 'Abra seus convites e responda quando quiser entrar na banda.'
              : 'Abra seus convites pendentes e responda os que fizerem sentido para voce.',
          actionLabel: 'Ver convites',
          route: RoutePaths.invites,
        ),
      );
    }

    return alerts;
  }

  String _compactAlertLabel(List<_HeaderAlert> alerts) {
    if (alerts.length == 1) return alerts.first.title;
    return '${alerts.length} alertas ativos';
  }

  String _formatAddressShortcut(SavedAddress? address) {
    if (address == null) return 'Adicionar endereco';

    final parts = <String>[
      address.logradouro.trim(),
      address.bairro.trim(),
    ].where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return 'Adicionar endereco';
    return parts.join(', ');
  }

  String _getDisplayName() {
    if (widget.currentUser == null) return 'Usuario';
    final display = widget.currentUser!.appDisplayName;
    if (display.trim().isNotEmpty) return display.trim();
    return widget.currentUser!.nome ?? 'Usuario';
  }

  String _getHeaderCategoryLabel() {
    final type = widget.currentUser?.tipoPerfil;
    if (type == null) return 'Perfil';

    switch (type) {
      case AppUserType.professional:
        return 'Perfil individual';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estudio';
      case AppUserType.contractor:
        return 'Contratante';
    }
  }

  String _getProfileTypeLabel() {
    final type = widget.currentUser?.tipoPerfil;
    if (type == null) return 'Musico';

    switch (type) {
      case AppUserType.professional:
        return 'Profissional';
      case AppUserType.band:
        return 'Banda';
      case AppUserType.studio:
        return 'Estudio';
      case AppUserType.contractor:
        return 'Contratante';
    }
  }

  String _getProfileRole() {
    if (widget.currentUser == null) return 'Musico';

    final profData = widget.currentUser!.dadosProfissional;
    if (profData != null) {
      final categorias = profData['categorias'] as List<dynamic>?;
      if (categorias != null && categorias.isNotEmpty) {
        return _getCategoryLabel(categorias.first as String);
      }

      final instrumentos = profData['instrumentos'] as List<dynamic>?;
      if (instrumentos != null && instrumentos.isNotEmpty) {
        return _formatRole(instrumentos.first as String);
      }
    }

    return 'Musico';
  }

  String _getCategoryLabel(String id) {
    try {
      final category = professionalCategories.firstWhere(
        (element) => element['id'] == id,
        orElse: () => {'label': _formatRole(id)},
      );
      return category['label'] as String;
    } catch (_) {
      return _formatRole(id);
    }
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map(
          (word) =>
              word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
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
