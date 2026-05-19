import 'package:flutter/material.dart';
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

import 'package:trocado/src/presentation/ui/home/notifiers/insights_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';
import 'package:trocado/src/presentation/ui/home/notifiers/recent_expenses_notifier.dart';

import 'package:trocado/src/presentation/ui/expenses/notifiers/expenses_state.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_groups_builder.dart';
import 'package:trocado/src/presentation/ui/expenses/data/expense_filter_chip_kind.dart';
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
    state = await AsyncValue.guard(() => _loadFirstPage(filter));
  }

  void searchChanged(String description) {
    _searchDebounce(() {
      final current = state.value?.filter ?? const .empty();
      applyFilter(current.copyWith(description: description));
    });
  }

  Future<void> removeFilter(ExpenseFilterChipKind kind) async {
    final currentValue = state.value;
    final current = currentValue?.filter ?? const .empty();

    final next = switch (kind) {
      .description => current.copyWith(description: ''),
      .category => current.copyWith(clearCategory: true),
      .value => current.copyWith(clearMinValue: true, clearMaxValue: true),
      .period => current.copyWith(clearEndDate: true, clearStartDate: true),
    };

    if (currentValue != null) {
      state = AsyncData(
        currentValue.copyWith(
          filter: next,
          activeFilterChips: _buildChips(next),
        ),
      );
    }

    await applyFilter(next);
  }

  Future<void> deleteById(int id) async {
    final current = state.value;
    if (current == null) return;

    final originalIndex = current.items.indexWhere(
      (item) => item.expense.id == id,
    );
    if (originalIndex < 0) return;

    final originalItem = current.items[originalIndex];
    final newItems = [...current.items]..removeAt(originalIndex);

    state = AsyncData(
      current.copyWith(
        items: newItems,
        clearDeleteFailure: true,
        groups: buildExpenseGroups(newItems, dateFormatter: _dateFormatter),
      ),
    );

    final data = await _repository.delete(id: id);

    data.fold(
      (Failure failure) {
        final restored = [...state.value!.items];
        final insertAt = originalIndex.clamp(0, restored.length);
        restored.insert(insertAt, originalItem);

        state = AsyncData(
          state.value!.copyWith(
            items: restored,
            deleteFailure: failure,
            groups: buildExpenseGroups(restored, dateFormatter: _dateFormatter),
          ),
        );
      },
      (_) {
        ref.invalidate(insightsProvider);
        ref.invalidate(activeBudgetProvider);
        ref.invalidate(recentExpensesProvider);
      },
    );
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
            clearNextCursor: page.nextCursor == null,
            groups: buildExpenseGroups(items, dateFormatter: _dateFormatter),
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
        formattedDate: _dateFormatter.formatLongDate(expense.date),
      );

  List<ExpenseActiveFilterChipPresentationData> _buildChips(
    ExpenseFilterModel filter,
  ) {
    final chips = <ExpenseActiveFilterChipPresentationData>[];

    if (filter.description.isNotEmpty) {
      chips.add(
        ExpenseActiveFilterChipPresentationData(
          kind: .description,
          icon: Icons.search,
          label: 'Busca: ${filter.description}',
        ),
      );
    }

    if (filter.category != null) {
      chips.add(
        ExpenseActiveFilterChipPresentationData(
          kind: .category,
          icon: filter.category!.icon,
          label: filter.category!.label,
        ),
      );
    }

    if (filter.minValue != null || filter.maxValue != null) {
      chips.add(
        ExpenseActiveFilterChipPresentationData(
          kind: .value,
          icon: Icons.payments_outlined,
          label: _valueLabel(filter.minValue, filter.maxValue),
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

    return chips;
  }

  String _valueLabel(int? min, int? max) => switch ((min, max)) {
    (final int m, final int x) =>
      '${_moneyService.format(m / 100)} – ${_moneyService.format(x / 100)}',
    (final int m, null) => 'Acima de ${_moneyService.format(m / 100)}',
    (null, final int x) => 'Até ${_moneyService.format(x / 100)}',
    (null, null) => '',
  };

  String _periodLabel(int? start, int? end) => switch ((start, end)) {
    (final int s, final int e) => _dateFormatter.formatPeriod(s, e),
    (null, final int e) => 'até ${_dateFormatter.formatLongDate(e)}',
    (final int s, null) => 'desde ${_dateFormatter.formatLongDate(s)}',
    (null, null) => '',
  };
}
