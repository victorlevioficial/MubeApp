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
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';
import '../steps/professional_category_step.dart';

/// Enhanced Professional Onboarding Flow with modern UI.
///
/// Steps:
/// 1. Basic Info (Name, Birth Date, Gender, Contact)
/// 2. Category Selection (Singer, Instrumentalist, Crew, DJ)
/// 3. Specialization (based on selected categories)
/// 4. Address
///
/// Features modern, professional UI matching the login screen design.
class EnhancedOnboardingProfessionalFlow extends ConsumerStatefulWidget {
  final AppUser user;

  const EnhancedOnboardingProfessionalFlow({super.key, required this.user});

  @override
  ConsumerState<EnhancedOnboardingProfessionalFlow> createState() =>
      _EnhancedOnboardingProfessionalFlowState();
}

class _EnhancedOnboardingProfessionalFlowState
    extends ConsumerState<EnhancedOnboardingProfessionalFlow> {
  final _formKey = GlobalKey<FormState>();

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
  List<String> _selectedInstruments = [];
  List<String> _selectedRoles = [];
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);

    // Restore Data
    _nomeController.text = formState.nome ?? widget.user.nome ?? '';
    _nomeArtisticoController.text = formState.nomeArtistico ?? '';
    _dataNascimentoController.text = formState.dataNascimento ?? '';
    _generoController.text = formState.genero ?? '';
    _celularController.text = formState.celular ?? '';
    _instagramController.text = formState.instagram ?? '';

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

    // Fetch location preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingFormProvider.notifier).fetchInitialLocation();
    });
  }

  @override
  void dispose() {
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
      setState(() => _currentStep++);
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
      setState(() => _currentStep++);
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

  bool _validateAge() {
    final dobText = _dataNascimentoController.text;
    if (dobText.isEmpty) return false;

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

    // Crew must select roles
    if (_selectedCategories.contains('crew') && _selectedRoles.isEmpty) {
      return false;
    }

    return true;
  }

  void _finishOnboarding() {
    final appConfigAsync = ref.read(appConfigProvider);
    final appConfig = appConfigAsync.value;

    List<String> genreIds = _selectedGenres;
    List<String> instrumentIds = _selectedInstruments;
    List<String> roleIds = _selectedRoles;

    if (appConfig != null) {
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
        return appConfig.crewRoles
            .firstWhere(
              (r) => r.label == label,
              orElse: () => ConfigItem(id: label, label: label, order: 0),
            )
            .id;
      }).toList();
    }

    final Map<String, dynamic> professionalData = {
      'nomeArtistico': _nomeArtisticoController.text,
      'celular': _celularController.text,
      'dataNascimento': _dataNascimentoController.text,
      'genero': _generoController.text,
      'instagram': _instagramController.text,
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
    }

    if (_selectedCategories.contains('crew')) {
      professionalData['funcoes'] = roleIds;
    }

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

    ref.read(onboardingControllerProvider.notifier).submitProfileForm(
          currentUser: widget.user,
          nome: _nomeController.text,
          location: location,
          dadosProfissional: professionalData,
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
                  if (_currentStep == 3) _buildStep3UI(),
                  if (_currentStep == 4)
                    OnboardingAddressStep(
                      onNext: () async => _finishOnboarding(),
                      onBack: _prevStep,
                      initialLocationLabel:
                          ref.watch(onboardingFormProvider).initialLocationLabel,
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
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v!.isEmpty ? 'Nome obrigatório' : null,
          prefixIcon: const Icon(Icons.person_outline, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _nomeArtisticoController,
          label: 'Nome Artístico',
          hint: 'Como você é conhecido',
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
          label: 'Data de Nascimento',
          controller: _dataNascimentoController,
          validator: (v) => v!.isEmpty ? 'Data obrigatória' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppDropdownField<String>(
          label: 'Gênero',
          value: _generoController.text.isEmpty ? null : _generoController.text,
          items: const [
            DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
            DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
            DropdownMenuItem(value: 'Outro', child: Text('Outro')),
            DropdownMenuItem(
              value: 'Prefiro não informar',
              child: Text('Prefiro não informar'),
            ),
          ],
          onChanged: (v) {
            setState(() => _generoController.text = v ?? '');
          },
          validator: (v) => v == null ? 'Selecione uma opção' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _instagramController,
          label: 'Instagram (opcional)',
          hint: '@seu_usuario',
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
        ],

        // Crew Section
        if (_selectedCategories.contains('crew')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildSelectionSection(
            title: 'Funções Técnicas *',
            subtitle: _selectedRoles.isEmpty
                ? 'Quais funções você desempenha?'
                : '${_selectedRoles.length} função${_selectedRoles.length > 1 ? 'ões' : ''} selecionada${_selectedRoles.length > 1 ? 's' : ''}',
            buttonText:
                _selectedRoles.isEmpty ? 'Selecionar Funções' : 'Editar Funções',
            selectedItems: _selectedRoles,
            onTap: () async {
              final result = await EnhancedMultiSelectModal.show<String>(
                context: context,
                title: 'Funções Técnicas',
                subtitle: 'Selecione suas áreas de atuação',
                items: crewRoles,
                selectedItems: _selectedRoles,
                searchHint: 'Buscar função...',
              );
              if (result != null) {
                setState(() => _selectedRoles = result);
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
              color: selectedItems.isEmpty ? AppColors.error : AppColors.textPrimary,
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
}
