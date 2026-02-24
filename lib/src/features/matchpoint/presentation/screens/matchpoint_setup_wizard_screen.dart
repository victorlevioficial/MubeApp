import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/firestore_constants.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
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
  static const int _totalSteps = 3;

  // Temporary state for the form
  String? _intent;
  final List<String> _profileGenreIds = [];
  final List<String> _hashtags = [];
  final TextEditingController _tagController = TextEditingController();
  bool _isVisibleInHome = true;
  bool _didPrefillFromProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromCurrentProfile();
    });
  }

  void _prefillFromCurrentProfile() {
    if (_didPrefillFromProfile) return;

    final user = ref.read(currentUserProfileProvider).value;
    if (user == null) return;

    final profile = user.matchpointProfile;
    final rawHashtags = profile?[FirestoreFields.hashtags];
    final visibleInHome = user.privacySettings['visible_in_home'];

    setState(() {
      _intent = profile?[FirestoreFields.intent] as String? ?? _intent;

      _profileGenreIds
        ..clear()
        ..addAll(_resolveUserGenreIds(user));

      if (rawHashtags is List) {
        _hashtags
          ..clear()
          ..addAll(rawHashtags.whereType<String>());
      }

      if (visibleInHome is bool) {
        _isVisibleInHome = visibleInHome;
      }

      _didPrefillFromProfile = true;
    });
  }

  List<String> _resolveUserGenreIds(AppUser user) {
    final matchpointGenres =
        user.matchpointProfile?[FirestoreFields.musicalGenres] ??
        user.matchpointProfile?['musicalGenres'] ??
        user.matchpointProfile?['musical_genres'];
    if (matchpointGenres is List && matchpointGenres.isNotEmpty) {
      return matchpointGenres.whereType<String>().toList();
    }

    final professionalGenres = user.dadosProfissional?['generosMusicais'];
    if (professionalGenres is List && professionalGenres.isNotEmpty) {
      return professionalGenres.whereType<String>().toList();
    }

    final bandGenres = user.dadosBanda?['generosMusicais'];
    if (bandGenres is List && bandGenres.isNotEmpty) {
      return bandGenres.whereType<String>().toList();
    }

    return const <String>[];
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_didPrefillFromProfile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillFromCurrentProfile();
      });
    }

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
            ref.invalidate(matchpointCandidatesProvider);
            context.pop();
          }
        },
      );
    });

    return Scaffold(
      appBar: const AppAppBar(
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
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
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
                AppButton.ghost(
                  onPressed: () => setState(() => _currentStep--),
                  text: 'Voltar',
                )
              else
                const SizedBox(width: AppSpacing.s48),

              AppButton.primary(
                onPressed:
                    ref.watch(
                      matchpointControllerProvider.select((s) => s.isLoading),
                    )
                    ? null
                    : _onNextPressed,
                isLoading: ref.watch(
                  matchpointControllerProvider.select((s) => s.isLoading),
                ),
                text: _currentStep == (_totalSteps - 1) ? 'Concluir' : 'Próximo',
                size: AppButtonSize.medium,
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
        return _buildHashtagsStep();
      case 2:
        return _buildPrivacyStep();
      default:
        return const SizedBox();
      }
  }

  Widget _buildIntentStep() {
    return ListView(
      padding: EdgeInsets.zero,
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
      borderRadius: AppRadius.all12,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: AppRadius.all12,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceHighlight,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
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
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
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
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagsStep() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildStepHeader(
          icon: Icons.tag,
          title: 'Aprofunde seus interesses',
          subtitle:
              'Adicione hashtags específicas (ex: Cover, Autoral, PinkFloyd).',
        ),
        const SizedBox(height: AppSpacing.s24),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all12,
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: Text(
            _profileGenreIds.isEmpty
                ? 'Os gêneros do cadastro não foram encontrados. Complete seu perfil musical para o MatchPoint funcionar melhor.'
                : 'Usaremos automaticamente os gêneros do seu cadastro para buscar perfis compatíveis.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.s16),

        AppTextField(
          controller: _tagController,
          hint: 'Digite uma tag e aperte Enter',
          prefixIcon: const Icon(Icons.tag, size: 20),
          textInputAction: TextInputAction.done,
          suffixIcon: IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
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

        Wrap(
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
    if (!_validateCurrentStep()) return;

    if (_currentStep < (_totalSteps - 1)) {
      setState(() => _currentStep++);
    } else {
      final user = ref.read(currentUserProfileProvider).value;
      final genreIds = user == null
          ? List<String>.from(_profileGenreIds)
          : _resolveUserGenreIds(user);

      if (genreIds.isEmpty) {
        _showValidationError(
          'Não encontramos seus gêneros musicais. Complete seu cadastro primeiro.',
        );
        return;
      }

      await ref
          .read(matchpointControllerProvider.notifier)
          .saveMatchpointProfile(
            intent: _intent ?? 'both',
            genres: genreIds,
            hashtags: _hashtags,
            isVisibleInHome: _isVisibleInHome,
          );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_intent == null) {
          _showValidationError('Selecione seu objetivo para continuar.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  Widget _buildPrivacyStep() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildStepHeader(
          icon: Icons.privacy_tip_outlined,
          title: 'Configuração de Visibilidade',
          subtitle: 'Escolha onde seu perfil deve aparecer.',
        ),
        const SizedBox(height: AppSpacing.s24),
        _buildSelectionCard(
          title: 'Modo Público',
          subtitle: 'Aparecer na Home, Busca e MatchPoint',
          icon: Icons.public,
          isSelected: _isVisibleInHome,
          onTap: () => setState(() => _isVisibleInHome = true),
        ),
        const SizedBox(height: AppSpacing.s16),
        _buildSelectionCard(
          title: 'Apenas MatchPoint',
          subtitle:
              'Esconder da Home/Busca. Ideal para quem busca banda discretamente.',
          icon: Icons.visibility_off_outlined,
          isSelected: !_isVisibleInHome,
          onTap: () => setState(() => _isVisibleInHome = false),
        ),
      ],
    );
  }

  Widget _buildStepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, size: 48, color: AppColors.primary),
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
