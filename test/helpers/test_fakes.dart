import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/core/errors/failures.dart';
import 'package:mube/src/core/mixins/pagination_mixin.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/chat/data/chat_repository.dart';
import 'package:mube/src/features/chat/domain/conversation_preview.dart';
import 'package:mube/src/features/chat/domain/message.dart';
import 'package:mube/src/features/favorites/data/favorite_repository.dart';
import 'package:mube/src/features/favorites/domain/paginated_favorites_response.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/feed/presentation/feed_image_precache_service.dart';
import 'package:mube/src/features/moderation/data/moderation_repository.dart';
import 'package:mube/src/features/notifications/data/notification_repository.dart';
import 'package:mube/src/features/notifications/domain/notification_model.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';
import 'package:mube/src/features/search/presentation/search_controller.dart';
import 'package:mube/src/features/storage/data/storage_repository.dart';
import 'package:mube/src/features/support/data/support_repository.dart';
import 'package:mube/src/features/support/domain/ticket_model.dart';

/// Fake implementation of Firebase User
class FakeFirebaseUser extends Fake implements firebase_auth.User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  FakeFirebaseUser({
    this.uid = 'test-user-id',
    this.email = 'test@example.com',
    this.displayName = 'Test User',
    this.photoURL,
  });

  @override
  bool get emailVerified => true;

  @override
  bool get isAnonymous => false;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'fake-token';
}

/// Fake implementation of AuthRepository
class FakeAuthRepository extends Fake implements AuthRepository {
  firebase_auth.User? _currentUser;
  final _authStateController =
      StreamController<firebase_auth.User?>.broadcast();

  // Mutable state for testing
  AppUser? _appUser;
  AppUser? lastUpdatedUser;
  bool shouldThrow = false;

  FakeAuthRepository({firebase_auth.User? initialUser})
    : _currentUser = initialUser;

  void emitUser(firebase_auth.User? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  @override
  firebase_auth.User? get currentUser => _currentUser;

  // Helper to set initial state for watchUser
  set appUser(AppUser? user) {
    _appUser = user;
  }

  @override
  Stream<firebase_auth.User?> authStateChanges() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  Stream<AppUser?> watchUser(String? uid) {
    if (shouldThrow) return Stream.error(Exception('Failed to load user'));
    return Stream.value(_appUser);
  }

  @override
  FutureResult<Unit> updateUser(AppUser user) async {
    if (shouldThrow) return const Left(ServerFailure(message: 'Update failed'));
    _appUser = user;
    lastUpdatedUser = user;
    return const Right(unit);
  }

  @override
  FutureResult<List<AppUser>> getUsersByIds(List<String> uids) async {
    if (shouldThrow) {
      return const Left(ServerFailure(message: 'Failed to load users'));
    }
    if (_appUser != null && uids.contains(_appUser!.uid)) {
      return Right([_appUser!]);
    }
    return const Right([]);
  }

  @override
  FutureResult<Unit> signOut() async {
    _currentUser = null;
    _appUser = null;
    _authStateController.add(null);
    return const Right(unit);
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Fake implementation of FavoriteRepository
class FakeFavoriteRepository extends Fake implements FavoriteRepository {
  Set<String> favorites = {};
  bool throwError = false;

  @override
  Future<Set<String>> loadFavorites() async {
    if (throwError) throw Exception('Favorite loading failed');
    return favorites;
  }

  @override
  Future<void> addFavorite(String targetUserId) async {
    favorites.add(targetUserId);
  }

  @override
  Future<void> removeFavorite(String targetUserId) async {
    favorites.remove(targetUserId);
  }

  @override
  Future<int> getLikeCount(String userId) async => 0;

  @override
  Future<PaginatedFavoritesResponse> loadFavoritesPage({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    if (throwError) {
      return const PaginatedFavoritesResponse.empty();
    }
    final favoriteIds = favorites.toList();
    return PaginatedFavoritesResponse(
      favoriteIds: favoriteIds,
      lastDocument: null,
      hasMore: false,
    );
  }
}

/// Fake implementation of AnalyticsService
class FakeAnalyticsService extends Fake implements AnalyticsService {
  final List<String> loggedEvents = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    loggedEvents.add(name);
  }

  @override
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  }) async {
    loggedEvents.add('matchpoint_filter');
  }

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  FirebaseAnalyticsObserver getObserver() =>
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  @override
  Future<void> logAuthSignupComplete({required String method}) async {}

  @override
  Future<void> logFeedPostView({required String postId}) async {}

  @override
  Future<void> logProfileEdit({required String userId}) async {}
}

/// Fake implementation of FeedRepository
class FakeFeedRepository extends Fake implements FeedRepository {
  bool throwError = false;
  Completer<void>? requestCompleter;
  List<FeedItem> nearbyUsers = [];
  List<FeedItem> artists = [];
  List<FeedItem> bands = [];
  List<FeedItem> studios = [];
  List<FeedItem> technicians = [];
  List<FeedItem> professionals = [];
  PaginatedFeedResponse? mainFeedResponse;

