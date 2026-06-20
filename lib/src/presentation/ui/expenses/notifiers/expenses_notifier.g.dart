// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expenses_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpensesNotifier)
final expensesProvider = ExpensesNotifierProvider._();

final class ExpensesNotifierProvider
    extends $AsyncNotifierProvider<ExpensesNotifier, ExpensesState> {
  ExpensesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expensesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expensesNotifierHash();

  @$internal
  @override
  ExpensesNotifier create() => ExpensesNotifier();
}

String _$expensesNotifierHash() => r'254d4acd1aef0e869b3178d3cd4bb6edb4a7fb46';

abstract class _$ExpensesNotifier extends $AsyncNotifier<ExpensesState> {
  FutureOr<ExpensesState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExpensesState>, ExpensesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExpensesState>, ExpensesState>,
              AsyncValue<ExpensesState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
