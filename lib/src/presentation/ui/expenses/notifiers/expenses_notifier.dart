import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/models/expense/expenses_page_model.dart';
import 'package:trocado/src/domain/models/expense/expense_filter_model.dart';
import 'package:trocado/src/domain/repositories/interface_expense_repository.dart';

import 'package:trocado/src/presentation/actions/debounce_action.dart';
import 'package:trocado/src/presentation/data/expense_item_presentation_data.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_visual_extension.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_groups_builder.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_active_filter_chip_presentation_data.dart';

part 'expenses_notifier.g.dart';

@Riverpod(keepAlive: true)
final class ExpensesNotifier extends _$ExpensesNotifier {
  late IMoneyService _moneyService;
  late DebounceAction _searchDebounce;
  late IExpenseRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<ExpensesState> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(expenseRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    _searchDebounce = DebounceAction();
    ref.onDispose(_searchDebounce.dispose);

    return await _loadFirstPage(const .empty());
  }

  Future<void> applyFilter(ExpenseFilterModel filter) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _loadFirstPage(filter.normalized()));
  }

  void searchChanged(String description) {
    _searchDebounce(() {
      final current = state.value?.filter ?? const .empty();
      applyFilter(current.copyWith(description: description));
    });
  }

  Future<void> removeFilter(ExpenseFilterChipKind kind) async {
    final current = state.value?.filter ?? const .empty();

    final next = switch (kind) {
      .ordering => current.copyWith(ordering: .dateDesc),
      .category => current.copyWith(clearCategory: true),
      .value => current.copyWith(clearMinValue: true, clearMaxValue: true),
      .period => current.copyWith(clearEndDate: true, clearStartDate: true),
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
      filter: current.filter,
      cursor: current.nextCursor,
    );

    state = AsyncData(
      data.fold<ExpensesState>(
        (Failure failure) =>
            current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        (ExpensesPageModel page) {
          final items = [...current.items, ...page.expenses.map(_toItem)];
          return current.copyWith(
            items: items,
            isLoadingMore: false,
            clearLoadMoreFailure: true,
            nextCursor: page.nextCursor,
            groups: buildExpenseGroups(items, dateFormatter: _dateFormatter),
            clearNextCursor: page.nextCursor == null,
          );
        },
      ),
    );
  }

  Future<ExpensesState> _loadFirstPage(ExpenseFilterModel filter) async {
    final data = await _repository.findAll(filter: filter);

    return data.fold((failure) => throw failure, (page) {
      final items = page.expenses.map(_toItem).toList();

      return ExpensesState(
        items: items,
        filter: filter,
        nextCursor: page.nextCursor,
        activeFilterChips: _buildChips(filter),
        groups: buildExpenseGroups(items, dateFormatter: _dateFormatter),
      );
    });
  }

  ExpenseItemPresentationData _toItem(ExpenseModel expense) =>
      ExpenseItemPresentationData(
        expense: expense,
        formattedValue: _moneyService.format(expense.value / 100),
        formattedTime: _dateFormatter.formatTime(expense.createdAt),
        formattedDate: _dateFormatter.formatDayMonth(expense.createdAt),
      );

  List<ExpenseActiveFilterChipPresentationData> _buildChips(
    ExpenseFilterModel filter,
  ) {
    final chips = <ExpenseActiveFilterChipPresentationData>[];

    if (filter.category != null) {
      chips.add(
        ExpenseActiveFilterChipPresentationData(
          kind: .category,
          icon: filter.category!.icon,
          label: filter.category!.label,
        ),
      );
    }

    if (filter.startDate != null || filter.endDate != null) {
      chips.add(
        ExpenseActiveFilterChipPresentationData(
          kind: .period,
          label: _periodLabel(filter.startDate, filter.endDate),
        ),
      );
    }

    if (filter.minValue != null || filter.maxValue != null) {
      chips.add(
        ExpenseActiveFilterChipPresentationData(
          kind: .value,
          label: _valueLabel(filter.minValue, filter.maxValue),
        ),
      );
    }

    if (filter.ordering != .dateDesc) {
      chips.add(
        ExpenseActiveFilterChipPresentationData(
          kind: .ordering,
          label: filter.ordering.label,
        ),
      );
    }

    return chips;
  }

  String _periodLabel(int? start, int? end) {
    final startLabel = start != null
        ? _dateFormatter.formatShortDate(start)
        : null;
    final endLabel = end != null ? _dateFormatter.formatShortDate(end) : null;

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
