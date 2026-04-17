part of 'create_gig_screen.dart';

extension _CreateGigScreenUi on _CreateGigScreenState {
  Widget _buildCreateGigScreen(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    final createState = ref.watch(createGigControllerProvider);
    final hasDateValidationError =
        _showValidationErrors &&
        _dateMode == GigDateMode.fixedDate &&
        _gigDate == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: _isEditing ? 'Editar gig' : 'Nova gig'),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Text(
              resolveGigErrorMessage(error),
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        data: (config) => SafeArea(
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s20,
              ),
              children: [
                // ── Section: Informações básicas ──────────────────────
                _FormSection(
                  label: 'Informações básicas',
                  children: [
                    AppTextField(
                      controller: _titleController,
                      label: 'Título',
                      hint: 'Ex: Procuro baterista para show de pop/rock',
                      textCapitalization: TextCapitalization.words,
                      readOnly: !_canEditAllFields,
                      validator: (value) {
                        if ((value ?? '').trim().length < 6) {
                          return 'Informe um título com pelo menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    AppDropdownField<GigType>(
                      label: 'Tipo de gig',
                      value: _gigType,
                      onChanged: !_canEditAllFields
                          ? (_) {}
                          : (value) {
                              if (value == null) return;
                              _updateState(() => _gigType = value);
                            },
                      items: GigType.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    AppTextField(
                      controller: _descriptionController,
                      label: 'Descrição da demanda',
                      hint:
                          'Explique contexto, repertório, expectativa e detalhes.',
                      maxLines: 5,
                      minLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if ((value ?? '').trim().length < 20) {
                          return 'Descreva a oportunidade com mais detalhes';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                // ── Section: Data e local ─────────────────────────────
                _FormSection(
                  label: 'Data e local',
                  children: [
                    AppDropdownField<GigDateMode>(
                      label: 'Data',
                      value: _dateMode,
                      onChanged: !_canEditAllFields
                          ? (_) {}
                          : (value) {
                              if (value == null) return;
                              _updateState(() {
                                _dateMode = value;
                                if (_dateMode != GigDateMode.fixedDate) {
                                  _gigDate = null;
                                }
                              });
                            },
                      items: GigDateMode.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (_dateMode == GigDateMode.fixedDate) ...[
                      const SizedBox(height: AppSpacing.s12),
                      KeyedSubtree(
                        key: _dateFieldKey,
                        child: _DatePickerTile(
                          gigDate: _gigDate,
                          enabled: _canEditAllFields,
                          errorText: hasDateValidationError
                              ? 'Selecione a data da gig.'
                              : null,
                          onTap: _pickDateTime,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s16),
                    AppDropdownField<GigLocationType>(
                      label: 'Modalidade',
                      value: _locationType,
                      onChanged: !_canEditAllFields
                          ? (_) {}
                          : (value) {
                              if (value == null) return;
                              _updateState(() => _locationType = value);
                            },
                      items: GigLocationType.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    AppTextField(
                      controller: _locationController,
                      label: _locationType == GigLocationType.remote
                          ? 'Abrangência / observação'
                          : 'Local',
                      hint: _locationType == GigLocationType.remote
                          ? 'Ex: remoto para todo Brasil'
                          : 'Ex: São Paulo - SP',
                      textCapitalization: TextCapitalization.words,
                      readOnly: !_canEditAllFields,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                // ── Section: Vagas e cachê ────────────────────────────
                _FormSection(
                  label: 'Vagas e cachê',
                  children: [
                    AppTextField(
                      controller: _slotsController,
                      label: 'Quantidade de vagas',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      readOnly: !_canEditAllFields,
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed < 1) {
                          return 'Informe ao menos 1 vaga';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    AppDropdownField<CompensationType>(
                      label: 'Cachê',
                      value: _compensationType,
                      onChanged: !_canEditAllFields
                          ? (_) {}
                          : (value) {
                              if (value == null) return;
                              _updateState(() => _compensationType = value);
                            },
                      items: CompensationType.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    if (_compensationType == CompensationType.fixed) ...[
                      const SizedBox(height: AppSpacing.s12),
                      AppTextField(
                        controller: _compensationValueController,
                        label: 'Valor do cachê',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        readOnly: !_canEditAllFields,
                        validator: (value) {
                          if (_compensationType != CompensationType.fixed) {
                            return null;
                          }
                          final parsed = int.tryParse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Informe um valor válido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.s24),
                // ── Section: Requisitos ───────────────────────────────
                _FormSection(
                  label: 'Requisitos',
                  children: [
                    const _RequirementsIntroCard(),
                    const SizedBox(height: AppSpacing.s16),
                    _RequirementCategoryCard(
                      title: 'Gêneros',
                      subtitle:
                          'Use se quiser sinalizar estilo, repertório ou sonoridade esperada.',
                      icon: Icons.library_music_outlined,
                      selectedCount: _selectedGenres.length,
                      isExpanded: _showGenresRequirements,
                      onToggle: () => _updateState(() {
                        _showGenresRequirements = !_showGenresRequirements;
                      }),
                      child: _ConfigMultiSelectField(
                        enabled: _canEditAllFields,
                        title: 'Gêneros',
                        subtitle: 'Selecione os estilos da oportunidade',
                        items: config.genres,
                        selectedIds: _selectedGenres,
                        showTitle: false,
                        emptyLabel: 'Selecionar gêneros',
                        onChanged: (next) =>
                            _updateState(() => _selectedGenres = next),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    _RequirementCategoryCard(
                      title: 'Instrumentos',
                      subtitle:
                          'Abra só se você precisa filtrar músicos por instrumento.',
                      icon: Icons.music_note_rounded,
                      selectedCount: _selectedInstruments.length,
                      isExpanded: _showInstrumentsRequirements,
                      onToggle: () => _updateState(() {
                        _showInstrumentsRequirements =
                            !_showInstrumentsRequirements;
                      }),
                      child: _ConfigMultiSelectField(
                        enabled: _canEditAllFields,
                        title: 'Instrumentos',
                        subtitle: 'Selecione os instrumentos requisitados',
                        items: config.instruments,
                        selectedIds: _selectedInstruments,
                        showTitle: false,
                        emptyLabel: 'Selecionar instrumentos',
                        onChanged: (next) =>
                            _updateState(() => _selectedInstruments = next),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    _RequirementCategoryCard(
                      title: 'Funções técnicas',
                      subtitle:
                          'Abra quando a vaga for para roadie, técnico, produção ou apoio.',
                      icon: Icons.engineering_outlined,
                      selectedCount: _selectedRoles.length,
                      isExpanded: _showRolesRequirements,
                      onToggle: () => _updateState(() {
                        _showRolesRequirements = !_showRolesRequirements;
                      }),
                      child: _ConfigMultiSelectField(
                        enabled: _canEditAllFields,
                        title: 'Funções técnicas',
                        subtitle: 'Selecione as funções desejadas',
                        items: config.crewRoles,
                        selectedIds: _selectedRoles,
                        showTitle: false,
                        emptyLabel: 'Selecionar funções técnicas',
                        onChanged: (next) =>
                            _updateState(() => _selectedRoles = next),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s16),
                    _RequirementCategoryCard(
                      title: 'Serviços de estúdio',
                      subtitle:
                          'Use apenas quando a oportunidade envolver gravação, mix, master ou serviços similares.',
                      icon: Icons.graphic_eq_rounded,
                      selectedCount: _selectedServices.length,
                      isExpanded: _showServicesRequirements,
                      onToggle: () => _updateState(() {
                        _showServicesRequirements = !_showServicesRequirements;
                      }),
                      child: _ConfigMultiSelectField(
                        enabled: _canEditAllFields,
                        title: 'Serviços de estúdio',
                        subtitle: 'Selecione os serviços desejados',
                        items: config.studioServices,
                        selectedIds: _selectedServices,
                        showTitle: false,
                        emptyLabel: 'Selecionar serviços',
                        onChanged: (next) =>
                            _updateState(() => _selectedServices = next),
                      ),
                    ),
                  ],
                ),
                // ── Warning for locked fields ──────────────────────────
                if (!_canEditAllFields) ...[
                  const SizedBox(height: AppSpacing.s20),
                  const _LockedFieldsBanner(),
                ],
                const SizedBox(height: AppSpacing.s24),
                AppButton.primary(
                  text: _isEditing ? 'Salvar alterações' : 'Publicar gig',
                  isFullWidth: true,
                  isLoading: createState.isLoading,
                  onPressed: () => _submit(config),
                ),
                const SizedBox(height: AppSpacing.s16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
