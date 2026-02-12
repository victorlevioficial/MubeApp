import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/analytics/analytics_provider.dart';
import '../../../shared/services/content_moderation_service.dart';
import '../../../utils/app_logger.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../storage/data/storage_repository.dart';

part 'profile_controller.g.dart';

@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  @override
  FutureOr<void> build() {
    // No initial state to load beyond what's passed or available in auth
  }

  Future<void> updateProfile({
    required AppUser currentUser,
    required Map<String, dynamic> updates,
  }) async {
    final authRepo = ref.read(authRepositoryProvider);
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final updatedDadosProfissional = Map<String, dynamic>.from(
        currentUser.dadosProfissional ?? {},
      );
      if (updates.containsKey('dadosProfissional')) {
        updatedDadosProfissional.addAll(updates['dadosProfissional']);
      }

      final updatedDadosEstudio = Map<String, dynamic>.from(
        currentUser.dadosEstudio ?? {},
      );
      if (updates.containsKey('dadosEstudio')) {
        updatedDadosEstudio.addAll(updates['dadosEstudio']);
      }

      final updatedDadosBanda = Map<String, dynamic>.from(
        currentUser.dadosBanda ?? {},
      );
      if (updates.containsKey('dadosBanda')) {
        updatedDadosBanda.addAll(updates['dadosBanda']);
      }

      final updatedDadosContratante = Map<String, dynamic>.from(
        currentUser.dadosContratante ?? {},
      );
      if (updates.containsKey('dadosContratante')) {
        updatedDadosContratante.addAll(updates['dadosContratante']);
      }

      final updatedUser = currentUser.copyWith(
        nome: updates['nome'] ?? currentUser.nome,
        bio: updates['bio'] ?? currentUser.bio,
        location: updates['location'] ?? currentUser.location,
        foto: updates['foto'] ?? currentUser.foto,
        dadosProfissional: updatedDadosProfissional,
        dadosEstudio: updatedDadosEstudio,
        dadosBanda: updatedDadosBanda,
        dadosContratante: updatedDadosContratante,
      );

      final result = await authRepo.updateUser(updatedUser);

      return result.fold((failure) => throw failure.message, (_) {
        unawaited(
          ref
              .read(analyticsServiceProvider)
              .logProfileEdit(userId: currentUser.uid),
        );
        return null;
      });
    });
  }

  Future<void> updateProfileImage({
    required File file,
    required AppUser currentUser,
  }) async {
    final storageRepo = ref.read(storageRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final moderationTest = ref.read(contentModerationServiceProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      AppLogger.info(
        'Profile image update started for user: ${currentUser.uid}',
      );
      await moderationTest.validateImage(file);

      final imageUrls = await storageRepo.uploadProfileImageWithSizes(
        userId: currentUser.uid,
        file: file,
      );

      final photoUrl = imageUrls.full;
      if (photoUrl == null || photoUrl.isEmpty) {
        throw Exception('Upload retornou URL de foto vazia');
      }

      final updatedPhotoUrl = _withCacheBuster(photoUrl);
      final updatedUser = currentUser.copyWith(foto: updatedPhotoUrl);
      final result = await authRepo.updateUser(updatedUser);

      result.fold(
        (failure) {
          AppLogger.error(
            'Profile image update failed to persist user profile',
            failure.message,
          );
          throw failure.message;
        },
        (_) {
          AppLogger.info(
            'Profile image updated successfully: $updatedPhotoUrl',
          );
        },
      );

      unawaited(
        ref
            .read(analyticsServiceProvider)
            .logProfileEdit(userId: currentUser.uid),
      );
      return;
    });
  }

  String _withCacheBuster(String url) {
    final separator = url.contains('?') ? '&' : '?';
    final version = DateTime.now().millisecondsSinceEpoch;
    return '$url${separator}v=$version';
  }

  Future<void> deleteProfile() async {
    final authRepo = ref.read(authRepositoryProvider);
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await authRepo.deleteAccount();
    });
  }
}
