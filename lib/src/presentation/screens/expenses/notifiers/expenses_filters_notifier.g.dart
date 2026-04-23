// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expenses_filters_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpensesFiltersNotifier)
final expensesFiltersProvider = ExpensesFiltersNotifierProvider._();

final class ExpensesFiltersNotifierProvider
    extends $NotifierProvider<ExpensesFiltersNotifier, ExpensesFiltersState> {
  ExpensesFiltersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesFiltersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesFiltersNotifierHash();

  @$internal
  @override
  ExpensesFiltersNotifier create() => ExpensesFiltersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpensesFiltersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpensesFiltersState>(value),
    );
  }
}

String _$expensesFiltersNotifierHash() =>
    r'bf6fe5b9f3c20d1b65492fe46c0022618c375b7c';

abstract class _$ExpensesFiltersNotifier
    extends $Notifier<ExpensesFiltersState> {
  ExpensesFiltersState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExpensesFiltersState, ExpensesFiltersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExpensesFiltersState, ExpensesFiltersState>,
              ExpensesFiltersState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
