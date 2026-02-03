import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../../shared/services/content_moderation_service.dart';
import '../../../core/services/analytics/analytics_provider.dart';
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
    // Capture repository BEFORE any async operation
    final authRepo = ref.read(authRepositoryProvider);

    state = const AsyncLoading();

    // Build the updated user object synchronously
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
      location: updates['location'] ?? currentUser.location,
      foto: updates['foto'] ?? currentUser.foto,
      dadosProfissional: updatedDadosProfissional,
      dadosEstudio: updatedDadosEstudio,
      dadosBanda: updatedDadosBanda,
      dadosContratante: updatedDadosContratante,
    );

    // Call repository and handle Result
    final result = await authRepo.updateUser(updatedUser);

    result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        throw Exception(failure.message); // Re-throw to be caught by UI
      },
      (_) {
        ref
            .read(analyticsServiceProvider)
            .logProfileEdit(userId: currentUser.uid);
        state = const AsyncData(null);
      },
    );
  }

  Future<void> updateProfileImage({
    required File file,
    required AppUser currentUser,
  }) async {
    // Capture repositories BEFORE any async operation
    final storageRepo = ref.read(storageRepositoryProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final moderationTest = ref.read(contentModerationServiceProvider);

    state = const AsyncLoading();

    try {
      // 1. Validate Image Content
      await moderationTest.validateImage(file);

      // 2. Upload if safe
      final downloadUrl = await storageRepo.uploadProfileImage(
        userId: currentUser.uid,
        file: file,
      );

      final updatedUser = currentUser.copyWith(foto: downloadUrl);
      await authRepo.updateUser(updatedUser);
      ref
          .read(analyticsServiceProvider)
          .logProfileEdit(userId: currentUser.uid);
      state = const AsyncData(null);
    } catch (e, st) {
      try {
        state = AsyncError(e, st);
      } catch (_) {
        // Provider was disposed, ignore
      }
      rethrow;
    }
  }

  Future<void> deleteProfile() async {
    // Capture repository BEFORE any async operation
    final authRepo = ref.read(authRepositoryProvider);

    state = const AsyncValue.loading();

    try {
      await authRepo.deleteAccount();
      state = const AsyncData(null);
    } catch (e, st) {
      try {
        state = AsyncError(e, st);
      } catch (_) {
        // Provider was disposed, ignore
      }
      rethrow;
    }
  }
}
