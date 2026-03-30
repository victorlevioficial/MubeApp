import 'dart:async';

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
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_type.dart';
import '../../auth/presentation/account_deletion_provider.dart';
import '../../matchpoint/presentation/widgets/matchpoint_highlight_card.dart';
import 'widgets/bento_header.dart';
import 'widgets/neon_settings_tile.dart';
import 'widgets/settings_group.dart';

/// Professional Settings screen with enhanced UI/UX
///
/// Features:
/// - Modern bento grid header with stats
/// - Refined settings groups with better visual hierarchy
/// - Professional spacing and typography
/// - Smooth interactions and animations
/// - Clear visual separation between sections
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: l10n.settings_title, showBackButton: false),
      extendBodyBehindAppBar: false,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s4),
            const BentoHeader(),
            const SizedBox(height: AppSpacing.s16),
            MatchpointHighlightCard(
              user: ref.watch(currentUserProfileProvider).value,
              onTap: () => context.push(RoutePaths.matchpoint),
            ),
            const SizedBox(height: AppSpacing.s40),
            SettingsGroup(
              title: l10n.settings_account,
              children: [
                NeonSettingsTile(
                  icon: Icons.person_outline,
                  title: l10n.profile_edit_title,
                  onTap: () => context.push(RoutePaths.profileEdit),
                  customAccentColor: AppColors.primary,
                ),
                NeonSettingsTile(
                  icon: Icons.work_outline_rounded,
                  title: l10n.settings_my_gigs,
                  subtitle: l10n.settings_my_gigs_subtitle,
                  onTap: () => context.push(RoutePaths.settingsMyGigs),
                  customAccentColor: AppColors.warning,
                ),
                NeonSettingsTile(
                  icon: Icons.assignment_outlined,
                  title: l10n.settings_my_applications,
                  subtitle: l10n.settings_my_applications_subtitle,
                  onTap: () => context.push(RoutePaths.settingsMyApplications),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.favorite_outline,
                  title: l10n.settings_favorites,
                  onTap: () => context.push(RoutePaths.favorites),
                  customAccentColor: AppColors.primary,
                ),
                NeonSettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: l10n.settings_notifications,
                  onTap: () => context.push(RoutePaths.notifications),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.location_on_outlined,
                  title: l10n.settings_addresses,
                  subtitle: l10n.settings_addresses_subtitle,
                  onTap: () => context.push(RoutePaths.addresses),
                  customAccentColor: AppColors.info,
                ),
                if (ref.watch(
                      currentUserProfileProvider.select(
                        (s) => s.value?.tipoPerfil,
                      ),
                    ) ==
                    AppUserType.band)
                  NeonSettingsTile(
                    icon: Icons.groups_outlined,
                    title: l10n.settings_band_management,
                    subtitle: l10n.settings_band_management_subtitle,
                    onTap: () => context.push(RoutePaths.invites),
                    customAccentColor: AppColors.warning,
                  )
                else
                  NeonSettingsTile(
                    icon: Icons.mail_outline,
                    title: l10n.settings_my_bands,
                    subtitle: l10n.settings_my_bands_subtitle,
                    onTap: () => context.push(RoutePaths.invites),
                    customAccentColor: AppColors.warning,
                  ),
                if (canChangePassword)
                  NeonSettingsTile(
                    icon: Icons.lock_outline,
                    title: l10n.settings_change_password,
                    onTap: () => _changePassword(context, ref),
                    customAccentColor: AppColors.info,
                  ),
                NeonSettingsTile(
                  icon: Icons.public,
                  title: l10n.settings_privacy_visibility,
                  subtitle: l10n.settings_privacy_visibility_subtitle,
                  onTap: () => context.push(RoutePaths.privacySettings),
                  customAccentColor: AppColors.primary,
                ),
              ],
            ),
            SettingsGroup(
              title: l10n.settings_other,
              children: [
                NeonSettingsTile(
                  icon: Icons.language_rounded,
                  title: l10n.settings_app_language,
                  subtitle: _labelForLanguageOptionId(l10n, selectedLanguageId),
                  onTap: () => _selectLanguage(
                    context,
                    ref,
                    selectedLanguageId: selectedLanguageId,
                  ),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: l10n.settings_help,
                  onTap: () => context.push(RoutePaths.support),
                  customAccentColor: AppColors.info,
                ),
                NeonSettingsTile(
                  icon: Icons.star_outline_rounded,
                  title: l10n.settings_rate_app,
                  subtitle: l10n.settings_rate_app_subtitle,
                  onTap: () => _requestStoreReview(context, ref),
                  customAccentColor: AppColors.warning,
                ),
                NeonSettingsTile(
                  icon: Icons.description_outlined,
                  title: l10n.settings_terms_of_use,
                  onTap: () =>
                      context.push(RoutePaths.legalDetail('termsOfUse')),
                  customAccentColor: AppColors.textSecondary.withValues(
                    alpha: 0.6,
                  ),
                ),
                NeonSettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.settings_privacy_policy,
                  onTap: () =>
                      context.push(RoutePaths.legalDetail('privacyPolicy')),
                  customAccentColor: AppColors.textSecondary.withValues(
                    alpha: 0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            _LogoutSection(
              onLogout: () => _confirmLogout(context, ref),
              onDelete: () => _confirmDelete(context, ref),
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
      unawaited(ref.read(authRepositoryProvider).signOut());
      if (context.mounted) {
        context.go(RoutePaths.login);
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
      builder: (context) => AppConfirmationDialog(
        title: l10n.settings_delete_confirm_title,
        message: l10n.settings_delete_confirm_message,
        confirmText: l10n.common_delete,
        isDestructive: true,
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;
    ref.read(accountDeletionInProgressProvider.notifier).start();
    AppSnackBar.info(context, l10n.settings_delete_in_progress);

    try {
      final result = await ref.read(authRepositoryProvider).deleteAccount();
      if (!context.mounted) return;

      result.fold(
        (failure) {
          ref.read(accountDeletionInProgressProvider.notifier).clear();
          AppSnackBar.error(
            context,
            _messageForDeleteFailure(l10n, failure.message),
          );
        },
        (_) {
          ref.invalidate(authStateChangesProvider);
          ref.invalidate(currentUserProfileProvider);
          AppSnackBar.success(context, l10n.settings_delete_success);
        },
      );
    } catch (error) {
      ref.read(accountDeletionInProgressProvider.notifier).clear();
      if (!context.mounted) return;
      AppSnackBar.error(
        context,
        l10n.settings_error_with_details(error.toString()),
      );
    }
  }

  String _messageForDeleteFailure(AppLocalizations l10n, String message) {
    if (message == 'requires-recent-login') {
      return l10n.settings_delete_requires_recent_login;
    }
    const exceptionPrefix = 'Exception: ';
    if (message.startsWith(exceptionPrefix)) {
      return message.substring(exceptionPrefix.length).trim();
    }

    return message.trim();
  }
}

bool _supportsPasswordReset(User? user) {
  if (user == null) return false;

  // Password reset only applies to accounts that authenticate with
  // Firebase email/password. Social-only providers like Apple should not
  // expose this action in settings.
  final providerIds = user.providerData
      .map((provider) => provider.providerId)
      .toSet();

  return providerIds.contains('password');
}

class _LogoutSection extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  const _LogoutSection({required this.onLogout, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _LogoutButton(onTap: onLogout),
        const SizedBox(height: AppSpacing.s16),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s8,
            ),
          ),
          child: Text(
            l10n.settings_delete_account,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.error.withValues(alpha: 0.9),
              decoration: TextDecoration.underline,
              decorationColor: AppColors.error.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
      duration: AppEffects.fast,
      curve: Curves.easeOut,
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: _isPressed
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withValues(alpha: 0.8),
                  AppColors.surface.withValues(alpha: 0.6),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withValues(alpha: 0.7),
                  AppColors.surface.withValues(alpha: 0.5),
                ],
              ),
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: _isPressed
              ? AppColors.textPrimary.withValues(alpha: 0.12)
              : AppColors.textPrimary.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: _isPressed
            ? null
            : [
                BoxShadow(
                  color: AppColors.background.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: AppRadius.all16,
          splashColor: AppColors.textPrimary.withValues(alpha: 0.05),
          highlightColor: AppColors.textPrimary.withValues(alpha: 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                color: AppColors.textPrimary.withValues(alpha: 0.9),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(
                l10n.settings_logout_account,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
