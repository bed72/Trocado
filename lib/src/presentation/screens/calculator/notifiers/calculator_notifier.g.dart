// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculator_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalculatorNotifier)
final calculatorProvider = CalculatorNotifierProvider._();

final class CalculatorNotifierProvider
    extends $NotifierProvider<CalculatorNotifier, CalculatorState> {
  CalculatorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calculatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calculatorNotifierHash();

  @$internal
  @override
  CalculatorNotifier create() => CalculatorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalculatorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalculatorState>(value),
    );
  }
}

String _$calculatorNotifierHash() =>
    r'a96a1e0d45461b9d7198f36542822d8b4af7ea8e';

abstract class _$CalculatorNotifier extends $Notifier<CalculatorState> {
  CalculatorState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CalculatorState, CalculatorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CalculatorState, CalculatorState>,
              CalculatorState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
