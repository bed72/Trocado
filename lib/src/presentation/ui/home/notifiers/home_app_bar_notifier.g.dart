// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_app_bar_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeAppBarNotifier)
final homeAppBarProvider = HomeAppBarNotifierProvider._();

final class HomeAppBarNotifierProvider
    extends
        $AsyncNotifierProvider<HomeAppBarNotifier, HomeAppBarPresentationData> {
  HomeAppBarNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeAppBarProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeAppBarNotifierHash();

  @$internal
  @override
  HomeAppBarNotifier create() => HomeAppBarNotifier();
}

String _$homeAppBarNotifierHash() =>
    r'f912455ecb5c082b5b3cf2d5c34c6f7607da2e49';

abstract class _$HomeAppBarNotifier
    extends $AsyncNotifier<HomeAppBarPresentationData> {
  FutureOr<HomeAppBarPresentationData> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<HomeAppBarPresentationData>,
              HomeAppBarPresentationData
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<HomeAppBarPresentationData>,
                HomeAppBarPresentationData
              >,
              AsyncValue<HomeAppBarPresentationData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
