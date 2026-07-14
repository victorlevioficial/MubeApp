part of 'edit_profile_screen.dart';

extension _EditProfileScreenUi on _EditProfileScreenState {
  Widget _buildEditProfileScreen(BuildContext context) {
    // Watch current user to get ID and initial data
    final userAsync = ref.watch(currentUserProfileProvider);

    return userAsync.when(
      loading: () => const _EditProfileScreenSkeleton(),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuário não encontrado')),
          );
        }

        // Initialize controllers once
        if (!_isControllersInitialized) {
          _initializeControllers(user);
        }
        _ensureTabControllerForUser(user);
        final tabController = _activeTabController;

        // Watch edit state
        final editUiState = ref.watch(
          editProfileControllerProvider(user.uid).select(
            (state) => (
              hasChanges: state.hasChanges,
              isSaving: state.isSaving,
              isUploadingMedia: state.isUploadingMedia,
              uploadStatus: state.uploadStatus,
            ),
          ),
        );
        final isContractor = user.tipoPerfil == AppUserType.contractor;

        return PopScope(
          canPop: !editUiState.hasChanges && !editUiState.isUploadingMedia,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            unawaited(_handleBack(user));
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppAppBar(
              title: 'Editar Perfil',
              showBackButton: true,
              onBackPressed: () => _handleBack(user),
            ),
            body: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(AppSpacing.s16),
                  height: AppSpacing.s48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
                    borderRadius: AppRadius.pill,
                    border: Border.all(
                      color: AppColors.textPrimary.withValues(alpha: 0.05),
                    ),
                  ),
                  child: TabBar(
                    controller: tabController,
                    onTap: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                    labelColor: AppColors.textPrimary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: AppRadius.pill,
                      boxShadow: AppEffects.buttonShadow,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: AppColors.transparent,
                    padding: AppSpacing.all4,
                    tabs: isContractor
                        ? const [Tab(text: 'Perfil'), Tab(text: 'Mídia')]
                        : const [
                            Tab(text: 'Perfil'),
                            Tab(text: 'Mídia'),
                            Tab(text: 'Links'),
                          ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      _buildProfileTab(user),
                      _shouldBuildTab(1)
                          ? MediaGallerySection(user: user)
                          : const SizedBox.shrink(),
                      if (!isContractor)
                        _shouldBuildTab(2)
                            ? Form(
                                key: _musicLinksFormKey,
                                child: MusicLinksForm(
                                  controllers: _musicLinkControllers,
                                  onChanged: ref
                                      .read(
                                        editProfileControllerProvider(
                                          user.uid,
                                        ).notifier,
                                      )
                                      .markChanged,
                                ),
                              )
                            : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(
                  left: AppSpacing.s16,
                  right: AppSpacing.s16,
                  bottom: AppSpacing.s16,
                ),
                padding: const EdgeInsets.all(AppSpacing.s10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.surface,
                      AppColors.surface.withValues(alpha: 0.98),
                    ],
                  ),
                  borderRadius: AppRadius.all24,
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.08),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.background.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _usernameController,
                  builder: (context, value, child) =>
                      ValueListenableBuilder<int>(
                        valueListenable: _usernameUiVersion,
                        builder: (context, version, innerChild) =>
                            AppButton.primary(
                              text: 'Salvar Alterações',
                              onPressed:
                                  editUiState.hasChanges &&
                                      !editUiState.isSaving &&
                                      !editUiState.isUploadingMedia &&
                                      _canSaveWithUsername(user)
                                  ? () => _handleSave(user)
                                  : null,
                              isLoading: editUiState.isSaving,
                              isFullWidth: true,
                              size: AppButtonSize.large,
                            ),
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user.tipoPerfil == AppUserType.professional) ...[
              Text('Informações Pessoais', style: AppTypography.headlineMedium),
              const SizedBox(height: AppSpacing.s16),
            ],
            EditProfileHeader(user: user, nomeController: _nomeController),
            const SizedBox(height: AppSpacing.s16),
            _buildProfileReadinessCard(user),
            const SizedBox(height: AppSpacing.s16),
            _buildPublicLinkSection(user),
            const SizedBox(height: AppSpacing.s24),
            _buildTypeSpecificFields(user),
            // Bottom spacing
            const SizedBox(height: AppSpacing.s48 + AppSpacing.s32),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificFields(AppUser user) {
    final editState = ref.watch(editProfileControllerProvider(user.uid));
    final notifier = ref.read(editProfileControllerProvider(user.uid).notifier);

    switch (user.tipoPerfil) {
      case AppUserType.professional:
        return ProfessionalFormFields(
          nomeArtisticoController: _nomeArtisticoController,
          celularController: _celularController,
          dataNascimentoController: _dataNascimentoController,
          generoController: _generoController,
          instagramController: _instagramController,
          bioController: _bioController,
          celularMask: _celularMask,
          selectedCategories: editState.selectedCategories,
          selectedGenres: editState.selectedGenres,
          selectedInstruments: editState.selectedInstruments,
          selectedRoles: editState.selectedRoles,
          onCategoriesChanged: notifier.updateCategories,
          onGenresChanged: notifier.updateGenres,
          onInstrumentsChanged: notifier.updateInstruments,
          onRolesChanged: notifier.updateRoles,
          backingVocalMode: editState.backingVocalMode,
          onBackingVocalModeChanged: notifier.setBackingVocalMode,
          instrumentalistBackingVocal: editState.instrumentalistBackingVocal,
          onInstrumentalistBackingVocalChanged:
              notifier.setInstrumentalistBackingVocal,
          offersRemoteRecording: editState.offersRemoteRecording,
          onOffersRemoteRecordingChanged: notifier.setOffersRemoteRecording,
          onStateChanged: notifier.markChanged,
        );
      case AppUserType.studio:
        return StudioFormFields(
          nomeEstudioController: _nomeArtisticoController,
          celularController: _celularController,
          instagramController: _instagramController,
          celularMask: _celularMask,
          studioType: editState.studioType,
          onStudioTypeChanged: notifier.setStudioType,
          selectedServices: editState.selectedServices,
          onServicesChanged: notifier.updateServices,
          bioController: _bioController,
          onChanged: notifier.markChanged,
        );
      case AppUserType.band:
        return BandFormFields(
          nomeBandaController: _nomeArtisticoController,
          instagramController: _instagramController,
          selectedGenres: editState.bandGenres,
          onGenresChanged: notifier.updateBandGenres,
          bioController: _bioController,
          onChanged: notifier.markChanged,
        );
      case AppUserType.contractor:
        return ContractorFormFields(
          nomeExibicaoController: _nomeArtisticoController,
          celularController: _celularController,
          celularMask: _celularMask,
          dataNascimentoController: _dataNascimentoController,
          generoController: _generoController,
          instagramController: _instagramController,
          bioController: _bioController,
          contractorVenueType: editState.contractorVenueType,
          contractorAmenities: editState.contractorAmenities,
          onVenueTypeChanged: notifier.setContractorVenueType,
          onAmenitiesChanged: notifier.updateContractorAmenities,
          onChanged: notifier.markChanged,
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildPublicLinkSection(AppUser user) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(color: AppColors.surfaceHighlight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Link público do perfil',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Escolha um @usuário para compartilhar seu perfil com um link curto.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _buildUsernameField(user),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _usernameController,
            builder: (context, value, _) {
              return ValueListenableBuilder<int>(
                valueListenable: _usernameUiVersion,
                builder: (context, version, child) {
                  final usernameStatus = _buildUsernameStatus(user);
                  final normalizedUsername = normalizedPublicUsernameOrNull(
                    value.text,
                  );
                  final hasValidUsername =
                      normalizedUsername != null &&
                      validatePublicUsername(normalizedUsername) == null;
                  final previewUrl = RoutePaths.publicProfileShareUrl(
                    uid: user.uid,
                    username: hasValidUsername
                        ? normalizedUsername
                        : user.publicUsername,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...(usernameStatus == null
                          ? const <Widget>[]
                          : <Widget>[usernameStatus]),
                      const SizedBox(height: AppSpacing.s10),
                      Text(
                        'Preview: $previewUrl',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileReadinessCard(AppUser user) {
    final completion = ProfileCompletionEvaluator.evaluate(user);
    final isPublicable = _hasPublicableMinimum(user);
    final actions = _buildProfileImprovementActions(user, completion);
    final isContractor = user.tipoPerfil == AppUserType.contractor;
    final statusLabel = isContractor ? 'Conta liberada' : 'Perfil publicável';
    final title = isPublicable ? statusLabel : 'Revise os dados essenciais';
    final subtitle = isPublicable
        ? isContractor
              ? 'Você já pode acessar o Mube. Se quiser aparecer como estabelecimento, complete os dados públicos depois.'
              : 'Seu perfil já pode aparecer no Mube. Complete os próximos pontos para ser encontrado com mais confiança.'
        : 'Faltam dados mínimos para este perfil aparecer corretamente no Mube.';

    return Container(
      key: const Key('edit_profile_readiness_card'),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: isPublicable
              ? AppColors.success.withValues(alpha: 0.28)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (isPublicable ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.14),
                  borderRadius: AppRadius.all12,
                ),
                child: Icon(
                  isPublicable
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: isPublicable ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s10,
                  vertical: AppSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${completion.percent}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s14),
          Divider(
            height: 1,
            color: AppColors.textPrimary.withValues(alpha: 0.07),
          ),
          const SizedBox(height: AppSpacing.s14),
          Text(
            actions.isEmpty ? 'Perfil forte' : 'Próximas melhorias',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.s10),
          if (actions.isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.done_all_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    'Foto, bio e mídia já ajudam seu perfil a passar confiança.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                for (final action in actions.take(4))
                  _buildProfileImprovementAction(action),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildProfileImprovementAction(_ProfileImprovementAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.all12,
        onTap: () => _handleProfileImprovementAction(action),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
          child: Row(
            children: [
              Icon(action.icon, color: AppColors.primary, size: 18),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s2),
                    Text(
                      action.description,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ProfileImprovementAction> _buildProfileImprovementActions(
    AppUser user,
    ProfileCompletionResult completion,
  ) {
    final missing = completion.missingRequirements.toSet();
    final actions = <_ProfileImprovementAction>[];

    if (missing.contains('Foto de perfil')) {
      actions.add(
        const _ProfileImprovementAction(
          icon: Icons.add_a_photo_outlined,
          title: 'Adicionar foto de perfil',
          description: 'Ajuda outras pessoas a reconhecerem seu perfil.',
          tabIndex: 0,
        ),
      );
    }

    if (missing.contains('Bio')) {
      actions.add(
        const _ProfileImprovementAction(
          icon: Icons.short_text_rounded,
          title: 'Escrever uma bio curta',
          description: 'Conte em poucas linhas o que você faz na cena.',
          tabIndex: 0,
        ),
      );
    }

    if (missing.contains('Galeria de fotos')) {
      actions.add(
        const _ProfileImprovementAction(
          icon: Icons.photo_library_outlined,
          title: 'Adicionar fotos na mídia',
          description: 'Mostre palco, estúdio, bastidores ou trabalhos reais.',
          tabIndex: 1,
        ),
      );
    }

    if (missing.contains('Galeria de videos')) {
      actions.add(
        const _ProfileImprovementAction(
          icon: Icons.play_circle_outline_rounded,
          title: 'Adicionar vídeo',
          description: 'Vídeo dá contexto rápido para quem está avaliando.',
          tabIndex: 1,
        ),
      );
    }

    if (missing.contains('Localizacao')) {
      actions.add(
        const _ProfileImprovementAction(
          icon: Icons.location_on_outlined,
          title: 'Revisar localização',
          description: 'A busca usa localização para aproximar oportunidades.',
          route: RoutePaths.addresses,
        ),
      );
    }

    final technicalMissing = missing.difference(const {
      'Cadastro concluido',
      'Tipo de perfil',
      'Nome',
      'Foto de perfil',
      'Localizacao',
      'Bio',
      'Galeria de fotos',
      'Galeria de videos',
    });
    for (final label in technicalMissing.take(2)) {
      actions.add(
        _ProfileImprovementAction(
          icon: Icons.tune_rounded,
          title: 'Revisar $label',
          description: 'Atualize este dado para melhorar a leitura do perfil.',
          tabIndex: 0,
        ),
      );
    }

    if (user.tipoPerfil != AppUserType.contractor && !_hasAnyMusicLink(user)) {
      actions.add(
        const _ProfileImprovementAction(
          icon: Icons.link_rounded,
          title: 'Adicionar link musical',
          description: 'Leve contratantes e parceiros para seu som publicado.',
          tabIndex: 2,
        ),
      );
    }

    return actions;
  }

  void _handleProfileImprovementAction(_ProfileImprovementAction action) {
    final route = action.route;
    if (route != null) {
      context.push(route);
      return;
    }

    final tabIndex = action.tabIndex;
    final tabController = _activeTabController;
    if (tabIndex == null) return;
    if (tabIndex >= tabController.length) return;

    FocusManager.instance.primaryFocus?.unfocus();
    tabController.animateTo(tabIndex);
  }

  bool _hasPublicableMinimum(AppUser user) {
    final type = user.tipoPerfil;
    if (!user.isCadastroConcluido ||
        type == null ||
        user.registrationName.isEmpty ||
        !_hasValidLocation(user.location)) {
      return false;
    }

    final data = _activeProfileData(user, type);
    return switch (type) {
      AppUserType.professional =>
        _hasText(data['nomeArtistico']) &&
            _hasText(data['celular']) &&
            _asStringList(data['categorias']).isNotEmpty &&
            _asStringList(data['funcoes']).isNotEmpty,
      AppUserType.band =>
        (_hasText(data['nomeBanda']) ||
                _hasText(data['nomeArtistico']) ||
                _hasText(data['nome'])) &&
            _asStringList(data['generosMusicais']).isNotEmpty,
      AppUserType.studio =>
        (_hasText(data['nomeEstudio']) ||
                _hasText(data['nomeArtistico']) ||
                _hasText(data['nome'])) &&
            _hasText(data['celular']) &&
            _hasText(data['studioType']) &&
            (_asStringList(data['servicosOferecidos']).isNotEmpty ||
                _asStringList(data['services']).isNotEmpty),
      AppUserType.contractor => _hasText(data['celular']),
    };
  }

  Map<String, dynamic> _activeProfileData(AppUser user, AppUserType type) {
    return switch (type) {
      AppUserType.professional =>
        user.dadosProfissional ?? const <String, dynamic>{},
      AppUserType.band => user.dadosBanda ?? const <String, dynamic>{},
      AppUserType.studio =>
        (user.dadosEstudio != null && user.dadosEstudio!.isNotEmpty)
            ? user.dadosEstudio!
            : user.dadosProfissional ?? const <String, dynamic>{},
      AppUserType.contractor =>
        user.dadosContratante ?? const <String, dynamic>{},
    };
  }

  bool _hasValidLocation(Map<String, dynamic>? location) {
    if (location == null) return false;
    final lat = location['lat'];
    final lng = location['lng'];
    if (lat is! num || lng is! num) return false;
    return lat != 0 || lng != 0;
  }

  bool _hasAnyMusicLink(AppUser user) {
    return user.musicLinks.values.any((value) => value.trim().isNotEmpty);
  }

  bool _hasText(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return value.toString().trim().isNotEmpty;
  }

  List<String> _asStringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Widget _buildUsernameField(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '@usuario',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        TextFormField(
          controller: _usernameController,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          style: AppTypography.input.copyWith(color: AppColors.textPrimary),
          validator: (fieldValue) => _usernameValidator(user, fieldValue),
          onChanged: (value) => _handleUsernameChanged(user, value),
          inputFormatters: <TextInputFormatter>[
            LengthLimitingTextInputFormatter(maxPublicUsernameLength + 1),
          ],
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'mubeoficial',
            hintStyle: AppTypography.inputHint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s16,
                right: AppSpacing.s8,
              ),
              child: Text(
                '@',
                style: AppTypography.input.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: AppSpacing.s16,
            ),
            border: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: AppRadius.all12,
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileScreenSkeleton extends StatelessWidget {
  const _EditProfileScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(title: 'Editar Perfil', showBackButton: true),
      body: SafeArea(
        child: SkeletonShimmer(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(AppSpacing.s16),
                child: SkeletonBox(
                  width: double.infinity,
                  height: AppSpacing.s48,
                  borderRadius: AppRadius.rPill,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: AppSpacing.s8),
                      Center(child: SkeletonCircle(size: 104)),
                      SizedBox(height: AppSpacing.s20),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 52, borderRadius: AppRadius.r12),
                      SizedBox(height: AppSpacing.s12),
                      SkeletonBox(height: 124, borderRadius: AppRadius.r12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.s16,
            0,
            AppSpacing.s16,
            AppSpacing.s16,
          ),
          child: SkeletonShimmer(
            child: SkeletonBox(
              width: double.infinity,
              height: 56,
              borderRadius: AppRadius.r24,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileImprovementAction {
  const _ProfileImprovementAction({
    required this.icon,
    required this.title,
    required this.description,
    this.tabIndex,
    this.route,
  });

  final IconData icon;
  final String title;
  final String description;
  final int? tabIndex;
  final String? route;
}
