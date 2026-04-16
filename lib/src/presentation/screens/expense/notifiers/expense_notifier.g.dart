// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExpenseNotifier)
final expenseProvider = ExpenseNotifierProvider._();

final class ExpenseNotifierProvider
    extends $NotifierProvider<ExpenseNotifier, ExpenseState> {
  ExpenseNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseNotifierHash();

  @$internal
  @override
  ExpenseNotifier create() => ExpenseNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExpenseState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExpenseState>(value),
    );
  }
}

String _$expenseNotifierHash() => r'db79d5ae6e01fdccf524c847d7aae228e385666b';

abstract class _$ExpenseNotifier extends $Notifier<ExpenseState> {
  ExpenseState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ExpenseState, ExpenseState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ExpenseState, ExpenseState>,
              ExpenseState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
