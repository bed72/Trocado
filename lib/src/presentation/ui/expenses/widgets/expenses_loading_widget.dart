import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:trocado/src/domain/models/expense/expense_model.dart';

import 'package:trocado/src/presentation/widgets/expense/expense_item_widget.dart';

class ExpensesLoadingWidget extends StatelessWidget {
  const ExpensesLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: Column(
      mainAxisSize: .min,
      children: .generate(
        12,
        (_) => const ExpenseItemWidget(
          expense: _placeholder,
          formattedDate: _placeholderDate,
          formattedValue: _placeholderValue,
        ),
      ),
    ),
  );
}

const _placeholderValue = 'R\$ 000,00';
const _placeholderDate = '00 de Mmm';
const _placeholder = ExpenseModel(
  id: 0,
  date: 0,
  value: 0,
  createdAt: 0,
  category: .unknown,
  description: 'Carregando descrição da despesa',
);
