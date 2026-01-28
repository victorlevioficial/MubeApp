// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_view_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(FeedListController)
const feedListControllerProvider = FeedListControllerFamily._();

final class FeedListControllerProvider
    extends $AsyncNotifierProvider<FeedListController, FeedListState> {
  const FeedListControllerProvider._({
    required FeedListControllerFamily super.from,
    required FeedSectionType super.argument,
  }) : super(
         retry: null,
         name: r'feedListControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedListControllerHash();

  @override
  String toString() {
    return r'feedListControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FeedListController create() => FeedListController();

  @override
  bool operator ==(Object other) {
    return other is FeedListControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedListControllerHash() =>
    r'967cc590388487a2e0e0e057bcd79a585b77583c';

final class FeedListControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          FeedListController,
          AsyncValue<FeedListState>,
          FeedListState,
          FutureOr<FeedListState>,
          FeedSectionType
        > {
  const FeedListControllerFamily._()
    : super(
        retry: null,
        name: r'feedListControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedListControllerProvider call(FeedSectionType sectionType) =>
      FeedListControllerProvider._(argument: sectionType, from: this);

  @override
  String toString() => r'feedListControllerProvider';
}

abstract class _$FeedListController extends $AsyncNotifier<FeedListState> {
  late final _$args = ref.$arg as FeedSectionType;
  FeedSectionType get sectionType => _$args;

  FutureOr<FeedListState> build(FeedSectionType sectionType);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<FeedListState>, FeedListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeedListState>, FeedListState>,
              AsyncValue<FeedListState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
