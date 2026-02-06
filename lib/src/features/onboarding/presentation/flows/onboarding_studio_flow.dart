import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../constants/app_constants.dart';
import '../../../../core/domain/app_config.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_filter_chip.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_selection_modal.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/navigation/responsive_center.dart';
import '../../../../design_system/components/patterns/onboarding_header.dart';
import '../../../../design_system/components/patterns/onboarding_section_card.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';

class OnboardingStudioFlow extends ConsumerStatefulWidget {
  final AppUser user;

  const OnboardingStudioFlow({super.key, required this.user});

  @override
  ConsumerState<OnboardingStudioFlow> createState() =>
      _OnboardingStudioFlowState();
}

class _OnboardingStudioFlowState extends ConsumerState<OnboardingStudioFlow> {
  final _formKey = GlobalKey<FormState>();

  // State
  int _currentStep = 1;
  static const int _totalSteps = 3;

  // Controllers Step 1
  final _nomeController = TextEditingController();
  final _celularController = TextEditingController();

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  String? _studioType; // No default

  // State Step 2
  List<String> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);

    // Initialize with persisted state
    // We map 'nomeArtistico' to 'Nome do Estúdio'
    _nomeController.text = formState.nomeArtistico ?? '';
    _celularController.text = formState.celular ?? '';

    // Initialize from persisted state if available
    _studioType = formState.studioType;
    _selectedServices = List.from(formState.selectedServices);

    // Listeners
    _nomeController.addListener(() {
      // Map Studio Name to Nome Artistico for consistency in storage
      ref
          .read(onboardingFormProvider.notifier)
          .updateNomeArtistico(_nomeController.text);
    });

    _celularController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateCelular(_celularController.text),
    );

    // Try to fetch location preview silently via Provider
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

      if (_studioType == null) {
        AppSnackBar.show(context, 'Selecione o tipo de estúdio', isError: true);
        return;
      }

      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (_selectedServices.isEmpty) {
        AppSnackBar.show(
          context,
          'Selecione pelo menos um serviço',
          isError: true,
        );
        return;
      }
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
    // Get AppConfig for ID mapping
    final appConfigAsync = ref.read(appConfigProvider);
    final appConfig = appConfigAsync.value;

    List<String> serviceIds = _selectedServices;

    if (appConfig != null) {
      serviceIds = _selectedServices.map<String>((label) {
        return appConfig.studioServices
            .firstWhere(
              (s) => s.label == label,
              orElse: () => ConfigItem(id: label, label: label, order: 0),
            )
            .id;
      }).toList();
    }

    // Prepare Data
    final Map<String, dynamic> studioData = {
      'nomeArtistico': _nomeController.text, // Studio Name
      'celular': _celularController.text,
      'studioType': _studioType,
      'services': serviceIds,
      'isPublic': true,
      // 'categorias': ['studio'], // Optionally add a category if 'studio' isn't just the user type
    };

    // Address
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
          nome: widget.user.nome ?? '', // Keep original name
          location: location,
          dadosProfissional: studioData, // Reusing generic map argument
        );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to persistence
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ResponsiveCenter(
            maxContentWidth: 600,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
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
          'Perfil de Estúdio',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Conte-nos sobre seu espaço',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        AppTextField(
          controller: _nomeController,
          label: 'Nome do Estúdio',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v!.isEmpty ? 'Nome do estúdio obrigatório' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _celularController,
          label: 'Celular / WhatsApp',
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [_celularMask],
          validator: (v) => v!.length < 14 ? 'Celular inválido' : null,
        ),
        const SizedBox(height: AppSpacing.s24),

        Text(
          'Tipo de Estúdio',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),

        _buildRadioOption(
          title: 'Home Studio',
          value: 'home_studio',
          description: 'Estúdio caseiro/amador',
        ),
        const SizedBox(height: AppSpacing.s16),
        _buildRadioOption(
          title: 'Estúdio Comercial',
          value: 'commercial',
          description: 'Estrutura profissional dedicada',
        ),

        const SizedBox(height: AppSpacing.s48),
        AppButton.primary(text: 'Continuar', onPressed: _nextStep),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }

  Widget _buildRadioOption({
    required String title,
    required String value,
    required String description,
  }) {
    final isSelected = _studioType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _studioType = value);
        ref.read(onboardingFormProvider.notifier).updateStudioType(value);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.all16,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _studioType,
              // ignore: deprecated_member_use
              onChanged: (v) {
                if (v != null) {
                  setState(() => _studioType = v);
                  ref.read(onboardingFormProvider.notifier).updateStudioType(v);
                }
              },
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: AppTypography.buttonPrimary.fontWeight,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2UI() {
    // Use provider for consistency with AppConfig
    final availableServices = ref.watch(studioServiceLabelsProvider);

    return Column(
      children: [
        /* Title removed as it is now part of the card */
        Text(
          'Serviços',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'O que você oferece?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        OnboardingSectionCard(
          title: 'Serviços do Estúdio',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton.outline(
                text: _selectedServices.isEmpty
                    ? 'Selecionar Serviços'
                    : 'Editar Serviços',
                icon: const Icon(Icons.add, size: 18),
                onPressed: () async {
                  final result = await showModalBottomSheet<List<String>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppColors.transparent,
                    builder: (context) => AppSelectionModal(
                      title: 'Serviços do Estúdio',
                      items: availableServices.isNotEmpty
                          ? availableServices
                          : studioServices, // Fallback to constant if provider empty
                      selectedItems: _selectedServices,
                      allowMultiple: true,
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      // Simple update
                      _selectedServices = result;
                      ref
                          .read(onboardingFormProvider.notifier)
                          .updateSelectedServices(_selectedServices);
                    });
                  }
                },
              ),

              if (_selectedServices.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment
                      .start, // Left align inside card looks better usually
                  children: _selectedServices.map((service) {
                    return AppFilterChip(
                      label: service,
                      isSelected: true,
                      onSelected: (_) {},
                      onRemove: () {
                        setState(() {
                          _selectedServices.remove(service);
                          ref
                              .read(onboardingFormProvider.notifier)
                              .updateSelectedServices(_selectedServices);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.s48),
        AppButton.primary(
          text: 'Continuar',
          onPressed: _selectedServices.isNotEmpty ? _nextStep : null,
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }
}
