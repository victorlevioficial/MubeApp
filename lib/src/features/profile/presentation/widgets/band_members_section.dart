import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../../utils/professional_profile_utils.dart';
import '../../../auth/domain/app_user.dart';

/// Horizontal scrollable section showing band members.
///
/// Each card displays the member avatar, name and their primary
/// instrument/role. Tapping a card navigates to the member's profile.
class BandMembersSection extends StatelessWidget {
  final List<AppUser> members;
  final Color accentColor;

  const BandMembersSection({
    super.key,
    required this.members,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s16),
        itemBuilder: (context, index) => _BandMemberCard(
          member: members[index],
          accentColor: accentColor,
          onTap: () =>
              context.push(RoutePaths.publicProfileById(members[index].uid)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Text(
      'Nenhum integrante confirmado ainda.',
      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _BandMemberCard extends StatelessWidget {
  final AppUser member;
  final Color accentColor;
  final VoidCallback onTap;

  const _BandMemberCard({
    required this.member,
    required this.accentColor,
    required this.onTap,
  });

  String get _primaryRole {
    final prof = member.dadosProfissional;
    if (prof == null) return 'M\u00FAsico';

    final instrumentos = prof['instrumentos'] as List?;
    if (instrumentos != null && instrumentos.isNotEmpty) {
      return instrumentDisplayLabel(instrumentos.first.toString());
    }
    final funcoes = prof['funcoes'] as List?;
    if (funcoes != null && funcoes.isNotEmpty) {
      return professionalRoleDisplayLabel(funcoes.first.toString());
    }
    // Legacy field
    final skills = prof['skills'] as List?;
    if (skills != null && skills.isNotEmpty) {
      return skills.first as String;
    }
    return 'M\u00FAsico';
  }

  @override
  Widget build(BuildContext context) {
    final name = member.appDisplayName;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with accent ring
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                UserAvatar(
                  size: 68,
                  photoUrl: member.avatarFullUrl,
                  photoPreviewUrl: member.avatarPreviewUrl,
                  name: name,
                  showBorder: false,
                ),
                // Small arrow-forward indicator
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            // Name
            Text(
              name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            // Role/Instrument
            Text(
              _primaryRole,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
