// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_by_id_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpenseByIdNotifier)
final expenseByIdProvider = ExpenseByIdNotifierFamily._();

final class ExpenseByIdNotifierProvider
    extends $AsyncNotifierProvider<ExpenseByIdNotifier, ExpenseModel> {
  ExpenseByIdNotifierProvider._({
    required ExpenseByIdNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'expenseByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expenseByIdNotifierHash();

  @override
  String toString() {
    return r'expenseByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ExpenseByIdNotifier create() => ExpenseByIdNotifier();

  @override
  bool operator ==(Object other) {
    return other is ExpenseByIdNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseByIdNotifierHash() =>
    r'ccd8d04450beea89f4221e656b8ce1f252a3e378';

final class ExpenseByIdNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ExpenseByIdNotifier,
          AsyncValue<ExpenseModel>,
          ExpenseModel,
          FutureOr<ExpenseModel>,
          int
        > {
  ExpenseByIdNotifierFamily._()
    : super(
        retry: null,
        name: r'expenseByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpenseByIdNotifierProvider call(int id) =>
      ExpenseByIdNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'expenseByIdProvider';
}

abstract class _$ExpenseByIdNotifier extends $AsyncNotifier<ExpenseModel> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<ExpenseModel> build(int id);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExpenseModel>, ExpenseModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExpenseModel>, ExpenseModel>,
              AsyncValue<ExpenseModel>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
