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
                        ? const [Tab(text: 'Perfil'), Tab(text: 'Midia')]
                        : const [
                            Tab(text: 'Perfil'),
                            Tab(text: 'Midia'),
                            Tab(text: 'Links Musicais'),
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
            'Link publico do perfil',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Escolha um @usuario para compartilhar seu perfil com um link curto.',
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
