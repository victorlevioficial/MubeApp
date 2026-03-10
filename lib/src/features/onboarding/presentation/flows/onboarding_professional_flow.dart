import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../constants/app_constants.dart';
import '../../../../core/domain/app_config.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_date_picker_field.dart';
import '../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../design_system/components/navigation/responsive_center.dart';
import '../../../../design_system/components/patterns/onboarding_header.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../utils/category_normalizer.dart';
import '../../../../utils/instagram_utils.dart';
import '../../../../utils/professional_profile_utils.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';
import '../steps/professional_category_step.dart';

/// Enhanced Professional Onboarding Flow with modern UI.
///
/// Steps:
/// 1. Basic Info (Name, Birth Date, Gender, Contact)
/// 2. Category Selection (Singer, Instrumentalist, DJ, Production, Stage Tech)
/// 3. Specialization (based on selected categories)
/// 4. Address
///
/// Features modern, professional UI matching the login screen design.
class OnboardingProfessionalFlow extends ConsumerStatefulWidget {
  final AppUser user;

  const OnboardingProfessionalFlow({super.key, required this.user});

  @override
  ConsumerState<OnboardingProfessionalFlow> createState() =>
      _OnboardingProfessionalFlowState();
}

class _OnboardingProfessionalFlowState
    extends ConsumerState<OnboardingProfessionalFlow> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // State
  int _currentStep = 1;
  static const int _totalSteps = 4;

  // Controllers Step 1
  final _nomeController = TextEditingController();
  final _nomeArtisticoController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _generoController = TextEditingController();
  final _celularController = TextEditingController();
  final _instagramController = TextEditingController();

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  // Step 2 & 3 Data
  List<String> _selectedCategories = [];
  String _backingVocalMode = '0';
  bool _instrumentalistBackingVocal = false;
  bool _offersRemoteRecording = false;
  List<String> _selectedInstruments = [];
  List<String> _selectedRoles = [];
  List<String> _selectedGenres = [];

  List<String> get _selectedProductionRoles =>
      CategoryNormalizer.filterProductionRoles(_selectedRoles);

  List<String> get _selectedStageTechRoles =>
      CategoryNormalizer.filterStageTechRoles(_selectedRoles);

  void _updateProductionRoles(List<String> roles) {
    setState(() {
      _selectedRoles = [
        ..._selectedRoles.where(
          (role) => !CategoryNormalizer.isProductionRole(role),
        ),
        ...roles,
      ];
    });
  }

  void _updateStageTechRoles(List<String> roles) {
    setState(() {
      _selectedRoles = [
        ..._selectedRoles.where(
          (role) => !CategoryNormalizer.isStageTechRole(role),
        ),
        ...roles,
      ];
    });
  }

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);

    // Restore Data
    _nomeController.text = formState.nome ?? widget.user.nome ?? '';
    _nomeArtisticoController.text = formState.nomeArtistico ?? '';
    _dataNascimentoController.text = formState.dataNascimento ?? '';
    _generoController.text = normalizeGenderValue(formState.genero);
    _celularController.text = formState.celular ?? '';
    _instagramController.text = normalizeInstagramHandle(formState.instagram);

    // Setup Listeners
    _nomeController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateNome(_nomeController.text),
    );
    _nomeArtisticoController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateNomeArtistico(_nomeArtisticoController.text),
    );
    _dataNascimentoController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateDataNascimento(_dataNascimentoController.text),
    );
    _generoController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateGenero(_generoController.text),
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

    // Initialize non-controller state
    _selectedCategories = List.from(formState.selectedCategories);
    _selectedGenres = List.from(formState.selectedGenres);
    _selectedInstruments = List.from(formState.selectedInstruments);
    _selectedRoles = List.from(formState.selectedRoles);
    _backingVocalMode = formState.backingVocalMode;
    _instrumentalistBackingVocal = formState.instrumentalistBackingVocal;
    _offersRemoteRecording = formState.offersRemoteRecording;

    // Fetch location preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingFormProvider.notifier).fetchInitialLocation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nomeController.dispose();
    _nomeArtisticoController.dispose();
    _celularController.dispose();
    _dataNascimentoController.dispose();
    _generoController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      if (!_validateAge()) return;
      _setCurrentStep(_currentStep + 1);
    } else if (_currentStep == 2) {
      if (_selectedCategories.isEmpty) {
        AppSnackBar.show(
          context,
          'Selecione pelo menos uma categoria',
          isError: true,
        );
        return;
      }
      // Update provider
      ref
          .read(onboardingFormProvider.notifier)
          .updateCategories(_selectedCategories);
      _setCurrentStep(_currentStep + 1);
    } else if (_currentStep == 3) {
      if (!_isStep3Valid) {
        AppSnackBar.show(
          context,
          'Preencha todas as informações obrigatórias',
          isError: true,
        );
        return;
      }
      // Update provider
      ref.read(onboardingFormProvider.notifier)
        ..updateGenres(_selectedGenres)
        ..updateInstruments(_selectedInstruments)
        ..updateRoles(_selectedRoles);
      _setCurrentStep(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      _setCurrentStep(_currentStep - 1);
    } else {
      ref
          .read(onboardingControllerProvider.notifier)
          .resetToTypeSelection(currentUser: widget.user);
    }
  }

  void _setCurrentStep(int nextStep) {
    setState(() => _currentStep = nextStep);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  bool _validateAge() {
    final dobText = _dataNascimentoController.text;
    if (dobText.isEmpty) return true;

    try {
      final parts = dobText.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final dob = DateTime(year, month, day);
      final today = DateTime.now();

      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      if (age < 18) {
        AppSnackBar.show(
          context,
          'É necessário ser maior de 18 anos para se cadastrar.',
          isError: true,
        );
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  bool get _isStep3Valid {
    // All must select genres
    if (_selectedGenres.isEmpty) return false;

    // Instrumentalist must select instruments
    if (_selectedCategories.contains('instrumentalist') &&
        _selectedInstruments.isEmpty) {
      return false;
    }

    if (_selectedCategories.contains('production') &&
        _selectedProductionRoles.isEmpty) {
      return false;
    }

    if (_selectedCategories.contains('stage_tech') &&
        _selectedStageTechRoles.isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _finishOnboarding() async {
    final appConfigAsync = ref.read(appConfigProvider);
    final appConfig = appConfigAsync.value;

    List<String> genreIds = _selectedGenres;
    List<String> instrumentIds = _selectedInstruments;
    List<String> roleIds = _selectedRoles;

    if (appConfig != null) {
      final professionalRoles = [
        ...appConfig.productionRoles,
        ...appConfig.stageTechRoles,
        ...appConfig.crewRoles,
      ];

      genreIds = _selectedGenres.map((label) {
        return appConfig.genres
            .firstWhere(
              (g) => g.label == label,
              orElse: () => ConfigItem(id: label, label: label, order: 0),
            )
            .id;
      }).toList();

      instrumentIds = _selectedInstruments.map((label) {
        return appConfig.instruments
            .firstWhere(
              (i) => i.label == label,
              orElse: () => ConfigItem(id: label, label: label, order: 0),
            )
            .id;
      }).toList();

      roleIds = _selectedRoles.map((label) {
        return professionalRoles
            .firstWhere(
              (r) => r.label == label,
              orElse: () => ConfigItem(id: label, label: label, order: 0),
            )
            .id;
      }).toList();
    }

    final Map<String, dynamic> professionalData = {
      'nomeArtistico': _nomeArtisticoController.text.trim(),
      'celular': _celularController.text.trim(),
      'dataNascimento': _dataNascimentoController.text.trim(),
      'genero': _generoController.text.trim(),
      'instagram': normalizeInstagramHandle(_instagramController.text),
      'categorias': _selectedCategories,
      'generosMusicais': genreIds,
      'isPublic': true,
    };

    if (_selectedCategories.contains('singer')) {
      professionalData['backingVocalMode'] = _backingVocalMode;
    }

    if (_selectedCategories.contains('instrumentalist')) {
      professionalData['instrumentos'] = instrumentIds;
      professionalData['fazBackingVocal'] = _instrumentalistBackingVocal;
      professionalData['instrumentalistBackingVocal'] =
          _instrumentalistBackingVocal;
    }

    if (_selectedCategories.contains('production') ||
        _selectedCategories.contains('stage_tech')) {
      professionalData['funcoes'] = roleIds;
    }

    professionalData[professionalRemoteRecordingFieldKey] =
        _selectedCategories.contains('production') && _offersRemoteRecording;

    final formState = ref.read(onboardingFormProvider);

    await ref
        .read(onboardingControllerProvider.notifier)
        .submitProfileForm(
          currentUser: widget.user,
          nome: _nomeController.text.trim(),
          location: formState.locationMap,
          dadosProfissional: professionalData,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(onboardingControllerProvider).isLoading;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || isSubmitting) return;
        _prevStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
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
                    if (_currentStep == 3) _buildStep3UI(),
                    if (_currentStep == 4)
                      OnboardingAddressStep(
                        onNext: _finishOnboarding,
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
      ),
    );
  }

  Widget _buildStep1UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dados Pessoais',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Conte-nos um pouco sobre você',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        AppTextField(
          controller: _nomeController,
          label: 'Nome Completo',
          hint: 'Digite seu nome completo',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v!.isEmpty ? 'Nome obrigatório' : null,
          prefixIcon: const Icon(Icons.person_outline, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _nomeArtisticoController,
          label: 'Nome Artístico',
          hint: 'Nome exibido no app',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v!.isEmpty ? 'Nome artístico obrigatório' : null,
          prefixIcon: const Icon(Icons.stars_outlined, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _celularController,
          label: 'Celular',
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [_celularMask],
          validator: (v) => v!.length < 14 ? 'Celular inválido' : null,
          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppDatePickerField(
          label: 'Data de Nascimento (opcional)',
          controller: _dataNascimentoController,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppDropdownField<String>(
          label: 'Gênero (opcional)',
          value: normalizeGenderValue(_generoController.text).isEmpty
              ? null
              : normalizeGenderValue(_generoController.text),
          items: genderOptions
              .map(
                (gender) =>
                    DropdownMenuItem(value: gender, child: Text(gender)),
              )
              .toList(),
          onChanged: (v) {
            setState(() => _generoController.text = normalizeGenderValue(v));
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _instagramController,
          label: instagramLabelOptional,
          hint: instagramHint,
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
    return ProfessionalCategoryStep(
      selectedCategories: _selectedCategories,
      onCategoriesChanged: (categories) {
        setState(() => _selectedCategories = categories);
      },
      onNext: _nextStep,
      onBack: _prevStep,
    );
  }

  Widget _buildStep3UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Especialização',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Informe suas habilidades e preferências musicais',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.s32),

        // Singer Section
        if (_selectedCategories.contains('singer')) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: AppDropdownField<String>(
              label: 'Faz Backing Vocal?',
              value: _backingVocalMode,
              items: const [
                DropdownMenuItem(
                  value: '0',
                  child: Text('Não, apenas voz principal'),
                ),
                DropdownMenuItem(
                  value: '1',
                  child: Text('Sim, também faço backing'),
                ),
                DropdownMenuItem(
                  value: '2',
                  child: Text('Faço exclusivamente backing vocal'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _backingVocalMode = v);
                ref
                    .read(onboardingFormProvider.notifier)
                    .updateBackingVocalMode(v);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
        ],

        // Genres (Required for all)
        _buildSelectionSection(
          title: 'Gêneros Musicais *',
          subtitle: _selectedGenres.isEmpty
              ? 'Selecione os estilos que você domina'
              : '${_selectedGenres.length} gênero${_selectedGenres.length > 1 ? 's' : ''} selecionado${_selectedGenres.length > 1 ? 's' : ''}',
          buttonText: _selectedGenres.isEmpty
              ? 'Selecionar Gêneros'
              : 'Editar Gêneros',
          selectedItems: _selectedGenres,
          onTap: () async {
            final result = await EnhancedMultiSelectModal.show<String>(
              context: context,
              title: 'Gêneros Musicais',
              subtitle: 'Selecione os estilos que você toca/canta',
              items: genres,
              selectedItems: _selectedGenres,
              searchHint: 'Buscar gênero...',
            );
            if (result != null) {
              setState(() => _selectedGenres = result);
            }
          },
        ),

        // Instrumentalist Section
        if (_selectedCategories.contains('instrumentalist')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildSelectionSection(
            title: 'Instrumentos *',
            subtitle: _selectedInstruments.isEmpty
                ? 'Quais instrumentos você toca?'
                : '${_selectedInstruments.length} instrumento${_selectedInstruments.length > 1 ? 's' : ''} selecionado${_selectedInstruments.length > 1 ? 's' : ''}',
            buttonText: _selectedInstruments.isEmpty
                ? 'Selecionar Instrumentos'
                : 'Editar Instrumentos',
            selectedItems: _selectedInstruments,
            onTap: () async {
              final result = await EnhancedMultiSelectModal.show<String>(
                context: context,
                title: 'Instrumentos',
                subtitle: 'Selecione os instrumentos que você domina',
                items: instruments,
                selectedItems: _selectedInstruments,
                searchHint: 'Buscar instrumento...',
              );
              if (result != null) {
                setState(() => _selectedInstruments = result);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Row(
              children: [
                Transform.scale(
                  scale: 1.2,
                  child: Checkbox(
                    value: _instrumentalistBackingVocal,
                    activeColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.textSecondary,
                      width: 2,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.all4,
                    ),
                    onChanged: (value) {
                      final enabled = value ?? false;
                      setState(() => _instrumentalistBackingVocal = enabled);
                      ref
                          .read(onboardingFormProvider.notifier)
                          .updateInstrumentalistBackingVocal(enabled);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(
                    'Faço backing vocal tocando',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],

        if (_selectedCategories.contains('production')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildSelectionSection(
            title: 'Produção Musical *',
            subtitle: _selectedProductionRoles.isEmpty
                ? 'Quais funções de produção você desempenha?'
                : '${_selectedProductionRoles.length} função${_selectedProductionRoles.length > 1 ? 'ões' : ''} selecionada${_selectedProductionRoles.length > 1 ? 's' : ''}',
            buttonText: _selectedProductionRoles.isEmpty
                ? 'Selecionar Funções'
                : 'Editar Funções',
            selectedItems: _selectedProductionRoles,
            onTap: () async {
              final result = await EnhancedMultiSelectModal.show<String>(
                context: context,
                title: 'Produção Musical',
                subtitle: 'Selecione suas funções de produção',
                items: productionRoles,
                selectedItems: _selectedProductionRoles,
                searchHint: 'Buscar função...',
              );
              if (result != null) {
                _updateProductionRoles(result);
              }
            },
          ),
          const SizedBox(height: AppSpacing.s16),
          _buildRemoteRecordingCheckbox(),
        ],

        if (_selectedCategories.contains('stage_tech')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildSelectionSection(
            title: 'Técnica de Palco *',
            subtitle: _selectedStageTechRoles.isEmpty
                ? 'Quais funções técnicas você desempenha?'
                : '${_selectedStageTechRoles.length} função${_selectedStageTechRoles.length > 1 ? 'ões' : ''} selecionada${_selectedStageTechRoles.length > 1 ? 's' : ''}',
            buttonText: _selectedStageTechRoles.isEmpty
                ? 'Selecionar Funções'
                : 'Editar Funções',
            selectedItems: _selectedStageTechRoles,
            onTap: () async {
              final result = await EnhancedMultiSelectModal.show<String>(
                context: context,
                title: 'Técnica de Palco',
                subtitle: 'Selecione suas funções técnicas de palco',
                items: stageTechRoles,
                selectedItems: _selectedStageTechRoles,
                searchHint: 'Buscar função...',
              );
              if (result != null) {
                _updateStageTechRoles(result);
              }
            },
          ),
        ],

        const SizedBox(height: AppSpacing.s48),

        SizedBox(
          height: 56,
          child: AppButton.primary(
            text: 'Continuar',
            size: AppButtonSize.large,
            onPressed: _isStep3Valid ? _nextStep : null,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionSection({
    required String title,
    required String subtitle,
    required String buttonText,
    required List<String> selectedItems,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: selectedItems.isEmpty ? AppColors.error : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: selectedItems.isEmpty
                  ? AppColors.error
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (selectedItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                ...selectedItems.take(3).map((item) {
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
                if (selectedItems.length > 3)
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
                      '+${selectedItems.length - 3}',
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
              text: buttonText,
              onPressed: onTap,
              icon: Icon(
                selectedItems.isEmpty ? Icons.add : Icons.edit_outlined,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteRecordingCheckbox() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: _offersRemoteRecording,
              activeColor: AppColors.primary,
              side: const BorderSide(color: AppColors.textSecondary, width: 2),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.all4),
              onChanged: (value) {
                final enabled = value ?? false;
                setState(() => _offersRemoteRecording = enabled);
                ref
                    .read(onboardingFormProvider.notifier)
                    .updateOffersRemoteRecording(enabled);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              professionalRemoteRecordingCheckboxLabel,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
