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
import '../../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../../routing/route_paths.dart';
import '../../domain/compensation_type.dart';
import '../../domain/gig.dart';
import '../../domain/gig_date_mode.dart';
import '../../domain/gig_draft.dart';
import '../../domain/gig_location_type.dart';
import '../../domain/gig_type.dart';
import '../controllers/create_gig_controller.dart';

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

  bool get _isEditing => widget.initialGig != null;
  bool get _canEditAllFields => widget.initialGig?.canEditAllFields ?? true;

  @override
  void initState() {
    super.initState();
    final gig = widget.initialGig;
    _titleController = TextEditingController(text: gig?.title ?? '');
    _descriptionController = TextEditingController(text: gig?.description ?? '');
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
      appBar: AppAppBar(
        title: _isEditing ? 'Editar gig' : 'Nova gig',
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erro ao carregar config: $error')),
        data: (config) => SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              children: [
                AppTextField(
                  controller: _titleController,
                  label: 'Titulo',
                  hint: 'Ex: Procuro baterista para show de pop/rock',
                  readOnly: !_canEditAllFields,
                  validator: (value) {
                    if ((value ?? '').trim().length < 6) {
                      return 'Informe um titulo com pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Descricao da demanda',
                  hint: 'Explique contexto, repertorio, expectativa e detalhes.',
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
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s16,
                    ),
                    title: const Text('Selecionar data e horario'),
                    subtitle: Text(
                      _gigDate == null
                          ? 'Toque para escolher'
                          : '${_gigDate!.day.toString().padLeft(2, '0')}/${_gigDate!.month.toString().padLeft(2, '0')}/${_gigDate!.year} ${_gigDate!.hour.toString().padLeft(2, '0')}:${_gigDate!.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.event_outlined),
                    onTap: !_canEditAllFields ? null : _pickDateTime,
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
                      ? 'Abrangencia / observacao'
                      : 'Local',
                  hint: _locationType == GigLocationType.remote
                      ? 'Ex: remoto para todo Brasil'
                      : 'Ex: Sao Paulo - SP',
                  readOnly: !_canEditAllFields,
                ),
                const SizedBox(height: AppSpacing.s16),
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
                  label: 'Cache',
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
                    label: 'Valor do cache',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    readOnly: !_canEditAllFields,
                    validator: (value) {
                      if (_compensationType != CompensationType.fixed) {
                        return null;
                      }
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Informe um valor valido';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.s24),
                _ConfigMultiSelectField(
                  enabled: _canEditAllFields,
                  title: 'Generos',
                  subtitle: 'Selecione os estilos da oportunidade',
                  items: config.genres,
                  selectedIds: _selectedGenres,
                  onChanged: (next) => setState(() => _selectedGenres = next),
                ),
                const SizedBox(height: AppSpacing.s16),
                _ConfigMultiSelectField(
                  enabled: _canEditAllFields,
                  title: 'Instrumentos',
                  subtitle: 'Selecione os instrumentos requisitados',
                  items: config.instruments,
                  selectedIds: _selectedInstruments,
                  onChanged: (next) =>
                      setState(() => _selectedInstruments = next),
                ),
                const SizedBox(height: AppSpacing.s16),
                _ConfigMultiSelectField(
                  enabled: _canEditAllFields,
                  title: 'Funcoes tecnicas',
                  subtitle: 'Selecione as funcoes desejadas',
                  items: config.crewRoles,
                  selectedIds: _selectedRoles,
                  onChanged: (next) => setState(() => _selectedRoles = next),
                ),
                const SizedBox(height: AppSpacing.s16),
                _ConfigMultiSelectField(
                  enabled: _canEditAllFields,
                  title: 'Servicos de estudio',
                  subtitle: 'Selecione os servicos desejados',
                  items: config.studioServices,
                  selectedIds: _selectedServices,
                  onChanged: (next) => setState(() => _selectedServices = next),
                ),
                if (!_canEditAllFields) ...[
                  const SizedBox(height: AppSpacing.s20),
                  const Text(
                    'Como esta gig ja recebeu candidaturas, apenas a descricao pode ser alterada.',
                    style: TextStyle(color: AppColors.warning),
                  ),
                ],
                const SizedBox(height: AppSpacing.s24),
                AppButton.primary(
                  text: _isEditing ? 'Salvar alteracoes' : 'Publicar gig',
                  isFullWidth: true,
                  isLoading: createState.isLoading,
                  onPressed: () => _submit(config),
                ),
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
                location: _locationController.text.trim().isEmpty
                    ? null
                    : {'label': _locationController.text.trim()},
                clearLocation: _locationController.text.trim().isEmpty,
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
          location: _locationController.text.trim().isEmpty
              ? null
              : {'label': _locationController.text.trim()},
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
      AppSnackBar.error(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }
}

class _ConfigMultiSelectField extends StatelessWidget {
  const _ConfigMultiSelectField({
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selectedIds,
    required this.onChanged,
  });

  final bool enabled;
  final String title;
  final String subtitle;
  final List<ConfigItem> items;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedItems = items
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        InkWell(
          onTap: !enabled
              ? null
              : () async {
                  final result = await EnhancedMultiSelectModal.show<ConfigItem>(
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              selectedItems.isEmpty
                  ? 'Selecionar'
                  : '${selectedItems.length} selecionados',
              style: TextStyle(
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
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
