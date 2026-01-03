import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import 'profile_controller.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/formatters/title_case_formatter.dart';
import '../../../common_widgets/responsive_center.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';

// Widgets
import 'widgets/professional_form_fields.dart';
import 'widgets/studio_form_fields.dart';
import 'widgets/band_form_fields.dart';
import 'widgets/contractor_form_fields.dart';
import 'widgets/profile_photo_widget.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Global Controllers
  final _nomeController = TextEditingController();
  final _celularController = TextEditingController();

  // Type Specific Controllers (Used across types)
  final _nomeArtisticoController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _generoController = TextEditingController();
  final _instagramController = TextEditingController();

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  // Dynamic State
  AppUser? _currentUser;
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  // Professional Lists
  List<String> _selectedCategories = [];
  List<String> _selectedGenres = [];
  List<String> _selectedInstruments = [];
  List<String> _selectedRoles = [];
  String _backingVocalMode = '0';
  bool _instrumentalistBackingVocal = false;

  // Studio Lists
  List<String> _selectedServices = [];
  String? _studioType;

  bool _isInitialized = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _celularController.dispose();
    _nomeArtisticoController.dispose();
    _dataNascimentoController.dispose();
    _generoController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final userAsync = ref.read(currentUserProfileProvider);
    if (userAsync.hasValue && userAsync.value != null) {
      _currentUser = userAsync.value;
      _populateFields(_currentUser!);
      _isInitialized = true;
    }
  }

  void _populateFields(AppUser user) {
    _nomeController.text = user.nome ?? '';

    final prof = user.dadosProfissional;
    final contractor = user.dadosContratante;
    final studio = user.dadosEstudio;

    if (user.tipoPerfil == AppUserType.professional) {
      _nomeArtisticoController.text = prof?['nomeArtistico'] ?? '';
      _celularController.text = prof?['celular'] ?? '';
      _dataNascimentoController.text = prof?['dataNascimento'] ?? '';
      _generoController.text = prof?['genero'] ?? '';
      _instagramController.text = prof?['instagram'] ?? '';

      _selectedCategories =
          (prof?['categorias'] as List?)?.cast<String>() ?? [];
      _selectedGenres =
          (prof?['generosMusicais'] as List?)?.cast<String>() ?? [];
      _selectedInstruments =
          (prof?['instrumentos'] as List?)?.cast<String>() ?? [];
      _selectedRoles = (prof?['funcoes'] as List?)?.cast<String>() ?? [];
      _backingVocalMode = prof?['backingVocalMode'] ?? '0';
      _instrumentalistBackingVocal = prof?['fazBackingVocal'] ?? false;
    } else if (user.tipoPerfil == AppUserType.studio) {
      _nomeArtisticoController.text = studio?['nomeArtistico'] ?? '';
      _celularController.text = studio?['celular'] ?? '';
      _studioType = studio?['studioType'];
      _selectedServices =
          (studio?['servicosOferecidos'] as List?)?.cast<String>() ?? [];
    } else if (user.tipoPerfil == AppUserType.band) {
      final band = user.dadosBanda;
      _selectedGenres =
          (band?['generosMusicais'] as List?)?.cast<String>() ?? [];
    } else if (user.tipoPerfil == AppUserType.contractor) {
      _celularController.text = contractor?['celular'] ?? '';
      _dataNascimentoController.text = contractor?['dataNascimento'] ?? '';
      _generoController.text = contractor?['genero'] ?? '';
      _instagramController.text = contractor?['instagram'] ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Validations
      if (_currentUser!.tipoPerfil == AppUserType.professional) {
        if (_selectedCategories.isEmpty) {
          _showError('Selecione pelo menos uma Categoria (Atuação).');
          return;
        }
        if (_selectedCategories.contains('instrumentalist') &&
            _selectedInstruments.isEmpty) {
          _showError('Selecione pelo menos um Instrumento.');
          return;
        }
        if (_selectedCategories.contains('crew') && _selectedRoles.isEmpty) {
          _showError('Selecione pelo menos uma Função Técnica.');
          return;
        }
        if (_selectedGenres.isEmpty) {
          _showError('Selecione pelo menos um Gênero Musical.');
          return;
        }
      } else if (_currentUser!.tipoPerfil == AppUserType.band &&
          _selectedGenres.isEmpty) {
        _showError('Selecione pelo menos um Gênero Musical.');
        return;
      }

      final updates = <String, dynamic>{'nome': _nomeController.text.trim()};

      // Normalize Instagram
      final instagramClean = _instagramController.text.trim().replaceAll(
        '@',
        '',
      );

      if (_currentUser!.tipoPerfil == AppUserType.professional) {
        updates['dadosProfissional'] = {
          'nomeArtistico': _nomeArtisticoController.text.trim(),
          'celular': _celularController.text,
          'dataNascimento': _dataNascimentoController.text,
          'genero': _generoController.text,
          'instagram': instagramClean,
          'categorias': _selectedCategories,
          'generosMusicais': _selectedGenres,
          'instrumentos': _selectedInstruments,
          'funcoes': _selectedRoles,
          'backingVocalMode': _backingVocalMode,
          'fazBackingVocal': _instrumentalistBackingVocal,
        };
      } else if (_currentUser!.tipoPerfil == AppUserType.studio) {
        updates['dadosEstudio'] = {
          'nomeArtistico': _nomeController.text.trim(),
          'celular': _celularController.text,
          'studioType': _studioType,
          'servicosOferecidos': _selectedServices,
        };
      } else if (_currentUser!.tipoPerfil == AppUserType.band) {
        updates['dadosBanda'] = {'generosMusicais': _selectedGenres};
      } else if (_currentUser!.tipoPerfil == AppUserType.contractor) {
        updates['dadosContratante'] = {
          'celular': _celularController.text,
          'dataNascimento': _dataNascimentoController.text,
          'genero': _generoController.text,
          'instagram': instagramClean,
        };
      }

      await ref
          .read(profileControllerProvider.notifier)
          .updateProfile(currentUser: _currentUser!, updates: updates);

      if (mounted) {
        AppSnackBar.show(
          context,
          'Perfil atualizado com sucesso!',
          isError: false,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) _showError('Erro ao atualizar perfil: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    AppSnackBar.show(context, message, isError: true);
    setState(() => _isLoading = false);
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Excluir Conta?', style: AppTypography.headlineMedium),
        content: Text(
          'Tem certeza que deseja excluir sua conta? Essa ação não pode ser desfeita.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Excluir',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(profileControllerProvider.notifier).deleteProfile();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = 'Erro ao excluir conta: $e';
        if (e.toString().contains('requires-recent-login')) {
          message =
              'Por segurança, faça login novamente para excluir sua conta.';
        }
        AppSnackBar.show(context, message, isError: true);
      }
    }
  }

  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (_isLoading) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Alterar Foto de Perfil', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.s24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  Icons.camera_alt,
                  'Câmera',
                  () => _handleImageSource(ImageSource.camera),
                ),
                _buildPhotoOption(
                  Icons.photo_library,
                  'Galeria',
                  () => _handleImageSource(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.surfaceHighlight,
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(label, style: AppTypography.bodySmall),
        ],
      ),
    );
  }

  Future<void> _handleImageSource(ImageSource source) async {
    Navigator.pop(context);
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null && _currentUser != null && mounted) {
        setState(() {
          _isLoading = true;
          _isUploadingPhoto = true;
        });

        await ref
            .read(profileControllerProvider.notifier)
            .updateProfileImage(
              file: File(pickedFile.path),
              currentUser: _currentUser!,
            );

        if (mounted) {
          AppSnackBar.show(
            context,
            'Foto atualizada com sucesso!',
            isError: false,
          );
          if (_currentUser?.foto != null)
            NetworkImage(_currentUser!.foto!).evict();

          setState(() {
            _isLoading = false;
            _isUploadingPhoto = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingPhoto = false;
        });
        AppSnackBar.show(
          context,
          'Erro ao selecionar imagem: $e',
          isError: true,
        );
      }
    }
  }

  String _getNameLabel() {
    switch (_currentUser?.tipoPerfil) {
      case AppUserType.band:
        return 'Nome da Banda';
      case AppUserType.studio:
        return 'Nome do Estúdio';
      case AppUserType.contractor:
        return 'Nome do Responsável';
      case AppUserType.professional:
      default:
        return 'Nome Completo';
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProfileProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          setState(() {
            _currentUser = user;
            if (!_isInitialized) {
              _populateFields(user);
              _isInitialized = true;
            }
          });
        }
      });
    });

    if (_currentUser == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Editar Perfil', style: AppTypography.headlineMedium),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: ResponsiveCenter(
            maxContentWidth: 600,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfilePhotoWidget(
                    photoUrl: _currentUser?.foto,
                    isLoading: _isUploadingPhoto,
                    onTap: _pickImage,
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  AppTextField(
                    controller: _nomeController,
                    label: _getNameLabel(),
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [TitleCaseTextInputFormatter()],
                    validator: (v) => v!.isEmpty ? 'Nome obrigatório' : null,
                  ),
                  const SizedBox(height: AppSpacing.s24),

                  // Type Specific Fields
                  if (_currentUser!.tipoPerfil == AppUserType.professional)
                    ProfessionalFormFields(
                      nomeArtisticoController: _nomeArtisticoController,
                      celularController: _celularController,
                      dataNascimentoController: _dataNascimentoController,
                      generoController: _generoController,
                      instagramController: _instagramController,
                      celularMask: _celularMask,
                      selectedCategories: _selectedCategories,
                      selectedGenres: _selectedGenres,
                      selectedInstruments: _selectedInstruments,
                      selectedRoles: _selectedRoles,
                      backingVocalMode: _backingVocalMode,
                      onBackingVocalModeChanged: (v) =>
                          setState(() => _backingVocalMode = v),
                      instrumentalistBackingVocal: _instrumentalistBackingVocal,
                      onInstrumentalistBackingVocalChanged: (v) =>
                          setState(() => _instrumentalistBackingVocal = v),
                      onStateChanged: () => setState(() {}),
                    ),

                  if (_currentUser!.tipoPerfil == AppUserType.studio)
                    StudioFormFields(
                      celularController: _celularController,
                      celularMask: _celularMask,
                      studioType: _studioType,
                      onStudioTypeChanged: (v) =>
                          setState(() => _studioType = v),
                      selectedServices: _selectedServices,
                      onStateChanged: () => setState(() {}),
                    ),

                  if (_currentUser!.tipoPerfil == AppUserType.band)
                    BandFormFields(
                      selectedGenres: _selectedGenres,
                      onStateChanged: () => setState(() {}),
                    ),

                  if (_currentUser!.tipoPerfil == AppUserType.contractor)
                    ContractorFormFields(
                      celularController: _celularController,
                      dataNascimentoController: _dataNascimentoController,
                      generoController: _generoController,
                      instagramController: _instagramController,
                      celularMask: _celularMask,
                      onStateChanged: () => setState(() {}),
                    ),

                  const SizedBox(height: AppSpacing.s32),

                  PrimaryButton(
                    text: _isLoading ? 'Salvando...' : 'Salvar Alterações',
                    onPressed: _isLoading ? null : _saveProfile,
                  ),

                  const SizedBox(height: AppSpacing.s24),

                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _deleteAccount,
                      child: Text(
                        'Excluir Conta',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
