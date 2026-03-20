import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/category/category_widget.dart';
import 'package:trocado/src/presentation/data/category_presentation_data.dart';
import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';

class CategoriesWidget extends StatelessWidget {
  final ExpenseFormBloc bloc;

  const CategoriesWidget({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    final categories = CategoryPresentationData.values;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: categories.length,
        (_, index) => CategoryWidget(bloc: bloc, category: categories[index]),
      ),
    );
  }
}
