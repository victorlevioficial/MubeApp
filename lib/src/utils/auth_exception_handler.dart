import 'package:firebase_auth/firebase_auth.dart';

class AuthExceptionHandler {
  static String handleException(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Este e-mail já está sendo usado por outra conta.';
        case 'invalid-email':
          return 'O e-mail digitado não é válido.';
        case 'operation-not-allowed':
          return 'Esta operação não é permitida.';
        case 'weak-password':
          return 'A senha é muito fraca. Tente uma senha mais forte.';
        case 'user-disabled':
          return 'Este usuário foi desativado.';
        case 'user-not-found':
          return 'Não encontramos uma conta com este e-mail.';
        case 'wrong-password':
          return 'Senha incorreta. Tente novamente.';
        case 'invalid-credential':
          return 'Credenciais inválidas ou expiradas.';
        case 'account-exists-with-different-credential':
          return 'Já existe uma conta com este e-mail usando outro método de login.';
        case 'network-request-failed':
          return 'Erro de conexão. Verifique sua internet.';
        default:
          return 'Ocorreu um erro no servidor. Tente novamente mais tarde. (${e.code})';
      }
    } else {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }
}
