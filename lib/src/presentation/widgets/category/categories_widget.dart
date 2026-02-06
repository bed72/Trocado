import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/category_model.dart';
import 'package:trocado/src/domain/models/transaction_model.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/category/category_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class CategoriesWidget extends StatelessWidget {
  final CategoryModel? selected;
  final ValueChanged<CategoryModel> onSelected;

  const CategoriesWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        _buildSectionHeader(
          context: context,
          title: 'Receitas',
          icon: Icons.trending_up,
          color: context.colors.primary,
        ),
        _buildCategories(CategoryModel.values),

        // _buildSectionHeader(
        //   context: context,
        //   title: 'Despesas',
        //   icon: Icons.trending_down,
        //   color: context.colors.error,
        // ),
        // _buildCategories(_expenseCategories),
      ],
    );
  }

  SliverList _buildCategories(List<CategoryModel> categories) => SliverList(
    delegate: SliverChildBuilderDelegate(childCount: categories.length, (
      _,
      index,
    ) {
      final category = categories[index];

      return CategoryWidget(
        category: category,
        selected: selected == category,
        onTap: () => onSelected(category),
      );
    }),
  );

  SliverToBoxAdapter _buildSectionHeader({
    required BuildContext context,
    required Color color,
    required String title,
    required IconData icon,
  }) => SliverToBoxAdapter(
    child: Padding(
      padding: const .symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        spacing: 16.0,
        children: [
          BackgroundIconWidget(icon: icon, color: color),
          Text(
            title,
            style: context.typography.bodyLarge?.copyWith(
              fontWeight: .w800,
              color: context.colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    ),
  );
}
