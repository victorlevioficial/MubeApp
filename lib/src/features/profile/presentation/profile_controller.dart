import 'dart:async';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../storage/data/storage_repository.dart';

part 'profile_controller.g.dart';

@riverpod
class ProfileController extends _$ProfileController {
  @override
  FutureOr<void> build() {
    // No initial state to load beyond what's passed or available in auth
  }

  Future<void> updateProfile({
    required AppUser currentUser,
    required Map<String, dynamic> updates,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // Create a copy of the user with the updates
      // This is a shallow merge, be careful with nested maps if not handled correctly
      // Ideally AppUser would have a copyWith that accepts raw maps or we parse first.

      // Construct the updated map manually to ensure specific fields are updated correctly
      // or rely on Firestore SetOptions(merge: true) which authRepository.updateUser uses.

      // However, AppUser is a class. We need to create a new AppUser instance.
      // But wait, authRepository.updateUser takes an AppUser.
      // If we use copyWith, we can update known fields.
      // For dynamic maps (dadosProfissional), we need to merge them.

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
        // Location is a Map, assume it's replaced entirely if provided
        location: updates['location'] ?? currentUser.location,
        foto: updates['foto'] ?? currentUser.foto,
        dadosProfissional: updatedDadosProfissional,
        dadosEstudio: updatedDadosEstudio,
        dadosBanda: updatedDadosBanda,
        dadosContratante: updatedDadosContratante,
      );

      await ref.read(authRepositoryProvider).updateUser(updatedUser);
    });
  }

  Future<void> updateProfileImage({
    required File file,
    required AppUser currentUser,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final downloadUrl = await ref
          .read(storageRepositoryProvider)
          .uploadProfileImage(userId: currentUser.uid, file: file);

      final updatedUser = currentUser.copyWith(foto: downloadUrl);
      await ref.read(authRepositoryProvider).updateUser(updatedUser);
    });
  }

  Future<void> deleteProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).deleteAccount();
    });
  }
}
