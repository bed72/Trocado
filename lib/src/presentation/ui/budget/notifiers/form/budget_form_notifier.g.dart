// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_form_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BudgetFormNotifier)
final budgetFormProvider = BudgetFormNotifierFamily._();

final class BudgetFormNotifierProvider
    extends $AsyncNotifierProvider<BudgetFormNotifier, BudgetFormState> {
  BudgetFormNotifierProvider._({
    required BudgetFormNotifierFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'budgetFormProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetFormNotifierHash();

  @override
  String toString() {
    return r'budgetFormProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BudgetFormNotifier create() => BudgetFormNotifier();

  @override
  bool operator ==(Object other) {
    return other is BudgetFormNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetFormNotifierHash() =>
    r'd2d482778c466f3dd513ad744439e63a16b7241f';

final class BudgetFormNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BudgetFormNotifier,
          AsyncValue<BudgetFormState>,
          BudgetFormState,
          FutureOr<BudgetFormState>,
          int?
        > {
  BudgetFormNotifierFamily._()
    : super(
        retry: null,
        name: r'budgetFormProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BudgetFormNotifierProvider call(int? id) =>
      BudgetFormNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'budgetFormProvider';
}

abstract class _$BudgetFormNotifier extends $AsyncNotifier<BudgetFormState> {
  late final _$args = ref.$arg as int?;
  int? get id => _$args;

  FutureOr<BudgetFormState> build(int? id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BudgetFormState>, BudgetFormState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BudgetFormState>, BudgetFormState>,
              AsyncValue<BudgetFormState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
