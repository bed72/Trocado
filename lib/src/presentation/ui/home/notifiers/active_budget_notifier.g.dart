// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_budget_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ActiveBudgetNotifier)
final activeBudgetProvider = ActiveBudgetNotifierProvider._();

final class ActiveBudgetNotifierProvider
    extends
        $AsyncNotifierProvider<
          ActiveBudgetNotifier,
          BudgetCardPresentationData?
        > {
  ActiveBudgetNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeBudgetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeBudgetNotifierHash();

  @$internal
  @override
  ActiveBudgetNotifier create() => ActiveBudgetNotifier();
}

String _$activeBudgetNotifierHash() =>
    r'4ba1207b0c4b90fd6e68f3164c1f0cf6062b3aa9';

abstract class _$ActiveBudgetNotifier
    extends $AsyncNotifier<BudgetCardPresentationData?> {
  FutureOr<BudgetCardPresentationData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<BudgetCardPresentationData?>,
              BudgetCardPresentationData?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<BudgetCardPresentationData?>,
                BudgetCardPresentationData?
              >,
              AsyncValue<BudgetCardPresentationData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
