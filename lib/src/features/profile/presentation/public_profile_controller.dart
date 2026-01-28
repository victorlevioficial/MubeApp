import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../design_system/foundations/app_colors.dart';
import '../../../routing/route_paths.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';
import '../../chat/data/chat_repository.dart';
// import '../../feed/data/favorites_provider.dart'; // Removed
import '../domain/media_item.dart';

part 'public_profile_controller.g.dart';

// --- State Class ---

class PublicProfileState {
  final AppUser? user;
  final List<MediaItem> galleryItems;
  final bool isLoading;
  final String? error;

  const PublicProfileState({
    this.user,
    this.galleryItems = const [],
    this.isLoading = true,
    this.error,
  });

  PublicProfileState copyWith({
    AppUser? user,
    List<MediaItem>? galleryItems,
    bool? isLoading,
    String? error,
  }) {
    return PublicProfileState(
      user: user ?? this.user,
      galleryItems: galleryItems ?? this.galleryItems,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nullable override
    );
  }
}

// --- Controller ---

@riverpod
class PublicProfileController extends _$PublicProfileController {
  @override
  FutureOr<PublicProfileState> build(String uid) async {
    // Initial load
    return _loadProfile(uid);
  }

  Future<PublicProfileState> _loadProfile(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return const PublicProfileState(
          isLoading: false,
          error: 'Perfil não encontrado',
        );
      }

      final data = doc.data()!;
      data['uid'] = doc.id;
      final user = AppUser.fromJson(data);

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

      final gallery =
          galleryData
              .map((item) => MediaItem.fromJson(item as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));

      return PublicProfileState(
        user: user,
        galleryItems: gallery,
        isLoading: false,
      );
    } catch (e) {
      return PublicProfileState(
        isLoading: false,
        error: 'Erro ao carregar perfil: $e',
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadProfile(uid));
  }

  Future<void> openChat(BuildContext context) async {
    final currentUser = ref.read(currentUserProfileProvider).value;
    final targetUser = state.value?.user;

    if (currentUser == null || targetUser == null) return;

    try {
      // 1. Calculate conversation ID
      final repository = ref.read(chatRepositoryProvider);
      final conversationId = repository.getConversationId(
        currentUser.uid,
        targetUser.uid,
      );

      // 2. Prepare extra data for optimistic header
      final extra = {
        'otherUserName': targetUser.nome ?? 'Usuário',
        'otherUserPhoto': targetUser.foto,
        'otherUserId': targetUser.uid,
      };

      // 3. Navigate
      if (context.mounted) {
        await context.push(
          '${RoutePaths.conversation}/$conversationId',
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

  // toggleLike method removed
}
