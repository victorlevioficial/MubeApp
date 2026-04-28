// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gig_streams.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gigsStream)
const gigsStreamProvider = GigsStreamProvider._();

final class GigsStreamProvider
    extends
        $FunctionalProvider<AsyncValue<List<Gig>>, List<Gig>, Stream<List<Gig>>>
    with $FutureModifier<List<Gig>>, $StreamProvider<List<Gig>> {
  const GigsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gigsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gigsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Gig>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Gig>> create(Ref ref) {
    return gigsStream(ref);
  }
}

String _$gigsStreamHash() => r'e818dab7479d0aff5bc80d93c9206cc6f467cd1f';

@ProviderFor(myGigsStream)
const myGigsStreamProvider = MyGigsStreamProvider._();

final class MyGigsStreamProvider
    extends
        $FunctionalProvider<AsyncValue<List<Gig>>, List<Gig>, Stream<List<Gig>>>
    with $FutureModifier<List<Gig>>, $StreamProvider<List<Gig>> {
  const MyGigsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myGigsStreamProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myGigsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Gig>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Gig>> create(Ref ref) {
    return myGigsStream(ref);
  }
}

String _$myGigsStreamHash() => r'fc11057cf1a1a81526536e33b2eb7206b36a6bbe';

@ProviderFor(gigDetail)
const gigDetailProvider = GigDetailFamily._();

