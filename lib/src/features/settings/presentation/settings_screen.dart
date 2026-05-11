import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../core/providers/app_display_preferences_provider.dart';
import '../../../core/services/store_review_service.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_type.dart';
import '../../auth/presentation/account_deletion_provider.dart';
import '../../matchpoint/presentation/widgets/matchpoint_highlight_card.dart';
import 'widgets/bento_header.dart';

/// Settings screen used by the main app.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final authUser =
        ref.watch(authStateChangesProvider).value ??
        ref.read(authRepositoryProvider).currentUser;
    final canChangePassword = _supportsPasswordReset(authUser);
    final displayPreferences = ref.watch(appDisplayPreferencesProvider);
    final selectedLanguageId = _languageOptionIdFor(displayPreferences.locale);
    final userType = ref.watch(
      currentUserProfileProvider.select((s) => s.value?.tipoPerfil),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: l10n.settings_title, showBackButton: false),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BentoHeader(),
            const SizedBox(height: AppSpacing.s16),

            MatchpointHighlightCard(
              user: ref.watch(currentUserProfileProvider).value,
              onTap: () => context.push(RoutePaths.matchpoint),
            ),
            const SizedBox(height: AppSpacing.s32),

            _SectionLabel(label: l10n.settings_account.toUpperCase()),
            const SizedBox(height: AppSpacing.s8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: l10n.profile_edit_title,
                  onTap: () => context.push(RoutePaths.profileEdit),
                ),
                _SettingsTile(
                  icon: Icons.work_outline_rounded,
                  title: l10n.settings_my_gigs,
                  subtitle: l10n.settings_my_gigs_subtitle,
                  onTap: () => context.push(RoutePaths.settingsMyGigs),
                ),
                _SettingsTile(
                  icon: Icons.assignment_outlined,
                  title: l10n.settings_my_applications,
                  subtitle: l10n.settings_my_applications_subtitle,
                  onTap: () => context.push(RoutePaths.settingsMyApplications),
                ),
                _SettingsTile(
                  icon: Icons.favorite_outline_rounded,
                  title: l10n.settings_favorites,
                  onTap: () => context.push(RoutePaths.favorites),
                ),
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.settings_notifications,
                  onTap: () => context.push(RoutePaths.notifications),
                ),
                _SettingsTile(
                  icon: Icons.location_on_outlined,
                  title: l10n.settings_addresses,
                  subtitle: l10n.settings_addresses_subtitle,
                  onTap: () => context.push(RoutePaths.addresses),
                ),
                if (userType == AppUserType.band)
                  _SettingsTile(
                    icon: Icons.groups_outlined,
                    title: l10n.settings_band_management,
                    subtitle: l10n.settings_band_management_subtitle,
                    onTap: () => context.push(RoutePaths.invites),
                  )
                else
                  _SettingsTile(
                    icon: Icons.mail_outline_rounded,
                    title: l10n.settings_my_bands,
                    subtitle: l10n.settings_my_bands_subtitle,
                    onTap: () => context.push(RoutePaths.invites),
                  ),
                if (canChangePassword)
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    title: l10n.settings_change_password,
                    onTap: () => _changePassword(context, ref),
                  ),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  title: l10n.settings_privacy_visibility,
                  subtitle: l10n.settings_privacy_visibility_subtitle,
                  onTap: () => context.push(RoutePaths.privacySettings),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),

            _SectionLabel(label: l10n.settings_other.toUpperCase()),
            const SizedBox(height: AppSpacing.s8),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: l10n.settings_app_language,
                  valueText: _labelForLanguageOptionId(
                    l10n,
                    selectedLanguageId,
                  ),
                  onTap: () => _selectLanguage(
                    context,
                    ref,
                    selectedLanguageId: selectedLanguageId,
                  ),
                ),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: l10n.settings_help,
                  onTap: () => context.push(RoutePaths.support),
                ),
                _SettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: l10n.settings_rate_app,
                  subtitle: l10n.settings_rate_app_subtitle,
                  onTap: () => _requestStoreReview(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: l10n.settings_terms_of_use,
                  onTap: () =>
                      context.push(RoutePaths.legalDetail('termsOfUse')),
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.settings_privacy_policy,
                  onTap: () =>
                      context.push(RoutePaths.legalDetail('privacyPolicy')),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s24),

            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.logout_rounded,
                  title: l10n.settings_logout_account,
                  onTap: () => _confirmLogout(context, ref),
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),

            Center(
              child: TextButton(
                onPressed: () => _confirmDelete(context, ref),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s8,
                  ),
                  foregroundColor: AppColors.error,
                  overlayColor: AppColors.error,
                ),
                child: Text(
                  l10n.settings_delete_account,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.error.withValues(alpha: 0.7),
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.error.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.s48),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: l10n.settings_logout_confirm_title,
        message: l10n.settings_logout_confirm_message,
        confirmText: l10n.settings_logout,
        isDestructive: true,
      ),
    );

    if (confirm == true) {
      final result = await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        result.fold(
          (_) => AppSnackBar.error(
            context,
            'Não foi possível sair. Tente novamente.',
          ),
          (_) => context.go(RoutePaths.login),
        );
      }
    }
  }

  Future<void> _selectLanguage(
    BuildContext context,
    WidgetRef ref, {
    required String selectedLanguageId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await _openPreferenceSelectionSheet(
      context,
      title: l10n.settings_app_language,
      items: _languageOptionIds,
      selectedItem: selectedLanguageId,
      itemLabelBuilder: (id) => _labelForLanguageOptionId(l10n, id),
    );

    if (!context.mounted ||
        selected == null ||
        selected == selectedLanguageId) {
      return;
    }

    final notifier = ref.read(appDisplayPreferencesProvider.notifier);
    switch (selected) {
      case _languageOptionPortuguese:
        await notifier.setLocaleOverride(const Locale('pt'));
        break;
      case _languageOptionEnglish:
        await notifier.setLocaleOverride(const Locale('en'));
        break;
    }

    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted) return;
    final updatedL10n = AppLocalizations.of(context)!;
    AppSnackBar.success(
      context,
      updatedL10n.settings_language_updated(
        _labelForLanguageOptionId(updatedL10n, selected),
      ),
    );
  }

  Future<String?> _openPreferenceSelectionSheet(
    BuildContext context, {
    required String title,
    required List<String> items,
    required String selectedItem,
    required String Function(String) itemLabelBuilder,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await AppOverlay.bottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.top24),
      builder: (context) => AppSelectionModal(
        title: title,
        items: items,
        selectedItems: [selectedItem],
        allowMultiple: false,
        showSearch: false,
        confirmButtonText: l10n.settings_apply_preference,
        itemLabelBuilder: itemLabelBuilder,
      ),
    );

    if (selected == null || selected.isEmpty) return null;
    return selected.first;
  }

  Future<void> _requestStoreReview(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ref
        .read(storeReviewServiceProvider)
        .requestManualReview();
    if (!context.mounted) return;

    switch (result) {
      case StoreReviewManualRequestResult.promptRequested:
      case StoreReviewManualRequestResult.fallbackOpened:
        return;
      case StoreReviewManualRequestResult.unavailable:
        AppSnackBar.info(context, l10n.settings_rate_app_unavailable);
        return;
      case StoreReviewManualRequestResult.launchFailed:
        AppSnackBar.error(context, l10n.settings_rate_app_store_open_error);
        return;
    }
  }

  void _changePassword(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.read(authRepositoryProvider).currentUser;
    final email = user?.email;

    if (email == null || email.isEmpty) {
      AppSnackBar.error(context, l10n.settings_change_password_email_missing);
      return;
    }

    final confirm = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => AppConfirmationDialog(
        title: l10n.settings_change_password,
        message: l10n.settings_change_password_message(email),
        confirmText: l10n.settings_change_password_send,
        isDestructive: false,
      ),
    );

    if (confirm == true && context.mounted) {
      AppSnackBar.info(context, l10n.settings_change_password_sending);

      final result = await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email);

      if (!context.mounted) return;

      result.fold(
        (failure) => AppSnackBar.error(context, failure.message),
        (_) => AppSnackBar.success(
          context,
          l10n.settings_change_password_email_sent,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await AppOverlay.dialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountConfirmDialog(),
    );

    if (confirm != true) return;
    if (!context.mounted) return;
    ref.read(accountDeletionInProgressProvider.notifier).start();
    AppSnackBar.info(context, l10n.settings_delete_in_progress);

    try {
      final result = await ref.read(authRepositoryProvider).deleteAccount();
      if (!context.mounted) return;

      await result.fold(
        (failure) async {
          ref.read(accountDeletionInProgressProvider.notifier).clear();
          await _showDeleteErrorDialog(
            context,
            _messageForDeleteFailure(l10n, failure.message),
          );
        },
        (_) async {
          ref.invalidate(authStateChangesProvider);
          ref.invalidate(currentUserProfileProvider);
          ref.read(accountDeletionInProgressProvider.notifier).clear();
          AppSnackBar.success(context, l10n.settings_delete_success);
        },
      );
    } catch (error) {
      ref.read(accountDeletionInProgressProvider.notifier).clear();
      if (!context.mounted) return;
      await _showDeleteErrorDialog(
        context,
        l10n.settings_error_with_details(error.toString()),
      );
    }
  }

  Future<void> _showDeleteErrorDialog(
    BuildContext context,
    String message,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete_account_error_title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _messageForDeleteFailure(AppLocalizations l10n, String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('requires-recent-login')) {
      return l10n.settings_delete_requires_recent_login;
    }
    if (normalized.contains('unauthenticated') ||
        normalized.contains('appcheck') ||
        normalized.contains('app check') ||
        normalized.contains('throttled')) {
      return l10n.delete_account_session_issue;
    }
    const exceptionPrefix = 'Exception: ';
    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length).trim();
    }
    return message.trim();
  }
}

