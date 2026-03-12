import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/app_config.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/chips/app_chip.dart';
import '../../../../design_system/components/feedback/app_snackbar.dart';
import '../../../../design_system/components/inputs/app_dropdown_field.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
import '../../../../design_system/components/navigation/app_app_bar.dart';
import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../../../design_system/foundations/tokens/app_radius.dart';
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../design_system/foundations/tokens/app_typography.dart';
import '../../../../routing/route_paths.dart';
import '../../../../utils/geohash_helper.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/app_user.dart';
import '../../../settings/domain/saved_address_book.dart';
import '../../domain/compensation_type.dart';
import '../../domain/gig.dart';
import '../../domain/gig_date_mode.dart';
import '../../domain/gig_draft.dart';
import '../../domain/gig_location_type.dart';
import '../../domain/gig_type.dart';
import '../controllers/create_gig_controller.dart';
import '../gig_error_message.dart';

class CreateGigScreen extends ConsumerStatefulWidget {
  const CreateGigScreen({super.key, this.initialGig});

  final Gig? initialGig;

  @override
  ConsumerState<CreateGigScreen> createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends ConsumerState<CreateGigScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _compensationValueController;
  late final TextEditingController _slotsController;

  late GigType _gigType;
  late GigDateMode _dateMode;
  DateTime? _gigDate;
  late GigLocationType _locationType;
  late CompensationType _compensationType;
  late List<String> _selectedGenres;
  late List<String> _selectedInstruments;
  late List<String> _selectedRoles;
  late List<String> _selectedServices;
  late bool _showGenresRequirements;
  late bool _showInstrumentsRequirements;
  late bool _showRolesRequirements;
  late bool _showServicesRequirements;

  bool get _isEditing => widget.initialGig != null;
  bool get _canEditAllFields => widget.initialGig?.canEditAllFields ?? true;

