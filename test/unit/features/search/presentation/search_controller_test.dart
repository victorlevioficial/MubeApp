import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/search/data/search_repository.dart';
import 'package:mube/src/features/search/domain/paginated_search_response.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';
import 'package:mube/src/features/search/presentation/search_controller.dart';

import '../../../../helpers/test_fakes.dart';

/// Fake SearchRepository for testing
class FakeSearchRepository extends Fake implements SearchRepository {
  List<FeedItem> _searchResults = [];
  bool throwError = false;
  bool rateLimitExceeded = false;
  int searchCallCount = 0;
  SearchFilters? lastSearchFilters;

  void setSearchResults(List<FeedItem> results) {
    _searchResults = results;
  }

  @override
  FutureResult<PaginatedSearchResponse> searchUsers({
    required SearchFilters filters,
    DocumentSnapshot? startAfter,
    required int requestId,
    required ValueGetter<int> getCurrentRequestId,
    List<String> blockedUsers = const [],
  }) async {
    searchCallCount++;
    lastSearchFilters = filters;

    if (throwError) {
      return const Left(ServerFailure(message: 'Search failed'));
    }

    if (rateLimitExceeded) {
      return const Left(ServerFailure(message: 'Rate limit exceeded'));
    }

    return Right(
      PaginatedSearchResponse(items: _searchResults, hasMore: false),
    );
  }
}

