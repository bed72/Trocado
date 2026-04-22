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
    extends $AsyncNotifierProvider<ActiveBudgetNotifier, ActiveBudgetModel?> {
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
    r'a4081be7ebe4b387c4ed3115f88c0bdddef20f00';

abstract class _$ActiveBudgetNotifier
    extends $AsyncNotifier<ActiveBudgetModel?> {
  FutureOr<ActiveBudgetModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ActiveBudgetModel?>, ActiveBudgetModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ActiveBudgetModel?>, ActiveBudgetModel?>,
              AsyncValue<ActiveBudgetModel?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
