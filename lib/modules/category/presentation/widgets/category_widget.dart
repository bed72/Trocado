import 'package:flutter/material.dart';

import 'package:trocado/modules/core/core.dart';
import 'package:trocado/modules/category/category.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryData category;
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
      shape: RoundedRectangleBorder(borderRadius: .circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const .symmetric(vertical: 8.0, horizontal: 12.0),
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
