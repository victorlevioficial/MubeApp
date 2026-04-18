part of 'onboarding_professional_flow.dart';

extension _OnboardingProfessionalFlowActions
    on _OnboardingProfessionalFlowState {
  bool get _shouldShowGenres => _categoriesRequireGenres(_selectedCategories);

  List<String> _selectedRoleIdsForCategory(String categoryId) {
    return _selectedRoles
        .where((roleId) => _roleBelongsToCategory(roleId, categoryId))
        .toList(growable: false);
  }

  bool _roleBelongsToCategory(String roleId, String categoryId) {
    return professionalRoleSectionByCategoryId[categoryId]?.options.any(
          (option) => option.id == roleId,
        ) ??
        false;
  }

  String _normalizeRoleId(String rawRole) {
    final trimmed = rawRole.trim();
    if (trimmed.isEmpty) return '';
    return professionalRoleIdLookup[trimmed] ??
        professionalRoleIdLookup[CategoryNormalizer.sanitize(trimmed)] ??
        trimmed;
  }

  List<String> _normalizeRoleIds(Iterable<String> rawRoles) {
    return rawRoles
        .map(_normalizeRoleId)
        .where((role) => role.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _pruneRolesForCategories(List<String> categories) {
    return _selectedRoles
        .where(
          (roleId) => _roleBelongsToAnySelectedCategory(roleId, categories),
        )
        .toList(growable: false);
  }

  bool _roleBelongsToAnySelectedCategory(
    String roleId,
    List<String> categories,
  ) {
    return categories.any(
      (category) => _roleBelongsToCategory(roleId, category),
    );
  }

  bool _categoriesRequireGenres(List<String> categories) {
    final resolved = CategoryNormalizer.resolveCategories(
      rawCategories: categories,
      rawRoles: _selectedRoles,
    );
    return resolved.any(
      (category) => !professionalGenreHiddenCategories.contains(category),
    );
  }

  void _updateRolesForCategory(String categoryId, List<String> roleIds) {
    _selectedRoles = [
      ..._selectedRoles.where(
        (roleId) => !_roleBelongsToCategory(roleId, categoryId),
      ),
      ...roleIds,
    ];
  }

  Future<void> _showRoleSelector(ProfessionalRoleSection section) async {
    final currentRoleIds = _selectedRoleIdsForCategory(section.categoryId);
    final result = await EnhancedMultiSelectModal.show<String>(
      context: context,
      title: section.title,
      subtitle: section.subtitle,
      items: section.options.map((option) => option.id).toList(growable: false),
      selectedItems: currentRoleIds,
      searchHint: 'Buscar função...',
      itemLabel: (id) => section.labelById[id] ?? id,
    );

    if (result != null) {
      _updateState(() {
        _updateRolesForCategory(section.categoryId, result);
      });
      ref.read(onboardingFormProvider.notifier).updateRoles(_selectedRoles);
    }
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (!_formKey.currentState!.validate()) return;
      if (!_validateAge()) return;
      _setCurrentStep(_currentStep + 1);
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
      _updateState(() {
        _selectedRoles = _pruneRolesForCategories(_selectedCategories);
      });
      ref.read(onboardingFormProvider.notifier).updateRoles(_selectedRoles);
      _setCurrentStep(_currentStep + 1);
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
      _setCurrentStep(_currentStep + 1);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      _setCurrentStep(_currentStep - 1);
    } else {
      ref
          .read(onboardingControllerProvider.notifier)
          .resetToTypeSelection(currentUser: widget.user);
    }
  }

  void _setCurrentStep(int nextStep) {
    _updateState(() => _currentStep = nextStep);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(0);
    });
  }

  bool _validateAge() {
    if (!_isAdultConfirmed) {
      AppSnackBar.show(
        context,
        'Confirme que você tem 18 anos ou mais para continuar.',
        isError: true,
      );
      return false;
    }

    final dobText = _dataNascimentoController.text.trim();
    if (dobText.isEmpty) {
      return true;
    }

    final dob = BirthDateValidator.parseStrict(dobText);
    if (dob == null) {
      AppSnackBar.show(
        context,
        'Data de nascimento inválida. Use o formato dd/mm/aaaa.',
        isError: true,
      );
      return false;
    }

    if (!BirthDateValidator.isAdult(dob)) {
      AppSnackBar.show(
        context,
        'É necessário ser maior de 18 anos para se cadastrar.',
        isError: true,
      );
      return false;
    }
    return true;
  }

  bool get _isStep3Valid {
    if (_shouldShowGenres && _selectedGenres.isEmpty) return false;

    // Instrumentalist must select instruments
    if (_selectedCategories.contains('instrumentalist') &&
        _selectedInstruments.isEmpty) {
      return false;
    }

    for (final categoryId in professionalRoleSectionByCategoryId.keys) {
      if (_selectedCategories.contains(categoryId) &&
          _selectedRoleIdsForCategory(categoryId).isEmpty) {
        return false;
      }
    }

    return true;
  }

  Future<void> _finishOnboarding() async {
    AppConfig appConfig;
    try {
      appConfig = await ref.read(appConfigProvider.future);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        'Não foi possível carregar as opções de gêneros e instrumentos. '
        'Tente novamente em instantes.',
        isError: true,
      );
      return;
    }

    final roleIds = _selectedRoles
        .where(
          (roleId) =>
              _roleBelongsToAnySelectedCategory(roleId, _selectedCategories),
        )
        .toList(growable: false);

    final genreIds = _selectedGenres.map((label) {
      return appConfig.genres
          .firstWhere(
            (g) => g.label == label,
            orElse: () => ConfigItem(id: label, label: label, order: 0),
          )
          .id;
    }).toList();

    final instrumentIds = _selectedInstruments.map((label) {
      return appConfig.instruments
          .firstWhere(
            (i) => i.label == label,
            orElse: () => ConfigItem(id: label, label: label, order: 0),
          )
          .id;
    }).toList();

    final Map<String, dynamic> professionalData = {
      'nomeArtistico': _nomeArtisticoController.text.trim(),
      'celular': _celularController.text.trim(),
      'dataNascimento': _dataNascimentoController.text.trim(),
      'genero': _generoController.text.trim(),
      'instagram': normalizeInstagramHandle(_instagramController.text),
      'categorias': _selectedCategories,
      'generosMusicais': _shouldShowGenres ? genreIds : <String>[],
      'funcoes': roleIds,
      'isPublic': true,
    };

    if (_selectedCategories.contains('singer')) {
      professionalData['backingVocalMode'] = _backingVocalMode;
    }

    if (_selectedCategories.contains('instrumentalist')) {
      professionalData['instrumentos'] = instrumentIds;
      professionalData['fazBackingVocal'] = _instrumentalistBackingVocal;
      professionalData['instrumentalistBackingVocal'] =
          _instrumentalistBackingVocal;
    }

    professionalData[professionalRemoteRecordingFieldKey] =
        _selectedCategories.contains('production') && _offersRemoteRecording;

    final formState = ref.read(onboardingFormProvider);

    await ref
        .read(onboardingControllerProvider.notifier)
        .submitProfileForm(
          currentUser: widget.user,
          nome: _nomeController.text.trim(),
          location: formState.locationMap,
          dadosProfissional: professionalData,
        );
  }
}
