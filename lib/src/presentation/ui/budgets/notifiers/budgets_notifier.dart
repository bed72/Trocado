import 'dart:math';

import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/main/providers/services_provider.dart';
import 'package:trocado/src/main/providers/repositories_provider.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/budget/budget_model.dart';
import 'package:trocado/src/domain/models/budget/budgets_page_model.dart';
import 'package:trocado/src/domain/repositories/interface_budget_repository.dart';

import 'package:trocado/src/presentation/data/budget/budget_card_presentation_data.dart';
import 'package:trocado/src/presentation/ui/budgets/notifiers/budgets_state.dart';
import 'package:trocado/src/presentation/ui/budgets/data/budget_item_presentation_data.dart';

part 'budgets_notifier.g.dart';

@Riverpod(keepAlive: true)
final class BudgetsNotifier extends _$BudgetsNotifier {
  late IMoneyService _moneyService;
  late IBudgetRepository _repository;

  @override
  Future<BudgetsState> build() async {
    _moneyService = ref.watch(moneyServiceProvider);
    _repository = ref.watch(budgetRepositoryProvider);

    return await _loadFirstPage();
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

    return data.fold(
      (failure) => throw failure,
      (page) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final active = _pickActive(page.budgets, now);
        final remaining = active == null
            ? page.budgets
            : page.budgets.where((b) => b.id != active.id).toList();

        return BudgetsState(
          nextCursor: page.nextCursor,
          activeCard: active == null ? null : _toCardData(active),
          items: remaining.map(_toItem).toList(),
        );
      },
    );
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
        formattedValue: _moneyService.format(budget.value / 100),
        formattedTotalSpent: _moneyService.format((budget.totalSpent ?? 0) / 100),
        formattedRemaining: _moneyService.format((budget.remaining ?? 0) / 100),
        formattedPeriod: _formatPeriod(budget.startDate, budget.endDate),
      );

  BudgetCardPresentationData _toCardData(BudgetModel model) {
    final value = model.value;
    final totalSpent = model.totalSpent ?? 0;
    final remaining = model.remaining ?? (value - totalSpent);
    final percentage = value > 0 ? totalSpent / value : 0.0;
    final dailyBudget =
        (remaining / max(1, _daysRemaining(model.endDate))).round();

    return BudgetCardPresentationData(
      percentage: percentage,
      overspent: remaining < 0,
      formattedEndDate: _formatEndDate(model.endDate),
      formattedValue: _moneyService.format(value / 100),
      formattedDailyBudget: _moneyService.format(dailyBudget / 100),
      formattedTotalSpent: _moneyService.format(totalSpent / 100),
      formattedOverspent: _moneyService.format(remaining.abs() / 100),
      formattedRemaining: _moneyService.format(max(0, remaining) / 100),
      formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
    );
  }

  String _formatPeriod(int startMs, int endMs) {
    final start = DateTime.fromMillisecondsSinceEpoch(startMs);
    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    final currentYear = DateTime.now().year;
    final sameYear = start.year == currentYear && end.year == currentYear;
    final pattern = sameYear ? 'dd/MM' : 'dd/MM/yy';
    final format = DateFormat(pattern, 'pt_BR');

    return '${format.format(start)} – ${format.format(end)}';
  }

  String _formatEndDate(int endDate) => DateFormat(
    'dd/MM',
    'pt_BR',
  ).format(DateTime.fromMillisecondsSinceEpoch(endDate));

  int _daysRemaining(int endDate) {
    final now = DateTime.now();
    final end = DateTime.fromMillisecondsSinceEpoch(endDate);
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(end.year, end.month, end.day);

    return endDay.difference(today).inDays + 1;
  }
}
