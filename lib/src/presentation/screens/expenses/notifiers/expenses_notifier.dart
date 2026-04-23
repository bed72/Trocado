import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expense_ordering.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/actions/debounce_action.dart';
import 'package:trocado/src/presentation/data/expense/expense_item_data.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_visual_extension.dart';

import 'package:trocado/src/presentation/screens/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/screens/expenses/data/expense_filter_chip_kind.dart';
import 'package:trocado/src/presentation/screens/expenses/data/expense_active_filter_chip_data.dart';

part 'expenses_notifier.g.dart';

@Riverpod(keepAlive: true)
final class ExpensesNotifier extends _$ExpensesNotifier {
  late IMoneyService _moneyService;
  late IExpenseRepository _repository;
  late DebounceAction _searchDebounce;

  @override
  Future<ExpensesState> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(expenseRepositoryProvider);
    _searchDebounce = DebounceAction();
    ref.onDispose(_searchDebounce.dispose);

    return await _loadFirstPage(const ExpenseFilterModel.empty());
  }

  Future<void> applyFilter(ExpenseFilterModel filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadFirstPage(filter.normalized()));
  }

  void searchChanged(String description) {
    _searchDebounce(() {
      final current =
          state.value?.filter ?? const ExpenseFilterModel.empty();
      applyFilter(current.copyWith(description: description));
    });
  }

  Future<void> removeFilter(ExpenseFilterChipKind kind) async {
    final current =
        state.value?.filter ?? const ExpenseFilterModel.empty();

    final next = switch (kind) {
      ExpenseFilterChipKind.category => current.copyWith(clearCategory: true),
      ExpenseFilterChipKind.period => current.copyWith(
        clearStartDate: true,
        clearEndDate: true,
      ),
      ExpenseFilterChipKind.value => current.copyWith(
        clearMinValue: true,
        clearMaxValue: true,
      ),
      ExpenseFilterChipKind.ordering => current.copyWith(
        ordering: ExpenseOrdering.dateDesc,
      ),
    };

    await applyFilter(next);
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null) return;
    if (current.isLoadingMore) return;
    if (current.nextCursor == null) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    final data = await _repository.findAll(
      cursor: current.nextCursor,
      filter: current.filter,
    );

    state = AsyncData(
      data.fold<ExpensesState>(
        (Failure failure) =>
            current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        (ExpensesPageModel page) => current.copyWith(
          isLoadingMore: false,
          clearLoadMoreFailure: true,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          items: [...current.items, ...page.expenses.map(_toItem)],
        ),
      ),
    );
  }

  Future<ExpensesState> _loadFirstPage(ExpenseFilterModel filter) async {
    final data = await _repository.findAll(filter: filter);

    return data.fold(
      (failure) => throw failure,
      (page) => ExpensesState(
        filter: filter,
        nextCursor: page.nextCursor,
        items: page.expenses.map(_toItem).toList(),
        activeFilterChips: _buildChips(filter),
      ),
    );
  }

  ExpenseItemData _toItem(ExpenseModel expense) => ExpenseItemData(
    expense: expense,
    formattedValue: _moneyService.format(expense.value / 100),
  );

  List<ExpenseActiveFilterChipData> _buildChips(ExpenseFilterModel filter) {
    final chips = <ExpenseActiveFilterChipData>[];

    if (filter.category != null) {
      chips.add(
        ExpenseActiveFilterChipData(
          label: filter.category!.label,
          icon: filter.category!.icon,
          kind: ExpenseFilterChipKind.category,
        ),
      );
    }

    if (filter.startDate != null || filter.endDate != null) {
      chips.add(
        ExpenseActiveFilterChipData(
          label: _periodLabel(filter.startDate, filter.endDate),
          kind: ExpenseFilterChipKind.period,
        ),
      );
    }

    if (filter.minValue != null || filter.maxValue != null) {
      chips.add(
        ExpenseActiveFilterChipData(
          label: _valueLabel(filter.minValue, filter.maxValue),
          kind: ExpenseFilterChipKind.value,
        ),
      );
    }

    if (filter.ordering != ExpenseOrdering.dateDesc) {
      chips.add(
        ExpenseActiveFilterChipData(
          label: filter.ordering.label,
          kind: ExpenseFilterChipKind.ordering,
        ),
      );
    }

    return chips;
  }

  String _periodLabel(int? start, int? end) {
    final format = DateFormat('dd/MM/yyyy', 'pt_BR');
    final startLabel = start != null
        ? format.format(DateTime.fromMillisecondsSinceEpoch(start))
        : null;
    final endLabel = end != null
        ? format.format(DateTime.fromMillisecondsSinceEpoch(end))
        : null;

    if (startLabel != null && endLabel != null) {
      return '$startLabel – $endLabel';
    }
    if (startLabel != null) return 'desde $startLabel';
    return 'até $endLabel';
  }

  String _valueLabel(int? min, int? max) {
    final minLabel = min != null ? _moneyService.format(min / 100) : null;
    final maxLabel = max != null ? _moneyService.format(max / 100) : null;

    if (minLabel != null && maxLabel != null) return '$minLabel – $maxLabel';
    if (minLabel != null) return '≥ $minLabel';
    return '≤ $maxLabel';
  }
}