  Future<void> _maybeWait() async {
    if (throwError) throw Exception('Connection failed');
    if (requestCompleter != null) await requestCompleter!.future;
  }

  @override
  FutureResult<List<FeedItem>> getNearbyUsers({
    required double lat,
    required double long,
    required double radiusKm,
    required String currentUserId,
    List<String> excludedIds = const [],
    int limit = 10,
  }) async {
    await _maybeWait();
    return Either.right(nearbyUsers);
  }

  @override
  FutureResult<List<FeedItem>> getArtists({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: ''));
    return Either.right(artists);
  }

  @override
  FutureResult<List<FeedItem>> getUsersByType({
    required String type,
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: ''));
    switch (type) {
      case 'banda':
        return Either.right(bands);
      case 'estudio':
        return Either.right(studios);
      case 'profissional':
        return Either.right(professionals.isNotEmpty ? professionals : artists);
      default:
        return Either.right(bands);
    }
  }

  @override
  FutureResult<List<FeedItem>> getNearbyUsersOptimized({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    List<String> excludedIds = const [],
    int targetResults = 20,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: ''));
    return Either.right(nearbyUsers);
  }

  @override
  FutureResult<List<FeedItem>> getUsersByIds({
    required List<String> ids,
    required String currentUserId,
    double? userLat,
    double? userLong,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: 'Failed'));
    // Retorna items que correspondem aos IDs solicitados
    final allItems = [
      ...nearbyUsers,
      ...artists,
      ...bands,
      ...studios,
      ...technicians,
      ...professionals,
    ];
    final result = allItems.where((item) => ids.contains(item.uid)).toList();
    return Either.right(result);
  }

  @override
  FutureResult<PaginatedFeedResponse> getMainFeedPaginated({
    required String currentUserId,
    String? filterType,
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: ''));
    return Either.right(
      mainFeedResponse ??
          const PaginatedFeedResponse(
            items: [],
            hasMore: false,
            lastDocument: null,
          ),
    );
  }

  @override
  FutureResult<List<FeedItem>> getAllUsersSortedByDistance({
    required String currentUserId,
    required double userLat,
    required double userLong,
    String? filterType,
    String? category,
    String? excludeCategory,
    List<String> excludedIds = const [],
    int? limit,
    String? userGeohash,
    double? radiusKm,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: ''));
    switch (filterType) {
      case 'banda':
        return Either.right(bands);
      case 'estudio':
        return Either.right(studios);
      case 'profissional':
        return Either.right(
          professionals.isNotEmpty ? professionals : nearbyUsers,
        );
      default:
        return Either.right(nearbyUsers);
    }
  }

  @override
  FutureResult<PaginatedFeedResponse> getUsersByTypePaginated({
    required String type,
    required String currentUserId,
    double? userLat,
    double? userLong,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: ''));
    final List<FeedItem> fallbackItems = switch (type) {
      'banda' => bands,
      'estudio' => studios,
      'profissional' => professionals.isNotEmpty ? professionals : artists,
      _ => bands,
    };

    return Either.right(
      mainFeedResponse ??
          PaginatedFeedResponse(
            items: fallbackItems,
            hasMore: false,
            lastDocument: null,
          ),
    );
  }

  @override
  FutureResult<List<FeedItem>> getTechnicians({
    required String currentUserId,
    List<String> excludedIds = const [],
    double? userLat,
    double? userLong,
    int limit = 10,
  }) async {
    await _maybeWait();
    if (throwError) return Either.left(const ServerFailure(message: ''));
    return Either.right(technicians);
  }
}

/// Fake implementation of FeedImagePrecacheService
class FakeFeedImagePrecacheService extends Fake
    implements FeedImagePrecacheService {
  @override
  Future<void> precacheItems(dynamic context, List<FeedItem> items) async {}
}

/// Fake implementation of NotificationRepository
class FakeNotificationRepository extends Fake
    implements NotificationRepository {
  List<AppNotification> _notifications = [];
  bool throwError = false;

  void setNotifications(List<AppNotification> items) {
    _notifications = items;
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    if (throwError) return Stream.error(Exception('Failed to load'));
    return Stream.value(_notifications);
  }

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    if (throwError) throw Exception('Failed');
    _notifications = _notifications
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList();
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    if (throwError) throw Exception('Failed');
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
  }

  @override
  Future<void> deleteNotification(String userId, String notificationId) async {
    if (throwError) throw Exception('Failed');
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    if (throwError) throw Exception('Failed');
    _notifications.clear();
  }
}

