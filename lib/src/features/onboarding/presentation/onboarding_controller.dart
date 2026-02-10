import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_type.dart';

part 'onboarding_controller.g.dart';

@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  FutureOr<void> build() {
    // nothing to do
  }

  Future<void> selectProfileType({
    required String selectedType,
    required AppUser currentUser,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updatedUser = currentUser.copyWith(
        tipoPerfil: AppUserType.values.firstWhere((e) => e.id == selectedType),
        cadastroStatus: 'perfil_pendente', // Avança o status
      );
      final result = await ref
          .read(authRepositoryProvider)
          .updateUser(updatedUser);
      result.fold((l) => throw l, (r) => null);
      // O Router vai detectar a mudança no currentUserProfileProvider stream
    });
  }

  Future<void> resetToTypeSelection({required AppUser currentUser}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updatedUser = currentUser.copyWith(
        tipoPerfil: null, // Resetar tipo para forçar nova escolha
        cadastroStatus: 'tipo_pendente', // Retorna status anterior
      );
      final result = await ref
          .read(authRepositoryProvider)
          .updateUser(updatedUser);
      result.fold((l) => throw l, (r) => null);
      // Router vai notar status 'tipo_pendente' e redirecionar/manter em '/onboarding'
    });
  }

  // Método FINAL para concluir o cadastro com os dados do formulário
  Future<void> submitProfileForm({
    required AppUser currentUser,
    // Dados Opcionais de cada tipo (apenas um conjunto será preenchido)
    Map<String, dynamic>? dadosProfissional,
    Map<String, dynamic>? dadosBanda,
    Map<String, dynamic>? dadosEstudio,
    Map<String, dynamic>? dadosContratante,
    // Dados Comuns obrigatórios na spec
    required Map<String, dynamic> location,
    required String nome,
    String? foto,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1. Monta o objeto final dependendo do tipo
      // A spec diz que ao concluir, status = 'concluido'

      final updatedUser = currentUser.copyWith(
        nome: nome,
        foto: foto,
        location: location,
        cadastroStatus: 'concluido',
        status:
            'ativo', // Perfil ativo (exceto banda draft, que tratamos abaixo)
        // Atribui os maps específicos
        dadosProfissional: dadosProfissional,
        dadosBanda: dadosBanda,
        dadosEstudio: dadosEstudio,
        dadosContratante: dadosContratante,
      );

      final result = await ref
          .read(authRepositoryProvider)
          .updateUser(updatedUser);
      result.fold((l) => throw l, (r) => null);
    });
  }
}
