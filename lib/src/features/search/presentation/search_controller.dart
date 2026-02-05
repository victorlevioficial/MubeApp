import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mixins/pagination_mixin.dart';
import '../../../core/utils/rate_limiter.dart';
import '../../auth/data/auth_repository.dart';
import '../../feed/domain/feed_item.dart';
import '../data/search_repository.dart';
import '../domain/search_filters.dart';

/// Estado de paginação específico para busca.
@immutable
class SearchPaginationState extends PaginationState<FeedItem> {
  /// Filtros atuais da busca.
  final SearchFilters filters;

  /// Latitude do usuário para ordenação por proximidade.
  final double? userLat;

  /// Longitude do usuário para ordenação por proximidade.
  final double? userLng;

  const SearchPaginationState({
    this.filters = const SearchFilters(),
    this.userLat,
    this.userLng,
    super.items = const [],
    super.status = PaginationStatus.initial,
    super.errorMessage,
    super.lastDocument,
    super.hasMore = true,
    super.currentPage = 0,
    super.pageSize = 20,
  });

  SearchPaginationState copyWithSearch({
    SearchFilters? filters,
    double? userLat,
    double? userLng,
    List<FeedItem>? items,
    PaginationStatus? status,
    String? errorMessage,
    DocumentSnapshot? lastDocument,
    bool? hasMore,
    int? currentPage,
    int? pageSize,
    bool clearError = false,
    bool clearLastDocument = false,
  }) {
    return SearchPaginationState(
      filters: filters ?? this.filters,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchPaginationState &&
        other.filters == filters &&
        other.userLat == userLat &&
        other.userLng == userLng &&
        listEquals(other.items, items) &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.lastDocument == lastDocument &&
        other.hasMore == hasMore &&
        other.currentPage == currentPage &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        filters,
        userLat,
        userLng,
        items,
        status,
        errorMessage,
        lastDocument,
        hasMore,
        currentPage,
        pageSize,
      );
}

/// Controller para a tela de busca usando padrão unificado de paginação.
class SearchController extends Notifier<SearchPaginationState> {
  Timer? _debounceTimer;
  int _currentRequestId = 0;
  final RateLimiter _rateLimiter = RateLimitConfigs.search;

  @override
  SearchPaginationState build() {
    // Inicializa com a localização do usuário
    final userAsync = ref.read(currentUserProfileProvider);

    double? lat;
    double? lng;
    userAsync.whenData((user) {
      if (user?.location != null) {
        lat = (user!.location!['lat'] as num?)?.toDouble();
        lng = (user.location!['lng'] as num?)?.toDouble();
      }
    });

    // Inicializa a busca após o build
    Future.microtask(() => _performSearch());

    return SearchPaginationState(userLat: lat, userLng: lng);
  }

  /// Atualiza o estado interno.
  void _updateState(SearchPaginationState newState) {
    state = newState;
  }

