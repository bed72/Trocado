import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';
import 'package:trocado/src/domain/services/money_service.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';

import 'package:trocado/src/presentation/screens/home/widgets/recent_expenses/expense_item_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/recent_expenses/recent_expenses_empty_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/recent_expenses/recent_expenses_loading_widget.dart';
import 'package:trocado/src/presentation/screens/home/widgets/recent_expenses/recent_expenses_failure_widget.dart';

class RecentExpensesSectionWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onSeeAll;
  final IMoneyService moneyService;
  final AsyncValue<List<ExpenseModel>> state;

  const RecentExpensesSectionWidget({
    super.key,
    required this.state,
    required this.onRetry,
    required this.onSeeAll,
    required this.moneyService,
  });

  @override
  Widget build(BuildContext context) => Column(
    spacing: 8.0,
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: [
      Padding(
        padding: const .symmetric(horizontal: 20.0),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          crossAxisAlignment: .center,
          children: [
            Text(
              'Despesas recentes',
              style: context.typography.titleMedium?.copyWith(
                fontWeight: .w600,
                color: context.colors.onSurface,
              ),
            ),
            ButtonWidget.text(onTap: onSeeAll, label: 'Ver tudo'),
          ],
        ),
      ),
      switch (state) {
        AsyncLoading() => RecentExpensesLoadingWidget(
          moneyService: moneyService,
        ),
        AsyncError() => RecentExpensesFailureWidget(onRetry: onRetry),
        AsyncData(:final value) when value.isEmpty =>
          const RecentExpensesEmptyWidget(),
        AsyncData(:final value) => Column(
          mainAxisSize: .min,
          children: [
            for (final expense in value)
              ExpenseItemWidget(expense: expense, moneyService: moneyService),
          ],
        ),
      },
    ],
  );
}
