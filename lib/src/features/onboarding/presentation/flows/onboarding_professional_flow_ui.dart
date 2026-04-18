part of 'onboarding_professional_flow.dart';

extension _OnboardingProfessionalFlowUi on _OnboardingProfessionalFlowState {
  Widget _buildOnboardingProfessionalFlow(BuildContext context) {
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
                      totalSteps: _OnboardingProfessionalFlowState._totalSteps,
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
          fieldKey: const Key('onboarding_nome_input'),
          controller: _nomeController,
          label: 'Nome Completo',
          hint: 'Digite seu nome completo',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Nome obrigatório' : null,
          prefixIcon: const Icon(Icons.person_outline, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          fieldKey: const Key('onboarding_nome_artistico_input'),
          controller: _nomeArtisticoController,
          label: 'Nome Artístico',
          hint: 'Nome exibido no app',
          textCapitalization: TextCapitalization.words,
          inputFormatters: [TitleCaseTextInputFormatter()],
          validator: (v) => (v == null || v.isEmpty)
              ? 'Nome artístico obrigatório'
              : null,
          prefixIcon: const Icon(Icons.stars_outlined, size: 20),
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          fieldKey: const Key('onboarding_celular_input'),
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
            _updateState(
              () => _generoController.text = normalizeGenderValue(v),
            );
          },
        ),
        const SizedBox(height: AppSpacing.s16),
        AppTextField(
          controller: _instagramController,
          label: instagramLabelOptional,
          hint: instagramHint,
          prefixIcon: const Icon(Icons.alternate_email, size: 20),
        ),

        const SizedBox(height: AppSpacing.s24),

        AppCheckbox(
          key: const Key('onboarding_adult_confirm_checkbox'),
          label: 'Tenho 18 anos ou mais',
          value: _isAdultConfirmed,
          onChanged: (v) =>
              _updateState(() => _isAdultConfirmed = v ?? false),
        ),

        const SizedBox(height: AppSpacing.s32),

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
        _updateState(() {
          _selectedCategories = categories;
          _selectedRoles = _pruneRolesForCategories(categories);
        });
        ref.read(onboardingFormProvider.notifier)
          ..updateCategories(categories)
          ..updateRoles(_selectedRoles);
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
          'Informe suas habilidades e preferências profissionais',
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
                _updateState(() => _backingVocalMode = v);
                ref
                    .read(onboardingFormProvider.notifier)
                    .updateBackingVocalMode(v);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
        ],

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
                _updateState(() => _selectedInstruments = result);
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
                      _updateState(
                        () => _instrumentalistBackingVocal = enabled,
                      );
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

        if (_shouldShowGenres) ...[
          const SizedBox(height: AppSpacing.s24),
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
                _updateState(() => _selectedGenres = result);
              }
            },
          ),
        ],

        if (_selectedCategories.contains('production')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildRoleSection(professionalRoleSectionByCategoryId['production']!),
          const SizedBox(height: AppSpacing.s16),
          _buildRemoteRecordingCheckbox(),
        ],

        if (_selectedCategories.contains('stage_tech')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildRoleSection(professionalRoleSectionByCategoryId['stage_tech']!),
        ],

        for (final categoryId in const [
          'audiovisual',
          'education',
          'luthier',
          'performance',
          'graphic_design',
          'marketing',
        ])
          if (_selectedCategories.contains(categoryId)) ...[
            const SizedBox(height: AppSpacing.s24),
            _buildRoleSection(professionalRoleSectionByCategoryId[categoryId]!),
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

  Widget _buildRoleSection(ProfessionalRoleSection section) {
    final selectedIds = _selectedRoleIdsForCategory(section.categoryId);
    final selectedLabels = selectedIds
        .map((id) => section.labelById[id] ?? id)
        .toList(growable: false);

    return _buildSelectionSection(
      title: section.title,
      subtitle: selectedLabels.isEmpty
          ? section.subtitle
          : selectedLabels.length == 1
          ? '1 função selecionada'
          : '${selectedLabels.length} funções selecionadas',
      buttonText: selectedLabels.isEmpty
          ? 'Selecionar Funções'
          : 'Editar Funções',
      selectedItems: selectedLabels,
      onTap: () => _showRoleSelector(section),
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
            height: AppSpacing.s48,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                selectedItems.isEmpty ? Icons.add : Icons.edit_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              label: Text(buttonText),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.2),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.pill,
                ),
                textStyle: AppTypography.buttonSecondary.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                _updateState(() => _offersRemoteRecording = enabled);
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
