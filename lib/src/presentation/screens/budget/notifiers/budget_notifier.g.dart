// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BudgetNotifier)
final budgetProvider = BudgetNotifierProvider._();

final class BudgetNotifierProvider
    extends $NotifierProvider<BudgetNotifier, BudgetState> {
  BudgetNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetNotifierHash();

  @$internal
  @override
  BudgetNotifier create() => BudgetNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetState>(value),
    );
  }
}

String _$budgetNotifierHash() => r'60ea8c59c413113bcd97f947c66da84345e985ac';

abstract class _$BudgetNotifier extends $Notifier<BudgetState> {
  BudgetState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<BudgetState, BudgetState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BudgetState, BudgetState>,
              BudgetState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
