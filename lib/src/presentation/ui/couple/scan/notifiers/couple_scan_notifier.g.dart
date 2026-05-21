// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple_scan_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoupleScanNotifier)
final coupleScanProvider = CoupleScanNotifierProvider._();

final class CoupleScanNotifierProvider
    extends $AsyncNotifierProvider<CoupleScanNotifier, CoupleScanState> {
  CoupleScanNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coupleScanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coupleScanNotifierHash();

  @$internal
  @override
  CoupleScanNotifier create() => CoupleScanNotifier();
}

String _$coupleScanNotifierHash() =>
    r'90215a927383b7c17e354f97c3447ee8715fb804';

abstract class _$CoupleScanNotifier extends $AsyncNotifier<CoupleScanState> {
  FutureOr<CoupleScanState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CoupleScanState>, CoupleScanState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CoupleScanState>, CoupleScanState>,
              AsyncValue<CoupleScanState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