  /// Atualiza o termo de busca com debounce.
  void setTerm(String term) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(term: term),
    ));
    _debouncedSearch();
  }

  /// Atualiza o filtro de categoria.
  void setCategory(SearchCategory category) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(
        category: category,
        professionalSubcategory: null,
      ),
    ));
    _performSearch();
  }

  /// Atualiza a subcategoria profissional.
  void setProfessionalSubcategory(ProfessionalSubcategory? subcategory) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(professionalSubcategory: subcategory),
    ));
    _performSearch();
  }

  /// Atualiza o filtro de gêneros.
  void setGenres(List<String> genres) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(genres: genres),
    ));
    _performSearch();
  }

  /// Atualiza o filtro de instrumentos.
  void setInstruments(List<String> instruments) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(instruments: instruments),
    ));
    _performSearch();
  }

  /// Atualiza o filtro de funções (crew).
  void setRoles(List<String> roles) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(roles: roles),
    ));
    _performSearch();
  }

  /// Atualiza o filtro de serviços (estúdios).
  void setServices(List<String> services) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(services: services),
    ));
    _performSearch();
  }

  /// Atualiza o tipo de estúdio.
  void setStudioType(String? type) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(studioType: type),
    ));
    _performSearch();
  }

  /// Atualiza o filtro de backing vocal.
  void setBackingVocalFilter(bool? canDoBacking) {
    _updateState(state.copyWithSearch(
      filters: state.filters.copyWith(canDoBackingVocal: canDoBacking),
    ));
    _performSearch();
  }

  /// Limpa todos os filtros.
  void clearFilters() {
    _updateState(state.copyWithSearch(
      filters: state.filters.clearFilters(),
    ));
    _performSearch();
  }

  /// Reseta tudo.
  void reset() {
    _updateState(state.copyWithSearch(
      filters: const SearchFilters(),
      clearError: true,
      clearLastDocument: true,
    ));
    _performSearch();
  }

  /// Atualiza os resultados (pull-to-refresh).
  Future<void> refresh() async {
    await _performSearch();
  }

  /// Carrega mais resultados (paginação).
  Future<void> loadMore() async {
    if (!canLoadMore) return;

    final requestId = ++_currentRequestId;

    _updateState(state.copyWithSearch(
      status: PaginationStatus.loadingMore,
      clearError: true,
    ));

    try {
      final user = ref.read(currentUserProfileProvider).value;
      final blockedUsers = user?.blockedUsers ?? [];

      final repository = ref.read(searchRepositoryProvider);

      // Para busca, usamos o lastDocument do estado anterior
      final result = await repository.searchUsers(
        filters: state.filters,
        startAfter: state.lastDocument,
        requestId: requestId,
        getCurrentRequestId: () => _currentRequestId,
        blockedUsers: blockedUsers,
      );

      if (_currentRequestId != requestId) return;

      result.fold(
        (failure) {
          if (_currentRequestId != requestId) return;
          _updateState(state.copyWithSearch(
            status: PaginationStatus.error,
            errorMessage: failure.message,
          ));
        },
        (response) {
          if (_currentRequestId != requestId) return;

          final sortedResults = SearchRepository.sortByProximity(
            response.items,
            state.userLat,
            state.userLng,
          );

          final existingIds = state.items.map((item) => item.uid).toSet();
          final newItems =
              sortedResults.where((item) => !existingIds.contains(item.uid)).toList();

          final allItems = [...state.items, ...newItems];
          final hasMore = response.hasMore;

          _updateState(state.copyWithSearch(
            items: allItems,
            status: hasMore
                ? PaginationStatus.loaded
                : PaginationStatus.noMoreData,
            hasMore: hasMore,
            currentPage: state.currentPage + 1,
            lastDocument: response.lastDocument,
          ));
        },
      );
    } catch (e) {
      if (_currentRequestId != requestId) return;
      _updateState(state.copyWithSearch(
        status: PaginationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Busca com debounce para entrada de texto.
  void _debouncedSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), _performSearch);
  }

  /// Executa a busca.
  Future<void> _performSearch() async {
    final requestId = ++_currentRequestId;
    final user = ref.read(currentUserProfileProvider).value;
    final blockedUsers = user?.blockedUsers ?? [];
    final userId = user?.uid ?? 'anonymous';

    // Rate limiting check
    if (!_rateLimiter.allowRequest(userId)) {
      final timeUntil = _rateLimiter.timeUntilNextRequest(userId);
      debugPrint('[Search] Rate limit exceeded. Try again in $timeUntil');
      _updateState(state.copyWithSearch(
        status: PaginationStatus.error,
        errorMessage: 'Muitas buscas. Tente novamente em alguns segundos.',
      ));
      return;
    }

    _updateState(state.copyWithSearch(
      status: PaginationStatus.loading,
      hasMore: true,
      clearError: true,
      clearLastDocument: true,
    ));

    try {
      final repository = ref.read(searchRepositoryProvider);
      final result = await repository.searchUsers(
        filters: state.filters,
        startAfter: null,
        requestId: requestId,
        getCurrentRequestId: () => _currentRequestId,
        blockedUsers: blockedUsers,
      );

      if (_currentRequestId != requestId) return;

      result.fold(
        (failure) {
          if (_currentRequestId != requestId) return;
          debugPrint('[Search] Error: $failure');
          _updateState(state.copyWithSearch(
            status: PaginationStatus.error,
            errorMessage: failure.message,
          ));
        },
        (response) {
          if (_currentRequestId != requestId) return;

          final sortedResults = SearchRepository.sortByProximity(
            response.items,
            state.userLat,
            state.userLng,
          );

          final hasMore = response.hasMore;

          _updateState(state.copyWithSearch(
            items: sortedResults,
            status: hasMore
                ? PaginationStatus.loaded
                : PaginationStatus.noMoreData,
            hasMore: hasMore,
            currentPage: 1,
            lastDocument: response.lastDocument,
          ));
        },
      );
    } catch (e) {
      if (_currentRequestId != requestId) return;
      debugPrint('[Search] Error: $e');
      _updateState(state.copyWithSearch(
        status: PaginationStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Verifica se pode carregar mais resultados.
  bool get canLoadMore {
    return state.hasMore &&
        !state.isLoading &&
        state.status != PaginationStatus.error;
  }

  /// Verifica se está carregando mais resultados.
  bool get isLoadingMore => state.isLoadingMore;

  /// Converte o estado para AsyncValue (para compatibilidade com UI).
  AsyncValue<List<FeedItem>> get resultsAsyncValue => state.toAsyncValue();

  /// Cancela o debounce pendente.
  void cancelDebounce() {
    _debounceTimer?.cancel();
  }
}

/// Provider para SearchController
final searchControllerProvider =
    NotifierProvider<SearchController, SearchPaginationState>(() {
  return SearchController();
});
