import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';

import 'package:trocado/src/presentation/widgets/app_bar_widget.dart';
import 'package:trocado/src/presentation/widgets/scaffold_widget.dart';
import 'package:trocado/src/presentation/widgets/buttons/icon_button_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_date_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_save_button_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_amount_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_field_widget.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_description_field_widget.dart';

class ExpenseScreen extends StatelessWidget {
  final int? id;

  final ExpenseFormBloc bloc;
  final VoidCallback navigateToDate;
  final VoidCallback navigateToCategory;
  final VoidCallback navigateToCalculator;

  const ExpenseScreen({
    super.key,
    required this.bloc,
    required this.navigateToDate,
    required this.navigateToCategory,
    required this.navigateToCalculator,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldWidget(
      appBar: AppBarWidget(
        title: 'Nova Despesa',
        leading: _buildGoBack(context),
      ),
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
                    ExpenseDescriptionFieldWidget(bloc: bloc),
                    ExpenseAmountFieldWidget(
                      bloc: bloc,
                      navigateTo: navigateToCalculator,
                    ),
                    ExpenseDateFieldWidget(navigateTo: navigateToDate),
                    ExpenseCategoryFieldWidget(navigateTo: navigateToCategory),
                  ],
                ),
              ),
            ),
            ExpenseSaveButtonWidget(bloc: bloc),
          ],
        ),
      ),
    );
  }

  IconButtonWidget _buildGoBack(BuildContext context) => IconButtonWidget(
    width: 36.0,
    height: 36.0,
    iconSize: 24.0,
    onPress: context.pop,
    icon: Icons.chevron_left,
    borderRadius: .circular(14.0),
  );
}
