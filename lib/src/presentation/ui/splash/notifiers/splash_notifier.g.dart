// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SplashNotifier)
final splashProvider = SplashNotifierProvider._();

final class SplashNotifierProvider
    extends $AsyncNotifierProvider<SplashNotifier, SplashStatus> {
  SplashNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splashProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splashNotifierHash();

  @$internal
  @override
  SplashNotifier create() => SplashNotifier();
}

String _$splashNotifierHash() => r'2728778d1fccd8e96c563b7235021ec478e0cc9b';

abstract class _$SplashNotifier extends $AsyncNotifier<SplashStatus> {
  FutureOr<SplashStatus> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<SplashStatus>, SplashStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SplashStatus>, SplashStatus>,
              AsyncValue<SplashStatus>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
