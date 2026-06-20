// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expenses_filters_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpensesFiltersNotifier)
final expensesFiltersProvider = ExpensesFiltersNotifierFamily._();

final class ExpensesFiltersNotifierProvider
    extends $NotifierProvider<ExpensesFiltersNotifier, ExpensesFiltersState> {
  ExpensesFiltersNotifierProvider._({
    required ExpensesFiltersNotifierFamily super.from,
    required ExpenseFilterModel super.argument,
  }) : super(
         retry: null,
         name: r'expensesFiltersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expensesFiltersNotifierHash();

  @override
  String toString() {
    return r'expensesFiltersProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is ExpensesFiltersNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expensesFiltersNotifierHash() =>
    r'9d534b5f291ec3ccf33383015406a66e40b02846';

final class ExpensesFiltersNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ExpensesFiltersNotifier,
          ExpensesFiltersState,
          ExpensesFiltersState,
          ExpensesFiltersState,
          ExpenseFilterModel
        > {
  ExpensesFiltersNotifierFamily._()
    : super(
        retry: null,
        name: r'expensesFiltersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpensesFiltersNotifierProvider call(ExpenseFilterModel seed) =>
      ExpensesFiltersNotifierProvider._(argument: seed, from: this);

  @override
  String toString() => r'expensesFiltersProvider';
}

abstract class _$ExpensesFiltersNotifier
    extends $Notifier<ExpensesFiltersState> {
  late final _$args = ref.$arg as ExpenseFilterModel;
  ExpenseFilterModel get seed => _$args;

  ExpensesFiltersState build(ExpenseFilterModel seed);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExpensesFiltersState, ExpensesFiltersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExpensesFiltersState, ExpensesFiltersState>,
              ExpensesFiltersState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
