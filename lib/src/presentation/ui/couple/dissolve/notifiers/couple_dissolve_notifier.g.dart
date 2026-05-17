// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'couple_dissolve_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CoupleDissolveNotifier)
final coupleDissolveProvider = CoupleDissolveNotifierProvider._();

final class CoupleDissolveNotifierProvider
    extends
        $AsyncNotifierProvider<CoupleDissolveNotifier, CoupleDissolveState> {
  CoupleDissolveNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coupleDissolveProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coupleDissolveNotifierHash();

  @$internal
  @override
  CoupleDissolveNotifier create() => CoupleDissolveNotifier();
}

String _$coupleDissolveNotifierHash() =>
    r'29b15160c9f3a95523f8e670d6bd65554a255db9';

abstract class _$CoupleDissolveNotifier
    extends $AsyncNotifier<CoupleDissolveState> {
  FutureOr<CoupleDissolveState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CoupleDissolveState>, CoupleDissolveState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CoupleDissolveState>, CoupleDissolveState>,
              AsyncValue<CoupleDissolveState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
