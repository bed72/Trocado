import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/category/category.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryDto category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryWidget({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: .symmetric(horizontal: 0.0, vertical: 4.0),
      child: ListTile(
        onTap: onTap,
        leading: BackgroundIconWidget(
          name: category.icon,
          color: category.color,
        ),
        title: Text(
          category.label,
          style: context.typography.bodyLarge?.copyWith(fontWeight: .w600),
        ),
        trailing: SwitcherAnimation(
          child: selected
              ? IconWidget(
                  name: Icons.check_circle,
                  color: context.colors.primary,
                  key: const ValueKey('selected'),
                )
              : const SizedBox(key: ValueKey('empty'), width: 24.0),
        ),
      ),
    );
  }
}
