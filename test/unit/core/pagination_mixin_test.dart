import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';

void main() {
  group('PaginationState', () {
    test('should create empty state with default values', () {
      final state = PaginationState<String>.empty();

      expect(state.items, isEmpty);
      expect(state.status, PaginationStatus.initial);
      expect(state.errorMessage, isNull);
      expect(state.hasMore, true);
      expect(state.currentPage, 0);
      expect(state.pageSize, 20);
    });

    test('should create state with custom page size', () {
      final state = PaginationState<String>.empty(pageSize: 10);
      expect(state.pageSize, 10);
    });

    test('should correctly identify loading states', () {
      const loadingState = PaginationState<String>(
        status: PaginationStatus.loading,
      );
      expect(loadingState.isLoading, true);
      expect(loadingState.isInitialLoading, true);
      expect(loadingState.isLoadingMore, false);

      const loadingMoreState = PaginationState<String>(
        status: PaginationStatus.loadingMore,
      );
      expect(loadingMoreState.isLoading, true);
      expect(loadingMoreState.isInitialLoading, false);
      expect(loadingMoreState.isLoadingMore, true);
    });

    test('should correctly identify loaded state', () {
      const loadedState = PaginationState<String>(
        status: PaginationStatus.loaded,
        items: ['item1', 'item2'],
      );
      expect(loadedState.isLoaded, true);
      expect(loadedState.hasError, false);
      expect(loadedState.isLoading, false);
    });

    test('should correctly identify error state', () {
      const errorState = PaginationState<String>(
        status: PaginationStatus.error,
        errorMessage: 'Something went wrong',
      );
      expect(errorState.hasError, true);
      expect(errorState.errorMessage, 'Something went wrong');
    });

    test('should correctly identify no more data state', () {
      const noMoreState = PaginationState<String>(
        status: PaginationStatus.noMoreData,
        hasMore: false,
      );
      expect(noMoreState.hasMore, false);
    });

    test('copyWith should update values correctly', () {
      const state = PaginationState<String>(
        items: ['item1'],
        status: PaginationStatus.loaded,
        currentPage: 1,
        hasMore: true,
      );

      final newState = state.copyWith(
        items: ['item1', 'item2'],
        currentPage: 2,
      );

      expect(newState.items, ['item1', 'item2']);
      expect(newState.status, PaginationStatus.loaded);
      expect(newState.currentPage, 2);
      expect(newState.hasMore, true);
    });

    test('copyWith with clearError should remove error message', () {
      const state = PaginationState<String>(
        status: PaginationStatus.error,
        errorMessage: 'Error message',
      );

      final newState = state.copyWith(clearError: true);

      expect(newState.errorMessage, isNull);
    });

    test('should implement equality correctly', () {
      const state1 = PaginationState<String>(
        items: ['a', 'b'],
        status: PaginationStatus.loaded,
      );
      const state2 = PaginationState<String>(
        items: ['a', 'b'],
        status: PaginationStatus.loaded,
      );
      const state3 = PaginationState<String>(
        items: ['a', 'c'],
        status: PaginationStatus.loaded,
      );

      expect(state1, state2);
      expect(state1.hashCode, state2.hashCode);
      expect(state1, isNot(state3));
    });

    test('toString should return meaningful representation', () {
      const state = PaginationState<String>(
        items: ['item1', 'item2'],
        status: PaginationStatus.loaded,
        hasMore: true,
        currentPage: 1,
      );

      expect(
        state.toString(),
        'PaginationState(items: 2, status: PaginationStatus.loaded, hasMore: true, page: 1)',
      );
    });
  });

  group('PaginationStatus', () {
    test('should have all expected values', () {
      expect(PaginationStatus.values, [
        PaginationStatus.initial,
        PaginationStatus.loading,
        PaginationStatus.loaded,
        PaginationStatus.loadingMore,
        PaginationStatus.error,
        PaginationStatus.noMoreData,
      ]);
    });
  });

  group('PaginationStateAsyncValue', () {
    test('should convert initial state to AsyncValue.loading', () {
      const state = PaginationState<String>(status: PaginationStatus.initial);
      final asyncValue = state.toAsyncValue();

      expect(asyncValue is AsyncLoading, true);
    });

    test('should convert loading state to AsyncValue.loading', () {
      const state = PaginationState<String>(status: PaginationStatus.loading);
      final asyncValue = state.toAsyncValue();

      expect(asyncValue is AsyncLoading, true);
    });

    test('should convert loaded state to AsyncValue.data', () {
      const state = PaginationState<String>(
        status: PaginationStatus.loaded,
        items: ['item1', 'item2'],
      );
      final asyncValue = state.toAsyncValue();

      expect(asyncValue is AsyncData, true);
      expect(asyncValue.value, ['item1', 'item2']);
    });

    test('should convert loadingMore state to AsyncValue.data', () {
      const state = PaginationState<String>(
        status: PaginationStatus.loadingMore,
        items: ['item1'],
      );
      final asyncValue = state.toAsyncValue();

      expect(asyncValue is AsyncData, true);
      expect(asyncValue.value, ['item1']);
    });

    test('should convert noMoreData state to AsyncValue.data', () {
      const state = PaginationState<String>(
        status: PaginationStatus.noMoreData,
        items: ['item1', 'item2'],
      );
      final asyncValue = state.toAsyncValue();

      expect(asyncValue is AsyncData, true);
    });

    test('should convert error state to AsyncValue.error', () {
      const state = PaginationState<String>(
        status: PaginationStatus.error,
        errorMessage: 'Something went wrong',
      );
      final asyncValue = state.toAsyncValue();

      expect(asyncValue is AsyncError, true);
    });

    test('should use default error message when errorMessage is null', () {
      const state = PaginationState<String>(status: PaginationStatus.error);
      final asyncValue = state.toAsyncValue();

      expect(asyncValue is AsyncError, true);
      final error = asyncValue as AsyncError;
      expect(error.error, 'Unknown error');
    });
  });
}
