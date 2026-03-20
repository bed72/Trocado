import 'package:flutter/widgets.dart';

import 'package:trocado/src/presentation/bloc/expense_form/expense_form_bloc.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/category/categories_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class CategoryScreen extends StatelessWidget {
  final ExpenseFormBloc bloc;

  const CategoryScreen({super.key, required this.bloc});

  @override
  Widget build(BuildContext context) {
    return BottomSheetScaffoldWidget(
      title: 'Categorias',
      subtitle: 'Escolha a categoria que melhor representa esta transação.',
      child: Column(
        mainAxisSize: .min,
        children: [
          Flexible(
            child: CustomScrollView(
              shrinkWrap: true,
              slivers: [
                CategoriesWidget(bloc: bloc),
                const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
              ],
            ),
          ),
          Container(
            width: .infinity,
            padding: const .symmetric(vertical: 20.0),
            child: ButtonWidget.outlined(
              onTap: context.pop,
              label: 'Selecionar',
            ),
          ),
        ],
      ),
    );
  }
}
