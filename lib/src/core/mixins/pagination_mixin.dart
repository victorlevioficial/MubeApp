import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lifecycle states shared by paginated feature controllers.
enum PaginationStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
  noMoreData,
}

/// Immutable pagination state shared by feature-specific controllers.
@immutable
class PaginationState<T> {
  final List<T> items;
  final PaginationStatus status;
  final String? errorMessage;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
  final int currentPage;
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

  factory PaginationState.empty({int pageSize = 20}) {
    return PaginationState<T>(pageSize: pageSize);
  }

  bool get isLoading =>
      status == PaginationStatus.loading ||
      status == PaginationStatus.loadingMore;
  bool get isInitialLoading => status == PaginationStatus.loading;
  bool get isLoadingMore => status == PaginationStatus.loadingMore;
  bool get hasError => status == PaginationStatus.error;
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
  int get hashCode => Object.hash(
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

extension PaginationStateAsyncValue<T> on PaginationState<T> {
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
