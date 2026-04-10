import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/category/category_widget.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = CategoryPresentationData.values;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: categories.length,
        (_, index) => CategoryWidget(category: categories[index]),
      ),
    );
  }
}
