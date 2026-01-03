import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/app_date_picker_field.dart';
import '../../../../common_widgets/app_dropdown_field.dart';
import '../../../../common_widgets/app_text_field.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../common_widgets/onboarding_header.dart';
import '../../../../common_widgets/primary_button.dart';
import '../../../../common_widgets/responsive_center.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';

import '../steps/onboarding_address_step.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';

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

  // State
  int _currentStep = 1;
  static const int _totalSteps = 2;

  // Controllers Step 1
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

    // 1. Restore Personal Info
    _nomeController.text = formState.nome ?? widget.user.nome ?? '';
    _celularController.text = formState.celular ?? '';
    _dataNascimentoController.text = formState.dataNascimento ?? '';
    _generoController.text = formState.genero ?? '';
    _instagramController.text = formState.instagram ?? '';

    // 2. Address Info (Handled by Step)

    // Derive UI state

    // 3. Setup Listeners
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

    // Try to fetch location preview silently via Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingFormProvider.notifier).fetchInitialLocation();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Removed _onSearchChanged, _selectAddress, _useCurrentLocation, _fillAddressFields

  void _finishOnboarding() {
    if (_formKey.currentState!.validate()) {
      // Create location map
      final formState = ref.read(onboardingFormProvider);
      // Create location map from Provider (populated by OnboardingAddressStep)
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

      // Submit to Controller
      ref
          .read(onboardingControllerProvider.notifier)
          .submitProfileForm(
            currentUser: widget.user,
            nome: _nomeController.text,
            location: location,
            foto: null, // Contractor might not need photo or it's optional
            dadosContratante: {
              'celular': _celularController.text,
              'dataNascimento': _dataNascimentoController.text,
              'genero': _generoController.text,
              'instagram': _instagramController.text,
              'isPublic': false, // Contractors are private by default
            },
          );
    }
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      // Age Verification Logic
      final dobText = _dataNascimentoController.text;
      if (dobText.isNotEmpty) {
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
            return; // Block progress
          }
        } catch (e) {
          // If parsing fails, let it pass or handle error?
          // Validator usually catches format issues, but being safe:
          // print('Date Parse Error: $e');
        }
      }

      setState(() {
        _currentStep++;
      });
      // Here we would typically persist draft data or navigate to Step 2 screen component
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      // Back to type selection (handled by parent or specialized callback if needed)
      // For now, let generic AppBar back handle it via Navigator.pop
    }
  }

  @override
  Widget build(BuildContext context) {
    // If Step 2 is "totally different" and generic, we might need a switcher here.
    // For this task, we focus on Step 1 implementation logic.

    return Scaffold(
      // backgroundColor: Use default,
      // No AppBar - Header scrolls with content
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxContentWidth: 600,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row (Scrollable)
                  OnboardingHeader(
                    currentStep: _currentStep,
                    totalSteps: _totalSteps,
                    onBack: () {
                      if (_currentStep == 1) {
                        ref
                            .read(onboardingControllerProvider.notifier)
                            .resetToTypeSelection(currentUser: widget.user);
                      } else {
                        _prevStep();
                      }
                    },
                  ),

                  const SizedBox(
                    height: AppSpacing.s32,
                  ), // Standardized spacing

                  if (_currentStep == 1) _buildStep1UI(),
                  if (_currentStep == 2) _buildStep2UI(),
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
        // Spacing handled by parent column
        Text(
          'Perfil de Contratante',
          textAlign: TextAlign.center,
          style: AppTypography.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.s8), // Standardized spacing
        Text(
          'Conte-nos um pouco sobre você',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.s32),

        // Nome
        AppTextField(
          controller: _nomeController,
          label: 'Nome Completo',
          hint: 'Seu nome completo',
          textCapitalization: TextCapitalization.words, // Fixed capitalization
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v == null || v.isEmpty ? 'Nome obrigatório' : null,
        ),
        const SizedBox(height: AppSpacing.s24),

        // Celular (Refatorado para usar label nativa do AppTextField)
        AppTextField(
          controller: _celularController,
          label: 'Celular',
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [_celularMask],
          validator: (v) =>
              (v == null || v.length < 14) ? 'Celular inválido' : null,
        ),
        const SizedBox(height: AppSpacing.s24),

        // Data Nascimento
        AppDatePickerField(
          label: 'Data de Nascimento',
          controller: _dataNascimentoController,
          validator: (v) => v == null || v.isEmpty ? 'Data obrigatória' : null,
        ),
        const SizedBox(height: AppSpacing.s24),

        // Gênero
        AppDropdownField<String>(
          label: 'Gênero',
          value: _generoController.text.isEmpty ? null : _generoController.text,
          items: const [
            DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
            DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
            DropdownMenuItem(value: 'Outro', child: Text('Outro')),
            DropdownMenuItem(
              value: 'Prefiro não dizer',
              child: Text('Prefiro não dizer'),
            ),
          ],
          onChanged: (val) {
            setState(() {
              _generoController.text = val ?? '';
            });
            ref.read(onboardingFormProvider.notifier).updateGenero(val ?? '');
          },
          validator: (v) => v == null ? 'Selecione uma opção' : null,
        ),
        const SizedBox(height: AppSpacing.s24),

        // Instagram (Opcional)
        AppTextField(
          controller: _instagramController,
          label: 'Instagram (Opcional)',
          hint: '@seu.perfil',
        ),

        const SizedBox(height: AppSpacing.s48),

        SizedBox(
          height: 56,
          child: PrimaryButton(text: 'Continuar', onPressed: _nextStep),
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }

  Widget _buildStep2UI() {
    return OnboardingAddressStep(
      onNext: () async => _finishOnboarding(),
      onBack: _prevStep,
      initialLocationLabel: ref
          .watch(onboardingFormProvider)
          .initialLocationLabel,
    );
  }
}
