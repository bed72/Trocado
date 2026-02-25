import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';

import 'package:trocado/src/presentation/widgets/budget/budget_date_field_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/budget_save_button_widget.dart';
import 'package:trocado/src/presentation/widgets/budget/budget_amount_field_widget.dart';

class BudgetScreen extends StatelessWidget {
  final VoidCallback navigateToDate;
  final VoidCallback navigateToCalculator;

  const BudgetScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(title: 'Novo orçamento', leading: GoBackWidget()),
      child: Padding(
        padding: const .all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  spacing: 16.0,
                  children: [
                    BudgetAmountFieldWidget(navigateTo: navigateToCalculator),
                    BudgetDateFieldWidget(navigateTo: navigateToDate),
                  ],
                ),
              ),
            ),
            BudgetSaveButtonWidget(),
          ],
        ),
      ),
    );
  }
}
