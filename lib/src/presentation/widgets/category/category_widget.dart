import 'package:flutter/material.dart';
import 'package:flutter_rearch/flutter_rearch.dart';

import 'package:trocado/src/presentation/animation/animation.dart';
import 'package:trocado/src/presentation/capsules/category_capsule.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/data/category_presentation_data.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class CategoryWidget extends StatelessWidget {
  final CategoryPresentationData category;

  const CategoryWidget({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return RearchBuilder(
      builder: (_, use) {
        final (selected, setSelected) = use(categoryCapsule);
        final isSelected = selected == category;

        return BounceWidget.withOnPress(
          onPress: () => setSelected(category),
          child: Card(
            color: isSelected
                ? category.color.withValues(alpha: .04)
                : context.colors.surface,
            margin: const .symmetric(horizontal: 0.0, vertical: 4.0),
            child: ListTile(
              leading: BackgroundIconWidget(
                icon: category.icon,
                color: category.color,
              ),
              title: Text(
                category.label,
                style: context.typography.bodyLarge?.copyWith(
                  fontWeight: isSelected ? .bold : .w600,
                ),
              ),

              trailing: SwitcherAnimation(
                child: isSelected
                    ? BackgroundIconWidget(
                        width: 32.0,
                        height: 32.0,
                        icon: Icons.check,
                        color: category.color,
                        borderRadius: .circular(14.0),
                        key: ValueKey('selected-${category.labelKey}'),
                      )
                    : SizedBox(
                        key: ValueKey('empty-${category.labelKey}'),
                        width: 24.0,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
