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
    extends
        $AsyncNotifierProvider<
          RecentExpensesNotifier,
          List<ExpenseItemPresentationData>
        > {
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
    r'5707aa6c445ad69236c1550cf92b31f0ade8c574';

abstract class _$RecentExpensesNotifier
    extends $AsyncNotifier<List<ExpenseItemPresentationData>> {
  FutureOr<List<ExpenseItemPresentationData>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<ExpenseItemPresentationData>>,
              List<ExpenseItemPresentationData>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<ExpenseItemPresentationData>>,
                List<ExpenseItemPresentationData>
              >,
              AsyncValue<List<ExpenseItemPresentationData>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
