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
    extends
        $AsyncNotifierProvider<CoupleNotifier, CoupleCardPresentationData?> {
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

String _$coupleNotifierHash() => r'1276eb360822c7aafad68b05654e63406ee7b82c';

abstract class _$CoupleNotifier
    extends $AsyncNotifier<CoupleCardPresentationData?> {
  FutureOr<CoupleCardPresentationData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CoupleCardPresentationData?>,
              CoupleCardPresentationData?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CoupleCardPresentationData?>,
                CoupleCardPresentationData?
              >,
              AsyncValue<CoupleCardPresentationData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
