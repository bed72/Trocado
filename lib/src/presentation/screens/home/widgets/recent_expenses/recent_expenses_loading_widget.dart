import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/domain/services/money_service.dart';
import 'package:trocado/src/domain/models/expense/expense_model.dart';

import 'package:trocado/src/presentation/screens/home/widgets/recent_expenses/expense_item_widget.dart';

class RecentExpensesLoadingWidget extends StatelessWidget {
  final IMoneyService moneyService;

  const RecentExpensesLoadingWidget({super.key, required this.moneyService});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        mainAxisSize: .min,
        children: List.generate(
          3,
          (_) => ExpenseItemWidget(
            expense: _placeholder,
            moneyService: moneyService,
          ),
        ),
      ),
    );
  }
}

final _placeholder = ExpenseModel(
  id: 0,
  date: 0,
  value: 0,
  createdAt: 0,
  category: .unknown,
  description: 'Carregando descrição da despesa',
);
