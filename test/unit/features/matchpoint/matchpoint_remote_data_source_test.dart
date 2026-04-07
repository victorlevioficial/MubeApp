import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart' as app_check;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mube/src/core/services/analytics/analytics_service.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/matchpoint/data/matchpoint_remote_data_source.dart';

class _CallableInvocation {
  final String name;
  final Object? parameters;

  const _CallableInvocation({required this.name, required this.parameters});
}

typedef _CallableHandler =
    Future<HttpsCallableResult<dynamic>> Function(Object? parameters);

class _FakeHttpsCallableResult<T> extends Fake
    implements HttpsCallableResult<T> {
  final T _value;

  _FakeHttpsCallableResult(this._value);

  @override
  T get data => _value;
}

class _FakeHttpsCallable extends Fake implements HttpsCallable {
  final String name;
  final List<_CallableInvocation> invocations;
  final _CallableHandler? handler;

  _FakeHttpsCallable(this.name, this.invocations, {this.handler});

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    invocations.add(_CallableInvocation(name: name, parameters: parameters));
    if (handler != null) {
      return (await handler!(parameters)) as HttpsCallableResult<T>;
    }
    return _FakeHttpsCallableResult<T>(
      (<String, dynamic>{'success': true}) as T,
    );
  }
}

class _FakeFunctions extends Fake implements FirebaseFunctions {
  final Map<String, _CallableHandler> handlers;
  final List<_CallableInvocation> invocations = [];

  _FakeFunctions({this.handlers = const {}});

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    return _FakeHttpsCallable(name, invocations, handler: handlers[name]);
  }
}

class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  final User? _currentUser;

  _FakeFirebaseAuth({User? currentUser}) : _currentUser = currentUser;

  @override
  User? get currentUser => _currentUser;
}

class _FakeAppCheck extends Fake implements app_check.FirebaseAppCheck {
  int cachedTokenCalls = 0;
  int forcedTokenCalls = 0;
  String? cachedToken;
  String? forcedToken;
  Object? cachedError;
  Object? forcedError;
  Duration cachedTokenDelay;

  _FakeAppCheck({
    this.cachedToken,
    this.forcedToken,
    this.cachedError,
    this.forcedError,
    this.cachedTokenDelay = Duration.zero,
  });

  @override
  Future<String?> getToken([bool? forceRefresh]) async {
    final isForced = forceRefresh ?? false;
    if (isForced) {
      forcedTokenCalls += 1;
      if (forcedError != null) throw forcedError!;
      return forcedToken;
    }

    cachedTokenCalls += 1;
    if (cachedTokenDelay > Duration.zero) {
      await Future<void>.delayed(cachedTokenDelay);
    }
    if (cachedError != null) throw cachedError!;
    return cachedToken;
  }
}

class _RecordingAnalyticsService extends Fake implements AnalyticsService {
  final List<String> eventNames = [];
  final List<Map<String, Object>?> eventParameters = [];

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    eventNames.add(name);
    eventParameters.add(parameters);
  }

  @override
  NavigatorObserver getObserver() =>
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

  @override
  Future<void> logAuthSignupComplete({required String method}) async {}

  @override
  Future<void> logFeedPostView({required String postId}) async {}

  @override
  Future<void> logMatchPointFilter({
    required List<String> instruments,
    required List<String> genres,
    required double distance,
  }) async {}

  @override
  Future<void> logProfileEdit({required String userId}) async {}

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}

Map<String, dynamic> _userDoc({
  required String uid,
  required String email,
  String profileType = 'profissional',
  String registrationStatus = 'concluido',
  String status = 'ativo',
  Map<String, dynamic>? location,
  Map<String, dynamic>? matchpointProfile,
  Map<String, dynamic>? profissional,
  Map<String, dynamic>? banda,
}) {
  return <String, dynamic>{
    'uid': uid,
    'email': email,
    'tipo_perfil': profileType,
    'cadastro_status': registrationStatus,
    'status': status,
    ..._optionalEntry('location', location),
    ..._optionalEntry('matchpoint_profile', matchpointProfile),
    ..._optionalEntry('profissional', profissional),
    ..._optionalEntry('banda', banda),
  };
}

Map<String, dynamic> _optionalEntry(String key, Object? value) {
  if (value == null) return const <String, dynamic>{};
  return <String, dynamic>{key: value};
}

MatchpointRemoteDataSourceImpl _buildDataSource(
  FirebaseFirestore firestore,
  FirebaseFunctions functions, {
  AnalyticsService? analytics,
  FirebaseAuth? auth,
  app_check.FirebaseAppCheck? appCheck,
}) {
  return MatchpointRemoteDataSourceImpl(
    firestore,
    functions,
    analytics: analytics,
    auth: auth ?? _FakeFirebaseAuth(),
    appCheck: appCheck ?? _FakeAppCheck(),
  );
}

