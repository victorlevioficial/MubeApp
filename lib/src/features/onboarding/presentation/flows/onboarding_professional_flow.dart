import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../../constants/app_constants.dart';
import '../../../../core/domain/app_config.dart';
import '../../../../core/domain/professional_roles.dart';
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
import '../../../../utils/category_normalizer.dart';
import '../../../../utils/instagram_utils.dart';
import '../../../../utils/professional_profile_utils.dart';
import '../../../auth/domain/app_user.dart';
import '../onboarding_controller.dart';
import '../onboarding_form_provider.dart';
import '../steps/onboarding_address_step.dart';
import '../steps/professional_category_step.dart';

part 'onboarding_professional_flow_actions.dart';
part 'onboarding_professional_flow_ui.dart';

/// Enhanced Professional Onboarding Flow with modern UI.
///
/// Steps:
/// 1. Basic Info (Name, Birth Date, Gender, Contact)
/// 2. Category Selection (Singer, Instrumentalist, DJ, Production, Stage Tech)
/// 3. Specialization (based on selected categories)
/// 4. Address
///
/// Features modern, professional UI matching the login screen design.
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
  final _scrollController = ScrollController();

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
  bool _offersRemoteRecording = false;
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
    _generoController.text = normalizeGenderValue(formState.genero);
    _celularController.text = formState.celular ?? '';
    _instagramController.text = normalizeInstagramHandle(formState.instagram);

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
    _selectedRoles = _normalizeRoleIds(formState.selectedRoles);
    _backingVocalMode = formState.backingVocalMode;
    _instrumentalistBackingVocal = formState.instrumentalistBackingVocal;
    _offersRemoteRecording = formState.offersRemoteRecording;

    // Fetch location preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingFormProvider.notifier).fetchInitialLocation();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nomeController.dispose();
    _nomeArtisticoController.dispose();
    _celularController.dispose();
    _dataNascimentoController.dispose();
    _generoController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _buildOnboardingProfessionalFlow(context);

  void _updateState(VoidCallback fn) => setState(fn);
}