void main() {
  group('SearchController - Filtros Complexos', () {
    late ProviderContainer container;
    late FakeAuthRepository fakeAuthRepository;
    late FakeSearchRepository fakeSearchRepository;
    late FakeFirebaseUser fakeUser;
    late AppUser testAppUser;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      fakeSearchRepository = FakeSearchRepository();
      fakeUser = FakeFirebaseUser(uid: 'user123');

      testAppUser = const AppUser(
        uid: 'user123',
        email: 'test@example.com',
        nome: 'Test User',
        foto: 'photo.jpg',
        matchpointProfile: {},
        privacySettings: {},
        blockedUsers: [],
      );

      fakeAuthRepository.emitUser(fakeUser);
      fakeAuthRepository.appUser = testAppUser;

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
          searchRepositoryProvider.overrideWithValue(fakeSearchRepository),
          currentUserProfileProvider.overrideWithValue(
            AsyncValue.data(testAppUser),
          ),
        ],
      );
    });

    tearDown(() {
      // Cancel any pending debounce timers before disposing
      final controller = container.read(searchControllerProvider.notifier);
      controller.cancelDebounce();
      container.dispose();
    });

    test(
      'setTerm should update filters and trigger debounced search',
      () async {
        // Arrange
        final controller = container.read(searchControllerProvider.notifier);

        // Act
        controller.setTerm('rock band');

        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 500));

        // Assert
        final state = container.read(searchControllerProvider);
        expect(state.filters.term, 'rock band');
        expect(fakeSearchRepository.searchCallCount, greaterThan(0));
      },
    );

    test('setCategory should update category filter and search', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      await Future.delayed(Duration.zero); // Wait for initial search
      fakeSearchRepository.searchCallCount = 0;

      // Act
      controller.setCategory(SearchCategory.professionals);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.category, SearchCategory.professionals);
      expect(fakeSearchRepository.searchCallCount, greaterThan(0));
    });

    test('setCategory should reset professionalSubcategory', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);

      // First set a subcategory
      controller.setProfessionalSubcategory(ProfessionalSubcategory.singer);
      await Future.delayed(Duration.zero);

      // Act - change category
      controller.setCategory(SearchCategory.bands);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.professionalSubcategory, isNull);
    });

    test(
      'setProfessionalSubcategory should update subcategory filter',
      () async {
        // Arrange
        final controller = container.read(searchControllerProvider.notifier);

        // Act
        controller.setProfessionalSubcategory(
          ProfessionalSubcategory.instrumentalist,
        );
        await Future.delayed(Duration.zero);

        // Assert
        final state = container.read(searchControllerProvider);
        expect(
          state.filters.professionalSubcategory,
          ProfessionalSubcategory.instrumentalist,
        );
      },
    );

    test('setGenres should update genres filter with AND logic', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      const genres = ['rock', 'pop', 'jazz'];

      // Act
      controller.setGenres(genres);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.genres, genres);
      expect(state.filters.genres.length, 3);
    });

    test('setInstruments should update instruments filter', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      const instruments = ['guitar', 'drums', 'bass'];

      // Act
      controller.setInstruments(instruments);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.instruments, instruments);
    });

    test('setRoles should update crew roles filter', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      const roles = ['sound_engineer', 'lighting_technician'];

      // Act
      controller.setRoles(roles);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.roles, roles);
    });

    test('setServices should update studio services filter', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      const services = ['recording', 'mixing', 'mastering'];

      // Act
      controller.setServices(services);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.services, services);
    });

    test('setStudioType should update studio type filter', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);

      // Act
      controller.setStudioType('home_studio');
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.studioType, 'home_studio');
    });

    test(
      'setBackingVocalFilter should update backing vocal capability filter',
      () async {
        // Arrange
        final controller = container.read(searchControllerProvider.notifier);

        // Act - filter for users who CAN do backing vocals
        controller.setBackingVocalFilter(true);
        await Future.delayed(Duration.zero);

        // Assert
        final state = container.read(searchControllerProvider);
        expect(state.filters.canDoBackingVocal, true);
      },
    );

    test('clearFilters should reset all filters except category', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      controller.setTerm('search term');
      controller.setGenres(['rock']);
      controller.setInstruments(['guitar']);
      controller.setProfessionalSubcategory(ProfessionalSubcategory.singer);
      await Future.delayed(Duration.zero);

      // Act
      controller.clearFilters();
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.term, '');
      expect(state.filters.genres, isEmpty);
      expect(state.filters.instruments, isEmpty);
      expect(state.filters.professionalSubcategory, isNull);
      // Category should be preserved
      expect(state.filters.category, SearchCategory.all);
    });

    test('reset should reset all filters to default', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      controller.setTerm('search term');
      controller.setCategory(SearchCategory.professionals);
      controller.setGenres(['rock']);
      await Future.delayed(Duration.zero);

      // Act
      controller.reset();
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.term, '');
      expect(state.filters.category, SearchCategory.all);
      expect(state.filters.genres, isEmpty);
    });

    test('hasActiveFilters should be true when filters are applied', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);

      // Initially no active filters
      expect(
        container.read(searchControllerProvider).filters.hasActiveFilters,
        false,
      );

      // Act - add a filter
      controller.setTerm('rock');
      await Future.delayed(Duration.zero);

      // Assert
      expect(
        container.read(searchControllerProvider).filters.hasActiveFilters,
        true,
      );
    });

    test('multiple filters should work together', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);

      // Act - apply multiple filters
      controller.setCategory(SearchCategory.professionals);
      controller.setProfessionalSubcategory(
        ProfessionalSubcategory.instrumentalist,
      );
      controller.setGenres(['rock', 'blues']);
      controller.setInstruments(['guitar', 'bass']);
      await Future.delayed(Duration.zero);

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.filters.category, SearchCategory.professionals);
      expect(
        state.filters.professionalSubcategory,
        ProfessionalSubcategory.instrumentalist,
      );
      expect(state.filters.genres, ['rock', 'blues']);
      expect(state.filters.instruments, ['guitar', 'bass']);
      expect(state.filters.hasActiveFilters, true);
    });

    test('refresh should reload search results', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      fakeSearchRepository.searchCallCount = 0;

      // Act
      await controller.refresh();

      // Assert
      expect(fakeSearchRepository.searchCallCount, greaterThan(0));
    });

    test('cancelDebounce should prevent pending search', () async {
      // Arrange
      final controller = container.read(searchControllerProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      fakeSearchRepository.searchCallCount = 0;

      // Act - set term (triggers debounce) then immediately cancel
      controller.setTerm('test');
      controller.cancelDebounce();

      // Wait for debounce period
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - search should not have been triggered
      expect(fakeSearchRepository.searchCallCount, 0);
    });

    test('should handle error state gracefully', () async {
      // Arrange
      fakeSearchRepository.throwError = true;
      final controller = container.read(searchControllerProvider.notifier);

      // Act
      controller.setTerm('trigger error');
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert
      final state = container.read(searchControllerProvider);
      expect(state.status, PaginationStatus.error);
      expect(state.errorMessage, isNotNull);
    });
  });

  group('SearchFilters - Regras de Negócio', () {
    test('SearchFilters equality works correctly', () {
      const filters1 = SearchFilters(
        term: 'rock',
        category: SearchCategory.professionals,
        genres: ['rock', 'pop'],
      );
      const filters2 = SearchFilters(
        term: 'rock',
        category: SearchCategory.professionals,
        genres: ['rock', 'pop'],
      );
      const filters3 = SearchFilters(
        term: 'jazz',
        category: SearchCategory.professionals,
        genres: ['rock', 'pop'],
      );

      expect(filters1, filters2);
      expect(filters1, isNot(filters3));
    });

    test('clearFilters preserves category', () {
      const filters = SearchFilters(
        term: 'search',
        category: SearchCategory.bands,
        genres: ['rock'],
        instruments: ['guitar'],
      );

      final cleared = filters.clearFilters();

      expect(cleared.term, '');
      expect(cleared.category, SearchCategory.bands); // Preserved
      expect(cleared.genres, isEmpty);
      expect(cleared.instruments, isEmpty);
    });

    test('reset returns default filters', () {
      const filters = SearchFilters(
        term: 'search',
        category: SearchCategory.bands,
        genres: ['rock'],
      );

      final reset = filters.reset();

      expect(reset.term, '');
      expect(reset.category, SearchCategory.all);
      expect(reset.genres, isEmpty);
    });

    test('hasActiveFilters detects any active filter', () {
      expect(const SearchFilters().hasActiveFilters, false);
      expect(const SearchFilters(term: 'search').hasActiveFilters, true);
      expect(const SearchFilters(genres: ['rock']).hasActiveFilters, true);
      expect(
        const SearchFilters(instruments: ['guitar']).hasActiveFilters,
        true,
      );
      expect(const SearchFilters(roles: ['engineer']).hasActiveFilters, true);
      expect(
        const SearchFilters(services: ['recording']).hasActiveFilters,
        true,
      );
      expect(
        const SearchFilters(canDoBackingVocal: true).hasActiveFilters,
        true,
      );
      expect(const SearchFilters(studioType: 'home').hasActiveFilters, true);
      expect(
        const SearchFilters(
          professionalSubcategory: ProfessionalSubcategory.singer,
        ).hasActiveFilters,
        true,
      );
    });

    test('category alone does not count as active filter', () {
      const filters = SearchFilters(category: SearchCategory.professionals);
      expect(filters.hasActiveFilters, false);
    });

    test('copyWith creates correct copy with updates', () {
      const filters = SearchFilters(
        term: 'initial',
        category: SearchCategory.professionals,
        genres: ['rock'],
      );

      final updated = filters.copyWith(term: 'updated', genres: ['jazz']);

      expect(updated.term, 'updated');
      expect(updated.category, SearchCategory.professionals); // Preserved
      expect(updated.genres, ['jazz']);
    });

    test('empty genres and instruments lists are handled correctly', () {
      const filters = SearchFilters(
        genres: [],
        instruments: [],
        roles: [],
        services: [],
      );

      expect(filters.genres, isEmpty);
      expect(filters.instruments, isEmpty);
      expect(filters.roles, isEmpty);
      expect(filters.services, isEmpty);
      expect(filters.hasActiveFilters, false);
    });

    test('null values are handled correctly', () {
      const filters = SearchFilters(
        professionalSubcategory: null,
        canDoBackingVocal: null,
        studioType: null,
      );

      expect(filters.professionalSubcategory, isNull);
      expect(filters.canDoBackingVocal, isNull);
      expect(filters.studioType, isNull);
      expect(filters.hasActiveFilters, false);
    });
  });
}
