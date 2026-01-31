import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mube/src/app.dart';
import 'package:mube/src/core/typedefs.dart';
import 'package:mube/src/features/auth/data/auth_repository.dart';
import 'package:mube/src/features/auth/domain/app_user.dart';
import 'package:mube/src/features/auth/domain/user_type.dart';
import 'package:mube/src/features/feed/data/feed_repository.dart';
import 'package:mube/src/features/feed/domain/feed_item.dart';
import 'package:mube/src/features/feed/domain/paginated_feed_response.dart';
import 'package:mube/src/features/search/data/search_repository.dart';
import 'package:mube/src/features/search/domain/search_filters.dart';

// --- STUBS & MOCKS ---

class MockUser implements User {
  @override
  String get uid => 'mock_user_123';
  @override
  String? get email => 'artista@mube.app';
  @override
  String? get displayName => 'Artista Demo';
  @override
  String? get photoURL => 'https://i.pravatar.cc/300';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final mockAuthStreamController = StreamController<User?>.broadcast();
final mockProfileStreamController = StreamController<AppUser?>.broadcast();

class MockAuthRepository implements AuthRepository {
  @override
  Stream<User?> authStateChanges() => mockAuthStreamController.stream;

  @override
  Stream<AppUser?> watchUser(String uid) => mockProfileStreamController.stream;

  @override
  User? get currentUser => null;

  @override
  FutureResult<Unit> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = MockUser();

    final appUser = AppUser(
      uid: user.uid,
      email: user.email!,
      nome: user.displayName,
      foto: user.photoURL,
      tipoPerfil: AppUserType.professional,
      dadosProfissional: {
        'genres': ['Rock', 'Pop', 'Indie'],
        'skills': ['Vocal', 'Guitarra'],
      },
      bio: 'Artista demonstrativo para screenshots.',
      createdAt: DateTime.now(),
      cadastroStatus: 'concluido',
    );

    mockAuthStreamController.add(user);
    mockProfileStreamController.add(appUser);

    return const Right(unit);
  }

  @override
  FutureResult<Unit> signOut() async {
    mockAuthStreamController.add(null);
    mockProfileStreamController.add(null);
    return const Right(unit);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUsersByIds) {
      return Future.value(const Right(<AppUser>[]));
    }
    return super.noSuchMethod(invocation);
  }
}

// --- DUMMY DATA ---

final List<FeedItem> _dummyFeedItems = [
  const FeedItem(
    uid: 'artist_1',
    nome: 'Ana Silva',
    nomeArtistico: 'Ana Rocks',
    foto: 'https://i.pravatar.cc/301',
    categoria: 'Profissional',
    generosMusicais: ['rock', 'blues'],
    tipoPerfil: 'profissional',
    likeCount: 120,
    skills: ['Guitarra', 'Voz'],
    location: {'lat': 0.0, 'lng': 0.0},
    distanceKm: 2.5,
  ),
  const FeedItem(
    uid: 'band_1',
    nome: 'The Fakes',
    nomeArtistico: 'The Real Fakes',
    foto: 'https://i.pravatar.cc/302',
    categoria: 'Banda',
    generosMusicais: ['indie', 'pop'],
    tipoPerfil: 'banda',
    likeCount: 450,
    skills: [],
    location: {'lat': 0.0, 'lng': 0.0},
    distanceKm: 5.0,
  ),
  const FeedItem(
    uid: 'studio_1',
    nome: 'Studio Box',
    nomeArtistico: 'Studio Box Records',
    foto: 'https://i.pravatar.cc/303',
    categoria: 'Estúdio',
    generosMusicais: [],
    tipoPerfil: 'estudio',
    likeCount: 89,
    skills: ['Gravação', 'Mixagem'],
    location: {'lat': 0.0, 'lng': 0.0},
    distanceKm: 1.2,
  ),
  const FeedItem(
    uid: 'artist_2',
    nome: 'Carlos Drum',
    nomeArtistico: 'Carlinhos Batera',
    foto: 'https://i.pravatar.cc/304',
    categoria: 'Profissional',
    generosMusicais: ['samba', 'pagode'],
    tipoPerfil: 'profissional',
    likeCount: 32,
    skills: ['Bateria', 'Percussão'],
    location: {'lat': 0.0, 'lng': 0.0},
    distanceKm: 8.0,
  ),
];

// --- FEED REPOSITORY MOCK ---

class MockFeedRepository implements FeedRepository {
  @override
  FutureResult<PaginatedFeedResponse> getMainFeedPaginated({
    required String currentUserId,
    String? filterType,
    double? userLat,
    double? userLong,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    return Right(PaginatedFeedResponse(items: _dummyFeedItems, hasMore: false));
  }

  // Implement other methods essentially returning empty or dummy data
  // Using noSuchMethod for brevity on unused methods, but implementing required ones

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return empty list or failures for other methods to avoid crashes
    if (invocation.memberName == #getUsersByIds) {
      return Future.value(const Right(<FeedItem>[]));
    }
    if (invocation.memberName == #getNearbyUsers) {
      return Future.value(const Right(<FeedItem>[]));
    }
    return super.noSuchMethod(invocation);
  }
}

// --- SEARCH REPOSITORY MOCK ---

class MockSearchRepository implements SearchRepository {
  @override
  FutureResult<List<FeedItem>> searchUsers({
    required SearchFilters filters,
    DocumentSnapshot? startAfter,
    required int requestId,
    required ValueGetter<int> getCurrentRequestId,
    List<String> blockedUsers = const [],
  }) async {
    // Return all dummy items for any search
    return Right(_dummyFeedItems);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Inicializa controllers com estado deslogado
  mockAuthStreamController.add(null);
  mockProfileStreamController.add(null);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        authStateChangesProvider.overrideWith(
          (ref) => mockAuthStreamController.stream,
        ),
        currentUserProfileProvider.overrideWith(
          (ref) => mockProfileStreamController.stream,
        ),

        feedRepositoryProvider.overrideWithValue(MockFeedRepository()),
        searchRepositoryProvider.overrideWithValue(MockSearchRepository()),
      ],
      child: const MubeApp(),
    ),
  );
}
