// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'matchpoint_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MatchpointController)
const matchpointControllerProvider = MatchpointControllerProvider._();

final class MatchpointControllerProvider
    extends $AsyncNotifierProvider<MatchpointController, void> {
  const MatchpointControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchpointControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchpointControllerHash();

  @$internal
  @override
  MatchpointController create() => MatchpointController();
}

String _$matchpointControllerHash() =>
    r'9d781204a320a2cd656d7c7b14596882862fa324';

abstract class _$MatchpointController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

/// Provider para quota de likes

@ProviderFor(LikesQuota)
const likesQuotaProvider = LikesQuotaProvider._();

/// Provider para quota de likes
final class LikesQuotaProvider
    extends $NotifierProvider<LikesQuota, LikesQuotaState> {
  /// Provider para quota de likes
  const LikesQuotaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'likesQuotaProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$likesQuotaHash();

  @$internal
  @override
  LikesQuota create() => LikesQuota();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LikesQuotaState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LikesQuotaState>(value),
    );
  }
}

String _$likesQuotaHash() => r'b708bea0ad483f5cc79b1b3ba6d8680f6d823eba';

/// Provider para quota de likes

abstract class _$LikesQuota extends $Notifier<LikesQuotaState> {
  LikesQuotaState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<LikesQuotaState, LikesQuotaState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LikesQuotaState, LikesQuotaState>,
              LikesQuotaState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider para lista de candidatos com estado mutável (UI otimista)

@ProviderFor(MatchpointCandidates)
const matchpointCandidatesProvider = MatchpointCandidatesProvider._();

/// Provider para lista de candidatos com estado mutável (UI otimista)
final class MatchpointCandidatesProvider
    extends $AsyncNotifierProvider<MatchpointCandidates, List<AppUser>> {
  /// Provider para lista de candidatos com estado mutável (UI otimista)
  const MatchpointCandidatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchpointCandidatesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchpointCandidatesHash();

  @$internal
  @override
  MatchpointCandidates create() => MatchpointCandidates();
}

String _$matchpointCandidatesHash() =>
    r'05c71d68abb8aa4821ae587084f7abdfd8b4a696';

/// Provider para lista de candidatos com estado mutável (UI otimista)

abstract class _$MatchpointCandidates extends $AsyncNotifier<List<AppUser>> {
  FutureOr<List<AppUser>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<AppUser>>, List<AppUser>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AppUser>>, List<AppUser>>,
              AsyncValue<List<AppUser>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider para lista de matches do usuário

@ProviderFor(matches)
const matchesProvider = MatchesProvider._();

/// Provider para lista de matches do usuário

final class MatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchInfo>>,
          List<MatchInfo>,
          FutureOr<List<MatchInfo>>
        >
    with $FutureModifier<List<MatchInfo>>, $FutureProvider<List<MatchInfo>> {
  /// Provider para lista de matches do usuário
  const MatchesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'matchesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$matchesHash();

  @$internal
  @override
  $FutureProviderElement<List<MatchInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MatchInfo>> create(Ref ref) {
    return matches(ref);
  }
}

String _$matchesHash() => r'd71f8f40e378e8c2e11aec803262cbeaae8783e3';

/// Provider para ranking de hashtags

@ProviderFor(hashtagRanking)
const hashtagRankingProvider = HashtagRankingFamily._();

/// Provider para ranking de hashtags

final class HashtagRankingProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HashtagRanking>>,
          List<HashtagRanking>,
          FutureOr<List<HashtagRanking>>
        >
    with
        $FutureModifier<List<HashtagRanking>>,
        $FutureProvider<List<HashtagRanking>> {
  /// Provider para ranking de hashtags
  const HashtagRankingProvider._({
    required HashtagRankingFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'hashtagRankingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hashtagRankingHash();

  @override
  String toString() {
    return r'hashtagRankingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HashtagRanking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HashtagRanking>> create(Ref ref) {
    final argument = this.argument as int;
    return hashtagRanking(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HashtagRankingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hashtagRankingHash() => r'4021cf2e5872fee7673eadb15616b33c860d5dfb';

/// Provider para ranking de hashtags

final class HashtagRankingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HashtagRanking>>, int> {
  const HashtagRankingFamily._()
    : super(
        retry: null,
        name: r'hashtagRankingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider para ranking de hashtags

  HashtagRankingProvider call(int limit) =>
      HashtagRankingProvider._(argument: limit, from: this);

  @override
  String toString() => r'hashtagRankingProvider';
}

/// Provider para busca de hashtags

@ProviderFor(hashtagSearch)
const hashtagSearchProvider = HashtagSearchFamily._();

/// Provider para busca de hashtags

final class HashtagSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HashtagRanking>>,
          List<HashtagRanking>,
          FutureOr<List<HashtagRanking>>
        >
    with
        $FutureModifier<List<HashtagRanking>>,
        $FutureProvider<List<HashtagRanking>> {
  /// Provider para busca de hashtags
  const HashtagSearchProvider._({
    required HashtagSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hashtagSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hashtagSearchHash();

  @override
  String toString() {
    return r'hashtagSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HashtagRanking>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HashtagRanking>> create(Ref ref) {
    final argument = this.argument as String;
    return hashtagSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HashtagSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hashtagSearchHash() => r'0eab766807c22e23dae2e268c4ae0c514bb0532e';

/// Provider para busca de hashtags

final class HashtagSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<HashtagRanking>>, String> {
  const HashtagSearchFamily._()
    : super(
        retry: null,
        name: r'hashtagSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider para busca de hashtags

  HashtagSearchProvider call(String query) =>
      HashtagSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'hashtagSearchProvider';
}

/// Provider para histórico de swipes local (sessão atual)

@ProviderFor(SwipeHistory)
const swipeHistoryProvider = SwipeHistoryProvider._();

/// Provider para histórico de swipes local (sessão atual)
final class SwipeHistoryProvider
    extends $NotifierProvider<SwipeHistory, List<SwipeHistoryItem>> {
  /// Provider para histórico de swipes local (sessão atual)
  const SwipeHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeHistoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeHistoryHash();

  @$internal
  @override
  SwipeHistory create() => SwipeHistory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SwipeHistoryItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SwipeHistoryItem>>(value),
    );
  }
}

String _$swipeHistoryHash() => r'69246f49bfb8ec3d48031ef382a5f638f9d10f9b';

/// Provider para histórico de swipes local (sessão atual)

abstract class _$SwipeHistory extends $Notifier<List<SwipeHistoryItem>> {
  List<SwipeHistoryItem> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<List<SwipeHistoryItem>, List<SwipeHistoryItem>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SwipeHistoryItem>, List<SwipeHistoryItem>>,
              List<SwipeHistoryItem>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
