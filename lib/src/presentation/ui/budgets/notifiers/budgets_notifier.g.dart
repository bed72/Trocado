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

String _$budgetsNotifierHash() => r'2dddc3c5295571a30f032183b51432c678e5e7c0';

abstract class _$BudgetsNotifier extends $AsyncNotifier<BudgetsState> {
  FutureOr<BudgetsState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<BudgetsState>, BudgetsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<BudgetsState>, BudgetsState>,
              AsyncValue<BudgetsState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
