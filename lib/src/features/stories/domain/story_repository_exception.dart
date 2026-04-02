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
      'Esse story nao esta mais disponivel.',
    );
  }

  factory StoryRepositoryException.loadViewersFailed() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.loadViewersFailed,
      'Nao foi possivel carregar as visualizacoes agora.',
    );
  }

  factory StoryRepositoryException.publishFailed([String? message]) {
    return StoryRepositoryException(
      StoryRepositoryExceptionCode.publishFailed,
      message?.trim().isNotEmpty == true
          ? message!.trim()
          : 'Nao foi possivel publicar o story.',
    );
  }

  factory StoryRepositoryException.deleteFailed() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.deleteFailed,
      'Nao foi possivel excluir o story agora.',
    );
  }

  factory StoryRepositoryException.uploadFileMissing() {
    return const StoryRepositoryException(
      StoryRepositoryExceptionCode.uploadFileMissing,
      'Arquivo nao encontrado para upload.',
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
