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
    r'aa863a156b5d80cc745cb45abe00def198b394ac';

abstract class _$CoupleDissolveNotifier
    extends $AsyncNotifier<CoupleDissolveState> {
  FutureOr<CoupleDissolveState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
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
    return element.handleCreate(ref, build);
  }
}
