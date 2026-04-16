import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/go_back_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_date_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_save_button_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_amount_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_description_field_widget.dart';

class ExpenseScreen extends StatelessWidget {
  final int? id;

  final VoidCallback navigateToDate;
  final VoidCallback navigateToCalculator;

  const ExpenseScreen({
    super.key,
    required this.navigateToDate,
    required this.navigateToCalculator,
    this.id,
  });

  @override
  Widget build(BuildContext context) => ScaffoldWidget(
    appBar: AppBarWidget(leading: GoBackWidget()),
    child: Padding(
      padding: const .all(16.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                spacing: 16.0,
                crossAxisAlignment: .start,
                children: [
                  Text(
                    id != null ? 'Editar despesa' : 'Nova despesa',
                    style: context.typography.headlineMedium?.copyWith(
                      fontWeight: .bold,
                    ),
                  ),
                  Text(
                    'Preencha as informações abaixo para registrar sua despesa.',
                    style: context.typography.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  ExpenseDescriptionFieldWidget(),
                  ExpenseAmountFieldWidget(navigateTo: navigateToCalculator),
                  ExpenseDateFieldWidget(navigateTo: navigateToDate),
                ],
              ),
            ),
          ),
          ExpenseSaveButtonWidget(),
        ],
      ),
    ),
  );
}
