import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/responsive_center.dart';
import '../../../../design_system/components/patterns/onboarding_header.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';

/// Enhanced Contractor Onboarding Flow with modern UI.
///
/// Steps:
/// 1. Basic Info (Name, Contact)
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

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);

    _nomeController.text = formState.nome ?? widget.user.nome ?? '';
    _celularController.text = formState.celular ?? '';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingFormProvider.notifier).fetchInitialLocation();
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _celularController.dispose();
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

  void _finishOnboarding() {
    final Map<String, dynamic> contractorData = {
      'celular': _celularController.text,
      'isPublic': false, // Contractors are private by default
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
          nome: _nomeController.text,
          location: location,
          dadosContratante: contractorData,
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
                  if (_currentStep == 2)
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
