// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpenseNotifier)
final expenseProvider = ExpenseNotifierFamily._();

final class ExpenseNotifierProvider
    extends $NotifierProvider<ExpenseNotifier, ExpenseState> {
  ExpenseNotifierProvider._({
    required ExpenseNotifierFamily super.from,
    required ExpenseModel? super.argument,
  }) : super(
         retry: null,
         name: r'expenseProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseNotifierHash();

  @override
  String toString() {
    return r'expenseProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExpenseNotifier create() => ExpenseNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseNotifierHash() => r'fa79a88d91ba5511914427a6d6b521df76826c57';

final class ExpenseNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ExpenseNotifier,
          ExpenseState,
          ExpenseState,
          ExpenseState,
          ExpenseModel?
        > {
  ExpenseNotifierFamily._()
    : super(
        retry: null,
        name: r'expenseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpenseNotifierProvider call(ExpenseModel? expense) =>
      ExpenseNotifierProvider._(argument: expense, from: this);

  @override
  String toString() => r'expenseProvider';
}

abstract class _$ExpenseNotifier extends $Notifier<ExpenseState> {
  late final _$args = ref.$arg as ExpenseModel?;
  ExpenseModel? get expense => _$args;

  ExpenseState build(ExpenseModel? expense);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExpenseState, ExpenseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExpenseState, ExpenseState>,
              ExpenseState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
