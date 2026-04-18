import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../common_widgets/formatters/sentence_start_uppercase_formatter.dart';
import '../../../constants/app_constants.dart';
import '../../../core/errors/error_message_resolver.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_overlay.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/loading/app_skeleton.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_effects.dart';
import '../../../design_system/foundations/tokens/app_radius.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/instagram_utils.dart';
import '../../../utils/public_username.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../domain/music_link_validator.dart';
import 'edit_profile/controllers/edit_profile_controller.dart';
import 'edit_profile/widgets/edit_profile_header.dart';
import 'edit_profile/widgets/forms/band_form_fields.dart';
import 'edit_profile/widgets/forms/contractor_form_fields.dart';
import 'edit_profile/widgets/forms/music_links_form.dart';
import 'edit_profile/widgets/forms/professional_form_fields.dart';
import 'edit_profile/widgets/forms/studio_form_fields.dart';
import 'edit_profile/widgets/media_gallery_section.dart';
import 'music_platform_catalog.dart';

part 'edit_profile_screen_actions.dart';
part 'edit_profile_screen_state.dart';
part 'edit_profile_screen_ui.dart';
part 'edit_profile_screen_username.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

enum _UsernameAvailabilityState {
  idle,
  checking,
  available,
  unavailable,
  current,
  error,
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _bioFormatter = SentenceStartUppercaseTextInputFormatter();
  TabController? _tabController;
  final _profileFormKey = GlobalKey<FormState>();
  final _musicLinksFormKey = GlobalKey<FormState>();
  final Set<int> _visitedTabs = {0};
  Timer? _usernameValidationDebounce;
  final ValueNotifier<int> _usernameUiVersion = ValueNotifier<int>(0);
  _UsernameAvailabilityState _usernameAvailabilityState =
      _UsernameAvailabilityState.idle;
  String? _usernameAvailabilityMessage;
  int _usernameValidationRequestId = 0;

  // Controllers for text fields managed in UI state
  late TextEditingController _nomeController;
  late TextEditingController _nomeArtisticoController;
  late TextEditingController _celularController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _generoController;
  late TextEditingController _instagramController;
  late TextEditingController _bioController;
  late TextEditingController _usernameController;
  late TextEditingController _spotifyController;
  late TextEditingController _deezerController;
  late TextEditingController _youtubeMusicController;
  late TextEditingController _appleMusicController;

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  bool _isControllersInitialized = false;

  @override
  void initState() {
    super.initState();
    // Preload app config to avoid empty option lists on first modal open.
    unawaited(ref.read(appConfigProvider.future));
  }

  @override
  void dispose() {
    _usernameValidationDebounce?.cancel();
    _usernameUiVersion.dispose();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    if (_isControllersInitialized) {
      _nomeController.dispose();
      _nomeArtisticoController.dispose();
      _celularController.dispose();
      _dataNascimentoController.dispose();
      _generoController.dispose();
      _instagramController.dispose();
      _bioController.dispose();
      _usernameController.dispose();
      _spotifyController.dispose();
      _deezerController.dispose();
      _youtubeMusicController.dispose();
      _appleMusicController.dispose();
    }
    super.dispose();
  }

  void _handleTabChange() {
    final tabController = _tabController;
    if (tabController == null) return;

    if (tabController.index == tabController.previousIndex) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_visitedTabs.add(tabController.index) && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => _buildEditProfileScreen(context);
}