  @override
  void initState() {
    super.initState();
    final gig = widget.initialGig;
    _titleController = TextEditingController(text: gig?.title ?? '');
    _descriptionController = TextEditingController(
      text: gig?.description ?? '',
    );
    _locationController = TextEditingController(
      text: gig?.location?['label']?.toString() ?? '',
    );
    _compensationValueController = TextEditingController(
      text: gig?.compensationValue?.toString() ?? '',
    );
    _slotsController = TextEditingController(
      text: (gig?.slotsTotal ?? 1).toString(),
    );
    _gigType = gig?.gigType ?? GigType.liveShow;
    _dateMode = gig?.dateMode ?? GigDateMode.fixedDate;
    _gigDate = gig?.gigDate;
    _locationType = gig?.locationType ?? GigLocationType.onsite;
    _compensationType = gig?.compensationType ?? CompensationType.toBeDefined;
    _selectedGenres = List<String>.from(gig?.genres ?? const []);
    _selectedInstruments = List<String>.from(
      gig?.requiredInstruments ?? const [],
    );
    _selectedRoles = List<String>.from(gig?.requiredCrewRoles ?? const []);
    _selectedServices = List<String>.from(
      gig?.requiredStudioServices ?? const [],
    );
    _showGenresRequirements = _selectedGenres.isNotEmpty;
    _showInstrumentsRequirements = _selectedInstruments.isNotEmpty;
    _showRolesRequirements = _selectedRoles.isNotEmpty;
    _showServicesRequirements = _selectedServices.isNotEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _compensationValueController.dispose();
    _slotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    final createState = ref.watch(createGigControllerProvider);

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
            child: ListView(
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
                              setState(() => _gigType = value);
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
                              setState(() {
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
                      _DatePickerTile(
                        gigDate: _gigDate,
                        enabled: _canEditAllFields,
                        onTap: _pickDateTime,
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
                              setState(() => _locationType = value);
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
                              setState(() => _compensationType = value);
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
                      onToggle: () => setState(() {
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
                            setState(() => _selectedGenres = next),
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
                      onToggle: () => setState(() {
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
                            setState(() => _selectedInstruments = next),
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
                      onToggle: () => setState(() {
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
                            setState(() => _selectedRoles = next),
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
                      onToggle: () => setState(() {
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
                            setState(() => _selectedServices = next),
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

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final initial = _gigDate ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: DateTime(now.year + 3),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    setState(() {
      _gigDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit(AppConfig config) async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateMode == GigDateMode.fixedDate && _gigDate == null) {
      AppSnackBar.error(context, 'Selecione a data da gig.');
      return;
    }

    try {
      final currentUser = ref.read(currentUserProfileProvider).asData?.value;
      final locationPayload = _buildLocationPayload(currentUser);
      final geohash = _buildLocationGeohash(locationPayload);

      if (_isEditing) {
        final update = _canEditAllFields
            ? GigUpdate(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                gigType: _gigType,
                dateMode: _dateMode,
                gigDate: _gigDate,
                clearGigDate: _dateMode != GigDateMode.fixedDate,
                locationType: _locationType,
                location: locationPayload,
                geohash: geohash,
                clearLocation: locationPayload == null,
                genres: _selectedGenres,
                requiredInstruments: _selectedInstruments,
                requiredCrewRoles: _selectedRoles,
                requiredStudioServices: _selectedServices,
                slotsTotal: int.parse(_slotsController.text),
                compensationType: _compensationType,
                compensationValue: _compensationType == CompensationType.fixed
                    ? int.tryParse(_compensationValueController.text)
                    : null,
                clearCompensationValue:
                    _compensationType != CompensationType.fixed,
              )
            : GigUpdate(description: _descriptionController.text.trim());

        await ref
            .read(createGigControllerProvider.notifier)
            .updateDraft(widget.initialGig!.id, update);
        if (!mounted) return;
        AppSnackBar.success(context, 'Gig atualizada com sucesso.');
      } else {
        final draft = GigDraft(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          gigType: _gigType,
          dateMode: _dateMode,
          gigDate: _gigDate,
          locationType: _locationType,
          location: locationPayload,
          geohash: geohash,
          genres: _selectedGenres,
          requiredInstruments: _selectedInstruments,
          requiredCrewRoles: _selectedRoles,
          requiredStudioServices: _selectedServices,
          slotsTotal: int.parse(_slotsController.text),
          compensationType: _compensationType,
          compensationValue: _compensationType == CompensationType.fixed
              ? int.tryParse(_compensationValueController.text)
              : null,
        );
        final gigId = await ref
            .read(createGigControllerProvider.notifier)
            .submitDraft(draft);
        if (!mounted) return;
        AppSnackBar.success(context, 'Gig publicada com sucesso.');
        context.go(RoutePaths.gigDetailById(gigId));
        return;
      }

      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.error(context, resolveGigErrorMessage(error));
    }
  }

  Map<String, dynamic>? _buildLocationPayload(AppUser? currentUser) {
    final label = _locationController.text.trim();
    if (_locationType == GigLocationType.remote) {
      if (label.isEmpty) return null;
      return {'label': label};
    }

    final primaryAddress = currentUser == null
        ? null
        : SavedAddressBook.effectiveAddresses(currentUser).firstOrNull;

    final payload = <String, dynamic>{};
    if (label.isNotEmpty) {
      payload['label'] = label;
    } else if (primaryAddress != null &&
        primaryAddress.shortDisplay.isNotEmpty) {
      payload['label'] = primaryAddress.shortDisplay;
    }

    if (primaryAddress?.lat != null) payload['lat'] = primaryAddress!.lat;
    if (primaryAddress?.lng != null) payload['lng'] = primaryAddress!.lng;
    if (primaryAddress != null && primaryAddress.cidade.isNotEmpty) {
      payload['cidade'] = primaryAddress.cidade;
    }
    if (primaryAddress != null && primaryAddress.estado.isNotEmpty) {
      payload['estado'] = primaryAddress.estado;
    }

    return payload.isEmpty ? null : payload;
  }

  String? _buildLocationGeohash(Map<String, dynamic>? locationPayload) {
    if (_locationType != GigLocationType.onsite || locationPayload == null) {
      return null;
    }

    final lat = (locationPayload['lat'] as num?)?.toDouble();
    final lng = (locationPayload['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return GeohashHelper.encode(lat, lng, precision: 5);
  }
}

// ── Form section header ───────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  const _FormSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.pill,
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text(label.toUpperCase(), style: AppTypography.settingsGroupTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.s14),
        Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.all16,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

// ── Date picker tile ──────────────────────────────────────────────────────────

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.gigDate,
    required this.enabled,
    required this.onTap,
  });

  final DateTime? gigDate;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDate = gigDate != null;
    final label = hasDate
        ? '${gigDate!.day.toString().padLeft(2, '0')}/${gigDate!.month.toString().padLeft(2, '0')}/${gigDate!.year}  ${gigDate!.hour.toString().padLeft(2, '0')}:${gigDate!.minute.toString().padLeft(2, '0')}'
        : 'Selecionar data e horário';

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: AppRadius.all12,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceHighlight,
          borderRadius: AppRadius.all12,
          border: Border.all(
            color: hasDate
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: 18,
              color: hasDate ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: hasDate
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Locked fields banner ──────────────────────────────────────────────────────

class _LockedFieldsBanner extends StatelessWidget {
  const _LockedFieldsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              'Como esta gig já recebeu candidaturas, apenas a descrição pode ser alterada.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warning,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementsIntroCard extends StatelessWidget {
  const _RequirementsIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s14,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: AppRadius.all8,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Text(
              'Esses blocos são opcionais e independentes. Abra somente o que fizer sentido para esta gig.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementCategoryCard extends StatelessWidget {
  const _RequirementCategoryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedCount,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int selectedCount;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCount > 0;
    final isHighlighted = isExpanded || hasSelection;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: AppRadius.all12,
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: AppRadius.all12,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : AppColors.surface2,
                        borderRadius: AppRadius.all12,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isHighlighted
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.s8),
                              _RequirementBadge(
                                label: hasSelection
                                    ? '$selectedCount selecionado${selectedCount == 1 ? '' : 's'}'
                                    : 'Opcional',
                                isHighlighted: hasSelection,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: !isExpanded
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s12,
                        0,
                        AppSpacing.s12,
                        AppSpacing.s12,
                      ),
                      child: child,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementBadge extends StatelessWidget {
  const _RequirementBadge({required this.label, required this.isHighlighted});

  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surface2,
        borderRadius: AppRadius.pill,
        border: Border.all(
          color: isHighlighted
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.border.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: isHighlighted ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Multi-select field ────────────────────────────────────────────────────────

class _ConfigMultiSelectField extends StatelessWidget {
  const _ConfigMultiSelectField({
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
    this.showTitle = true,
    this.emptyLabel = 'Selecionar',
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final List<ConfigItem> items;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;
  final bool showTitle;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final selectedItems = items
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            title,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
        ],
        InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final result =
                      await EnhancedMultiSelectModal.show<ConfigItem>(
                        context: context,
                        title: title,
                        subtitle: subtitle,
                        items: items,
                        selectedItems: selectedItems,
                        itemLabel: (item) => item.label,
                      );
                  if (result == null) return;
                  onChanged(
                    result.map((item) => item.id).toList(growable: false),
                  );
                },
          borderRadius: AppRadius.all12,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s14,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadius.all12,
              border: Border.all(
                color: selectedItems.isNotEmpty
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedItems.isEmpty
                        ? emptyLabel
                        : '${selectedItems.length} selecionado${selectedItems.length == 1 ? '' : 's'}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: enabled
                          ? (selectedItems.isNotEmpty
                                ? AppColors.textPrimary
                                : AppColors.textTertiary)
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: selectedItems
                .map((item) => AppChip.skill(label: item.label))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
