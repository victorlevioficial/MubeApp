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

part 'create_gig_screen_actions.dart';
part 'create_gig_screen_ui.dart';
part 'create_gig_screen_widgets.dart';

class CreateGigScreen extends ConsumerStatefulWidget {
  const CreateGigScreen({super.key, this.initialGig});

  final Gig? initialGig;

  @override
  ConsumerState<CreateGigScreen> createState() => _CreateGigScreenState();
}

class _CreateGigScreenState extends ConsumerState<CreateGigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFieldKey = GlobalKey();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _compensationValueController;
  late final TextEditingController _slotsController;
  late final ScrollController _scrollController;

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
  bool _showValidationErrors = false;

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
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildCreateGigScreen(context);

  void _updateState(VoidCallback fn) => setState(fn);
}
