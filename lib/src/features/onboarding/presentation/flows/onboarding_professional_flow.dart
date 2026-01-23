import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/app_checkbox.dart';
import '../../../../common_widgets/app_date_picker_field.dart';
import '../../../../common_widgets/app_dropdown_field.dart';
import '../../../../common_widgets/app_filter_chip.dart';
import '../../../../common_widgets/app_selection_modal.dart';
import '../../../../common_widgets/app_snackbar.dart';
import '../../../../common_widgets/app_text_field.dart';
import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../common_widgets/onboarding_header.dart';
import '../../../../common_widgets/onboarding_section_card.dart';
import '../../../../common_widgets/primary_button.dart';
import '../../../../common_widgets/responsive_center.dart';
import '../../../../common_widgets/secondary_button.dart';
import '../../../../constants/app_constants.dart';
import '../../../../design_system/foundations/app_colors.dart';
import '../../../../design_system/foundations/app_radius.dart';
import '../../../../design_system/foundations/app_spacing.dart';
import '../../../../design_system/foundations/app_typography.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';

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

  // State
  int _currentStep = 1;
  static const int _totalSteps = 3;

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

  // State Step 2 & 3
  List<String> _selectedCategories = [];

  // Step 3 Data
  String _backingVocalMode = '0';
  bool _instrumentalistBackingVocal = false;
  List<String> _selectedInstruments = [];
  List<String> _selectedRoles = [];
  List<String> _selectedGenres = [];

  @override
  void initState() {
    super.initState();
    final formState = ref.read(onboardingFormProvider);

    // 1. Restore Data
    _nomeController.text = formState.nome ?? widget.user.nome ?? '';
    _nomeArtisticoController.text = formState.nomeArtistico ?? '';
    _dataNascimentoController.text = formState.dataNascimento ?? '';
    _generoController.text = formState.genero ?? '';
    _celularController.text = formState.celular ?? '';
    _instagramController.text = formState.instagram ?? '';

    // 2. Setup Listeners
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

    // Try to fetch location preview silently via Provider
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

  // --- Logic ---

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;

      // Age Validation
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
      setState(() => _currentStep++);
    } else if (_currentStep == 3) {
      if (!_isStep3Valid) return;
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    } else {
      // Reset to type selection
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

  void _finishOnboarding() {
    // Prepare Data based on selections
    final Map<String, dynamic> professionalData = {
      'nomeArtistico': _nomeArtisticoController.text,
      'celular': _celularController.text,
      'dataNascimento': _dataNascimentoController.text,
      'genero': _generoController.text,
      'instagram': _instagramController.text,
      'categorias': _selectedCategories,
      'generosMusicais': _selectedGenres,
      'isPublic': true, // Professionals are public
    };

    if (_selectedCategories.contains('singer')) {
      professionalData['backingVocalMode'] = _backingVocalMode;
    }

    if (_selectedCategories.contains('instrumentalist')) {
      professionalData['instrumentos'] = _selectedInstruments;
      professionalData['fazBackingVocal'] = _instrumentalistBackingVocal;
    }

    if (_selectedCategories.contains('crew')) {
      professionalData['funcoes'] = _selectedRoles;
    }

    // Get Address from Provider (it was updated by Step 4)
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

    // Submit
    ref
        .read(onboardingControllerProvider.notifier)
        .submitProfileForm(
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
                  const SizedBox(
                    height: AppSpacing.s32,
                  ), // Standardized spacing

                  if (_currentStep == 1) _buildStep1UI(),
                  if (_currentStep == 2) _buildStep2UI(),
                  if (_currentStep == 3) _buildStep3UI(),
                  if (_currentStep == 4)
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
          'Perfil Profissional',
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
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _nomeArtisticoController,
          label: 'Nome Artístico',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => v!.isEmpty ? 'Nome artístico obrigatório' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _celularController,
          label: 'Celular',
          hint: '(00) 00000-0000',
          keyboardType: TextInputType.phone,
          inputFormatters: [_celularMask],
          validator: (v) => v!.length < 14 ? 'Celular inválido' : null,
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
              value: 'Prefiro não dizer',
              child: Text('Prefiro não dizer'),
            ),
          ],
          onChanged: (val) {
            setState(() => _generoController.text = val ?? '');
            ref.read(onboardingFormProvider.notifier).updateGenero(val ?? '');
          },
          validator: (v) => v == null ? 'Selecione uma opção' : null,
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _instagramController,
          label: 'Instagram (Opcional)',
          hint: '@seu.perfil',
          onChanged: (val) {
            if (val.isNotEmpty && !val.startsWith('@')) {
              _instagramController.value = TextEditingValue(
                text: '@$val',
                selection: TextSelection.collapsed(offset: val.length + 1),
              );
            }
          },
        ),

        const SizedBox(height: AppSpacing.s48),
        PrimaryButton(text: 'Continuar', onPressed: _nextStep),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }

  Widget _buildStep2UI() {
    return Column(
      children: [
        Text(
          'Categoria',
          style: AppTypography.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Selecione todas que se aplicam:',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.s16,
            mainAxisSpacing: AppSpacing.s16,
            childAspectRatio: 1.2,
          ),
          itemCount: professionalCategories.length,
          itemBuilder: (context, index) {
            final cat = professionalCategories[index];
            final isSelected = _selectedCategories.contains(cat['id']);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedCategories.remove(cat['id']);
                  } else {
                    _selectedCategories.add(cat['id']);
                  }
                  ref
                      .read(onboardingFormProvider.notifier)
                      .updateSelectedCategories(_selectedCategories);
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: AppRadius.all16,
                  border: isSelected
                      ? null
                      : Border.all(color: AppColors.surfaceHighlight),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'],
                      size: 40,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      cat['label'],
                      style: AppTypography.titleMedium.copyWith(
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.s48),
        PrimaryButton(
          text: 'Continuar',
          onPressed: _selectedCategories.isNotEmpty ? _nextStep : null,
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }

  bool get _isStep3Valid {
    // 1. Genres are required
    if (_selectedGenres.isEmpty) return false;

    // 2. If 'singer', backing vocal mode is technically always set by default, so ok.

    // 3. If 'instrumentalist', must select at least one instrument
    if (_selectedCategories.contains('instrumentalist') &&
        _selectedInstruments.isEmpty) {
      return false;
    }

    // 4. If 'crew', must select at least one role
    if (_selectedCategories.contains('crew') && _selectedRoles.isEmpty) {
      return false;
    }

    return true;
  }

  Widget _buildStep3UI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Detalhes Técnicos',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          'Especifique suas habilidades',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s32),

        if (_selectedCategories.contains('singer'))
          _buildSectionCard(
            title: 'Cantor(a)',
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
                setState(() => _backingVocalMode = v!);
                ref
                    .read(onboardingFormProvider.notifier)
                    .updateBackingVocalMode(v!);
              },
            ),
          ),

        if (_selectedCategories.contains('instrumentalist'))
          _buildSectionCard(
            title: 'Instrumentista',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTagSelector(
                  'Quais instrumentos você toca?',
                  instruments,
                  _selectedInstruments,
                ),
                const SizedBox(height: AppSpacing.s16),
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(unselectedWidgetColor: AppColors.textSecondary),
                  child: AppCheckbox(
                    label: 'Faço backing vocal tocando',
                    value: _instrumentalistBackingVocal,
                    onChanged: (v) {
                      setState(() => _instrumentalistBackingVocal = v ?? false);
                      ref
                          .read(onboardingFormProvider.notifier)
                          .updateInstrumentalistBackingVocal(v ?? false);
                    },
                  ),
                ),
              ],
            ),
          ),

        if (_selectedCategories.contains('crew'))
          _buildSectionCard(
            title: 'Equipe Técnica',
            child: _buildTagSelector(
              'Quais suas funções?',
              crewRoles,
              _selectedRoles,
            ),
          ),

        _buildSectionCard(
          title: 'Gêneros Musicais',
          child: _buildTagSelector(
            'Com quais gêneros você trabalha?',
            genres,
            _selectedGenres,
          ),
        ),

        const SizedBox(height: AppSpacing.s16),
        PrimaryButton(
          text: 'Continuar',
          onPressed: _isStep3Valid ? _nextStep : null,
        ),
        const SizedBox(height: AppSpacing.s24),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return OnboardingSectionCard(title: title, child: child);
  }

  Widget _buildTagSelector(
    String label,
    List<String> options,
    List<String> selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.s12),

        // Button to open Modal
        SecondaryButton(
          text: selected.isEmpty ? 'Selecionar' : 'Editar seleção',
          icon: const Icon(Icons.add, size: 18),
          onPressed: () async {
            final result = await showModalBottomSheet<List<String>>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AppSelectionModal(
                title: label,
                items: options,
                selectedItems: selected,
                allowMultiple: true,
              ),
            );

            if (result != null) {
              setState(() {
                selected.clear();
                selected.addAll(result);

                // Update Provider based on which list is being modified
                final notifier = ref.read(onboardingFormProvider.notifier);
                if (selected == _selectedGenres) {
                  notifier.updateSelectedGenres(selected);
                }
                if (selected == _selectedInstruments) {
                  notifier.updateSelectedInstruments(selected);
                }
                if (selected == _selectedRoles) {
                  notifier.updateSelectedRoles(selected);
                }
              });
            }
          },
        ),

        if (selected.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected.map((opt) {
              return AppFilterChip(
                label: opt,
                isSelected: true,
                onSelected: (_) {}, // No-op, use remove icon
                onRemove: () {
                  // Allow removing directly from the list
                  setState(() {
                    selected.remove(opt);
                    final notifier = ref.read(onboardingFormProvider.notifier);
                    if (selected == _selectedGenres) {
                      notifier.updateSelectedGenres(selected);
                    }
                    if (selected == _selectedInstruments) {
                      notifier.updateSelectedInstruments(selected);
                    }
                    if (selected == _selectedRoles) {
                      notifier.updateSelectedRoles(selected);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
