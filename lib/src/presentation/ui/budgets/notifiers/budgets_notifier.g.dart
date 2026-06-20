// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budgets_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BudgetsNotifier)
final budgetsProvider = BudgetsNotifierProvider._();

final class BudgetsNotifierProvider
    extends $AsyncNotifierProvider<BudgetsNotifier, BudgetsState> {
  BudgetsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetsNotifierHash();

  @$internal
  @override
  BudgetsNotifier create() => BudgetsNotifier();
}

String _$budgetsNotifierHash() => r'dd7022e21c2b927ecfc8f4c2c93052f6f6f946fe';

abstract class _$BudgetsNotifier extends $AsyncNotifier<BudgetsState> {
  FutureOr<BudgetsState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BudgetsState>, BudgetsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BudgetsState>, BudgetsState>,
              AsyncValue<BudgetsState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
