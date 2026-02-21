import 'package:flutter/widgets.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/buttons/button_widget.dart';
import 'package:trocado/src/presentation/widgets/category/categories_widget.dart';
import 'package:trocado/src/presentation/widgets/bottom-sheets/bottom_sheet_scaffold_widget.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

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
                CategoriesWidget(),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const .symmetric(vertical: 20),
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
