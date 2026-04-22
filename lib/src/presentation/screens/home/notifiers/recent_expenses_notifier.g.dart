// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_expenses_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RecentExpensesNotifier)
final recentExpensesProvider = RecentExpensesNotifierProvider._();

final class RecentExpensesNotifierProvider
    extends $AsyncNotifierProvider<RecentExpensesNotifier, List<ExpenseModel>> {
  RecentExpensesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentExpensesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentExpensesNotifierHash();

  @$internal
  @override
  RecentExpensesNotifier create() => RecentExpensesNotifier();
}

String _$recentExpensesNotifierHash() =>
    r'b50c75fa8598d4869b22f11328745b1c6b2b0f5b';

abstract class _$RecentExpensesNotifier
    extends $AsyncNotifier<List<ExpenseModel>> {
  FutureOr<List<ExpenseModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ExpenseModel>>, List<ExpenseModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ExpenseModel>>, List<ExpenseModel>>,
              AsyncValue<List<ExpenseModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
