import 'package:flutter/widgets.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/presentation/states/category_state.dart';
import 'package:trocado/modules/category/presentation/widgets/categories_widget.dart';

class CategoryScreen extends StatefulWidget {
  final TransactionTypeState type;
  final ValueChanged<CategoryState> onSelected;

  const CategoryScreen({
    super.key,
    required this.type,
    required this.onSelected,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  CategoryState? _selected;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {},
      child: BottomSheetScaffoldWidget(
        title: 'Categorias',
        subtitle: 'Escolha a categoria que melhor representa esta transação.',
        child: CustomScrollView(
          shrinkWrap: true,
          slivers: [
            CategoriesWidget(
              type: widget.type,
              selected: _selected,
              onSelected: (category) {
                setState(() => _selected = category);
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12.0)),

            SliverToBoxAdapter(
              child: Container(
                width: .infinity,
                padding: .only(bottom: 20.0),
                child: ButtonWidget.elevated(
                  label: 'Selecionar',
                  onTap: _selected == null
                      ? null
                      : () {
                          widget.onSelected(_selected!);
                          context.pop();
                        },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
