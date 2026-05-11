import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../design_system/foundations/tokens/app_colors.dart';
import '../../../routing/route_paths.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/public_username.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../../chat/data/chat_repository.dart';
import '../../moderation/data/moderation_repository.dart';
import '../domain/media_item.dart';

part 'public_profile_controller.g.dart';

// --- State Class ---

class PublicProfileState {
  final AppUser? user;
  final List<MediaItem> galleryItems;
  final List<AppUser> bandMembers;
  final bool isLoading;
  final String? error;

  const PublicProfileState({
    this.user,
    this.galleryItems = const [],
    this.bandMembers = const [],
    this.isLoading = true,
    this.error,
  });

  PublicProfileState copyWith({
    AppUser? user,
    List<MediaItem>? galleryItems,
    List<AppUser>? bandMembers,
    bool? isLoading,
    String? error,
  }) {
    return PublicProfileState(
      user: user ?? this.user,
      galleryItems: galleryItems ?? this.galleryItems,
      bandMembers: bandMembers ?? this.bandMembers,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable override
    );
  }
}

// --- Controller ---

@riverpod
class PublicProfileController extends _$PublicProfileController {
  static const String _profileNotFoundMessage = 'Perfil n\u00E3o encontrado';

  @override
  FutureOr<PublicProfileState> build(String profileRef) async {
    final viewerAsync = ref.watch(currentUserProfileProvider);
    if (viewerAsync.isLoading) {
      return const PublicProfileState(isLoading: true);
    }

    return _loadProfile(
      profileRef,
      viewer: viewerAsync.hasValue ? viewerAsync.value : null,
    );
  }

  Future<PublicProfileState> _loadProfile(
    String profileRef, {
    AppUser? viewer,
  }) async {
    try {
      final user = await _resolveProfileUser(profileRef);

      if (user == null || !_canViewerAccessProfile(user, viewer)) {
        return const PublicProfileState(
          isLoading: false,
          error: _profileNotFoundMessage,
        );
      }

      // Load gallery items based on user type
      List<dynamic> galleryData = [];
      switch (user.tipoPerfil) {
        case AppUserType.professional:
          galleryData =
              user.dadosProfissional?['gallery'] as List<dynamic>? ?? [];
          break;
        case AppUserType.band:
          galleryData = user.dadosBanda?['gallery'] as List<dynamic>? ?? [];
          break;
        case AppUserType.studio:
          galleryData = user.dadosEstudio?['gallery'] as List<dynamic>? ?? [];
          break;
        case AppUserType.contractor:
          galleryData =
              user.dadosContratante?['gallery'] as List<dynamic>? ?? [];
          break;
        default:
          galleryData = [];
      }

      final gallery = _parseGalleryItems(galleryData);

      final memberIds = user.members
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      if (user.tipoPerfil == AppUserType.band && memberIds.isNotEmpty) {
        unawaited(_loadBandMembers(uid: user.uid, memberIds: memberIds));
      }

      return PublicProfileState(
        user: user,
        galleryItems: gallery,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      if (_looksLikePermissionDenied(e)) {
        return const PublicProfileState(
          isLoading: false,
          error: _profileNotFoundMessage,
        );
      }

      AppLogger.error(
        'Erro ao carregar perfil publico ($profileRef)',
        e,
        stackTrace,
      );
      return PublicProfileState(
        isLoading: false,
        error: 'Erro ao carregar perfil: $e',
      );
    }
  }

  bool _canViewerAccessProfile(AppUser user, AppUser? viewer) {
    if (user.tipoPerfil != AppUserType.contractor) {
      return true;
    }

    final contractorData = user.dadosContratante ?? const <String, dynamic>{};
    final isPublic = contractorData['isPublic'] == true;
    if (isPublic) {
      return true;
    }

    return viewer?.uid == user.uid;
  }

  bool _looksLikePermissionDenied(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('permission-denied') ||
        message.contains('insufficient permissions') ||
        message.contains('missing or insufficient permissions');
  }

  Future<AppUser?> _resolveProfileUser(String profileRef) async {
    if (profileRef.startsWith('@')) {
      final normalizedUsername = normalizedPublicUsernameOrNull(profileRef);
      if (normalizedUsername == null) {
        return null;
      }

      final result = await ref
          .read(authRepositoryProvider)
          .getUserByPublicUsername(normalizedUsername);

      return result.fold((failure) => throw Exception(failure.message), (user) {
        return user;
      });
    }

    return ref.read(authRepositoryProvider).watchUser(profileRef).first;
  }

  List<MediaItem> _parseGalleryItems(List<dynamic> galleryData) {
    final parsed = <MediaItem>[];

    for (final rawItem in galleryData) {
      if (rawItem is! Map) {
        AppLogger.warning(
          'Item de galeria invalido ignorado: ${rawItem.runtimeType}',
        );
        continue;
      }

      try {
        final json = Map<String, dynamic>.from(rawItem);
        parsed.add(MediaItem.fromJson(json));
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Erro ao converter item da galeria para MediaItem',
          e,
          stackTrace,
        );
      }
    }

    parsed.sort((a, b) => a.order.compareTo(b.order));
    return parsed;
  }

