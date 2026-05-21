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
    r'bd4eb99a8a54b04ead65c2375f36b145ac527fda';

abstract class _$HomeAppBarNotifier
    extends $AsyncNotifier<HomeAppBarPresentationData> {
  FutureOr<HomeAppBarPresentationData> build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
