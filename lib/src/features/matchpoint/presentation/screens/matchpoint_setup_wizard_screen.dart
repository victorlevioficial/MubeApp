import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common_widgets/app_text_field.dart';
import '../../../../common_widgets/mube_app_bar.dart';
import '../../../../common_widgets/app_filter_chip.dart';
import '../../../../common_widgets/app_skeleton.dart';
import '../../../../core/domain/app_config.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../controllers/matchpoint_controller.dart';

class MatchpointSetupWizardScreen extends ConsumerStatefulWidget {
  const MatchpointSetupWizardScreen({super.key});

  @override
  ConsumerState<MatchpointSetupWizardScreen> createState() =>
      _MatchpointSetupWizardScreenState();
}

class _MatchpointSetupWizardScreenState
    extends ConsumerState<MatchpointSetupWizardScreen> {
  int _currentStep = 0;

  // Temporary state for the form
  // ignore: unused_field
  String? _intent;
  // ignore: unused_field
  final List<String> _selectedGenres = [];
  // ignore: unused_field
  final List<String> _hashtags = [];
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(matchpointControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, stack) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $err'),
              backgroundColor: AppColors.error,
            ),
          );
        },
        data: (_) {
          if (prev?.isLoading == true) {
            // Only pop if we were loading (avoids init pop)
            context.pop();
          }
        },
      );
    });

    return Scaffold(
      appBar: const MubeAppBar(
        title: 'Configuração MatchPoint',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation(AppColors.brandPrimary),
            ),
            const SizedBox(height: AppSpacing.s24),

            Expanded(child: _buildStepContent()),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.surfaceHighlight)),
        ),
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: () => setState(() => _currentStep--),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text('Voltar'),
                )
              else
                const SizedBox(width: 64), // Keep layout stable

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size(120, 48),
                  elevation: 0,
                ),
                onPressed: ref.watch(matchpointControllerProvider).isLoading
                    ? null
                    : _onNextPressed,
                child: ref.watch(matchpointControllerProvider).isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : Text(_currentStep == 2 ? 'Concluir' : 'Próximo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIntentStep();
      case 1:
        return _buildGenresStep();
      case 2:
        return _buildHashtagsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildIntentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.rocket_launch_outlined,
          title: 'Qual seu objetivo?',
          subtitle: 'Isso nos ajuda a encontrar as pessoas certas.',
        ),
        const SizedBox(height: AppSpacing.s24),

        _buildSelectionCard(
          title: 'Entrar em uma banda',
          subtitle: 'Quero me juntar a um projeto existente',
          icon: Icons.group_add_outlined,
          isSelected: _intent == 'join_band',
          onTap: () => setState(() => _intent = 'join_band'),
        ),
        const SizedBox(height: AppSpacing.s16),
        _buildSelectionCard(
          title: 'Formar uma banda',
          subtitle: 'Procurando músicos para meu projeto',
          icon: Icons.music_note_outlined,
          isSelected: _intent == 'form_band',
          onTap: () => setState(() => _intent = 'form_band'),
        ),
        const SizedBox(height: AppSpacing.s16),
        _buildSelectionCard(
          title: 'Ambos',
          subtitle: 'Estou aberto a todas oportunidades',
          icon: Icons.all_inclusive,
          isSelected: _intent == 'both',
          onTap: () => setState(() => _intent = 'both'),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : AppColors.surfaceHighlight,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.brandPrimary
                  : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleLarge.copyWith(
                      color: isSelected
                          ? AppColors.brandPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.brandPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildGenresStep() {
    final availableGenres = ref.watch(genreLabelsProvider);
    final isConfigLoading = ref.watch(appConfigProvider).isLoading;

    if (availableGenres.isEmpty && isConfigLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepHeader(
            icon: Icons.music_note_rounded,
            title: 'Suas influências',
            subtitle: 'Escolha quais gêneros representam seu estilo.',
          ),
          const SizedBox(height: AppSpacing.s24),
          Expanded(
            child: SingleChildScrollView(
              child: SkeletonShimmer(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(12, (index) {
                    return const SkeletonBox(
                      width: 80,
                      height: 32,
                      borderRadius: 20,
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.music_note_rounded,
          title: 'Suas influências',
          subtitle: 'Escolha quais gêneros representam seu estilo.',
        ),
        const SizedBox(height: AppSpacing.s24),

        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: availableGenres.map((genre) {
                final isSelected = _selectedGenres.contains(genre);
                return AppFilterChip(
                  label: genre,
                  isSelected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre);
                      } else {
                        _selectedGenres.remove(genre);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStepHeader(
          icon: Icons.tag,
          title: 'Aprofunde seus interesses',
          subtitle:
              'Adicione hashtags específicas (ex: Cover, Autoral, PinkFloyd).',
        ),
        const SizedBox(height: AppSpacing.s24),

        AppTextField(
          controller: _tagController,
          hint: 'Digite uma tag e aperte Enter',
          prefixIcon: const Icon(Icons.tag, size: 20),
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: const Icon(Icons.add, color: AppColors.semanticAction),
            onPressed: _addHashtag,
          ),
          onSubmitted: (_) => _addHashtag(),
        ),
        const SizedBox(height: AppSpacing.s16),

        if (_hashtags.length >= 10)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s16),
            child: Text(
              'Limite de 10 hashtags atingido',
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),

        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hashtags.map((tag) {
                return AppFilterChip(
                  label: tag,
                  isSelected:
                      true, // Always "selected" style in this context or neutral
                  onSelected: (_) {}, // No-op, just visual
                  onRemove: () {
                    setState(() {
                      _hashtags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _addHashtag() {
    if (_tagController.text.isNotEmpty) {
      if (_hashtags.length >= 10) return;

      setState(() {
        // Sanitize input: remove all '#' user might have typed, trim, then add one '#'
        final String rawText = _tagController.text.replaceAll('#', '').trim();
        if (rawText.isNotEmpty) {
          final String tag = '#$rawText';
          if (!_hashtags.contains(tag)) {
            _hashtags.add(tag);
          }
        }
        _tagController.clear();
      });
    }
  }

  Future<void> _onNextPressed() async {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      // Get AppConfig to map Labels to IDs
      final appConfigAsync = ref.read(appConfigProvider);
      final appConfig = appConfigAsync.value;

      List<String> genreIds = [];
      if (appConfig != null) {
        genreIds = _selectedGenres.map((label) {
          final item = appConfig.genres.firstWhere(
            (g) => g.label == label,
            orElse: () => ConfigItem(id: label, label: label, order: 0),
          );
          return item.id;
        }).toList();
      } else {
        // Fallback: simple lowercase (should not happen if loaded)
        genreIds = _selectedGenres
            .map((e) => e.toLowerCase().replaceAll(' ', '_'))
            .toList();
      }

      await ref
          .read(matchpointControllerProvider.notifier)
          .saveMatchpointProfile(
            intent: _intent ?? 'both',
            genres: genreIds, // Send IDs, not Labels
            hashtags: _hashtags,
          );

      if (mounted) {
        // Success handled by listener
      }
    }
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, size: 48, color: AppColors.brandPrimary),
        const SizedBox(height: AppSpacing.s16),
        Text(
          title,
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
