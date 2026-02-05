import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failures.dart';
import '../typedefs.dart';

/// Estados possíveis para paginação.
enum PaginationStatus {
  /// Estado inicial, nenhuma carga realizada.
  initial,

  /// Carregando a primeira página.
  loading,

  /// Dados carregados com sucesso.
  loaded,

  /// Carregando mais dados (paginação).
  loadingMore,

  /// Erro ao carregar dados.
  error,

  /// Não há mais dados para carregar.
  noMoreData,
}

/// Classe base para estado de paginação.
///
/// Pode ser estendida por estados específicos de cada feature.
@immutable
class PaginationState<T> {
  /// Lista de itens carregados.
  final List<T> items;

  /// Status atual da paginação.
  final PaginationStatus status;

  /// Mensagem de erro (se houver).
  final String? errorMessage;

  /// Último documento do Firestore (para paginação cursor-based).
  final DocumentSnapshot? lastDocument;

  /// Indica se há mais dados para carregar.
  final bool hasMore;

  /// Número da página atual (para paginação offset-based).
  final int currentPage;

  /// Tamanho da página (quantidade de itens por página).
  final int pageSize;

  const PaginationState({
    this.items = const [],
    this.status = PaginationStatus.initial,
    this.errorMessage,
    this.lastDocument,
    this.hasMore = true,
    this.currentPage = 0,
    this.pageSize = 20,
  });

