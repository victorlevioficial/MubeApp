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

String _$gigsStreamHash() => r'ed9c7d6a9e944dcac397927333fb171a1ade7cd2';

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
        isAutoDispose: true,
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

String _$myGigsStreamHash() => r'f6e6c030fed521c08f0d9c95bffcc215b94db1ef';

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

String _$gigDetailHash() => r'def527d36d3cb26d7f504ffce141a3495faa5fcd';

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

String _$gigApplicationsHash() => r'393350b6c8931f27a3485455e47a303ebb356275';

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
        isAutoDispose: true,
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

String _$myApplicationsHash() => r'f5e6450c9b1a1bfeac5be0b82412ab19693fd5d0';

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

String _$hasAppliedHash() => r'ac90d5ac3eca82991f524ca6726f4df669f8b085';

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

String _$userReviewsHash() => r'f3e2b33c958aeb0ae658bb037044671c15f3056d';

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

String _$userAverageRatingHash() => r'b9b8234fd1f6bcaf4d9de9aae2cee3b8ededde35';

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

String _$gigUsersByIdsHash() => r'dfae2fa093e6064ca144304ea3b8274baff29414';

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

String _$pendingGigReviewsHash() => r'8d415e275ce9608edf17016c3ec172111a0539ae';