  Future<void> _loadBandMembers({
    required String uid,
    required List<String> memberIds,
  }) async {
    final membersResult = await ref
        .read(authRepositoryProvider)
        .getUsersByIds(memberIds);
    if (!ref.mounted) return;

    final currentState = state.asData?.value;
    if (currentState == null || currentState.user?.uid != uid) {
      return;
    }

    membersResult.fold(
      (failure) {
        AppLogger.warning(
          'Falha ao carregar integrantes da banda: ${failure.message}',
        );
      },
      (members) {
        final memberOrder = {
          for (int i = 0; i < memberIds.length; i++) memberIds[i]: i,
        };
        members.sort(
          (a, b) => (memberOrder[a.uid] ?? memberIds.length).compareTo(
            memberOrder[b.uid] ?? memberIds.length,
          ),
        );
        state = AsyncData(currentState.copyWith(bandMembers: members));
      },
    );
  }

  Future<void> refresh() async {
    final currentUserAsync = ref.read(currentUserProfileProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _loadProfile(
        profileRef,
        viewer: currentUserAsync.hasValue ? currentUserAsync.value : null,
      ),
    );
  }

  Future<void> openChat(BuildContext context) async {
    final currentUserAsync = ref.read(currentUserProfileProvider);
    final currentUser = currentUserAsync.hasValue
        ? currentUserAsync.value
        : null;
    final targetUser = state.value?.user;

    if (currentUser == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entre para iniciar uma conversa.')),
        );
        await context.push(RoutePaths.register);
      }
      return;
    }

    if (targetUser == null) return;
    if (currentUser.uid == targetUser.uid) return;

    try {
      final repository = ref.read(chatRepositoryProvider);
      final conversationId = repository.getConversationId(
        currentUser.uid,
        targetUser.uid,
      );

      final extra = {
        'otherUserName': targetUser.appDisplayName.isNotEmpty
            ? targetUser.appDisplayName
            : (targetUser.nome ?? 'Usuario'),
        'otherUserPhoto': targetUser.foto,
        'otherUserId': targetUser.uid,
        'conversationType': 'direct',
      };

      if (context.mounted) {
        await context.push(
          RoutePaths.conversationById(conversationId),
          extra: extra,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao abrir conversa: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<bool> blockUser() async {
    final currentUserAsync = ref.read(currentUserProfileProvider);
    final currentUser = currentUserAsync.hasValue
        ? currentUserAsync.value
        : null;
    final targetUser = state.value?.user;

    if (currentUser == null || targetUser == null) return false;

    final result = await ref
        .read(moderationRepositoryProvider)
        .blockUser(
          currentUserId: currentUser.uid,
          blockedUserId: targetUser.uid,
        );

    return result.fold((failure) => false, (_) => true);
  }

  Future<bool> reportUser(String reason, String? description) async {
    final currentUserAsync = ref.read(currentUserProfileProvider);
    final currentUser = currentUserAsync.hasValue
        ? currentUserAsync.value
        : null;
    final targetUser = state.value?.user;

    if (currentUser == null || targetUser == null) return false;

    final result = await ref
        .read(moderationRepositoryProvider)
        .reportUser(
          reporterId: currentUser.uid,
          reportedUserId: targetUser.uid,
          reason: reason,
          description: description,
        );

    return result.fold((failure) => false, (_) => true);
  }

  // toggleLike method removed
}
