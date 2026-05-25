import 'package:flutter/material.dart';

import 'package:trocado/src/domain/enums/expense/expense_category_enum.dart';

import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/expense/expense_category_visual_extension.dart';

class ExpensesFilterCategorySectionWidget extends StatelessWidget {
  final ExpenseCategoryEnum? selected;
  final ValueChanged<ExpenseCategoryEnum?> onSelected;

  const ExpensesFilterCategorySectionWidget({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const List<ExpenseCategoryEnum> _categories = [
    .food,
    .debt,
    .health,
    .housing,
    .shopping,
    .transport,
    .entertainment,
  ];

  @override
  Widget build(BuildContext context) => Column(
    spacing: 8.0,
    crossAxisAlignment: .start,
    children: [
      Text(
        'Categoria',
        style: context.typography.titleMedium?.copyWith(fontWeight: .w600),
      ),
      Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: _categories
            .map((category) => _chip(context, category))
            .toList(),
      ),
    ],
  );

  Widget _chip(BuildContext context, ExpenseCategoryEnum category) {
    final color = category.color(context);
    final isSelected = category == selected;

    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      materialTapTargetSize: .shrinkWrap,
      selectedColor: color.withValues(alpha: 0.15),
      labelPadding: const .symmetric(horizontal: 4.0),
      backgroundColor: context.colors.surfaceContainerHighest,
      onSelected: (_) => onSelected(isSelected ? null : category),
      label: Text(
        category.label,
        style: TextStyle(
          fontWeight: isSelected ? .w600 : null,
          color: isSelected ? color : context.colors.onSurfaceVariant,
        ),
      ),
      avatar: Icon(
        category.icon,
        size: 18.0,
        color: isSelected ? color : context.colors.onSurfaceVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: context.radius.cornerRadius050,
        side: BorderSide(color: isSelected ? color : Colors.transparent),
      ),
    );
  }
}
