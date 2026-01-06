import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:uuid/uuid.dart';

import '../../../common_widgets/app_snackbar.dart';
import '../../../common_widgets/app_text_field.dart';
import '../../../common_widgets/primary_button.dart';
import '../../../design_system/foundations/app_colors.dart';
import '../../../design_system/foundations/app_spacing.dart';
import '../../../design_system/foundations/app_typography.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../../storage/data/storage_repository.dart';
import '../domain/media_item.dart';
import 'profile_controller.dart';
import 'services/media_picker_service.dart';
import 'widgets/band_form_fields.dart';
import 'widgets/contractor_form_fields.dart';
import 'widgets/gallery_grid.dart';
import 'widgets/professional_form_fields.dart';
import 'widgets/profile_photo_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _nomeArtisticoController.dispose();
    _celularController.dispose();
    _dataNascimentoController.dispose();
    _generoController.dispose();
    _instagramController.dispose();
    _mediaPickerService.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Descartar alterações?', style: AppTypography.titleMedium),
        content: Text(
          'Você tem alterações não salvas. Deseja realmente sair sem salvar?',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Continuar editando',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Descartar',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
    if (_isInitialized) return;
    _isInitialized = true;

    _nomeController.text = user.nome ?? '';

    // Pre-cache avatar photo for instant display
    if (user.foto != null && user.foto!.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(user.foto!), context);
    }

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
        precacheImage(CachedNetworkImageProvider(imageUrl), context);
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
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _handleAddPhoto(AppUser user) async {
    // Check limits before opening picker
    if (_galleryItems.length >= _maxTotal) {
      AppSnackBar.warning(context, 'Limite máximo da galeria atingido.');
      return;
    }
    if (_photoCount >= _maxPhotos) {
      AppSnackBar.warning(
        context,
        'Você já atingiu o limite de $_maxPhotos fotos.',
      );
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
      if (file == null) {
        setState(() => _isUploadingMedia = false);
        return;
      }

      setState(() => _uploadStatus = 'Enviando foto...');

      final mediaId = const Uuid().v4();
      final storage = ref.read(storageRepositoryProvider);

      final url = await storage.uploadGalleryMedia(
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
    } catch (e) {
      setState(() {
        _isUploadingMedia = false;
        _uploadProgress = 0.0;
      });
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao adicionar foto: $e');
      }
    }
  }

  Future<void> _handleAddVideo(AppUser user) async {
    // Check limits before opening picker
    if (_galleryItems.length >= _maxTotal) {
      AppSnackBar.warning(context, 'Limite máximo da galeria atingido.');
      return;
    }
    if (_videoCount >= _maxVideos) {
      AppSnackBar.warning(
        context,
        'Você já atingiu o limite de $_maxVideos vídeos.',
      );
      return;
    }

    setState(() {
      _isUploadingMedia = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Processando vídeo...';
    });

    try {
      final result = await _mediaPickerService.pickAndProcessVideo(context);
      if (result == null) {
        setState(() => _isUploadingMedia = false);
        return;
      }

      final (videoFile, thumbnailFile) = result;
      final mediaId = const Uuid().v4();
      final storage = ref.read(storageRepositoryProvider);

      setState(() => _uploadStatus = 'Enviando vídeo...');

      // Upload video
      final videoUrl = await storage.uploadGalleryMedia(
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

      setState(() => _uploadStatus = 'Enviando thumbnail...');

      // Upload thumbnail
      final thumbUrl = await storage.uploadVideoThumbnail(
        userId: user.uid,
        mediaId: mediaId,
        thumbnail: thumbnailFile,
      );

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
    } catch (e) {
      setState(() {
        _isUploadingMedia = false;
        _uploadProgress = 0.0;
      });
      if (mounted) {
        AppSnackBar.error(context, 'Erro ao adicionar vídeo: $e');
      }
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

  Future<void> _saveProfile(AppUser user) async {
    // Only validate form if we're on profile tab and form exists
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final Map<String, dynamic> updates = {'nome': _nomeController.text.trim()};

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

      case AppUserType.studio:
        updates['dadosEstudio'] = {
          'nomeArtistico': _nomeArtisticoController.text.trim(),
          'celular': _celularController.text.trim(),
          'studioType': _studioType,
          'servicosOferecidos': _selectedServices,
          'gallery': _galleryToJson(),
        };

      case AppUserType.band:
        updates['dadosBanda'] = {
          'generosMusicais': _bandGenres,
          'gallery': _galleryToJson(),
        };

      case AppUserType.contractor:
        updates['dadosContratante'] = {
          'celular': _celularController.text.trim(),
          'dataNascimento': _dataNascimentoController.text.trim(),
          'genero': _generoController.text.trim(),
          'instagram': _instagramController.text.trim(),
        };

      default:
        break;
    }

    await ref
        .read(profileControllerProvider.notifier)
        .updateProfile(currentUser: user, updates: updates);

    if (mounted) {
      AppSnackBar.success(context, 'Perfil atualizado!');
      context.pop();
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
            appBar: AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: _handleBack,
              ),
              title: Text('Editar Perfil', style: AppTypography.titleMedium),
              centerTitle: true,
              bottom: isContractor
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: AppTypography.bodyMedium,
                          indicator: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          padding: const EdgeInsets.all(4),
                          tabs: const [
                            Tab(text: 'Perfil'),
                            Tab(text: 'Mídia'),
                          ],
                        ),
                      ),
                    ),
            ),
            body: isContractor
                ? _buildProfileTab(user)
                : TabBarView(
                    controller: _tabController,
                    children: [_buildProfileTab(user), _buildMediaTab(user)],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Photo
            Center(
              child: ProfilePhotoWidget(
                photoUrl: user.foto,
                isLoading: ref.watch(profileControllerProvider).isLoading,
                onTap: () async {
                  final picker = MediaPickerService();
                  final file = await picker.pickAndCropPhoto(context);
                  if (file != null) {
                    await ref
                        .read(profileControllerProvider.notifier)
                        .updateProfileImage(file: file, currentUser: user);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s32),

            // Name
            AppTextField(
              controller: _nomeController,
              label: 'Nome Completo',
              textCapitalization: TextCapitalization.words,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              onChanged: (_) => _markChanged(),
            ),
            const SizedBox(height: AppSpacing.s16),

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
                onStateChanged: () {
                  setState(() {});
                  _markChanged();
                },
              ),

            if (user.tipoPerfil == AppUserType.band)
              BandFormFields(
                selectedGenres: _bandGenres,
                onStateChanged: () {
                  setState(() {});
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
                onStateChanged: () {
                  setState(() {});
                  _markChanged();
                },
              ),

            const SizedBox(height: AppSpacing.s48),

            // Save button at bottom
            PrimaryButton(
              text: 'Salvar Alterações',
              isLoading: ref.watch(profileControllerProvider).isLoading,
              onPressed: _hasChanges ? () => _saveProfile(user) : null,
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
          child: PrimaryButton(
            text: 'Salvar Alterações',
            isLoading: ref.watch(profileControllerProvider).isLoading,
            onPressed: _hasChanges ? () => _saveProfile(user) : null,
          ),
        ),
      ],
    );
  }
}
