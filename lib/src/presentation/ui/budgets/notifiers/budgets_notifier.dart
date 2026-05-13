import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/services/date_formatter_service.dart';

import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/data/budget/budget_card_presentation_data.dart';

import 'package:trocado/src/presentation/ui/home/notifiers/active_budget_notifier.dart';

import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_state.dart';
import 'package:trocado/src/presentation/ui/budgets/data/budget_item_presentation_data.dart';

part 'budgets_notifier.g.dart';

@Riverpod()
final class BudgetsNotifier extends _$BudgetsNotifier {
  late DateTime Function() _now;
  late IMoneyService _moneyService;
  late IBudgetRepository _repository;
  late IDateFormatterService _dateFormatter;

  @override
  Future<BudgetsState> build() async {
    _now = ref.watch(nowProvider);
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(budgetRepositoryProvider);
    _dateFormatter = ref.watch(dateFormatterServiceProvider);

    return await _loadFirstPage();
  }

  Future<void> deleteById(int id) async {
    final current = state.value;
    if (current == null) return;

    final originalIndex = current.items.indexWhere(
      (item) => item.budget.id == id,
    );
    if (originalIndex < 0) return;

    final originalItem = current.items[originalIndex];
    final newItems = [...current.items]..removeAt(originalIndex);

    state = AsyncData(
      current.copyWith(items: newItems, clearDeleteFailure: true),
    );

    final data = await _repository.delete(id: id);

    data.fold((Failure failure) {
      final restored = [...state.value!.items];
      final insertAt = originalIndex.clamp(0, restored.length);
      restored.insert(insertAt, originalItem);

      state = AsyncData(
        state.value!.copyWith(items: restored, deleteFailure: failure),
      );
    }, (_) => ref.invalidate(activeBudgetProvider));
  }

  Future<void> loadMore() async {
    final current = state.value;

    if (current == null) return;
    if (current.isLoadingMore) return;
    if (current.nextCursor == null) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, clearLoadMoreFailure: true),
    );

    final data = await _repository.findAll(cursor: current.nextCursor);

    state = AsyncData(
      data.fold<BudgetsState>(
        (Failure failure) =>
            current.copyWith(isLoadingMore: false, loadMoreFailure: failure),
        (BudgetsPageModel page) => current.copyWith(
          isLoadingMore: false,
          clearLoadMoreFailure: true,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          items: [...current.items, ...page.budgets.map(_toItem)],
        ),
      ),
    );
  }

  Future<BudgetsState> _loadFirstPage() async {
    final data = await _repository.findAll();

    return data.fold((failure) => throw failure, (page) {
      final now = _now().millisecondsSinceEpoch;
      final active = _pickActive(page.budgets, now);
      final remaining = active == null
          ? page.budgets
          : page.budgets.where((b) => b.id != active.id).toList();

      return BudgetsState(
        activeBudget: active,
        nextCursor: page.nextCursor,
        items: remaining.map(_toItem).toList(),
        activeCard: active == null ? null : _toCardData(active),
      );
    });
  }

  BudgetModel? _pickActive(List<BudgetModel> budgets, int now) {
    for (final budget in budgets) {
      if (now >= budget.startDate && now <= budget.endDate) return budget;
    }

    return null;
  }

  BudgetItemPresentationData _toItem(BudgetModel budget) =>
      BudgetItemPresentationData(
        budget: budget,
        formattedTotalSpent: _moneyService.format(
          (budget.totalSpent ?? 0) / 100,
        ),
        formattedValue: _moneyService.format(budget.value / 100),
        formattedPeriod: _dateFormatter.formatPeriod(
          budget.startDate,
          budget.endDate,
        ),
        formattedRemaining: _moneyService.format((budget.remaining ?? 0) / 100),
      );

  BudgetCardPresentationData _toCardData(BudgetModel model) {
    final value = model.value;
    final totalSpent = model.totalSpent ?? 0;
    final percentage = value > 0 ? totalSpent / value : 0.0;
    final remaining = model.remaining ?? (value - totalSpent);
    final dailyBudget =
        (remaining / max(1, _dateFormatter.daysUntil(model.endDate))).round();

    return BudgetCardPresentationData(
      percentage: percentage,
      overspent: remaining < 0,
      formattedValue: _moneyService.format(value / 100),
      formattedTotalSpent: _moneyService.format(totalSpent / 100),
      formattedDailyBudget: _moneyService.format(dailyBudget / 100),
      formattedEndDate: _dateFormatter.formatDayMonth(model.endDate),
      formattedOverspent: _moneyService.format(remaining.abs() / 100),
      formattedRemaining: _moneyService.format(max(0, remaining) / 100),
      formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
    );
  }
}
