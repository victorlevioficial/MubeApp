enum StoryRepositoryExceptionCode {
  unauthenticated,
  loadTrayFailed,
  storyUnavailable,
  loadViewersFailed,
  publishFailed,
  deleteFailed,
  uploadFileMissing,
  uploadFailed,
}

class StoryRepositoryException implements Exception {
  const StoryRepositoryException(this.code, this.message);

  final StoryRepositoryExceptionCode code;
  final String message;

  bool get showsViewerFallback =>
      code == StoryRepositoryExceptionCode.storyUnavailable;

  factory StoryRepositoryException.unauthenticated() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.unauthenticated,
      'Faca login para continuar.',
    );
  }

  factory StoryRepositoryException.loadTrayFailed() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.loadTrayFailed,
      'Nao foi possivel carregar os stories agora.',
    );
  }

  factory StoryRepositoryException.storyUnavailable() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.storyUnavailable,
      'Esse story não está mais disponível.',
    );
  }

  factory StoryRepositoryException.loadViewersFailed() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.loadViewersFailed,
      'Não foi possível carregar as visualizações agora.',
    );
  }

  factory StoryRepositoryException.publishFailed([String? message]) {
    return StoryRepositoryException(
      StoryRepositoryExceptionCode.publishFailed,
      message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'Não foi possível publicar o story.',
    );
  }

  factory StoryRepositoryException.deleteFailed() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.deleteFailed,
      'Não foi possível excluir o story agora.',
    );
  }

  factory StoryRepositoryException.uploadFileMissing() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.uploadFileMissing,
      'Arquivo não encontrado para upload.',
    );
  }

  factory StoryRepositoryException.uploadFailed([String? message]) {
    return StoryRepositoryException(
      StoryRepositoryExceptionCode.uploadFailed,
      message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'Erro ao enviar arquivo. Verifique sua conexao.',
    );
  }

  @override
  String toString() => message;
}
