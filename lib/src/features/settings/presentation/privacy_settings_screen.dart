import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_type.dart';
import '../../chat/data/chat_repository.dart';
import '../../moderation/data/blocked_users_provider.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: l10n.settings_privacy_visibility),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(l10n.settings_user_not_found));
          }

          final isContractor = user.tipoPerfil == AppUserType.contractor;
          final isActiveMatchpoint =
              user.matchpointProfile?['is_active'] == true;
          final isVisibleHome =
              (user.privacySettings['visible_in_home'] as bool?) ?? true;
          final isChatOpen =
              (user.privacySettings['chat_open'] as bool?) ?? true;
          final isPublicProfile =
              (user.dadosContratante?['isPublic'] as bool?) ?? false;

          final totalBlockedCount = {
            ...user.blockedUsers,
            ...?ref.read(blockedUsersProvider).value,
          }.length;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              _buildSectionHeader(l10n.settings_section_visibility),
              if (!isContractor)
                _buildSwitchTile(
                  title: l10n.settings_privacy_home_visibility_title,
                  subtitle: l10n.settings_privacy_home_visibility_subtitle,
                  value: isVisibleHome,
                  onChanged: (val) async {
                    final notifier = ref.read(authRepositoryProvider);
                    final updatedPrivacy = {
                      ...user.privacySettings,
                      'visible_in_home': val,
                    };
                    await notifier.updateUser(
                      user.copyWith(privacySettings: updatedPrivacy),
                    );
                  },
                ),
              if (!isContractor)
                _buildSwitchTile(
                  title: l10n.settings_privacy_matchpoint_title,
                  subtitle: l10n.settings_privacy_matchpoint_subtitle,
                  value: isActiveMatchpoint,
                  onChanged: (val) async {
                    final notifier = ref.read(authRepositoryProvider);
                    final updatedMatchpoint = {
                      ...user.matchpointProfile ?? {},
                      'is_active': val,
                    };
                    await notifier.updateUser(
                      user.copyWith(matchpointProfile: updatedMatchpoint),
                    );
                  },
                ),
              if (isContractor)
                _buildSwitchTile(
                  title: l10n.settings_privacy_public_profile_title,
                  subtitle: l10n.settings_privacy_public_profile_subtitle,
                  value: isPublicProfile,
                  onChanged: (val) async {
                    if (val && (user.avatarFullUrl ?? '').trim().isEmpty) {
                      AppSnackBar.warning(
                        context,
                        l10n.settings_privacy_public_profile_photo_required,
                      );
                      return;
                    }

                    final notifier = ref.read(authRepositoryProvider);
                    final updatedContractor = Map<String, dynamic>.from(
                      user.dadosContratante ?? const <String, dynamic>{},
                    )..['isPublic'] = val;

                    final result = await notifier.updateUser(
                      user.copyWith(dadosContratante: updatedContractor),
                    );

                    if (!context.mounted) return;

                    if (result.isLeft()) {
                      final failure = result.fold(
                        (failure) => failure,
                        (_) => throw StateError('Expected update failure'),
                      );
                      AppSnackBar.error(
                        context,
                        l10n.settings_privacy_public_profile_update_error(
                          failure.message,
                        ),
                      );
                      return;
                    }

                    AppSnackBar.success(
                      context,
                      l10n.settings_privacy_public_profile_updated,
                    );
                  },
                ),
              _buildSwitchTile(
                title: l10n.settings_privacy_public_chat_title,
                subtitle: l10n.settings_privacy_public_chat_subtitle,
                value: isChatOpen,
                onChanged: (val) async {
                  final notifier = ref.read(authRepositoryProvider);
                  final updatedPrivacy = {
                    ...user.privacySettings,
                    'chat_open': val,
                  };
                  final result = await notifier.updateUser(
                    user.copyWith(privacySettings: updatedPrivacy),
                  );

                  if (!context.mounted) return;

                  if (result.isLeft()) {
                    final failure = result.fold(
                      (failure) => failure,
                      (_) => throw StateError('Expected update failure'),
                    );
                    AppSnackBar.error(
                      context,
                      l10n.settings_privacy_chat_update_error(failure.message),
                    );
                    return;
                  }

                  if (val) {
                    final reevaluateResult = await ref
                        .read(chatRepositoryProvider)
                        .reevaluatePendingConversationsForRecipient(
                          recipientId: user.uid,
                          trigger: 'privacy_settings_public',
                        );
                    if (!context.mounted) return;
                    reevaluateResult.fold(
                      (failure) => AppSnackBar.error(
                        context,
                        l10n.settings_privacy_chat_promote_error(
                          failure.message,
                        ),
                      ),
                      (_) => AppSnackBar.success(
                        context,
                        l10n.settings_privacy_chat_updated,
                      ),
                    );
                    return;
                  }

                  AppSnackBar.success(
                    context,
                    l10n.settings_privacy_chat_updated,
                  );
                },
              ),
              const Divider(color: AppColors.surfaceHighlight, height: 32),
              _buildSectionHeader(l10n.settings_section_security),
              ListTile(
                title: Text(
                  l10n.settings_blocked_users_title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.settings_blocked_users_count(
                    totalBlockedCount.toString(),
                  ),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                ),
                onTap: () {
                  context.push(RoutePaths.blockedUsers);
                },
              ),
            ],
          );
        },
        loading: () => const _PrivacySettingsSkeleton(),
        error: (err, stack) => Center(
          child: Text(l10n.settings_error_with_details(err.toString())),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: AppSpacing.v8,
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textTertiary,
          fontWeight: AppTypography.buttonPrimary.fontWeight,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      trackColor: WidgetStateProperty.resolveWith(
        (states) => AppColors.surfaceHighlight,
      ),
    );
  }
}

class _PrivacySettingsSkeleton extends StatelessWidget {
  const _PrivacySettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: const [
          SkeletonText(width: 110, height: 12),
          SizedBox(height: AppSpacing.s12),
          _PrivacyTileSkeleton(),
          SizedBox(height: AppSpacing.s12),
          _PrivacyTileSkeleton(),
          SizedBox(height: AppSpacing.s16),
          Divider(color: AppColors.surfaceHighlight, height: 32),
          SkeletonText(width: 92, height: 12),
          SizedBox(height: AppSpacing.s12),
          _SecurityTileSkeleton(),
        ],
      ),
    );
  }
}

class _PrivacyTileSkeleton extends StatelessWidget {
  const _PrivacyTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 170, height: 14),
                SizedBox(height: AppSpacing.s8),
                SkeletonText(width: double.infinity, height: 11),
                SizedBox(height: AppSpacing.s4),
                SkeletonText(width: 210, height: 11),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s12),
          SkeletonBox(width: 48, height: 28, borderRadius: AppRadius.rPill),
        ],
      ),
    );
  }
}

class _SecurityTileSkeleton extends StatelessWidget {
  const _SecurityTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all12,
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonText(width: 150, height: 14),
                SizedBox(height: AppSpacing.s8),
                SkeletonText(width: 92, height: 12),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.s8),
          SkeletonBox(width: 20, height: 20, borderRadius: AppRadius.r8),
        ],
      ),
    );
  }
}
