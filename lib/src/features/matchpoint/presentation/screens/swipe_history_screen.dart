import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mube/src/features/matchpoint/domain/swipe_history_entry.dart';

import '../../../../design_system/components/data_display/user_avatar.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../data/matchpoint_repository.dart';
import '../controllers/matchpoint_controller.dart';
import '../widgets/match_profile_preview_sheet.dart';

class SwipeHistoryScreen extends ConsumerStatefulWidget {
  const SwipeHistoryScreen({super.key});

  @override
  ConsumerState<SwipeHistoryScreen> createState() => _SwipeHistoryScreenState();
}

class _SwipeHistoryScreenState extends ConsumerState<SwipeHistoryScreen> {
  final Set<String> _loadingUserIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(swipeHistoryProvider);
    final dedupedHistory = _dedupeByTarget(history);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(
        title: 'Historico de Swipes',
        showBackButton: true,
      ),
      body: dedupedHistory.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.s16),
              itemCount: dedupedHistory.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.s12),
              itemBuilder: (context, index) {
                final item = dedupedHistory[index];
                return _buildHistoryItem(
                  item,
                  isLoading: _loadingUserIds.contains(item.targetUserId),
                  onTap: () => _openProfilePreview(item),
                );
              },
            ),
    );
  }

  List<SwipeHistoryEntry> _dedupeByTarget(List<SwipeHistoryEntry> input) {
    final seen = <String>{};
    return input.where((item) => seen.add(item.targetUserId)).toList();
  }

  Future<void> _openProfilePreview(SwipeHistoryEntry item) async {
    if (_loadingUserIds.contains(item.targetUserId)) return;

    setState(() {
      _loadingUserIds.add(item.targetUserId);
    });

    final repo = ref.read(matchpointRepositoryProvider);
    final result = await repo.fetchUserById(item.targetUserId);

    if (!mounted) return;

    setState(() {
      _loadingUserIds.remove(item.targetUserId);
    });

    await result.fold(
      (failure) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message.isNotEmpty
                  ? failure.message
                  : 'Nao foi possivel abrir este perfil agora.',
            ),
          ),
        );
      },
      (user) async {
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este perfil nao esta mais disponivel.'),
            ),
          );
          return;
        }

        await MatchProfilePreviewSheet.show(context, user);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Nenhum historico recente',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Seus swipes aparecerao aqui',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    SwipeHistoryEntry item, {
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final isLike = item.action == 'like' || item.action == 'superlike';
    final actionColor = isLike ? AppColors.success : AppColors.error;
    final actionIcon = isLike ? Icons.favorite : Icons.close;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all12,
        onTap: isLoading ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all12,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              UserAvatar(
                photoUrl: item.targetUserPhoto,
                name: item.targetUserName,
                size: 50,
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.targetUserName, style: AppTypography.titleSmall),
                    Text(
                      DateFormat('HH:mm - dd/MM').format(item.timestamp),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: actionColor,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(actionIcon, color: actionColor, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