class _DeleteAccountConfirmDialog extends StatefulWidget {
  const _DeleteAccountConfirmDialog();

  @override
  State<_DeleteAccountConfirmDialog> createState() =>
      _DeleteAccountConfirmDialogState();
}

class _DeleteAccountConfirmDialogState
    extends State<_DeleteAccountConfirmDialog> {
  final _controller = TextEditingController();
  static const _expected = 'EXCLUIR';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canConfirm = _controller.text.trim() == _expected;

    return AlertDialog(
      title: Text(l10n.settings_delete_confirm_title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.settings_delete_confirm_message),
            const SizedBox(height: AppSpacing.s16),
            Text(
              l10n.delete_account_type_to_confirm(_expected),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: _expected,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(l10n.common_delete),
        ),
      ],
    );
  }
}

bool _supportsPasswordReset(User? user) {
  if (user == null) return false;
  final providerIds = user.providerData
      .map((provider) => provider.providerId)
      .toSet();
  return providerIds.contains('password');
}

const String _languageOptionPortuguese = 'pt';
const String _languageOptionEnglish = 'en';
const List<String> _languageOptionIds = <String>[
  _languageOptionPortuguese,
  _languageOptionEnglish,
];

String _languageOptionIdFor(Locale? localeOverride) {
  switch (localeOverride?.languageCode) {
    case 'en':
      return _languageOptionEnglish;
    case 'pt':
    default:
      return _languageOptionPortuguese;
  }
}

