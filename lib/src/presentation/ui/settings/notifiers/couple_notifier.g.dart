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

String _$coupleNotifierHash() => r'6fae6af5d8072ef47ca4bd817c6344e74c020e07';

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
