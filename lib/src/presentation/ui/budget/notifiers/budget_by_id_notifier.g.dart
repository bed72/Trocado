// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_by_id_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BudgetByIdNotifier)
final budgetByIdProvider = BudgetByIdNotifierFamily._();

final class BudgetByIdNotifierProvider
    extends $AsyncNotifierProvider<BudgetByIdNotifier, BudgetModel> {
  BudgetByIdNotifierProvider._({
    required BudgetByIdNotifierFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'budgetByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetByIdNotifierHash();

  @override
  String toString() {
    return r'budgetByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  BudgetByIdNotifier create() => BudgetByIdNotifier();

  @override
  bool operator ==(Object other) {
    return other is BudgetByIdNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetByIdNotifierHash() =>
    r'94177b25b0b8687deffb130866b6b14625ea67dd';

final class BudgetByIdNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          BudgetByIdNotifier,
          AsyncValue<BudgetModel>,
          BudgetModel,
          FutureOr<BudgetModel>,
          int
        > {
  BudgetByIdNotifierFamily._()
    : super(
        retry: null,
        name: r'budgetByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BudgetByIdNotifierProvider call(int id) =>
      BudgetByIdNotifierProvider._(argument: id, from: this);

  @override
  String toString() => r'budgetByIdProvider';
}

abstract class _$BudgetByIdNotifier extends $AsyncNotifier<BudgetModel> {
  late final _$args = ref.$arg as int;
  int get id => _$args;

  FutureOr<BudgetModel> build(int id);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BudgetModel>, BudgetModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BudgetModel>, BudgetModel>,
              AsyncValue<BudgetModel>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
