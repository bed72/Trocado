import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trocado/src/presentation/widgets/category/categories_widget.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/cubits/category/category_cubit.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryCubit cubit;

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
                BlocBuilder<CategoryCubit, CategoryState>(
                  bloc: widget.cubit,
                  builder: (_, state) => CategoriesWidget(
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
