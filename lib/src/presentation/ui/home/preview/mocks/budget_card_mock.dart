import 'dart:math';

import 'package:trocado/src/presentation/ui/home/data/budget_card_presentation_data.dart';

String _format(double value) =>
    'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

BudgetCardPresentationData budgetCardMock({
  required int value,
  required int remaining,
  required int totalSpent,
  required String formattedEndDate,
}) {
  final percentage = value > 0 ? totalSpent / value : 0.0;
  final dailyBudget = (remaining / max(1, 7)).round();

  return BudgetCardPresentationData(
    percentage: percentage,
    overspent: remaining < 0,
    formattedEndDate: formattedEndDate,
    formattedValue: _format(value / 100),
    formattedTotalSpent: _format(totalSpent / 100),
    formattedDailyBudget: _format(dailyBudget / 100),
    formattedOverspent: _format(remaining.abs() / 100),
    formattedRemaining: _format(max(0, remaining) / 100),
    formattedPercentage: (percentage * 100).clamp(0, 100).toStringAsFixed(0),
  );
}
