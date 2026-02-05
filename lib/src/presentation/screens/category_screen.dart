import 'package:flutter/widgets.dart';

import 'package:trocado/src/presentation/widgets/category/categories_widget.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/cubits/transaction/transaction_cubit.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class CategoryScreen extends StatefulWidget {
  final TransactionCubit cubit;

  const CategoryScreen({super.key, required this.cubit});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
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
                BlocBuilder<TransactionCubit, TransactionState>(
                  bloc: widget.cubit,
                  builder: (_, state) => CategoriesWidget(
                    selected: state.form.category,
                    onSelected: widget.cubit.selectCategory,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
              ],
            ),
          ),

          Container(
            width: double.infinity,
            padding: .symmetric(vertical: 20.0),
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
