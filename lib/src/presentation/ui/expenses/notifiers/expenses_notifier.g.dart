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

String _$expensesNotifierHash() => r'5771a5ea9bbcaf1d5cff93037729b0f56640f24f';

abstract class _$ExpensesNotifier extends $AsyncNotifier<ExpensesState> {
  FutureOr<ExpensesState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ExpensesState>, ExpensesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ExpensesState>, ExpensesState>,
              AsyncValue<ExpensesState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
