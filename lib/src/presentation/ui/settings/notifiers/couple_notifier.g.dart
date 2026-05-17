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
    extends $AsyncNotifierProvider<CoupleNotifier, CoupleCardState> {
  CoupleNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coupleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coupleNotifierHash();

  @$internal
  @override
  CoupleNotifier create() => CoupleNotifier();
}

String _$coupleNotifierHash() => r'ee4def98b73a194775dff275ec6450c649204be9';

abstract class _$CoupleNotifier extends $AsyncNotifier<CoupleCardState> {
  FutureOr<CoupleCardState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CoupleCardState>, CoupleCardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CoupleCardState>, CoupleCardState>,
              AsyncValue<CoupleCardState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
