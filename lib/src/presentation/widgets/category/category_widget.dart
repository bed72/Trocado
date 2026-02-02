import 'package:flutter/material.dart';

import 'package:trocado/src/domain/models/category_model.dart';

import 'package:trocado/src/presentation/animation/animation.dart';
import 'package:trocado/src/presentation/widgets/icons/icon_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryModel category;
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
          icon: category.icon,
          color: category.color,
        ),
        title: Text(
          category.label,
          style: context.typography.bodyLarge?.copyWith(fontWeight: .w600),
        ),
        trailing: SwitcherAnimation(
          child: selected
              ? IconWidget(
                  icon: Icons.check_circle,
                  color: context.colors.primary,
                  key: const ValueKey('selected'),
                )
              : const SizedBox(key: ValueKey('empty'), width: 24.0),
        ),
      ),
    );
  }
}
