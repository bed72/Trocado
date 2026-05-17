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
    extends $AsyncNotifierProvider<ExpenseNotifier, ExpenseState> {
  ExpenseNotifierProvider._({
    required ExpenseNotifierFamily super.from,
    required int? super.argument,
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

  @override
  bool operator ==(Object other) {
    return other is ExpenseNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseNotifierHash() => r'4e40164e37dc4f9f181d0576c9cc4ad589eb5e18';

final class ExpenseNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ExpenseNotifier,
          AsyncValue<ExpenseState>,
          ExpenseState,
          FutureOr<ExpenseState>,
          int?
        > {
  ExpenseNotifierFamily._()
    : super(
        retry: null,
        name: r'expenseProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpenseNotifierProvider call(int? id) =>
      ExpenseNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'expenseProvider';
}

abstract class _$ExpenseNotifier extends $AsyncNotifier<ExpenseState> {
  late final _$args = ref.$arg as int?;
  int? get id => _$args;

  FutureOr<ExpenseState> build(int? id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExpenseState>, ExpenseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExpenseState>, ExpenseState>,
              AsyncValue<ExpenseState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
