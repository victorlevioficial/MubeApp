import 'package:freezed_annotation/freezed_annotation.dart';
import 'user_type.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,

    // Status do Cadastro (Controla o fluxo de Onboarding)
    // Valores: 'tipo_pendente', 'perfil_pendente', 'concluido'
    @Default('tipo_pendente')
    @JsonKey(name: 'cadastro_status')
    String cadastroStatus,

    // Tipo de Perfil (Só preenchido após seleção)
    @JsonKey(name: 'tipo_perfil') AppUserType? tipoPerfil,

    // Status do Perfil (Visibilidade)
    @Default('ativo') String status,

    // Dados Comuns / Específicos Mapeados
    String? nome,
    String? foto,
    String? bio,

    // Localização (Obrigatório para todos)
    // Armazenado como Map: { 'cidade': '...', 'estado': '...', 'lat': 0.0, 'long': 0.0 }
    Map<String, dynamic>? location,

    // Dados Específicos (achatados ou em maps, conforme Spec diz "Maps Tipados" no security rules)
    // Para simplificar e manter compatibilidade com Security Rules:
    @JsonKey(name: 'profissional') Map<String, dynamic>? dadosProfissional,
    @JsonKey(name: 'banda') Map<String, dynamic>? dadosBanda,
    @JsonKey(name: 'estudio') Map<String, dynamic>? dadosEstudio,
    @JsonKey(name: 'contratante') Map<String, dynamic>? dadosContratante,

    // Metadata
    @JsonKey(name: 'created_at') dynamic createdAt, // Timestamp
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);

  const AppUser._();

  // Helper para Router
  bool get isCadastroConcluido => cadastroStatus == 'concluido';
  bool get isTipoPendente => cadastroStatus == 'tipo_pendente';
  bool get isPerfilPendente => cadastroStatus == 'perfil_pendente';
}
