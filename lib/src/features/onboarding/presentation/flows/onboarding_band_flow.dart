import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../common_widgets/app_filter_chip.dart';
import '../../../../common_widgets/app_selection_modal.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../../../common_widgets/app_text_field.dart';
import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../common_widgets/onboarding_header.dart';
import '../../../../common_widgets/onboarding_section_card.dart';
import '../../../../common_widgets/primary_button.dart';
import '../../../../common_widgets/secondary_button.dart';
import '../../../../common_widgets/responsive_center.dart';
import '../../../../constants/app_constants.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';

class OnboardingBandFlow extends ConsumerStatefulWidget {
  final AppUser user;

  const OnboardingBandFlow({super.key, required this.user});

  @override
  ConsumerState<OnboardingBandFlow> createState() => _OnboardingBandFlowState();
}

class _OnboardingBandFlowState extends ConsumerState<OnboardingBandFlow> {
  final _formKey = GlobalKey<FormState>();

  // State
  int _currentStep = 1;
  static const int _totalSteps = 3;

  // Controllers
  final _nomeController = TextEditingController();
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);

    // Resume state if available
    _nomeController.text = formState.nomeArtistico ?? '';
    _selectedGenres = List.from(formState.selectedGenres);

    _nomeController.addListener(() {
      ref
          .read(onboardingFormProvider.notifier)
          .updateNomeArtistico(_nomeController.text);
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      // Tutorial Step
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      if (!_formKey.currentState!.validate()) return;
      if (_selectedGenres.isEmpty) {
        AppSnackBar.show(
          context,
          'Selecione pelo menos um gênero musical',
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
    // Prepare Data
    // Band specific data
    Map<String, dynamic> bandData = {
      'nome': _nomeController.text.trim(),
      'generosMusicais': _selectedGenres,
      'statusBanda': 'draft', // Critical requirement
      'adminUid': widget.user.uid,
      'integrantes': [widget.user.uid], // Admin is the first member
      'isPublic': true,
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
          nome: _nomeController.text
              .trim(), // Use band name as profile name for now logic-wise
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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

                  if (_currentStep == 1) _buildStep1Tutorial(),
                  if (_currentStep == 2) _buildStep2BasicInfo(),
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

  Widget _buildStep1Tutorial() {
    return Column(
      children: [
        const Icon(Icons.groups, size: 64, color: AppColors.primary),
        const SizedBox(height: AppSpacing.s24),
        Text(
          'Criando sua Banda',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s16),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceHighlight),
          ),
          child: Column(
            children: [
              Text(
                'Sua banda será criada como Rascunho (Draft) e não aparecerá no feed do Mube.',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              const Divider(color: AppColors.surfaceHighlight),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Para ativá-la, é necessário que pelo menos 2 integrantes com perfil profissional no Mube aceitem o convite para a banda.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.s16),
              Text(
                'Assim que os convites forem aceitos, a banda será ativada automaticamente e ficará visível para todos.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s48),
        PrimaryButton(text: 'Criar banda', onPressed: _nextStep),
      ],
    );
  }

  Widget _buildStep2BasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dados da Banda',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        AppTextField(
          controller: _nomeController,
          label: 'Nome da Banda',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v!.isEmpty ? 'Nome obrigatório' : null,
        ),
        const SizedBox(height: AppSpacing.s24),

        OnboardingSectionCard(
          title: 'Gêneros Musicais',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SecondaryButton(
                text: _selectedGenres.isEmpty
                    ? 'Selecionar Gêneros'
                    : 'Editar Gêneros',
                icon: const Icon(Icons.add, size: 18),
                onPressed: () async {
                  final result = await showModalBottomSheet<List<String>>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AppSelectionModal(
                      title: 'Gêneros Musicais',
                      items: GENRES,
                      selectedItems: _selectedGenres,
                      allowMultiple: true,
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      // Simple update as per previous logic
                      _selectedGenres = result;
                      ref
                          .read(onboardingFormProvider.notifier)
                          .updateSelectedGenres(_selectedGenres);
                    });
                  }
                },
              ),

              if (_selectedGenres.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedGenres.map((genre) {
                    return AppFilterChip(
                      label: genre,
                      isSelected: true,
                      onSelected: (_) {},
                      onRemove: () {
                        setState(() {
                          _selectedGenres.remove(genre);
                          ref
                              .read(onboardingFormProvider.notifier)
                              .updateSelectedGenres(
                                _selectedGenres,
                              ); // Note: using updateSelectedServices for consistency or verify existing method
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
        PrimaryButton(text: 'Continuar', onPressed: _nextStep),
      ],
    );
  }
}
