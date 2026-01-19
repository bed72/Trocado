import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/presentation/cubits/category_cubit.dart';
import 'package:trocado/modules/category/presentation/widgets/categories_widget.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryCubit cubit;
  final TransactionTypeDto type;

  const CategoryScreen({super.key, required this.type, required this.cubit});

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
                BlocBuilder<CategoryCubit, CategoryState>(
                  bloc: widget.cubit,
                  builder: (_, state) => CategoriesWidget(
                    type: widget.type,
                    selected: state.category,
                    onSelected: widget.cubit.select,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16.0)),
              ],
            ),
          ),

          Container(
            width: .infinity,
            padding: .symmetric(vertical: 20.0),
            child: ButtonWidget.elevated(
              onTap: context.pop,
              label: 'Selecionar',
            ),
          ),
        ],
      ),
    );
  }
}
