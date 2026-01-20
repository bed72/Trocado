import 'package:flutter/material.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';
import 'package:trocado/modules/category/presentation/widgets/category_widget.dart';

class CategoriesWidget extends StatelessWidget {
  final CategoryDto? selected;
  final ValueChanged<CategoryDto> onSelected;

  const CategoriesWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: CategoryDto.values.length,
        (_, index) {
          final category = CategoryDto.values[index];

          return CategoryWidget(
            category: category,
            selected: selected == category,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}
