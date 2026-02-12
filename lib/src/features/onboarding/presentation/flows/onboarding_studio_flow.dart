import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../constants/app_constants.dart';
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

/// Enhanced Studio Onboarding Flow with modern UI.
///
/// Steps:
/// 1. Basic Info (Full name + Studio name + Contact)
/// 2. Services Offered
/// 3. Address
class OnboardingStudioFlow extends ConsumerStatefulWidget {
  final AppUser user;

  const OnboardingStudioFlow({super.key, required this.user});

  @override
  ConsumerState<OnboardingStudioFlow> createState() =>
      _OnboardingStudioFlowState();
}

class _OnboardingStudioFlowState extends ConsumerState<OnboardingStudioFlow> {
  final _formKey = GlobalKey<FormState>();

  int _currentStep = 1;
  static const int _totalSteps = 3;

  final _nomeCompletoController = TextEditingController();
  final _nomeEstudioController = TextEditingController();
  final _celularController = TextEditingController();
  final _instagramController = TextEditingController();

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  List<String> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);
    final studioData = widget.user.dadosEstudio ?? const <String, dynamic>{};

    _nomeCompletoController.text = formState.nome ?? widget.user.nome ?? '';
    _nomeEstudioController.text =
        formState.nomeArtistico ??
        (studioData['nomeEstudio'] as String?) ??
        (studioData['nomeArtistico'] as String?) ??
        widget.user.appDisplayName;
    _celularController.text = formState.celular ?? '';
    _instagramController.text = formState.instagram ?? '';
    _selectedServices = List.from(formState.selectedServices);

    _nomeCompletoController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateNome(_nomeCompletoController.text),
    );
    _nomeEstudioController.addListener(
      () => ref
          .read(onboardingFormProvider.notifier)
          .updateNomeArtistico(_nomeEstudioController.text),
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
    _nomeEstudioController.dispose();
    _celularController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (_selectedServices.isEmpty) {
        AppSnackBar.show(
          context,
          'Selecione pelo menos um servico',
          isError: true,
        );
        return;
      }
      ref
          .read(onboardingFormProvider.notifier)
          .updateServices(_selectedServices);
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
    final studioDisplayName = _nomeEstudioController.text.trim();

    final Map<String, dynamic> studioData = {
      'nomeEstudio': studioDisplayName,
      'nomeArtistico': studioDisplayName,
      'nome': studioDisplayName,
      'celular': _celularController.text,
      'instagram': _instagramController.text,
      'servicosOferecidos': _selectedServices,
      'services': _selectedServices,
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
          dadosEstudio: studioData,
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
          'Dados do Estudio',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Informacoes basicas do seu espaco',
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
          controller: _nomeEstudioController,
          label: 'Nome do Estudio',
          hint: 'Nome exibido no app',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) =>
              v!.trim().isEmpty ? 'Nome do estudio obrigatorio' : null,
          prefixIcon: const Icon(Icons.business_outlined, size: 20),
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
          hint: '@nome_do_estudio',
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
          'Servicos Oferecidos',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Quais servicos seu estudio oferece?',
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
              color: _selectedServices.isEmpty
                  ? AppColors.error
                  : AppColors.border,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Servicos *',
                style: AppTypography.titleMedium.copyWith(
                  color: _selectedServices.isEmpty
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                _selectedServices.isEmpty
                    ? 'Selecione os servicos disponiveis'
                    : '${_selectedServices.length} servico${_selectedServices.length > 1 ? 's' : ''} selecionado${_selectedServices.length > 1 ? 's' : ''}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (_selectedServices.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    ..._selectedServices.take(3).map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s10,
                          vertical: AppSpacing.s4,
                        ),
                        decoration: BoxDecoration(
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
                    if (_selectedServices.length > 3)
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
                          '+${_selectedServices.length - 3}',
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
                  text: _selectedServices.isEmpty
                      ? 'Selecionar Servicos'
                      : 'Editar Servicos',
                  onPressed: () async {
                    final result = await EnhancedMultiSelectModal.show<String>(
                      context: context,
                      title: 'Servicos do Estudio',
                      subtitle: 'Selecione os servicos que voce oferece',
                      items: studioServices,
                      selectedItems: _selectedServices,
                      searchHint: 'Buscar servico...',
                    );
                    if (result != null) {
                      setState(() => _selectedServices = result);
                    }
                  },
                  icon: Icon(
                    _selectedServices.isEmpty ? Icons.add : Icons.edit_outlined,
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
            onPressed: _selectedServices.isNotEmpty ? _nextStep : null,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