void main() {
  group('MatchpointRemoteDataSource.fetchCandidates', () {
    test(
      'keeps legacy genre matching with case-insensitive normalization',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = _buildDataSource(firestore, _FakeFunctions());

        final currentUser = AppUser.fromJson(
          _userDoc(uid: 'current', email: 'current@test.com'),
        );

        await firestore
            .collection('users')
            .doc('current')
            .set(_userDoc(uid: 'current', email: 'current@test.com'));
        await firestore
            .collection('users')
            .doc('candidate')
            .set(
              _userDoc(
                uid: 'candidate',
                email: 'candidate@test.com',
                matchpointProfile: {
                  'is_active': true,
                  'musicalGenres': ['rock'],
                },
              ),
            );

        final result = await dataSource.fetchCandidates(
          currentUser: currentUser,
          genres: ['Rock'],
          hashtags: const [],
          excludedUserIds: const [],
        );

        expect(result, hasLength(1));
        expect(result.first.uid, 'candidate');
      },
    );

    test(
      'returns active profiles even without shared hashtags or genres',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = _buildDataSource(firestore, _FakeFunctions());

        final currentUser = AppUser.fromJson(
          _userDoc(uid: 'current', email: 'current@test.com'),
        );

        await firestore
            .collection('users')
            .doc('current')
            .set(_userDoc(uid: 'current', email: 'current@test.com'));
        await firestore
            .collection('users')
            .doc('candidate')
            .set(
              _userDoc(
                uid: 'candidate',
                email: 'candidate@test.com',
                matchpointProfile: {
                  'is_active': true,
                  'generosMusicais': ['jazz'],
                  'hashtags': ['#fusion'],
                },
              ),
            );

        final result = await dataSource.fetchCandidates(
          currentUser: currentUser,
          genres: ['Rock'],
          hashtags: const ['#cover'],
          excludedUserIds: const [],
        );

        expect(result, hasLength(1));
        expect(result.first.uid, 'candidate');
      },
    );

    test(
      'prioritizes nearby profiles before hashtag and genre affinity',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = _buildDataSource(firestore, _FakeFunctions());

        final currentUser = AppUser.fromJson(
          _userDoc(
            uid: 'current',
            email: 'current@test.com',
            location: {'lat': 0.0, 'lng': 0.0},
            matchpointProfile: {'is_active': true, 'search_radius': 50},
          ),
        );

        await firestore
            .collection('users')
            .doc('current')
            .set(
              _userDoc(
                uid: 'current',
                email: 'current@test.com',
                location: {'lat': 0.0, 'lng': 0.0},
                matchpointProfile: {'is_active': true, 'search_radius': 50},
              ),
            );
        await firestore
            .collection('users')
            .doc('nearby')
            .set(
              _userDoc(
                uid: 'nearby',
                email: 'nearby@test.com',
                location: {'lat': 0.01, 'lng': 0.01},
                matchpointProfile: {
                  'is_active': true,
                  'generosMusicais': ['blues'],
                  'hashtags': ['#jam'],
                },
              ),
            );
        await firestore
            .collection('users')
            .doc('far_with_match')
            .set(
              _userDoc(
                uid: 'far_with_match',
                email: 'far@test.com',
                location: {'lat': 2.0, 'lng': 2.0},
                matchpointProfile: {
                  'is_active': true,
                  'generosMusicais': ['rock'],
                  'hashtags': ['#cover'],
                },
              ),
            );

        final result = await dataSource.fetchCandidates(
          currentUser: currentUser,
          genres: const ['rock'],
          hashtags: const ['#cover'],
          excludedUserIds: const [],
          limit: 10,
        );

        expect(result, hasLength(2));
        expect(result.first.uid, 'nearby');
        expect(result.last.uid, 'far_with_match');
      },
    );

    test('emits ranking audit telemetry with classified sources', () async {
      final firestore = FakeFirebaseFirestore();
      final analytics = _RecordingAnalyticsService();
      final functions = _FakeFunctions();
      final dataSource = _buildDataSource(
        firestore,
        functions,
        analytics: analytics,
      );

      final currentUser = AppUser.fromJson(
        _userDoc(
          uid: 'current',
          email: 'current@test.com',
          location: {'lat': 0.0, 'lng': 0.0},
          matchpointProfile: {'is_active': true, 'search_radius': 50},
        ),
      );

      await firestore
          .collection('users')
          .doc('proximity')
          .set(
            _userDoc(
              uid: 'proximity',
              email: 'proximity@test.com',
              location: {'lat': 0.01, 'lng': 0.01},
              matchpointProfile: {
                'is_active': true,
                'hashtags': ['#cover'],
                'generosMusicais': ['rock'],
              },
            ),
          );
      await firestore
          .collection('users')
          .doc('hashtag')
          .set(
            _userDoc(
              uid: 'hashtag',
              email: 'hashtag@test.com',
              location: {'lat': 1.0, 'lng': 1.0},
              matchpointProfile: {
                'is_active': true,
                'hashtags': ['#cover'],
              },
            ),
          );
      await firestore
          .collection('users')
          .doc('genre')
          .set(
            _userDoc(
              uid: 'genre',
              email: 'genre@test.com',
              location: {'lat': 1.0, 'lng': 1.0},
              matchpointProfile: {
                'is_active': true,
                'generosMusicais': ['rock'],
              },
            ),
          );
      await firestore
          .collection('users')
          .doc('fallback')
          .set(
            _userDoc(
              uid: 'fallback',
              email: 'fallback@test.com',
              location: {'lat': 1.0, 'lng': 1.0},
              matchpointProfile: {
                'is_active': true,
                'generosMusicais': ['jazz'],
              },
            ),
          );

      await dataSource.fetchCandidates(
        currentUser: currentUser,
        genres: const ['rock'],
        hashtags: const ['#cover'],
        excludedUserIds: const [],
        limit: 10,
      );

      // The matchpoint_ranking_audit analytics event is intentionally
      // deferred ~250ms inside _logRankingAudit so its Pigeon call does
      // not overlap with the continuation of fetchCandidates() on iOS
      // (Crashlytics issue a37e597a SIGABRT mitigation). Wait long
      // enough for the deferred call to land before asserting.
      await Future<void>.delayed(const Duration(milliseconds: 350));

      expect(analytics.eventNames, contains('matchpoint_ranking_audit'));
      final params = analytics.eventParameters.last!;
      expect(params['pool_proximity'], 1);
      expect(params['pool_hashtag'], 1);
      expect(params['pool_genre'], 1);
      expect(params['pool_fallback'], 1);
      expect(params['pool_local_total'], 1);
      expect(params['pool_local_hashtag'], 1);
      expect(params['pool_local_genre'], 1);
      expect(params['ret_local_total'], 1);
      expect(params['ret_local_hashtag'], 1);
      expect(params['ret_local_genre'], 1);
      expect(params['returned_total'], 4);

      // The recordMatchpointRankingAudit Cloud Function mirror was removed
      // because it triggered concurrent platform-channel calls that crash
      // the iOS Swift Concurrency runtime (SIGABRT). The audit data is now
      // captured exclusively via the analytics event above.
      expect(
        functions.invocations.where(
          (call) => call.name == 'recordMatchpointRankingAudit',
        ),
        isEmpty,
      );
    });
  });

  group('MatchpointRemoteDataSource.fetchExistingInteractions', () {
    test(
      'keeps likes and active dislikes but ignores expired dislikes',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = _buildDataSource(firestore, _FakeFunctions());

        await firestore.collection('interactions').doc('like').set({
          'source_user_id': 'current',
          'target_user_id': 'liked',
          'type': 'like',
        });
        await firestore.collection('interactions').doc('active_dislike').set({
          'source_user_id': 'current',
          'target_user_id': 'recent_dislike',
          'type': 'dislike',
          'expires_at': Timestamp.fromDate(
            DateTime.now().add(const Duration(days: 10)),
          ),
        });
        await firestore.collection('interactions').doc('expired_dislike').set({
          'source_user_id': 'current',
          'target_user_id': 'expired_dislike',
          'type': 'dislike',
          'expires_at': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 1)),
          ),
        });

        final result = await dataSource.fetchExistingInteractions('current');

        expect(result, containsAll(<String>['liked', 'recent_dislike']));
        expect(result, isNot(contains('expired_dislike')));
      },
    );
  });

  group('MatchpointRemoteDataSource App Check recovery', () {
    FirebaseFunctionsException recoverableAppCheckError() {
      return FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'App Check token is required.',
      );
    }

    test('skips forced refresh when App Check reports throttling', () async {
      final firestore = FakeFirebaseFirestore();
      final functions = _FakeFunctions(
        handlers: {
          'getRemainingLikes': (_) async => throw recoverableAppCheckError(),
        },
      );
      final appCheck = _FakeAppCheck(
        cachedError: Exception('Too many attempts.'),
        forcedError: Exception('Should not force refresh while throttled.'),
      );
      final dataSource = _buildDataSource(
        firestore,
        functions,
        auth: _FakeFirebaseAuth(),
        appCheck: appCheck,
      );

      await expectLater(
        dataSource.getRemainingLikes(),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      expect(appCheck.cachedTokenCalls, 1);
      expect(appCheck.forcedTokenCalls, 0);
    });

    test('uses cooldown to avoid repeated forced App Check refresh', () async {
      final firestore = FakeFirebaseFirestore();
      final functions = _FakeFunctions(
        handlers: {
          'getRemainingLikes': (_) async => throw recoverableAppCheckError(),
        },
      );
      final appCheck = _FakeAppCheck(cachedToken: null, forcedToken: 'fresh');
      final dataSource = _buildDataSource(
        firestore,
        functions,
        auth: _FakeFirebaseAuth(),
        appCheck: appCheck,
      );

      await expectLater(
        dataSource.getRemainingLikes(),
        throwsA(isA<FirebaseFunctionsException>()),
      );
      await expectLater(
        dataSource.getRemainingLikes(),
        throwsA(isA<FirebaseFunctionsException>()),
      );

      expect(appCheck.cachedTokenCalls, 2);
      expect(appCheck.forcedTokenCalls, 1);
    });

    test('deduplicates concurrent security refresh attempts', () async {
      final firestore = FakeFirebaseFirestore();
      final functions = _FakeFunctions(
        handlers: {
          'getRemainingLikes': (_) async => throw recoverableAppCheckError(),
        },
      );
      final appCheck = _FakeAppCheck(
        cachedToken: null,
        forcedToken: 'fresh',
        cachedTokenDelay: const Duration(milliseconds: 60),
      );
      final dataSource = _buildDataSource(
        firestore,
        functions,
        auth: _FakeFirebaseAuth(),
        appCheck: appCheck,
      );

      await Future.wait<void>([
        dataSource.getRemainingLikes().then<void>((_) {}, onError: (_, _) {}),
        dataSource.getRemainingLikes().then<void>((_) {}, onError: (_, _) {}),
      ]);

      expect(appCheck.cachedTokenCalls, 1);
      expect(appCheck.forcedTokenCalls, 1);
    });

    test(
      'surfaces App Check refresh failure as functions precondition error',
      () async {
        final firestore = FakeFirebaseFirestore();
        final functions = _FakeFunctions(
          handlers: {
            'getRemainingLikes': (_) async => throw recoverableAppCheckError(),
          },
        );
        final appCheck = _FakeAppCheck(
          cachedToken: null,
          forcedError: Exception('403 App attestation failed.'),
        );
        final dataSource = _buildDataSource(
          firestore,
          functions,
          auth: _FakeFirebaseAuth(),
          appCheck: appCheck,
        );

        await expectLater(
          dataSource.getRemainingLikes(),
          throwsA(
            isA<FirebaseFunctionsException>()
                .having((error) => error.code, 'code', 'failed-precondition')
                .having(
                  (error) => error.message,
                  'message',
                  contains('App Check'),
                ),
          ),
        );

        expect(appCheck.cachedTokenCalls, 1);
        expect(appCheck.forcedTokenCalls, 1);
      },
    );
  });

  group('MatchpointRemoteDataSource hashtag firestore reads', () {
    // The Cloud Function path (getTrendingHashtags / searchHashtags) was
    // removed in 1.6.20+156 because it triggered the iOS Swift Concurrency
    // SIGABRT crash on the matchpoint Trending tab (Crashlytics issue
    // a37e597a). The data source now reads directly from the
    // hashtagRanking Firestore collection. These tests reflect the new
    // behavior.
    test('fetchHashtagRanking reads from Firestore ordered by use_count',
        () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('hashtagRanking').doc('rank-1').set({
        'hashtag': '#rock',
        'display_name': '#rock',
        'use_count': 42,
        'current_position': 1,
        'previous_position': 2,
        'trend': 'up',
        'trend_delta': 1,
        'is_trending': true,
        'updated_at': Timestamp.fromDate(DateTime(2026, 3, 13)),
      });
      final dataSource = _buildDataSource(firestore, _FakeFunctions());

      final result = await dataSource.fetchHashtagRanking(limit: 5);

      expect(result, hasLength(1));
      expect(result.first.id, 'rank-1');
      expect(result.first.hashtag, '#rock');
      expect(result.first.useCount, 42);
    });

    test(
      'searchHashtags reads from Firestore matching the query prefix',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('hashtagRanking').doc('rank-2').set({
          'hashtag': 'cover',
          'display_name': '#cover',
          'use_count': 7,
          'current_position': 5,
          'previous_position': 5,
          'trend': 'stable',
          'trend_delta': 0,
          'is_trending': false,
          'updated_at': Timestamp.fromDate(DateTime(2026, 3, 13)),
        });
        final dataSource = _buildDataSource(firestore, _FakeFunctions());

        final result = await dataSource.searchHashtags('co', limit: 5);

        expect(result, hasLength(1));
        expect(result.first.id, 'rank-2');
        expect(result.first.hashtag, 'cover');
        expect(result.first.useCount, 7);
      },
    );
  });
}
