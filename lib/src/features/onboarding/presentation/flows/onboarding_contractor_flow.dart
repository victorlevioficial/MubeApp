import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../constants/app_constants.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/inputs/app_date_picker_field.dart';
import '../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/responsive_center.dart';
import '../../../../design_system/components/patterns/onboarding_header.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
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
/// 2. Address
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

  int _currentStep = 1;
  static const int _totalSteps = 2;

  final _nomeController = TextEditingController();
  final _celularController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _generoController = TextEditingController();
  final _instagramController = TextEditingController();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingFormProvider.notifier).fetchInitialLocation();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _celularController.dispose();
    _dataNascimentoController.dispose();
    _generoController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
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

  Future<void> _finishOnboarding() async {
    final Map<String, dynamic> contractorData = {
      'celular': _celularController.text.trim(),
      'dataNascimento': _dataNascimentoController.text.trim(),
      'genero': normalizeGenderValue(_generoController.text),
      'instagram': normalizeInstagramHandle(_instagramController.text),
      'isPublic': false, // Contractors are private by default
    };

    final formState = ref.read(onboardingFormProvider);

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
                    if (_currentStep == 2)
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
          label: 'Data de Nascimento',
          controller: _dataNascimentoController,
          validator: (v) => v!.isEmpty ? 'Data obrigatória' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppDropdownField<String>(
          label: 'Gênero',
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
          validator: (v) => v == null ? 'Selecione uma opção' : null,
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
}
