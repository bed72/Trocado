import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/data/expense_presentation_data.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class ExpenseWidget extends StatelessWidget {
  final ValueChanged<int?> navigatTo;
  final ExpensePresentationData data;

  const ExpenseWidget({super.key, required this.data, required this.navigatTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: () => navigatTo(data.id),
      child: Card(
        color: data.category.color.withValues(alpha: .04),
        margin: const .symmetric(vertical: 4.0),
        child: ListTile(
          leading: BackgroundIconWidget(
            icon: data.category.icon,
            color: data.category.color,
          ),
          title: Text(
            data.description,
            style: context.typography.bodyMedium?.copyWith(fontWeight: .w600),
          ),
          subtitle: Text(data.date, style: context.typography.bodySmall),
          trailing: Text(
            data.formattedAmount,
            style: context.typography.bodyMedium?.copyWith(fontWeight: .w600),
          ),
        ),
      ),
    );
  }
}
