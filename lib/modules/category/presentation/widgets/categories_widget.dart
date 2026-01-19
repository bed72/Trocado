import 'package:flutter/material.dart';

import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';
import 'package:trocado/modules/category/presentation/widgets/category_widget.dart';

class CategoriesWidget extends StatelessWidget {
  final CategoryDto? selected;
  final TransactionTypeDto type;
  final ValueChanged<CategoryDto> onSelected;

  const CategoriesWidget({
    super.key,
    required this.type,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = CategoryDto.categoriesBy(type);

    return SliverList(
      delegate: SliverChildBuilderDelegate((_, index) {
        final category = categories[index];

        return CategoryWidget(
          category: category,
          selected: selected == category,
          onTap: () => onSelected(category),
        );
      }, childCount: categories.length),
    );
  }
}
