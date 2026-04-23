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
    extends $AsyncNotifierProvider<ActiveBudgetNotifier, BudgetCardData?> {
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
    r'6ab6b06b935a77ff9c995ab43d8d0d88d5252012';

abstract class _$ActiveBudgetNotifier extends $AsyncNotifier<BudgetCardData?> {
  FutureOr<BudgetCardData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BudgetCardData?>, BudgetCardData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BudgetCardData?>, BudgetCardData?>,
              AsyncValue<BudgetCardData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
