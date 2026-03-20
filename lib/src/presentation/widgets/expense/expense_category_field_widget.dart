import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/fields/text_field_widget.dart';

import 'package:trocado/src/presentation/data/category_presentation_data.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_state.dart';

class ExpenseCategoryFieldWidget extends StatelessWidget {
  final VoidCallback navigateTo;

  const ExpenseCategoryFieldWidget({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: navigateTo,
      child:
          BlocSelector<
            ExpenseFormBloc,
            ExpenseFormState,
            CategoryPresentationData
          >(
            selector: (state) => state.category,
            builder: (_, category) => TextFieldWidget(
              readOnly: true,
              absorbing: true,
              hint: 'Categoria',
              key: ValueKey(category),
              initialValue: category.label,
            ),
          ),
    );
  }
}
