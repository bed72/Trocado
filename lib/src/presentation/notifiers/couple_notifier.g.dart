// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoupleNotifier)
final coupleProvider = CoupleNotifierProvider._();

final class CoupleNotifierProvider
    extends $AsyncNotifierProvider<CoupleNotifier, CoupleModel?> {
  CoupleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coupleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coupleNotifierHash();

  @$internal
  @override
  CoupleNotifier create() => CoupleNotifier();
}

String _$coupleNotifierHash() => r'b6e8d60de33af3e4407300cf1a4af85720dbcd2b';

abstract class _$CoupleNotifier extends $AsyncNotifier<CoupleModel?> {
  FutureOr<CoupleModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CoupleModel?>, CoupleModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CoupleModel?>, CoupleModel?>,
              AsyncValue<CoupleModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