  /// Cria uma cópia do estado com valores atualizados.
  PaginationState<T> copyWith({
    List<T>? items,
    PaginationStatus? status,
    String? errorMessage,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    int? currentPage,
    int? pageSize,
    bool clearError = false,
    bool clearLastDocument = false,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastDocument: clearLastDocument
          ? null
          : (lastDocument ?? this.lastDocument),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Estado vazio (inicial).
  factory PaginationState.empty({int pageSize = 20}) =>
      PaginationState<T>(pageSize: pageSize);

  /// Verifica se está carregando (inicial ou mais).
  bool get isLoading =>
      status == PaginationStatus.loading ||
      status == PaginationStatus.loadingMore;

  /// Verifica se está carregando a primeira página.
  bool get isInitialLoading => status == PaginationStatus.loading;

  /// Verifica se está carregando mais itens.
  bool get isLoadingMore => status == PaginationStatus.loadingMore;

  /// Verifica se há erro.
  bool get hasError => status == PaginationStatus.error;

  /// Verifica se os dados foram carregados.
  bool get isLoaded => status == PaginationStatus.loaded;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginationState<T> &&
        listEquals(other.items, items) &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.lastDocument == lastDocument &&
        other.hasMore == hasMore &&
        other.currentPage == currentPage &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode =>
      Object.hash(
        items,
        status,
        errorMessage,
        lastDocument,
        hasMore,
        currentPage,
        pageSize,
      );

  @override
  String toString() {
    return 'PaginationState(items: ${items.length}, status: $status, '
        'hasMore: $hasMore, page: $currentPage)';
  }
}

/// Interface para repositórios que suportam paginação.
///
/// Implemente esta interface nos repositórios para usar com paginação.
abstract class PaginatedRepository<T> {
  /// Busca uma página de itens.
  ///
  /// [page] - Número da página (0-based).
  /// [pageSize] - Quantidade de itens por página.
  /// [lastDocument] - Último documento para paginação cursor-based.
  /// [filters] - Filtros opcionais.
  FutureResult<List<T>> fetchPage({
    required int page,
    required int pageSize,
    DocumentSnapshot? lastDocument,
    Map<String, dynamic>? filters,
  });

  /// Verifica se há mais dados disponíveis.
  ///
  /// [lastDocument] - Último documento recebido.
  /// [itemsCount] - Quantidade de itens na última página.
  /// [pageSize] - Tamanho esperado da página.
  bool hasMoreData(DocumentSnapshot? lastDocument, int itemsCount, int pageSize);
}

/// Helper class para gerenciar paginação sem usar mixin.
///
/// Use esta classe quando não puder usar o mixin [PaginationMixin]
/// devido a restrições de herança.
class PaginationHelper<T> {
  /// ID da requisição atual (para cancelar requisições antigas).
  int _currentRequestId = 0;

  /// Timer para debounce.
  Timer? _debounceTimer;

  /// Duração padrão do debounce.
  final Duration debounceDuration;

  /// Estado atual da paginação.
  PaginationState<T> _state;

  /// Callback para atualizar o estado.
  final void Function(PaginationState<T> newState) onStateChanged;

  /// Callback para buscar uma página.
  final FutureResult<List<T>> Function({
    required int page,
    required int pageSize,
    DocumentSnapshot? lastDocument,
    Map<String, dynamic>? filters,
  }) fetchPageCallback;

  PaginationHelper({
    required this.onStateChanged,
    required this.fetchPageCallback,
    this.debounceDuration = const Duration(milliseconds: 300),
    int pageSize = 20,
  }) : _state = PaginationState<T>(pageSize: pageSize);

  /// Estado atual.
  PaginationState<T> get state => _state;

  /// Atualiza o estado interno e notifica o callback.
  void _updateState(PaginationState<T> newState) {
    _state = newState;
    onStateChanged(newState);
  }

  /// Verifica se uma requisição de paginação está em andamento.
  bool get isLoading => _state.isLoading;

  /// Verifica se há mais dados para carregar.
  bool get canLoadMore => _state.hasMore && !isLoading;

  /// Carrega a primeira página.
  ///
  /// [filters] - Filtros opcionais para a busca.
  /// [clearExisting] - Se true, limpa os dados existentes antes de carregar.
  Future<void> loadFirstPage({
    Map<String, dynamic>? filters,
    bool clearExisting = true,
  }) async {
    if (isLoading) return;

    final requestId = ++_currentRequestId;

    if (clearExisting) {
      _updateState(_state.copyWith(
        items: [],
        status: PaginationStatus.loading,
        currentPage: 0,
        hasMore: true,
        clearError: true,
        clearLastDocument: true,
      ));
    } else {
      _updateState(_state.copyWith(
        status: PaginationStatus.loading,
        clearError: true,
      ));
    }

    try {
      final result = await fetchPageCallback(
        page: 0,
        pageSize: _state.pageSize,
        filters: filters,
      );

      // Verifica se a requisição ainda é válida
      if (_currentRequestId != requestId) return;

      result.fold(
        (failure) => _handleError(failure),
        (items) => _handleSuccess(items, isFirstPage: true),
      );
    } catch (e, stackTrace) {
      if (_currentRequestId != requestId) return;
      _handleError(UnexpectedFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  /// Carrega a próxima página.
  ///
  /// [filters] - Filtros opcionais para a busca.
  Future<void> loadNextPage({Map<String, dynamic>? filters}) async {
    if (!canLoadMore) return;

    final requestId = ++_currentRequestId;

    _updateState(_state.copyWith(
      status: PaginationStatus.loadingMore,
      clearError: true,
    ));

    try {
      final result = await fetchPageCallback(
        page: _state.currentPage + 1,
        pageSize: _state.pageSize,
        lastDocument: _state.lastDocument,
        filters: filters,
      );

      // Verifica se a requisição ainda é válida
      if (_currentRequestId != requestId) return;

      result.fold(
        (failure) => _handleError(failure),
        (items) => _handleSuccess(items, isFirstPage: false),
      );
    } catch (e, stackTrace) {
      if (_currentRequestId != requestId) return;
      _handleError(UnexpectedFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  /// Atualiza os dados (refresh).
  ///
  /// Recarrega a primeira página mantendo os dados atuais visíveis
  /// até que os novos dados sejam carregados.
  Future<void> refresh({Map<String, dynamic>? filters}) async {
    if (isLoading) return;

    final requestId = ++_currentRequestId;

    // Mantém os dados atuais visíveis durante o refresh
    _updateState(_state.copyWith(clearError: true));

    try {
      final result = await fetchPageCallback(
        page: 0,
        pageSize: _state.pageSize,
        filters: filters,
      );

      // Verifica se a requisição ainda é válida
      if (_currentRequestId != requestId) return;

      result.fold(
        (failure) => _handleError(failure),
        (items) => _handleSuccess(items, isFirstPage: true),
      );
    } catch (e, stackTrace) {
      if (_currentRequestId != requestId) return;
      _handleError(UnexpectedFailure(
        message: e.toString(),
        stackTrace: stackTrace,
      ));
    }
  }

  /// Executa uma busca com debounce.
  ///
  /// Útil para buscas em tempo real (search as you type).
  void debouncedSearch({
    required Map<String, dynamic> filters,
    Duration? duration,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration ?? debounceDuration, () {
      loadFirstPage(filters: filters);
    });
  }

  /// Cancela o debounce pendente.
  void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Manipula sucesso na busca.
  void _handleSuccess(List<T> newItems, {required bool isFirstPage}) {
    final allItems = isFirstPage ? newItems : [..._state.items, ...newItems];
    final hasMore = newItems.length >= _state.pageSize;

    _updateState(_state.copyWith(
      items: allItems,
      status: hasMore ? PaginationStatus.loaded : PaginationStatus.noMoreData,
      currentPage: isFirstPage ? 1 : _state.currentPage + 1,
      hasMore: hasMore,
      clearError: true,
    ));
  }

  /// Manipula erro na busca.
  void _handleError(Failure failure) {
    _updateState(_state.copyWith(
      status: PaginationStatus.error,
      errorMessage: failure.message,
    ));
  }

  /// Limpa o estado da paginação.
  void clear() {
    _currentRequestId++;
    cancelDebounce();
    _updateState(PaginationState<T>.empty(pageSize: _state.pageSize));
  }

  /// Adiciona um item ao estado atual.
  void addItem(T item) {
    _updateState(_state.copyWith(items: [..._state.items, item]));
  }

  /// Remove um item do estado atual.
  void removeItem(bool Function(T item) predicate) {
    _updateState(_state.copyWith(
      items: _state.items.where((item) => !predicate(item)).toList(),
    ));
  }

  /// Atualiza um item no estado atual.
  void updateItem(bool Function(T item) predicate, T Function(T item) update) {
    _updateState(_state.copyWith(
      items: _state.items.map((item) {
        if (predicate(item)) {
          return update(item);
        }
        return item;
      }).toList(),
    ));
  }

  /// Libera recursos.
  void dispose() {
    cancelDebounce();
  }
}

/// Extensão para facilitar o uso de paginação com Riverpod AsyncValue.
extension PaginationStateAsyncValue<T> on PaginationState<T> {
  /// Converte o estado de paginação para AsyncValue.
  ///
  /// Útil quando você precisa integrar com widgets que esperam AsyncValue.
  AsyncValue<List<T>> toAsyncValue() {
    switch (status) {
      case PaginationStatus.initial:
      case PaginationStatus.loading:
        return const AsyncValue.loading();
      case PaginationStatus.loaded:
      case PaginationStatus.loadingMore:
      case PaginationStatus.noMoreData:
        return AsyncValue.data(items);
      case PaginationStatus.error:
        return AsyncValue.error(
          errorMessage ?? 'Unknown error',
          StackTrace.current,
        );
    }
  }
}