/// Fake implementation of SupportRepository
class FakeSupportRepository extends Fake implements SupportRepository {
  List<Ticket> _tickets = [];
  bool throwError = false;

  void setTickets(List<Ticket> items) {
    _tickets = items;
  }

  List<Ticket> get tickets => _tickets;

  @override
  Future<void> createTicket(Ticket ticket) async {
    if (throwError) throw Exception('Failed to create ticket');
    _tickets.add(ticket);
  }

  @override
  Stream<List<Ticket>> watchUserTickets(String userId) {
    if (throwError) return Stream.error(Exception('Failed'));
    return Stream.value(_tickets.where((t) => t.userId == userId).toList());
  }

  @override
  Future<List<Ticket>> getUserTickets(String userId) async {
    if (throwError) throw Exception('Failed');
    return _tickets.where((t) => t.userId == userId).toList();
  }
}

/// Fake implementation of ChatRepository
class FakeChatRepository extends Fake implements ChatRepository {
  List<ConversationPreview> _conversations = [];
  bool throwError = false;

  void setConversations(List<ConversationPreview> items) {
    _conversations = items;
  }

  @override
  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Stream<List<ConversationPreview>> getUserConversations(String userId) {
    if (throwError) return Stream.error(Exception('Failed'));
    return Stream.value(_conversations);
  }

  @override
  Stream<List<Message>> getMessages(String conversationId) {
    return Stream.value([]);
  }

  @override
  FutureResult<Unit> markAsRead({
    required String conversationId,
    required String myUid,
  }) async {
    if (throwError) return const Left(ServerFailure(message: 'Failed'));
    return const Right(unit);
  }

  @override
  FutureResult<String> getOrCreateConversation({
    required String myUid,
    required String otherUid,
    required String otherUserName,
    String? otherUserPhoto,
    required String myName,
    String? myPhoto,
    String type = 'direct',
  }) async {
    if (throwError) return const Left(ServerFailure(message: 'Failed'));
    return Right(getConversationId(myUid, otherUid));
  }

  @override
  FutureResult<Unit> sendMessage({
    required String conversationId,
    required String text,
    required String myUid,
    required String otherUid,
  }) async {
    if (throwError) return const Left(ServerFailure(message: 'Failed'));
    return const Right(unit);
  }
}

/// Fake implementation of StorageRepository
class FakeStorageRepository extends Fake implements StorageRepository {
  bool throwError = false;
  String downloadUrl = 'http://fake.url/image.jpg';

  @override
  Future<String> uploadSupportAttachment({
    required String ticketId,
    required File file,
  }) async {
    if (throwError) throw Exception('Upload failed');
    return downloadUrl;
  }
}

/// Fake implementation of ModerationRepository
class FakeModerationRepository extends Fake implements ModerationRepository {
  bool throwError = false;

  @override
  FutureResult<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    if (throwError) return const Left(ServerFailure(message: 'Failed'));
    return const Right(null);
  }

  @override
  FutureResult<void> blockUser({
    required String currentUserId,
    required String blockedUserId,
  }) async {
    if (throwError) return const Left(ServerFailure(message: 'Failed'));
    return const Right(null);
  }
}

/// Fake implementation of SearchController for widget tests
class FakeSearchController extends SearchController {
  final SearchPaginationState _fixedState;
  final AsyncValue<List<FeedItem>> _fixedAsyncValue;

  FakeSearchController({
    SearchPaginationState? state,
    AsyncValue<List<FeedItem>>? asyncValue,
  }) : _fixedState =
           state ??
           const SearchPaginationState(
             status: PaginationStatus.loaded,
             hasMore: false,
           ),
       _fixedAsyncValue = asyncValue ?? const AsyncValue.data([]);

  @override
  SearchPaginationState build() {
    return _fixedState;
  }

  @override
  AsyncValue<List<FeedItem>> get resultsAsyncValue => _fixedAsyncValue;

  @override
  bool get canLoadMore => false;

  @override
  bool get isLoadingMore => false;

  @override
  void setTerm(String term) {}

  @override
  void setCategory(SearchCategory category) {}

  @override
  void setProfessionalSubcategory(ProfessionalSubcategory? subcategory) {}

  @override
  void setGenres(List<String> genres) {}

  @override
  void setInstruments(List<String> instruments) {}

  @override
  void setRoles(List<String> roles) {}

  @override
  void setServices(List<String> services) {}

  @override
  void setStudioType(String? type) {}

  @override
  void setBackingVocalFilter(bool? canDoBacking) {}

  @override
  void clearFilters() {}

  @override
  void reset() {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> loadMore() async {}

  @override
  void cancelDebounce() {}
}
