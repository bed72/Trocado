import 'package:flutter/material.dart';

import 'package:trocado/src/presentation/widgets/bounce_widget.dart';
import 'package:trocado/src/presentation/extensions/context_extension.dart';
import 'package:trocado/src/presentation/widgets/icons/background_icon_widget.dart';

class ExpenseWidget extends StatelessWidget {
  final ValueChanged<int?> navigatTo;

  const ExpenseWidget({super.key, required this.navigatTo});

  @override
  Widget build(BuildContext context) {
    return BounceWidget.withOnPress(
      onPress: () {}, //=> navigatTo(data.id),
      child: Card(
        color: Colors.amberAccent.withValues(alpha: .04),
        margin: const .symmetric(vertical: 4.0),
        child: ListTile(
          leading: BackgroundIconWidget(
            icon: Icons.add_ic_call_outlined,
            color: Colors.amberAccent,
          ),
          title: Text(
            'data.description',
            style: context.typography.bodyMedium?.copyWith(fontWeight: .w600),
          ),
          subtitle: Text('data.date', style: context.typography.bodySmall),
          trailing: Text(
            'data.formattedAmount',
            style: context.typography.bodyMedium?.copyWith(fontWeight: .w600),
          ),
        ),
      ),
    );
  }
}
