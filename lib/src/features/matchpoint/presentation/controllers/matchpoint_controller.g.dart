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
    r'85359e14c8abe55ef70f51f9a9b43c794d5c0f3a';

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

@ProviderFor(LikesQuota)
const likesQuotaProvider = LikesQuotaProvider._();

final class LikesQuotaProvider
    extends $NotifierProvider<LikesQuota, LikesQuotaState> {
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

@ProviderFor(MatchpointCandidates)
const matchpointCandidatesProvider = MatchpointCandidatesProvider._();

final class MatchpointCandidatesProvider
    extends $AsyncNotifierProvider<MatchpointCandidates, List<AppUser>> {
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
    r'06d3150b2a9e6397aafc7d8d7dcfe5f925e4390c';

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

@ProviderFor(matches)
const matchesProvider = MatchesProvider._();

final class MatchesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MatchInfo>>,
          List<MatchInfo>,
          FutureOr<List<MatchInfo>>
        >
    with $FutureModifier<List<MatchInfo>>, $FutureProvider<List<MatchInfo>> {
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

String _$matchesHash() => r'cd253537feb2462e93934711a0e809c1bbbc0859';

@ProviderFor(hashtagRanking)
const hashtagRankingProvider = HashtagRankingFamily._();

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

String _$hashtagRankingHash() => r'64c4fe7fe232125271a2f8d1449e327761a6db83';

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

  HashtagRankingProvider call(int limit) =>
      HashtagRankingProvider._(argument: limit, from: this);

  @override
  String toString() => r'hashtagRankingProvider';
}

@ProviderFor(hashtagSearch)
const hashtagSearchProvider = HashtagSearchFamily._();

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

String _$hashtagSearchHash() => r'b1dc900ef07ecf4df2d0c2de1193ca7b282dfd6e';

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

  HashtagSearchProvider call(String query) =>
      HashtagSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'hashtagSearchProvider';
}

@ProviderFor(SwipeHistory)
const swipeHistoryProvider = SwipeHistoryProvider._();

final class SwipeHistoryProvider
    extends $NotifierProvider<SwipeHistory, List<SwipeHistoryEntry>> {
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
  Override overrideWithValue(List<SwipeHistoryEntry> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SwipeHistoryEntry>>(value),
    );
  }
}

String _$swipeHistoryHash() => r'65dc9de5bcd08014947570a1fe1928b8d2047dad';

abstract class _$SwipeHistory extends $Notifier<List<SwipeHistoryEntry>> {
  List<SwipeHistoryEntry> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<List<SwipeHistoryEntry>, List<SwipeHistoryEntry>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SwipeHistoryEntry>, List<SwipeHistoryEntry>>,
              List<SwipeHistoryEntry>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
