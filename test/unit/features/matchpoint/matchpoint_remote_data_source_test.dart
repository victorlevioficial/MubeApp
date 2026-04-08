import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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
  FirebaseFunctions functions,
) {
  return MatchpointRemoteDataSourceImpl(firestore, functions);
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

  group('MatchpointRemoteDataSource callable access', () {
    test('getRemainingLikes forwards directly to the callable', () async {
      final firestore = FakeFirebaseFirestore();
      final functions = _FakeFunctions(
        handlers: {
          'getRemainingLikes': (_) async =>
              _FakeHttpsCallableResult(<String, dynamic>{
                'remaining': 7,
                'limit': 50,
                'resetTime': '2026-04-09T00:00:00.000Z',
              }),
        },
      );
      final dataSource = _buildDataSource(firestore, functions);

      final result = await dataSource.getRemainingLikes();

      expect(result.remaining, 7);
      expect(functions.invocations, hasLength(1));
      expect(functions.invocations.single.name, 'getRemainingLikes');
      expect(functions.invocations.single.parameters, isNull);
    });

    test(
      'submitAction forwards the swipe payload directly to the callable',
      () async {
        final firestore = FakeFirebaseFirestore();
        final functions = _FakeFunctions(
          handlers: {
            'submitMatchpointAction': (_) async =>
                _FakeHttpsCallableResult(<String, dynamic>{
                  'success': true,
                  'isMatch': true,
                  'conversationId': 'conversation-1',
                  'remainingLikes': 12,
                }),
          },
        );
        final dataSource = _buildDataSource(firestore, functions);

        final result = await dataSource.submitAction(
          targetUserId: 'target-1',
          action: 'like',
        );

        expect(result.success, isTrue);
        expect(result.isMatch, isTrue);
        expect(result.conversationId, 'conversation-1');
        expect(functions.invocations, hasLength(1));
        expect(functions.invocations.single.name, 'submitMatchpointAction');
        expect(functions.invocations.single.parameters, <String, dynamic>{
          'targetUserId': 'target-1',
          'action': 'like',
        });
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
    test(
      'fetchHashtagRanking reads from Firestore ordered by use_count',
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
      },
    );

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
