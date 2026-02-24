import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/expense/expense_date_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_amount_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_description_field_widget.dart';

class TransactionsFormWidget extends StatefulWidget {
  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const TransactionsFormWidget({
    super.key,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
  });

  @override
  State<TransactionsFormWidget> createState() => _TransactionsFormWidgetState();
}

class _TransactionsFormWidgetState extends State<TransactionsFormWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 16.0,
      crossAxisAlignment: .start,
      children: [
        ExpenseDescriptionFieldWidget(),
        ExpenseDateFieldWidget(navigateTo: widget.navigateToDate),
        ExpenseAmountFieldWidget(navigateTo: widget.navigateToCalculator),
        ExpenseCategoryFieldWidget(navigateTo: widget.navigateToCategory),
      ],
    );
  }
}
