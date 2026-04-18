import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../constants/app_constants.dart';
import '../../../../constants/venue_type_constants.dart';
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
import '../../../../utils/instagram_utils.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';

/// Enhanced Contractor Onboarding Flow with modern UI.
///
/// Steps:
/// 1. Basic Info (Name, Contact, Birth Date, Gender, Instagram)
/// 2. Optional venue setup
/// 3. Address
class OnboardingContractorFlow extends ConsumerStatefulWidget {
  final AppUser user;

  const OnboardingContractorFlow({super.key, required this.user});

  @override
  ConsumerState<OnboardingContractorFlow> createState() =>
      _OnboardingContractorFlowState();
}

class _OnboardingContractorFlowState
    extends ConsumerState<OnboardingContractorFlow> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  int _currentStep = 1;
  static const int _totalSteps = 3;

  final _nomeController = TextEditingController();
  final _celularController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _generoController = TextEditingController();
  final _instagramController = TextEditingController();
  final _nomeExibicaoController = TextEditingController();

  bool _wantsVenueSetup = false;
  String _selectedVenueType = '';
  List<String> _selectedAmenities = [];

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);
    final contractorData =
        widget.user.dadosContratante ?? const <String, dynamic>{};
    final savedGender =
        formState.genero ?? (contractorData['genero'] as String?);

    _nomeController.text = formState.nome ?? widget.user.nome ?? '';
    _celularController.text = formState.celular ?? '';
    _dataNascimentoController.text =
        formState.dataNascimento ??
        ((contractorData['dataNascimento'] as String?) ?? '');
    _generoController.text = normalizeGenderValue(savedGender);
    _instagramController.text = normalizeInstagramHandle(
      formState.instagram ?? (contractorData['instagram'] as String?),
    );
    _nomeExibicaoController.text = formState.contractorDisplayName.isNotEmpty
        ? formState.contractorDisplayName
        : (contractorData['nomeExibicao'] as String? ?? '');

    _selectedVenueType = _normalizeVenueTypeId(
      formState.contractorVenueType.isNotEmpty
          ? formState.contractorVenueType
          : (contractorData['venueType'] as String? ?? ''),
    );
    _selectedAmenities = _normalizeAmenityIds(
      formState.contractorAmenities.isNotEmpty
          ? List<String>.from(formState.contractorAmenities)
          : List<String>.from(contractorData['comodidades'] as List? ?? []),
    );

    final hasSavedVenueData =
        _nomeExibicaoController.text.trim().isNotEmpty ||
        _selectedVenueType.isNotEmpty ||
        _selectedAmenities.isNotEmpty;
    _wantsVenueSetup = formState.contractorWantsVenueSetup || hasSavedVenueData;

    _nomeController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateNome(_nomeController.text),
    );
    _celularController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateCelular(_celularController.text),
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
    _instagramController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateInstagram(_instagramController.text),
    );
    _nomeExibicaoController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateContractorDisplayName(_nomeExibicaoController.text.trim()),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(onboardingFormProvider.notifier);
      notifier.fetchInitialLocation();
      notifier.updateContractorWantsVenueSetup(_wantsVenueSetup);
      if (_selectedVenueType.isNotEmpty) {
        notifier.updateContractorVenueType(_selectedVenueType);
      }
      if (_selectedAmenities.isNotEmpty) {
        notifier.updateContractorAmenities(_selectedAmenities);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nomeController.dispose();
    _celularController.dispose();
    _dataNascimentoController.dispose();
    _generoController.dispose();
    _instagramController.dispose();
    _nomeExibicaoController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      _setCurrentStep(_currentStep + 1);
      return;
    }

    if (_currentStep == 2) {
      if (!_validateVenueSetupStep()) return;
      _persistVenueSetupDraft();
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

  Future<void> _finishOnboarding() async {
    _persistVenueSetupDraft();
    final Map<String, dynamic> contractorData = {
      'celular': _celularController.text.trim(),
      'dataNascimento': _dataNascimentoController.text.trim(),
      'genero': normalizeGenderValue(_generoController.text),
      'instagram': normalizeInstagramHandle(_instagramController.text),
      'isPublic': false, // Contractors are private by default
    };

    final formState = ref.read(onboardingFormProvider);
    if (formState.contractorWantsVenueSetup) {
      final displayName = formState.contractorDisplayName.trim();
      if (displayName.isNotEmpty) {
        contractorData['nomeExibicao'] = displayName;
      }
      if (formState.contractorVenueType.isNotEmpty) {
        contractorData['venueType'] = formState.contractorVenueType;
      }
      if (formState.contractorAmenities.isNotEmpty) {
        contractorData['comodidades'] = formState.contractorAmenities;
      }
    }

    await ref
        .read(onboardingControllerProvider.notifier)
        .submitProfileForm(
          currentUser: widget.user,
          nome: _nomeController.text.trim(),
          location: formState.locationMap,
          dadosContratante: contractorData,
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
                    if (_currentStep == 2) _buildStep2VenueSetupUI(),
                    if (_currentStep == 3)
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
          'Informações básicas de contato',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        AppTextField(
          fieldKey: const Key('onboarding_contractor_nome_input'),
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
          fieldKey: const Key('onboarding_contractor_celular_input'),
          controller: _celularController,
          label: 'Celular',
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [_celularMask],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Celular obrigatório';
            if (v.length < 14) return 'Celular inválido';
            return null;
          },
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
          fieldKey: const Key('onboarding_contractor_instagram_input'),
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

  bool _validateVenueSetupStep() {
    if (!_wantsVenueSetup) return true;

    final displayName = _nomeExibicaoController.text.trim();
    if (displayName.isEmpty) {
      AppSnackBar.show(
        context,
        'Informe um nome de exibicao para o estabelecimento',
        isError: true,
      );
      return false;
    }

    if (_selectedVenueType.isEmpty) {
      AppSnackBar.show(context, 'Selecione o tipo de local', isError: true);
      return false;
    }

    return true;
  }

  void _persistVenueSetupDraft() {
    final notifier = ref.read(onboardingFormProvider.notifier);
    if (!_wantsVenueSetup) {
      notifier.clearContractorVenueSetup();
      return;
    }

    notifier.updateContractorWantsVenueSetup(true);
    notifier.updateContractorDisplayName(_nomeExibicaoController.text.trim());
    notifier.updateContractorVenueType(_selectedVenueType);
    notifier.updateContractorAmenities(_selectedAmenities);
  }

  Widget _buildStep2VenueSetupUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Perfil do Estabelecimento',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Voce pode configurar agora os dados publicos do local, ou deixar para depois nas configuracoes.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s24),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurar estabelecimento agora',
                      style: AppTypography.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      'Ao ativar, seu perfil ficará público e exibirá nome, tipo de local e comodidades.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _wantsVenueSetup,
                onChanged: (value) {
                  setState(() {
                    _wantsVenueSetup = value;
                    if (!value) {
                      _nomeExibicaoController.clear();
                      _selectedVenueType = '';
                      _selectedAmenities = [];
                    }
                  });
                  _persistVenueSetupDraft();
                },
              ),
            ],
          ),
        ),
        if (_wantsVenueSetup) ...[
          const SizedBox(height: AppSpacing.s16),
          AppTextField(
            controller: _nomeExibicaoController,
            label: 'Nome de Exibicao *',
            hint: 'Ex.: Bar do Centro',
            textCapitalization: TextCapitalization.words,
            inputFormatters: [TitleCaseTextInputFormatter()],
            prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
          ),
          const SizedBox(height: AppSpacing.s16),
          AppDropdownField<String>(
            label: 'Tipo de Local *',
            value: _selectedVenueType.isEmpty ? null : _selectedVenueType,
            items: venueTypeOptions
                .map(
                  (venueTypeOption) => DropdownMenuItem(
                    value: venueTypeOption.id,
                    child: Text(venueTypeOption.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => _selectedVenueType = value ?? '');
              ref
                  .read(onboardingFormProvider.notifier)
                  .updateContractorVenueType(_selectedVenueType);
            },
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.all16,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comodidades (opcional)',
                  style: AppTypography.titleMedium,
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  _selectedAmenities.isEmpty
                      ? 'Selecione facilidades do local'
                      : '${_selectedAmenities.length} selecionada${_selectedAmenities.length > 1 ? 's' : ''}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_selectedAmenities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: _selectedAmenities.take(4).map((item) {
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
                          venueAmenityLabel(item),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  width: double.infinity,
                  child: AppButton.outline(
                    text: _selectedAmenities.isEmpty
                        ? 'Selecionar Comodidades'
                        : 'Editar Comodidades',
                    icon: Icon(
                      _selectedAmenities.isEmpty
                          ? Icons.add
                          : Icons.edit_outlined,
                      size: 18,
                    ),
                    onPressed: () async {
                      final selectedAmenityLabels = _selectedAmenities
                          .map(venueAmenityLabel)
                          .toList();
                      final result = await EnhancedMultiSelectModal.show<String>(
                        context: context,
                        title: 'Comodidades do Local',
                        subtitle:
                            'Selecione as facilidades disponiveis no estabelecimento',
                        items: venueAmenityOptions
                            .map((option) => option.label)
                            .toList(),
                        selectedItems: selectedAmenityLabels,
                        searchHint: 'Buscar comodidade...',
                      );
                      if (result == null) return;
                      final amenityIds = _amenityIdsFromLabels(result);
                      setState(() => _selectedAmenities = amenityIds);
                      ref
                          .read(onboardingFormProvider.notifier)
                          .updateContractorAmenities(amenityIds);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
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

  String _normalizeVenueTypeId(String rawValue) {
    final normalizedValue = rawValue.trim();
    if (normalizedValue.isEmpty) return '';

    for (final option in venueTypeOptions) {
      if (option.id == normalizedValue) return option.id;
      if (option.label.toLowerCase() == normalizedValue.toLowerCase()) {
        return option.id;
      }
    }
    return '';
  }

  List<String> _normalizeAmenityIds(Iterable<dynamic> rawValues) {
    final resolved = <String>[];
    final seen = <String>{};

    for (final raw in rawValues) {
      final normalizedValue = raw.toString().trim();
      if (normalizedValue.isEmpty) continue;

      String? mappedId;
      for (final option in venueAmenityOptions) {
        if (option.id == normalizedValue) {
          mappedId = option.id;
          break;
        }
        if (option.label.toLowerCase() == normalizedValue.toLowerCase()) {
          mappedId = option.id;
          break;
        }
      }

      if (mappedId == null || seen.contains(mappedId)) continue;
      seen.add(mappedId);
      resolved.add(mappedId);
    }

    return resolved;
  }

  List<String> _amenityIdsFromLabels(List<String> labels) {
    return _normalizeAmenityIds(labels);
  }
}
