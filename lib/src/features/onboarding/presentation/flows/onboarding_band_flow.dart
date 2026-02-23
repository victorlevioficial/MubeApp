import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../constants/app_constants.dart';
import '../../../../core/domain/app_config.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../design_system/components/navigation/responsive_center.dart';
import '../../../../design_system/components/patterns/onboarding_header.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';

/// Enhanced Band Onboarding Flow with modern UI.
///
/// Steps:
/// 1. Basic Info (Full name + Band name + Contact)
/// 2. Musical Genres
/// 3. Address
class OnboardingBandFlow extends ConsumerStatefulWidget {
  final AppUser user;

  const OnboardingBandFlow({super.key, required this.user});

  @override
  ConsumerState<OnboardingBandFlow> createState() => _OnboardingBandFlowState();
}

class _OnboardingBandFlowState extends ConsumerState<OnboardingBandFlow> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1;
  static const int _totalSteps = 3;

  final _nomeCompletoController = TextEditingController();
  final _nomeBandaController = TextEditingController();
  final _celularController = TextEditingController();
  final _instagramController = TextEditingController();

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);
    final bandData = widget.user.dadosBanda ?? const <String, dynamic>{};

    _nomeCompletoController.text = formState.nome ?? widget.user.nome ?? '';
    _nomeBandaController.text =
        formState.nomeArtistico ??
        (bandData['nomeBanda'] as String?) ??
        (bandData['nomeArtistico'] as String?) ??
        widget.user.appDisplayName;
    _celularController.text = formState.celular ?? '';
    _instagramController.text = formState.instagram ?? '';
    _selectedGenres = List.from(formState.selectedGenres);

    _nomeCompletoController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateNome(_nomeCompletoController.text),
    );
    _nomeBandaController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateNomeArtistico(_nomeBandaController.text),
    );
    _celularController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateCelular(_celularController.text),
    );
    _instagramController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateInstagram(_instagramController.text),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingFormProvider.notifier).fetchInitialLocation();
    });
  }

  @override
  void dispose() {
    _nomeCompletoController.dispose();
    _nomeBandaController.dispose();
    _celularController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (_selectedGenres.isEmpty) {
        AppSnackBar.show(
          context,
          'Selecione pelo menos um genero musical',
          isError: true,
        );
        return;
      }
      ref.read(onboardingFormProvider.notifier).updateGenres(_selectedGenres);
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      ref
          .read(onboardingControllerProvider.notifier)
          .resetToTypeSelection(currentUser: widget.user);
    }
  }

  void _finishOnboarding() {
    final appConfigAsync = ref.read(appConfigProvider);
    final appConfig = appConfigAsync.value;

    List<String> genreIds = _selectedGenres;

    if (appConfig != null) {
      genreIds = _selectedGenres.map((label) {
        return appConfig.genres
            .firstWhere(
              (g) => g.label == label,
              orElse: () => ConfigItem(id: label, label: label, order: 0),
            )
            .id;
      }).toList();
    }

    final bandDisplayName = _nomeBandaController.text.trim();

    final Map<String, dynamic> bandData = {
      'nomeBanda': bandDisplayName,
      'nomeArtistico': bandDisplayName,
      'nome': bandDisplayName,
      'celular': _celularController.text,
      'instagram': _instagramController.text,
      'generosMusicais': genreIds,
      'isPublic': true,
    };

    final formState = ref.read(onboardingFormProvider);

    final location = {
      'cep': formState.cep,
      'logradouro': formState.logradouro,
      'numero': formState.numero,
      'bairro': formState.bairro,
      'cidade': formState.cidade,
      'estado': formState.estado,
      'lat': formState.selectedLat,
      'lng': formState.selectedLng,
    };

    ref
        .read(onboardingControllerProvider.notifier)
        .submitProfileForm(
          currentUser: widget.user,
          nome: _nomeCompletoController.text.trim(),
          location: location,
          dadosBanda: bandData,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxContentWidth: 600,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s24,
              vertical: AppSpacing.s24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OnboardingHeader(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    onBack: _prevStep,
                  ),
                  const SizedBox(height: AppSpacing.s32),

                  if (_currentStep == 1) _buildStep1UI(),
                  if (_currentStep == 2) _buildStep2UI(),
                  if (_currentStep == 3)
                    OnboardingAddressStep(
                      onNext: () async => _finishOnboarding(),
                      onBack: _prevStep,
                      initialLocationLabel: ref
                          .watch(onboardingFormProvider)
                          .initialLocationLabel,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dados da Banda',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Informacoes basicas sobre o grupo',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        AppTextField(
          controller: _nomeCompletoController,
          label: 'Nome Completo (Responsavel)',
          hint: 'Usado para cadastro interno',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v!.trim().isEmpty ? 'Nome obrigatorio' : null,
          prefixIcon: const Icon(Icons.person_outline, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _nomeBandaController,
          label: 'Nome da Banda',
          hint: 'Nome exibido no app',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) =>
              v!.trim().isEmpty ? 'Nome da banda obrigatorio' : null,
          prefixIcon: const Icon(Icons.people_outline, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _celularController,
          label: 'Celular de Contato',
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [_celularMask],
          validator: (v) => v!.length < 14 ? 'Celular invalido' : null,
          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _instagramController,
          label: 'Instagram (opcional)',
          hint: '@nome_da_banda',
          prefixIcon: const Icon(Icons.alternate_email, size: 20),
        ),

        const SizedBox(height: AppSpacing.s48),

        SizedBox(
          height: 56,
          child: AppButton.primary(
            text: 'Continuar',
            size: AppButtonSize.large,
            onPressed: _nextStep,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Estilo Musical',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Quais generos a banda toca?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.s32),

        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(
              color: _selectedGenres.isEmpty
                  ? AppColors.error
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generos Musicais *',
                style: AppTypography.titleMedium.copyWith(
                  color: _selectedGenres.isEmpty
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _selectedGenres.isEmpty
                    ? 'Selecione os estilos que a banda toca'
                    : '${_selectedGenres.length} genero${_selectedGenres.length > 1 ? 's' : ''} selecionado${_selectedGenres.length > 1 ? 's' : ''}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (_selectedGenres.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    ..._selectedGenres.take(3).map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s10,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: AppRadius.all8,
                        ),
                        child: Text(
                          item,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }),
                    if (_selectedGenres.length > 3)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s10,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: AppRadius.all8,
                        ),
                        child: Text(
                          '+${_selectedGenres.length - 3}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
              SizedBox(
                width: double.infinity,
                child: AppButton.outline(
                  text: _selectedGenres.isEmpty
                      ? 'Selecionar Generos'
                      : 'Editar Generos',
                  onPressed: () async {
                    final result = await EnhancedMultiSelectModal.show<String>(
                      context: context,
                      title: 'Generos Musicais',
                      subtitle: 'Selecione os estilos da banda',
                      items: genres,
                      selectedItems: _selectedGenres,
                      searchHint: 'Buscar genero...',
                    );
                    if (result != null) {
                      setState(() => _selectedGenres = result);
                    }
                  },
                  icon: Icon(
                    _selectedGenres.isEmpty ? Icons.add : Icons.edit_outlined,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s48),

        SizedBox(
          height: 56,
          child: AppButton.primary(
            text: 'Continuar',
            size: AppButtonSize.large,
            onPressed: _selectedGenres.isNotEmpty ? _nextStep : null,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
