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

part 'feed_header_ui.dart';

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
                if (widget.currentUser != null) ...[
                  const SizedBox(height: AppSpacing.s14),
                  _buildFavoritesShortcut(
                    context,
                    widget.currentUser!.favoritesCount,
                  ),
                ],
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
    return ref.watch(
      pendingInviteCountProvider(user.uid).select((async) => async.value ?? 0),
    );
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
              : 'Abra seus convites pendentes e responda os que fizerem sentido para você.',
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
    if (id == 'crew') {
      return 'Equipe Técnica';
    }
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
