import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/transaction/transaction.dart';

import 'package:trocado/modules/category/data/dtos/category_dto.dart';
import 'package:trocado/modules/category/presentation/widgets/category_widget.dart';

class CategoriesWidget extends StatelessWidget {
  final CategoryDto? selected;
  final ValueChanged<CategoryDto> onSelected;

  List<CategoryDto> get _incomeCategories => CategoryDto.values
      .where((category) => category.types.contains(TransactionTypeDto.income))
      .toList();

  List<CategoryDto> get _expenseCategories => CategoryDto.values
      .where((category) => category.types.contains(TransactionTypeDto.expense))
      .toList();

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
        _buildCategories(_incomeCategories),

        const SliverToBoxAdapter(child: SizedBox(height: 16.0)),

        _buildSectionHeader(
          context: context,
          title: 'Despesas',
          icon: Icons.trending_down,
          color: context.colors.error,
        ),
        _buildCategories(_expenseCategories),
      ],
    );
  }

  SliverList _buildCategories(List<CategoryDto> categories) => SliverList(
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
          BackgroundIconWidget(name: icon, color: color),
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
