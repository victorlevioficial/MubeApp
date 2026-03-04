import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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

  _FakeHttpsCallable(this.name, this.invocations);

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    invocations.add(_CallableInvocation(name: name, parameters: parameters));
    return _FakeHttpsCallableResult<T>(
      (<String, dynamic>{'success': true}) as T,
    );
  }
}

class _FakeFunctions extends Fake implements FirebaseFunctions {
  final List<_CallableInvocation> invocations = [];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    return _FakeHttpsCallable(name, invocations);
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

void main() {
  group('MatchpointRemoteDataSource.fetchCandidates', () {
    test(
      'keeps legacy genre matching with case-insensitive normalization',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = MatchpointRemoteDataSourceImpl(
          firestore,
          _FakeFunctions(),
        );

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
        final dataSource = MatchpointRemoteDataSourceImpl(
          firestore,
          _FakeFunctions(),
        );

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
        final dataSource = MatchpointRemoteDataSourceImpl(
          firestore,
          _FakeFunctions(),
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
      final dataSource = MatchpointRemoteDataSourceImpl(
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

      await Future<void>.delayed(Duration.zero);

      final auditInvocation = functions.invocations.singleWhere(
        (call) => call.name == 'recordMatchpointRankingAudit',
      );
      final payload = auditInvocation.parameters! as Map<String, dynamic>;
      expect(payload['poolTotal'], 4);
      expect(payload['returnedTotal'], 4);
      expect(payload['poolProximity'], 1);
      expect(payload['poolHashtag'], 1);
      expect(payload['poolGenre'], 1);
      expect(payload['poolFallback'], 1);
      expect(payload['poolLocalTotal'], 1);
      expect(payload['poolLocalHashtag'], 1);
      expect(payload['poolLocalGenre'], 1);
      expect(payload['returnedLocalTotal'], 1);
      expect(payload['returnedLocalHashtag'], 1);
      expect(payload['returnedLocalGenre'], 1);
    });
  });

  group('MatchpointRemoteDataSource.fetchExistingInteractions', () {
    test(
      'keeps likes and active dislikes but ignores expired dislikes',
      () async {
        final firestore = FakeFirebaseFirestore();
        final dataSource = MatchpointRemoteDataSourceImpl(
          firestore,
          _FakeFunctions(),
        );

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
}
