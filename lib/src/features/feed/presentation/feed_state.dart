import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/mixins/pagination_mixin.dart';
import '../domain/feed_item.dart';
import '../domain/feed_section.dart';

/// Estado específico do feed, estendendo [PaginationState].
@immutable
class FeedState extends PaginationState<FeedItem> {
  /// Itens em destaque configurados pelo admin.
  final List<FeedItem> featuredItems;

  /// Itens das seções horizontais (destaques).
  final Map<FeedSectionType, List<FeedItem>> sectionItems;

  /// Filtro atual aplicado ao feed.
  final String currentFilter;

  /// Indica se está carregando a inicialização completa.
  @override
  final bool isInitialLoading;

  const FeedState({
    this.featuredItems = const [],
    this.sectionItems = const {},
    this.currentFilter = 'Todos',
    this.isInitialLoading = true,
    super.items = const [],
    super.status = PaginationStatus.initial,
    super.errorMessage,
    super.lastDocument,
    super.hasMore = true,
    super.currentPage = 0,
    super.pageSize = 20,
  });

  FeedState copyWithFeed({
    List<FeedItem>? featuredItems,
    Map<FeedSectionType, List<FeedItem>>? sectionItems,
    String? currentFilter,
    bool? isInitialLoading,
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
    return FeedState(
      featuredItems: featuredItems ?? this.featuredItems,
      sectionItems: sectionItems ?? this.sectionItems,
      currentFilter: currentFilter ?? this.currentFilter,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
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
    return other is FeedState &&
        listEquals(other.featuredItems, featuredItems) &&
        mapEquals(other.sectionItems, sectionItems) &&
        other.currentFilter == currentFilter &&
        other.isInitialLoading == isInitialLoading &&
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
    featuredItems,
    sectionItems,
    currentFilter,
    isInitialLoading,
    items,
    status,
    errorMessage,
    lastDocument,
    hasMore,
    currentPage,
    pageSize,
  );
}
