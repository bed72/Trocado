// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple_scan_confirm_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoupleScanConfirmNotifier)
final coupleScanConfirmProvider = CoupleScanConfirmNotifierProvider._();

final class CoupleScanConfirmNotifierProvider
    extends
        $NotifierProvider<CoupleScanConfirmNotifier, CoupleScanConfirmState> {
  CoupleScanConfirmNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coupleScanConfirmProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coupleScanConfirmNotifierHash();

  @$internal
  @override
  CoupleScanConfirmNotifier create() => CoupleScanConfirmNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoupleScanConfirmState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoupleScanConfirmState>(value),
    );
  }
}

String _$coupleScanConfirmNotifierHash() =>
    r'e68c9207f7cd724b774eb0bad60252f55705b5e2';

abstract class _$CoupleScanConfirmNotifier
    extends $Notifier<CoupleScanConfirmState> {
  CoupleScanConfirmState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<CoupleScanConfirmState, CoupleScanConfirmState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CoupleScanConfirmState, CoupleScanConfirmState>,
              CoupleScanConfirmState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
