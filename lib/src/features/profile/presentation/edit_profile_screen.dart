import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';

import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/feedback/app_confirmation_dialog.dart';
import '../../../design_system/components/feedback/app_snackbar.dart';
import '../../../design_system/components/inputs/app_text_field.dart';
import '../../../design_system/components/navigation/app_app_bar.dart';
import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../design_system/foundations/tokens/app_spacing.dart';
import '../../../design_system/foundations/tokens/app_typography.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../../storage/data/storage_repository.dart';
import '../domain/media_item.dart';
import 'profile_controller.dart';
import 'public_profile_controller.dart';
import 'services/media_picker_service.dart';
import 'widgets/band_form_fields.dart';
import 'widgets/contractor_form_fields.dart';
import 'widgets/gallery_grid.dart';
import 'widgets/professional_form_fields.dart';
import 'widgets/studio_form_fields.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _mediaPickerService = MediaPickerService();

  // Common controllers
  final _nomeController = TextEditingController();
  final _nomeArtisticoController = TextEditingController();
  final _celularController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _generoController = TextEditingController();
  final _instagramController = TextEditingController();
  final _bioController = TextEditingController();

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  // Professional specific
  List<String> _selectedCategories = [];
  List<String> _selectedGenres = [];
  List<String> _selectedInstruments = [];
  List<String> _selectedRoles = [];
  String _backingVocalMode = '0';
  bool _instrumentalistBackingVocal = false;

  // Studio specific
  String? _studioType;
  List<String> _selectedServices = [];

  // Band specific
  List<String> _bandGenres = [];

  // Gallery
  List<MediaItem> _galleryItems = [];
  bool _isUploadingMedia = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Gallery limits
  static const int _maxPhotos = 6;
  static const int _maxVideos = 3;
  static const int _maxTotal = 9;

  int get _photoCount =>
      _galleryItems.where((i) => i.type == MediaType.photo).length;
  int get _videoCount =>
      _galleryItems.where((i) => i.type == MediaType.video).length;

  bool _hasChanges = false;
  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    // Reset initialization flag so data reloads on next screen visit
    _isInitialized = false;
    _tabController.dispose();
    _nomeController.dispose();
    _nomeArtisticoController.dispose();
    _celularController.dispose();
    _dataNascimentoController.dispose();
    _generoController.dispose();
    _instagramController.dispose();
    _bioController.dispose();
    _mediaPickerService.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => const AppConfirmationDialog(
        title: 'Descartar alterações?',
        message:
            'Você tem alterações não salvas. Deseja realmente sair sem salvar?',
        confirmText: 'Descartar',
        cancelText: 'Continuar editando',
        isDestructive: true,
      ),
    );

    return shouldLeave ?? false;
  }

  void _handleBack() async {
    if (await _onWillPop()) {
      if (mounted) context.pop();
    }
  }

  void _initializeFromUser(AppUser user) {
    // Guard against re-initialization during rebuilds (e.g., when selecting items)
    // Flag is reset in dispose() to allow fresh data load on next screen visit
    if (_isInitialized) return;
    _isInitialized = true;

    _nomeController.text = user.nome ?? '';

    // Pre-cache removed to improve stability
    // if (user.foto != null && user.foto!.isNotEmpty) { ... }

    _bioController.text = user.bio ?? '';

    // Initialize type-specific data
    switch (user.tipoPerfil) {
      case AppUserType.professional:
        final data = user.dadosProfissional ?? {};
        _nomeArtisticoController.text = data['nomeArtistico'] ?? '';
        _celularController.text = data['celular'] ?? '';
        _dataNascimentoController.text = data['dataNascimento'] ?? '';
        _generoController.text = data['genero'] ?? '';
        _instagramController.text = data['instagram'] ?? '';
        _selectedCategories = List<String>.from(data['categorias'] ?? []);
        _selectedGenres = List<String>.from(data['generosMusicais'] ?? []);
        _selectedInstruments = List<String>.from(data['instrumentos'] ?? []);
        _selectedRoles = List<String>.from(data['funcoes'] ?? []);
        _backingVocalMode = (data['backingVocalMode'] ?? '0').toString();
        _instrumentalistBackingVocal =
            data['instrumentalistBackingVocal'] ?? false;
        _loadGallery(data['gallery']);

      case AppUserType.studio:
        final data = user.dadosEstudio ?? {};
        _nomeArtisticoController.text = data['nomeArtistico'] ?? '';
        _celularController.text = data['celular'] ?? '';
        _studioType = data['studioType'];
        _selectedServices = List<String>.from(data['servicosOferecidos'] ?? []);
        _loadGallery(data['gallery']);

      case AppUserType.band:
        final data = user.dadosBanda ?? {};
        _bandGenres = List<String>.from(data['generosMusicais'] ?? []);
        _loadGallery(data['gallery']);

      case AppUserType.contractor:
        final data = user.dadosContratante ?? {};
        _celularController.text = data['celular'] ?? '';
        _dataNascimentoController.text = data['dataNascimento'] ?? '';
        _generoController.text = data['genero'] ?? '';
        _instagramController.text = data['instagram'] ?? '';

      default:
        break;
    }
  }

  void _loadGallery(dynamic galleryData) {
    if (galleryData == null) return;
    final List<dynamic> items = galleryData as List<dynamic>;
    _galleryItems = items.map((item) {
      final map = item as Map<String, dynamic>;
      return MediaItem(
        id: map['id'] ?? const Uuid().v4(),
        url: map['url'] ?? '',
        type: map['type'] == 'video' ? MediaType.video : MediaType.photo,
        thumbnailUrl: map['thumbnailUrl'],
        order: map['order'] ?? 0,
      );
    }).toList();
    _galleryItems.sort((a, b) => a.order.compareTo(b.order));

    // Pre-cache gallery images for instant display
    _precacheGalleryImages();
  }

  void _precacheGalleryImages() {
    for (final item in _galleryItems) {
      final imageUrl = item.type == MediaType.video
          ? item.thumbnailUrl ?? item.url
          : item.url;

      if (imageUrl.isNotEmpty) {
        // Validate URL before attempting to load
        final uri = Uri.tryParse(imageUrl);
        if (uri == null || !uri.hasAbsolutePath) {
          AppLogger.warning('Invalid gallery URL skipped: $imageUrl');
          continue;
        }

        try {
          precacheImage(
            CachedNetworkImageProvider(imageUrl),
            context,
          ).catchError((e) {
            AppLogger.warning('Failed to precache image: $imageUrl', e);
          });
        } catch (e) {
          AppLogger.warning('Error initiating precache for: $imageUrl', e);
        }
      }
    }
  }

  List<Map<String, dynamic>> _galleryToJson() {
    return _galleryItems.asMap().entries.map((entry) {
      final item = entry.value;
      return {
        'id': item.id,
        'url': item.url,
        'type': item.type == MediaType.video ? 'video' : 'photo',
        'thumbnailUrl': item.thumbnailUrl,
        'order': entry.key,
      };
    }).toList();
  }

  void _markChanged() {
    // Don't mark as changed during save operation
    if (_isSaving) return;
    if (!_hasChanges) {
      AppLogger.info('Marking as changed');
      if (mounted) {
        setState(() => _hasChanges = true);
      }
    }
  }

  Future<void> _handleAddPhoto(AppUser user) async {
    // Check limits before opening picker
    if (_galleryItems.length >= _maxTotal) {
      if (mounted) {
        AppSnackBar.warning(context, 'Limite máximo da galeria atingido.');
      }
      return;
    }
    if (_photoCount >= _maxPhotos) {
      if (mounted) {
        AppSnackBar.warning(
          context,
          'Você já atingiu o limite de $_maxPhotos fotos.',
        );
      }
      return;
    }

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Processando foto...';
    });

    try {
      final file = await _mediaPickerService.pickAndCropPhoto(
        context,
        lockAspectRatio: false,
      );

      if (!context.mounted) return; // EARLY EXIT if unmounted

      if (file == null) {
        setState(() => _isUploadingMedia = false);
        return;
      }

      setState(() => _uploadStatus = 'Enviando foto...');

      final mediaId = const Uuid().v4();
      final storage = ref.read(storageRepositoryProvider);

      final mediaUrls = await storage.uploadGalleryMediaWithSizes(
        userId: user.uid,
        file: file,
        mediaId: mediaId,
        isVideo: false,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      final url = mediaUrls.full ?? '';

      if (!context.mounted) return;

      setState(() {
        _galleryItems.add(
          MediaItem(
            id: mediaId,
            url: url,
            type: MediaType.photo,
            order: _galleryItems.length,
          ),
        );
        _hasChanges = true;
        _isUploadingMedia = false;
        _uploadProgress = 0.0;
      });

      // Invalidate profile provider to refresh gallery on profile screen
      ref.invalidate(publicProfileControllerProvider(user.uid));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingMedia = false;
        _uploadProgress = 0.0;
      });

      AppSnackBar.error(context, 'Erro ao adicionar foto: $e');
    }
  }

  Future<void> _handleAddVideo(AppUser user) async {
    // Check limits before opening picker
    if (_galleryItems.length >= _maxTotal) {
      if (context.mounted) {
        AppSnackBar.warning(context, 'Limite máximo da galeria atingido.');
      }
      return;
    }
    if (_videoCount >= _maxVideos) {
      if (context.mounted) {
        AppSnackBar.warning(
          context,
          'Você já atingiu o limite de $_maxVideos vídeos.',
        );
      }
      return;
    }

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Processando vídeo...';
    });

    try {
      final result = await _mediaPickerService.pickAndProcessVideo(context);

      if (!mounted) return;

      if (result == null) {
        setState(() => _isUploadingMedia = false);
        return;
      }

      final (videoFile, thumbnailFile) = result;
      final mediaId = const Uuid().v4();
      final storage = ref.read(storageRepositoryProvider);

      setState(() => _uploadStatus = 'Enviando vídeo...');

      // Upload video
      final mediaUrls = await storage.uploadGalleryMediaWithSizes(
        userId: user.uid,
        file: videoFile,
        mediaId: mediaId,
        isVideo: true,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress * 0.9); // 90% for video
          }
        },
      );

      final videoUrl = mediaUrls.full ?? '';

      if (!mounted) return;

      setState(() => _uploadStatus = 'Enviando thumbnail...');

      // Upload thumbnail
      final thumbUrl = await storage.uploadVideoThumbnail(
        userId: user.uid,
        mediaId: mediaId,
        thumbnail: thumbnailFile,
      );

      if (!mounted) return;

      setState(() {
        _uploadProgress = 1.0;
        _galleryItems.add(
          MediaItem(
            id: mediaId,
            url: videoUrl,
            type: MediaType.video,
            thumbnailUrl: thumbUrl,
            order: _galleryItems.length,
          ),
        );
        _hasChanges = true;
        _isUploadingMedia = false;
        _uploadProgress = 0.0;
      });

      // Invalidate profile provider to refresh gallery on profile screen
      ref.invalidate(publicProfileControllerProvider(user.uid));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingMedia = false;
        _uploadProgress = 0.0;
      });
      AppSnackBar.error(context, 'Erro ao adicionar vídeo: $e');
    }
  }

  Future<void> _handleRemoveMedia(int index, AppUser user) async {
    final item = _galleryItems[index];

    // Delete from storage
    try {
      await ref
          .read(storageRepositoryProvider)
          .deleteGalleryItem(
            userId: user.uid,
            mediaId: item.id,
            isVideo: item.type == MediaType.video,
          );
    } catch (_) {
      // Ignore storage deletion errors
    }

    setState(() {
      _galleryItems.removeAt(index);
      _hasChanges = true;
    });
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _galleryItems.removeAt(oldIndex);
      _galleryItems.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  bool _validateData(AppUser user) {
    AppLogger.info('_validateData: tipoPerfil=${user.tipoPerfil}');

    if (user.tipoPerfil == AppUserType.professional) {
      if (_selectedCategories.isEmpty) {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'Selecione pelo menos uma categoria (Cantor, Instrumentista ou Equipe Técnica).',
          );
        }
        return false;
      }

      if (_selectedCategories.contains('instrumentalist') &&
          _selectedInstruments.isEmpty) {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'Selecione pelo menos um instrumento para continuar.',
          );
        }
        return false;
      }

      if (_selectedCategories.contains('crew') && _selectedRoles.isEmpty) {
        if (context.mounted) {
          AppSnackBar.error(
            context,
            'Selecione pelo menos uma função técnica para continuar.',
          );
        }
        return false;
      }

      if (_selectedGenres.isEmpty) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Selecione pelo menos um gênero musical.');
        }
        return false;
      }
    } else if (user.tipoPerfil == AppUserType.band) {
      if (_bandGenres.isEmpty) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Selecione pelo menos um gênero musical.');
        }
        return false;
      }
    } else if (user.tipoPerfil == AppUserType.studio) {
      if (_selectedServices.isEmpty) {
        if (context.mounted) {
          AppSnackBar.error(context, 'Selecione pelo menos um serviço.');
        }
        return false;
      }
    }

    return true;
  }

  Future<void> _saveProfile(AppUser user) async {
    AppLogger.info('=== _saveProfile START ===');

    if (_isSaving) return;
    if (!mounted) return;

    // Capture values needed for async operations
    final profileController = ref.read(profileControllerProvider.notifier);

    // Validate first (sync)
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      AppLogger.info('Form validation failed');
      return;
    }

    if (!_validateData(user)) {
      AppLogger.info('Business rule validation failed');
      return;
    }

    setState(() => _isSaving = true);

    // Build updates map
    final Map<String, dynamic> updates = {
      'nome': _nomeController.text.trim(),
      'bio': _bioController.text.trim(),
    };

    switch (user.tipoPerfil) {
      case AppUserType.professional:
        updates['dadosProfissional'] = {
          'nomeArtistico': _nomeArtisticoController.text.trim(),
          'celular': _celularController.text.trim(),
          'dataNascimento': _dataNascimentoController.text.trim(),
          'genero': _generoController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'categorias': _selectedCategories,
          'generosMusicais': _selectedGenres,
          'instrumentos': _selectedInstruments,
          'funcoes': _selectedRoles,
          'backingVocalMode': _backingVocalMode,
          'instrumentalistBackingVocal': _instrumentalistBackingVocal,
          'gallery': _galleryToJson(),
        };
        break;

      case AppUserType.studio:
        updates['dadosEstudio'] = {
          'nomeArtistico': _nomeArtisticoController.text.trim(),
          'celular': _celularController.text.trim(),
          'studioType': _studioType,
          'servicosOferecidos': _selectedServices,
          'gallery': _galleryToJson(),
        };
        break;

      case AppUserType.band:
        updates['dadosBanda'] = {
          'nomeArtistico': _nomeController.text.trim(),
          'bio': _bioController.text.trim(),
          'generosMusicais': _bandGenres,
          'gallery': _galleryToJson(),
        };
        break;

      case AppUserType.contractor:
        updates['dadosContratante'] = {
          'celular': _celularController.text.trim(),
          'dataNascimento': _dataNascimentoController.text.trim(),
          'genero': _generoController.text.trim(),
          'instagram': _instagramController.text.trim(),
        };
        break;

      default:
        break;
    }

    try {
      await profileController.updateProfile(
        currentUser: user,
        updates: updates,
      );

      // CRITICAL: Check mounted (State property) after await
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _hasChanges = false;
        _isInitialized = false; // Force reload on next visit
      });

      // Now it is safe to use context because mounted is true
      if (context.mounted) {
        AppSnackBar.success(context, 'Perfil atualizado com sucesso!');
      }
    } catch (e, st) {
      AppLogger.error('Erro ao salvar perfil', e, st);

      // CRITICAL: Check mounted (State property) after error
      if (!mounted) return;

      setState(() => _isSaving = false);

      final errorMessage = e.toString().toLowerCase();
      // Don't show technical errors if it's just a provider disposal (race condition)
      if (!errorMessage.contains('disposed') && context.mounted) {
        AppSnackBar.error(context, 'Erro ao salvar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProfileProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Usuário não encontrado')),
          );
        }

        _initializeFromUser(user);

        final isContractor = user.tipoPerfil == AppUserType.contractor;

        return PopScope(
          canPop: !_hasChanges,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            _handleBack();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppAppBar(
              title: 'Editar Perfil',
              showBackButton: true,
              onBackPressed: _handleBack,
            ),
            body: Column(
              children: [
                // Custom Rounded TabBar
                if (!isContractor)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(100), // Fully rounded
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: AppTypography.bodyMedium,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          100,
                        ), // Fully rounded
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(text: 'Perfil'),
                        Tab(text: 'Mídia & Portfólio'),
                      ],
                    ),
                  ),

                // Content
                Expanded(
                  child: isContractor
                      ? _buildProfileTab(user)
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildProfileTab(user),
                            _buildMediaTab(user),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Photo
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: AppColors.surface,
                      backgroundImage: user.foto != null
                          ? CachedNetworkImageProvider(user.foto!)
                          : null,
                      child: user.foto == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.textSecondary,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        // Capture controller and messenger before async gap
                        final controller = ref.read(
                          profileControllerProvider.notifier,
                        );
                        final messenger = ScaffoldMessenger.of(context);

                        final picker = MediaPickerService();
                        final file = await picker.pickAndCropPhoto(context);
                        if (file != null) {
                          try {
                            await controller.updateProfileImage(
                              file: file,
                              currentUser: user,
                            );
                            if (mounted) {
                              AppSnackBar.success(context, 'Foto atualizada!');
                            }
                          } catch (e) {
                            // Ignore disposed provider errors
                            final isDisposedError = e
                                .toString()
                                .toLowerCase()
                                .contains('disposed');
                            if (!isDisposedError && mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Erro ao atualizar foto: $e'),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s32),

            // --- NAME FIELDS SECTION START ---
            if (user.tipoPerfil == AppUserType.professional) ...[
              // Professional: Nome Artístico is already in ProfessionalFormFields below.
              // Only showing Private Name here.
              AppTextField(
                controller: _nomeController,
                label: 'Nome Completo (Privado)',
                hint: 'Seu nome real',
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onChanged: (_) => _markChanged(),
              ),
            ] else if (user.tipoPerfil == AppUserType.studio) ...[
              // Studio: Studio Name (Primary) + Responsible Name (Private)
              AppTextField(
                controller: _nomeArtisticoController,
                label: 'Nome do Estúdio (Público)',
                hint: 'Nome do seu estúdio',
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onChanged: (_) => _markChanged(),
              ),
              const SizedBox(height: AppSpacing.s16),
              AppTextField(
                controller: _nomeController,
                label: 'Nome do Responsável (Privado)',
                hint: 'Nome do proprietário/gerente',
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onChanged: (_) => _markChanged(),
              ),
            ] else if (user.tipoPerfil == AppUserType.band) ...[
              // Band: Band Name (Primary) - No Private Name
              AppTextField(
                controller: _nomeController,
                label: 'Nome da Banda (Público)',
                hint: 'Nome da sua banda',
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onChanged: (_) => _markChanged(),
              ),
            ] else if (user.tipoPerfil == AppUserType.contractor) ...[
              // Contractor: Full Name (Primary)
              AppTextField(
                controller: _nomeController,
                label: 'Nome Completo (Privado)',
                hint: 'Seu nome ou da empresa',
                textCapitalization: TextCapitalization.words,
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                onChanged: (_) => _markChanged(),
              ),
            ],
            // --- NAME FIELDS SECTION END ---
            const SizedBox(height: AppSpacing.s16),

            // Bio Field (Professional, Band, Studio)
            if (user.tipoPerfil == AppUserType.professional ||
                user.tipoPerfil == AppUserType.band ||
                user.tipoPerfil == AppUserType.studio) ...[
              AppTextField(
                controller: _bioController,
                label: 'Biografia',
                hint: user.tipoPerfil == AppUserType.band
                    ? 'Conte um pouco sobre a banda...'
                    : user.tipoPerfil == AppUserType.studio
                    ? 'Conte um pouco sobre o estúdio...'
                    : 'Conte um pouco sobre você...',
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => _markChanged(),
              ),
              const SizedBox(height: AppSpacing.s16),
            ],

            // Type-specific fields
            if (user.tipoPerfil == AppUserType.professional)
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
                onBackingVocalModeChanged: (v) {
                  setState(() => _backingVocalMode = v);
                  _markChanged();
                },
                instrumentalistBackingVocal: _instrumentalistBackingVocal,
                onInstrumentalistBackingVocalChanged: (v) {
                  setState(() => _instrumentalistBackingVocal = v);
                  _markChanged();
                },
                onStateChanged: () {
                  setState(() {});
                  _markChanged();
                },
                onInstrumentsChanged: (newInstruments) {
                  AppLogger.info(
                    '🔧 onInstrumentsChanged called: $newInstruments',
                  );
                  setState(() {
                    _selectedInstruments
                      ..clear()
                      ..addAll(newInstruments);
                  });
                  AppLogger.info(
                    '🔧 _selectedInstruments after: $_selectedInstruments',
                  );
                  _markChanged();
                },
                onRolesChanged: (newRoles) {
                  AppLogger.info('⚙️ onRolesChanged called: $newRoles');
                  setState(() {
                    _selectedRoles
                      ..clear()
                      ..addAll(newRoles);
                  });
                  AppLogger.info('⚙️ _selectedRoles after: $_selectedRoles');
                  _markChanged();
                },
                onGenresChanged: (newGenres) {
                  AppLogger.info('🎵 onGenresChanged called: $newGenres');
                  setState(() {
                    _selectedGenres
                      ..clear()
                      ..addAll(newGenres);
                  });
                  AppLogger.info('🎵 _selectedGenres after: $_selectedGenres');
                  _markChanged();
                },
                onCategoriesChanged: (newCategories) {
                  setState(() {
                    // Clear instruments if instrumentalist was removed
                    if (!newCategories.contains('instrumentalist')) {
                      _selectedInstruments.clear();
                      _instrumentalistBackingVocal = false;
                    }
                    // Clear roles if crew was removed
                    if (!newCategories.contains('crew')) {
                      _selectedRoles.clear();
                    }
                    // Clear backing vocal mode if singer was removed
                    if (!newCategories.contains('singer')) {
                      _backingVocalMode = '0';
                    }
                    // Update categories
                    _selectedCategories
                      ..clear()
                      ..addAll(newCategories);
                  });
                  _markChanged();
                },
              ),

            if (user.tipoPerfil == AppUserType.studio)
              StudioFormFields(
                celularController: _celularController,
                celularMask: _celularMask,
                studioType: _studioType,
                onStudioTypeChanged: (v) {
                  setState(() => _studioType = v);
                  _markChanged();
                },
                selectedServices: _selectedServices,
                onServicesChanged: (newServices) {
                  setState(() {
                    _selectedServices
                      ..clear()
                      ..addAll(newServices);
                  });
                  _markChanged();
                },
              ),

            if (user.tipoPerfil == AppUserType.band)
              BandFormFields(
                selectedGenres: _bandGenres,
                onGenresChanged: (newGenres) {
                  setState(() {
                    _bandGenres
                      ..clear()
                      ..addAll(newGenres);
                  });
                  _markChanged();
                },
              ),

            if (user.tipoPerfil == AppUserType.contractor)
              ContractorFormFields(
                celularController: _celularController,
                dataNascimentoController: _dataNascimentoController,
                generoController: _generoController,
                instagramController: _instagramController,
                celularMask: _celularMask,
                onChanged: () {
                  _markChanged();
                },
              ),

            const SizedBox(height: AppSpacing.s48),

            // Save button at bottom
            AppButton.primary(
              text: 'Salvar Alterações',
              isLoading: _isSaving,
              onPressed: _hasChanges ? () => _saveProfile(user) : null,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTab(AppUser user) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: GalleryGrid(
              items: _galleryItems,
              maxSlots: 9,
              maxVideos: 3,
              onAddPhoto: () => _handleAddPhoto(user),
              onAddVideo: () => _handleAddVideo(user),
              onRemove: (index) => _handleRemoveMedia(index, user),
              onReorder: _handleReorder,
              isUploading: _isUploadingMedia,
              uploadProgress: _uploadProgress,
              uploadStatus: _uploadStatus,
            ),
          ),
        ),
        // Bottom CTA button
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: AppButton.primary(
            text: 'Salvar Alterações',
            isLoading: _isSaving,
            onPressed: _hasChanges ? () => _saveProfile(user) : null,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