final class GigDetailProvider
    extends $FunctionalProvider<AsyncValue<Gig?>, Gig?, Stream<Gig?>>
    with $FutureModifier<Gig?>, $StreamProvider<Gig?> {
  const GigDetailProvider._({
    required GigDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gigDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gigDetailHash();

  @override
  String toString() {
    return r'gigDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Gig?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Gig?> create(Ref ref) {
    final argument = this.argument as String;
    return gigDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GigDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gigDetailHash() => r'2ef0bcf27aee20a9705acbf7c099a1830ba7cbfa';

final class GigDetailFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Gig?>, String> {
  const GigDetailFamily._()
    : super(
        retry: null,
        name: r'gigDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GigDetailProvider call(String gigId) =>
      GigDetailProvider._(argument: gigId, from: this);

  @override
  String toString() => r'gigDetailProvider';
}

@ProviderFor(gigApplications)
const gigApplicationsProvider = GigApplicationsFamily._();

final class GigApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GigApplication>>,
          List<GigApplication>,
          Stream<List<GigApplication>>
        >
    with
        $FutureModifier<List<GigApplication>>,
        $StreamProvider<List<GigApplication>> {
  const GigApplicationsProvider._({
    required GigApplicationsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gigApplicationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gigApplicationsHash();

  @override
  String toString() {
    return r'gigApplicationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GigApplication>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GigApplication>> create(Ref ref) {
    final argument = this.argument as String;
    return gigApplications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GigApplicationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gigApplicationsHash() => r'96649fbe4b7f840bbcf4a63a63ab8ec3e059da82';

final class GigApplicationsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GigApplication>>, String> {
  const GigApplicationsFamily._()
    : super(
        retry: null,
        name: r'gigApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GigApplicationsProvider call(String gigId) =>
      GigApplicationsProvider._(argument: gigId, from: this);

  @override
  String toString() => r'gigApplicationsProvider';
}

@ProviderFor(myApplications)
const myApplicationsProvider = MyApplicationsProvider._();

final class MyApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GigApplication>>,
          List<GigApplication>,
          Stream<List<GigApplication>>
        >
    with
        $FutureModifier<List<GigApplication>>,
        $StreamProvider<List<GigApplication>> {
  const MyApplicationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myApplicationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myApplicationsHash();

  @$internal
  @override
  $StreamProviderElement<List<GigApplication>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GigApplication>> create(Ref ref) {
    return myApplications(ref);
  }
}

String _$myApplicationsHash() => r'b2239b8c0d3cab5baa8393ad098090027d0ba941';

@ProviderFor(hasApplied)
const hasAppliedProvider = HasAppliedFamily._();

final class HasAppliedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  const HasAppliedProvider._({
    required HasAppliedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'hasAppliedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hasAppliedHash();

  @override
  String toString() {
    return r'hasAppliedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return hasApplied(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HasAppliedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hasAppliedHash() => r'53fcb464630a7dce0f6505636550ee8aa8cc12c6';

final class HasAppliedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  const HasAppliedFamily._()
    : super(
        retry: null,
        name: r'hasAppliedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  HasAppliedProvider call(String gigId) =>
      HasAppliedProvider._(argument: gigId, from: this);

  @override
  String toString() => r'hasAppliedProvider';
}

@ProviderFor(userReviews)
const userReviewsProvider = UserReviewsFamily._();

final class UserReviewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GigReview>>,
          List<GigReview>,
          Stream<List<GigReview>>
        >
    with $FutureModifier<List<GigReview>>, $StreamProvider<List<GigReview>> {
  const UserReviewsProvider._({
    required UserReviewsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userReviewsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userReviewsHash();

  @override
  String toString() {
    return r'userReviewsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GigReview>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GigReview>> create(Ref ref) {
    final argument = this.argument as String;
    return userReviews(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserReviewsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userReviewsHash() => r'c1561803921136b8e6156db10e33439e1fa52517';

final class UserReviewsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GigReview>>, String> {
  const UserReviewsFamily._()
    : super(
        retry: null,
        name: r'userReviewsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserReviewsProvider call(String userId) =>
      UserReviewsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userReviewsProvider';
}

@ProviderFor(userAverageRating)
const userAverageRatingProvider = UserAverageRatingFamily._();

final class UserAverageRatingProvider
    extends $FunctionalProvider<AsyncValue<double?>, double?, FutureOr<double?>>
    with $FutureModifier<double?>, $FutureProvider<double?> {
  const UserAverageRatingProvider._({
    required UserAverageRatingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userAverageRatingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userAverageRatingHash();

  @override
  String toString() {
    return r'userAverageRatingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<double?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<double?> create(Ref ref) {
    final argument = this.argument as String;
    return userAverageRating(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserAverageRatingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userAverageRatingHash() => r'c778ffbce0d39c6d6fc734d9fe61611a5f91a5a6';

final class UserAverageRatingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<double?>, String> {
  const UserAverageRatingFamily._()
    : super(
        retry: null,
        name: r'userAverageRatingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserAverageRatingProvider call(String userId) =>
      UserAverageRatingProvider._(argument: userId, from: this);

  @override
  String toString() => r'userAverageRatingProvider';
}

@ProviderFor(gigUsersByIds)
const gigUsersByIdsProvider = GigUsersByIdsFamily._();

final class GigUsersByIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, AppUser>>,
          Map<String, AppUser>,
          FutureOr<Map<String, AppUser>>
        >
    with
        $FutureModifier<Map<String, AppUser>>,
        $FutureProvider<Map<String, AppUser>> {
  const GigUsersByIdsProvider._({
    required GigUsersByIdsFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'gigUsersByIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gigUsersByIdsHash();

  @override
  String toString() {
    return r'gigUsersByIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, AppUser>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return gigUsersByIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GigUsersByIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gigUsersByIdsHash() => r'34379fb3d5ad527991af2b8895e5d7bd4f8060f7';

final class GigUsersByIdsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, AppUser>>,
          List<String>
        > {
  const GigUsersByIdsFamily._()
    : super(
        retry: null,
        name: r'gigUsersByIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GigUsersByIdsProvider call(List<String> ids) =>
      GigUsersByIdsProvider._(argument: ids, from: this);

  @override
  String toString() => r'gigUsersByIdsProvider';
}

@ProviderFor(pendingGigReviews)
const pendingGigReviewsProvider = PendingGigReviewsProvider._();

final class PendingGigReviewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GigReviewOpportunity>>,
          List<GigReviewOpportunity>,
          FutureOr<List<GigReviewOpportunity>>
        >
    with
        $FutureModifier<List<GigReviewOpportunity>>,
        $FutureProvider<List<GigReviewOpportunity>> {
  const PendingGigReviewsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingGigReviewsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingGigReviewsHash();

  @$internal
  @override
  $FutureProviderElement<List<GigReviewOpportunity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GigReviewOpportunity>> create(Ref ref) {
    return pendingGigReviews(ref);
  }
}

String _$pendingGigReviewsHash() => r'd8d715c5781659e8f6917c84086d08ee31c26b19';