String _labelForLanguageOptionId(AppLocalizations l10n, String id) {
  switch (id) {
    case _languageOptionPortuguese:
      return l10n.settings_language_portuguese_brazil;
    case _languageOptionEnglish:
      return l10n.settings_language_english;
    default:
      return l10n.settings_language_portuguese_brazil;
  }
}

/// Uppercase section label rendered above each [_SettingsCard].
class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.s4),
      child: Text(
        label,
        style: AppTypography.settingsGroupTitle.copyWith(
          color: AppColors.textTertiary,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

/// iOS-style card that groups related [_SettingsTile]s with indented dividers.
///
/// Uses [Material] so [InkWell] ripples inside each tile render correctly.
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    // Interleave dividers between consecutive tiles.
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(const _CardDivider());
      }
    }

    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.all20,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
          borderRadius: AppRadius.all20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        ),
      ),
    );
  }
}

/// Subtle indented divider between tiles inside a [_SettingsCard].
///
/// Indented past the icon area (padding 16 + icon 36 + gap 12 = 64 px).
class _CardDivider extends StatelessWidget {
  const _CardDivider();

  static const double _indent =
      AppSpacing.s16 + _SettingsTile._iconSize + AppSpacing.s12;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.border.withValues(alpha: 0.5),
      indent: _indent,
      endIndent: 0,
    );
  }
}

/// Single row inside a [_SettingsCard].
///
/// Layout: [icon container] [title + subtitle] [valueText?] [chevron?]
class _SettingsTile extends StatelessWidget {
  static const double _iconSize = 36.0;

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Optional right-side value text (e.g. current language name).
  final String? valueText;

  final VoidCallback onTap;

  /// Set to false for tiles that are self-explanatory (e.g. logout).
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.valueText,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.textPrimary.withValues(alpha: 0.08),
      highlightColor: AppColors.textPrimary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        child: Row(
          children: [
            Container(
              width: _iconSize,
              height: _iconSize,
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                borderRadius: AppRadius.all12,
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: AppSpacing.s12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      subtitle!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            if (valueText != null) ...[
              const SizedBox(width: AppSpacing.s8),
              Text(
                valueText!,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],

            if (showChevron) ...[
              const SizedBox(width: AppSpacing.s4),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
